-- ============================================================================
-- PHASE 4: WAITLIST MANAGEMENT & AUTO-BOOKING
-- ============================================================================
-- Implements intelligent waitlist system with:
-- 1. Priority-based waitlist queue
-- 2. Automatic slot notification when cancellations occur
-- 3. Auto-booking for waitlisted clients
-- 4. Expiring waitlist entries
-- 5. Preference matching (time, trainer, session type)
-- ============================================================================

-- STEP 1: Create waitlist table
-- ============================================================================

CREATE TABLE IF NOT EXISTS waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES client_packages(id) ON DELETE CASCADE,

  -- Waitlist Preferences
  preferred_dates DATE[],
  preferred_times TIME[],
  preferred_days_of_week INTEGER[], -- 0=Sunday, 1=Monday, etc.
  session_type TEXT DEFAULT 'in_person',
  duration_minutes INTEGER DEFAULT 60,
  location TEXT,
  notes TEXT,

  -- Priority & Status
  priority_score INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active', -- 'active', 'notified', 'booked', 'expired', 'cancelled'
  auto_book BOOLEAN DEFAULT FALSE, -- Auto-book when slot available

  -- Matching Criteria
  min_hours_notice INTEGER DEFAULT 24, -- Minimum notice required
  max_distance_km DECIMAL(5,2), -- For location-based matching

  -- Notification Tracking
  notified_at TIMESTAMPTZ,
  notification_expires_at TIMESTAMPTZ,
  notified_slots JSONB[], -- Track which slots were offered

  -- Outcome
  booked_session_id UUID REFERENCES sessions(id),
  booked_at TIMESTAMPTZ,
  cancelled_reason TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- Waitlist entry expiration

  CONSTRAINT valid_waitlist_status CHECK (status IN ('active', 'notified', 'booked', 'expired', 'cancelled')),
  CONSTRAINT valid_priority CHECK (priority_score BETWEEN 0 AND 1000)
);

CREATE INDEX IF NOT EXISTS idx_waitlist_client ON waitlist(client_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_trainer ON waitlist(trainer_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_status ON waitlist(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_waitlist_priority ON waitlist(priority_score DESC, created_at ASC) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_waitlist_expires ON waitlist(expires_at) WHERE expires_at IS NOT NULL;

COMMENT ON TABLE waitlist IS 'Manages client waitlist for booking slots';

-- STEP 2: Create waitlist_notifications table
-- ============================================================================

CREATE TABLE IF NOT EXISTS waitlist_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  waitlist_id UUID NOT NULL REFERENCES waitlist(id) ON DELETE CASCADE,

  -- Notification Details
  notification_type TEXT NOT NULL, -- 'slot_available', 'auto_booked', 'expired'
  notification_method TEXT NOT NULL, -- 'email', 'sms', 'push', 'in_app'
  notification_status TEXT DEFAULT 'pending', -- 'pending', 'sent', 'failed'

  -- Available Slot Details
  available_slot_start TIMESTAMPTZ,
  available_slot_end TIMESTAMPTZ,
  match_score INTEGER, -- How well the slot matches preferences (0-100)

  -- Response
  client_responded BOOLEAN DEFAULT FALSE,
  client_response TEXT, -- 'accept', 'decline', 'no_response'
  responded_at TIMESTAMPTZ,

  -- Metadata
  sent_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_notification_type CHECK (notification_type IN ('slot_available', 'auto_booked', 'expired')),
  CONSTRAINT valid_notification_status CHECK (notification_status IN ('pending', 'sent', 'failed'))
);

CREATE INDEX IF NOT EXISTS idx_waitlist_notifications_waitlist ON waitlist_notifications(waitlist_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_notifications_status ON waitlist_notifications(notification_status);

-- STEP 3: Function to calculate waitlist priority
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_waitlist_priority(
  p_client_id UUID,
  p_trainer_id UUID,
  p_created_at TIMESTAMPTZ
) RETURNS INTEGER AS $$
DECLARE
  v_priority INTEGER := 0;
  v_client_stats RECORD;
  v_cancellation_stats JSONB;
  v_days_waiting INTEGER;
BEGIN
  -- Base priority: days waiting (max 200 points)
  v_days_waiting := EXTRACT(DAYS FROM (NOW() - p_created_at))::INTEGER;
  v_priority := v_priority + LEAST(v_days_waiting * 10, 200);

  -- Client history bonus (max 300 points)
  SELECT
    COUNT(*) FILTER (WHERE status = 'completed') as completed_sessions,
    COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_sessions,
    AVG(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completion_rate
  INTO v_client_stats
  FROM sessions
  WHERE client_id = p_client_id;

  -- Reward loyal clients
  v_priority := v_priority + LEAST(v_client_stats.completed_sessions * 5, 150);

  -- Reward high completion rate
  IF v_client_stats.completion_rate >= 0.9 THEN
    v_priority := v_priority + 100;
  ELSIF v_client_stats.completion_rate >= 0.8 THEN
    v_priority := v_priority + 50;
  END IF;

  -- Cancellation penalty
  v_cancellation_stats := get_client_cancellation_stats(p_client_id);
  v_priority := v_priority - (COALESCE((v_cancellation_stats->>'recent_cancellations')::INTEGER, 0) * 50);

  -- Package expiry urgency (max 200 points)
  SELECT
    CASE
      WHEN expiry_date <= NOW() + INTERVAL '7 days' THEN 200
      WHEN expiry_date <= NOW() + INTERVAL '14 days' THEN 150
      WHEN expiry_date <= NOW() + INTERVAL '30 days' THEN 100
      ELSE 0
    END
  INTO v_priority
  FROM client_packages cp
  JOIN waitlist w ON w.package_id = cp.id
  WHERE w.client_id = p_client_id
    AND w.trainer_id = p_trainer_id
    AND w.status = 'active'
  ORDER BY cp.expiry_date ASC
  LIMIT 1;

  -- Ensure non-negative
  RETURN GREATEST(v_priority, 0);
END;
$$ LANGUAGE plpgsql;

-- STEP 4: Function to match waitlist to available slot
-- ============================================================================

CREATE OR REPLACE FUNCTION match_waitlist_to_slot(
  p_trainer_id UUID,
  p_slot_start TIMESTAMPTZ,
  p_slot_end TIMESTAMPTZ,
  p_location TEXT DEFAULT NULL
) RETURNS TABLE (
  waitlist_id UUID,
  client_id UUID,
  client_name TEXT,
  match_score INTEGER,
  auto_book BOOLEAN,
  package_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.client_id,
    u.full_name,
    (
      -- Calculate match score (0-100)
      CASE
        -- Preferred date match (30 points)
        WHEN DATE(p_slot_start) = ANY(w.preferred_dates) THEN 30
        ELSE 0
      END +
      CASE
        -- Preferred day of week match (20 points)
        WHEN EXTRACT(DOW FROM p_slot_start)::INTEGER = ANY(w.preferred_days_of_week) THEN 20
        ELSE 0
      END +
      CASE
        -- Preferred time match (30 points)
        WHEN p_slot_start::TIME = ANY(w.preferred_times) THEN 30
        WHEN ABS(EXTRACT(EPOCH FROM (p_slot_start::TIME - ANY(w.preferred_times)))) <= 1800 THEN 15 -- Within 30 min
        ELSE 0
      END +
      CASE
        -- Location match (10 points)
        WHEN p_location IS NOT NULL AND w.location = p_location THEN 10
        ELSE 5
      END +
      CASE
        -- Duration match (10 points)
        WHEN EXTRACT(EPOCH FROM (p_slot_end - p_slot_start)) / 60 = w.duration_minutes THEN 10
        ELSE 0
      END
    )::INTEGER as match_score,
    w.auto_book,
    w.package_id
  FROM waitlist w
  JOIN users u ON w.client_id = u.id
  JOIN client_packages cp ON w.package_id = cp.id
  WHERE w.trainer_id = p_trainer_id
    AND w.status = 'active'
    AND (w.expires_at IS NULL OR w.expires_at > NOW())
    AND cp.sessions_remaining > 0
    AND cp.status = 'active'
    AND (w.min_hours_notice IS NULL OR p_slot_start >= NOW() + (w.min_hours_notice || ' hours')::INTERVAL)
    AND NOT EXISTS (
      -- Exclude if client already has session at this time
      SELECT 1 FROM sessions s
      WHERE s.client_id = w.client_id
        AND s.status NOT IN ('cancelled', 'no_show')
        AND tstzrange(s.scheduled_start, s.scheduled_end) && tstzrange(p_slot_start, p_slot_end)
    )
  ORDER BY
    w.priority_score DESC,
    w.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- STEP 5: Function to process waitlist when slot becomes available
-- ============================================================================

CREATE OR REPLACE FUNCTION process_waitlist_for_slot(
  p_trainer_id UUID,
  p_slot_start TIMESTAMPTZ,
  p_slot_end TIMESTAMPTZ,
  p_location TEXT DEFAULT NULL,
  p_session_type TEXT DEFAULT 'in_person',
  p_notes TEXT DEFAULT 'Automatically offered from waitlist'
) RETURNS JSONB AS $$
DECLARE
  v_match RECORD;
  v_session_id UUID;
  v_notified_count INTEGER := 0;
  v_auto_booked_count INTEGER := 0;
  v_notification_id UUID;
BEGIN
  -- Find matching waitlist entries
  FOR v_match IN
    SELECT *
    FROM match_waitlist_to_slot(p_trainer_id, p_slot_start, p_slot_end, p_location)
    WHERE match_score >= 50 -- Minimum 50% match
    LIMIT 5 -- Notify top 5 matches
  LOOP
    -- Check if auto-book is enabled
    IF v_match.auto_book THEN
      -- Automatically book the session
      BEGIN
        INSERT INTO sessions (
          client_id, trainer_id, package_id,
          scheduled_start, scheduled_end,
          status, session_type, location, notes
        ) VALUES (
          v_match.client_id, p_trainer_id, v_match.package_id,
          p_slot_start, p_slot_end,
          'scheduled', p_session_type, p_location,
          'Auto-booked from waitlist (match score: ' || v_match.match_score || '%)'
        ) RETURNING id INTO v_session_id;

        -- Update package
        UPDATE client_packages
        SET sessions_scheduled = sessions_scheduled + 1
        WHERE id = v_match.package_id;

        -- Update waitlist entry
        UPDATE waitlist
        SET
          status = 'booked',
          booked_session_id = v_session_id,
          booked_at = NOW(),
          updated_at = NOW()
        WHERE id = v_match.waitlist_id;

        -- Create notification
        INSERT INTO waitlist_notifications (
          waitlist_id, notification_type, notification_method,
          available_slot_start, available_slot_end, match_score,
          notification_status
        ) VALUES (
          v_match.waitlist_id, 'auto_booked', 'in_app',
          p_slot_start, p_slot_end, v_match.match_score,
          'sent'
        );

        v_auto_booked_count := v_auto_booked_count + 1;

        -- Sync to Google Calendar (non-critical)
        -- This would call GoogleCalendarService.createEvent()

        EXIT; -- Stop after first auto-book

      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Auto-booking failed for waitlist %: %', v_match.waitlist_id, SQLERRM;
      END;
    ELSE
      -- Send notification (manual booking required)
      INSERT INTO waitlist_notifications (
        waitlist_id, notification_type, notification_method,
        available_slot_start, available_slot_end, match_score,
        notification_status, expires_at
      ) VALUES (
        v_match.waitlist_id, 'slot_available', 'in_app',
        p_slot_start, p_slot_end, v_match.match_score,
        'pending', p_slot_start - INTERVAL '1 hour' -- Must respond 1hr before slot
      ) RETURNING id INTO v_notification_id;

      -- Update waitlist status
      UPDATE waitlist
      SET
        status = 'notified',
        notified_at = NOW(),
        notification_expires_at = p_slot_start - INTERVAL '1 hour',
        updated_at = NOW()
      WHERE id = v_match.waitlist_id;

      v_notified_count := v_notified_count + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'success', TRUE,
    'slot_start', p_slot_start,
    'slot_end', p_slot_end,
    'auto_booked', v_auto_booked_count,
    'notified', v_notified_count,
    'total_processed', v_auto_booked_count + v_notified_count
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 6: Trigger to process waitlist on cancellation
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_waitlist_on_cancellation()
RETURNS TRIGGER AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Only process if session was cancelled (not completed/no-show)
  IF NEW.status = 'cancelled' AND OLD.status = 'scheduled' THEN
    -- Process waitlist for this newly available slot
    v_result := process_waitlist_for_slot(
      NEW.trainer_id,
      NEW.scheduled_start,
      NEW.scheduled_end,
      NEW.location,
      NEW.session_type,
      'Slot became available due to cancellation'
    );

    RAISE NOTICE 'Waitlist processed for cancelled session: %', v_result;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS process_waitlist_after_cancellation ON sessions;

CREATE TRIGGER process_waitlist_after_cancellation
  AFTER UPDATE ON sessions
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
  EXECUTE FUNCTION trigger_waitlist_on_cancellation();

-- STEP 7: Function to expire old waitlist entries
-- ============================================================================

CREATE OR REPLACE FUNCTION expire_old_waitlist_entries()
RETURNS INTEGER AS $$
DECLARE
  v_expired_count INTEGER;
BEGIN
  UPDATE waitlist
  SET
    status = 'expired',
    updated_at = NOW()
  WHERE status IN ('active', 'notified')
    AND (
      expires_at < NOW()
      OR
      (notification_expires_at IS NOT NULL AND notification_expires_at < NOW())
    );

  GET DIAGNOSTICS v_expired_count = ROW_COUNT;

  RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql;

-- STEP 8: Function to add client to waitlist
-- ============================================================================

CREATE OR REPLACE FUNCTION add_to_waitlist(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_preferred_dates DATE[] DEFAULT NULL,
  p_preferred_times TIME[] DEFAULT NULL,
  p_preferred_days_of_week INTEGER[] DEFAULT NULL,
  p_session_type TEXT DEFAULT 'in_person',
  p_duration_minutes INTEGER DEFAULT 60,
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_auto_book BOOLEAN DEFAULT FALSE,
  p_min_hours_notice INTEGER DEFAULT 24,
  p_expires_in_days INTEGER DEFAULT 30
) RETURNS JSONB AS $$
DECLARE
  v_waitlist_id UUID;
  v_priority INTEGER;
  v_package RECORD;
BEGIN
  -- Validate package
  SELECT * INTO v_package
  FROM client_packages
  WHERE id = p_package_id
    AND client_id = p_client_id
    AND status = 'active'
    AND sessions_remaining > 0;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'No active package with available sessions'
    );
  END IF;

  -- Calculate priority
  v_priority := calculate_waitlist_priority(p_client_id, p_trainer_id, NOW());

  -- Create waitlist entry
  INSERT INTO waitlist (
    client_id, trainer_id, package_id,
    preferred_dates, preferred_times, preferred_days_of_week,
    session_type, duration_minutes, location, notes,
    auto_book, min_hours_notice,
    priority_score, status,
    expires_at
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_preferred_dates, p_preferred_times, p_preferred_days_of_week,
    p_session_type, p_duration_minutes, p_location, p_notes,
    p_auto_book, p_min_hours_notice,
    v_priority, 'active',
    NOW() + (p_expires_in_days || ' days')::INTERVAL
  ) RETURNING id INTO v_waitlist_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'waitlist_id', v_waitlist_id,
    'priority_score', v_priority,
    'expires_at', NOW() + (p_expires_in_days || ' days')::INTERVAL,
    'message', CASE
      WHEN p_auto_book THEN 'Added to waitlist with auto-booking enabled'
      ELSE 'Added to waitlist - you will be notified when slots become available'
    END
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 9: Create view for waitlist dashboard
-- ============================================================================

CREATE OR REPLACE VIEW waitlist_dashboard AS
SELECT
  w.id as waitlist_id,
  u.full_name as client_name,
  u.email as client_email,
  u.phone as client_phone,
  t.full_name as trainer_name,
  w.priority_score,
  w.status,
  w.auto_book,
  w.preferred_dates,
  w.preferred_times,
  w.preferred_days_of_week,
  w.session_type,
  w.duration_minutes,
  w.location,
  cp.package_name,
  cp.sessions_remaining,
  w.min_hours_notice || ' hours' as minimum_notice,
  w.created_at as added_to_waitlist,
  w.expires_at,
  w.notified_at,
  w.booked_at,
  s.scheduled_start as booked_slot_start,
  COUNT(wn.id) as notifications_sent,
  EXTRACT(DAYS FROM (NOW() - w.created_at))::INTEGER as days_waiting,
  CASE
    WHEN w.status = 'active' AND w.expires_at > NOW() THEN '✅ Active'
    WHEN w.status = 'notified' THEN '📧 Notified'
    WHEN w.status = 'booked' THEN '✅ Booked'
    WHEN w.status = 'expired' THEN '❌ Expired'
    WHEN w.status = 'cancelled' THEN '🚫 Cancelled'
    ELSE w.status
  END as status_display
FROM waitlist w
JOIN users u ON w.client_id = u.id
JOIN users t ON w.trainer_id = t.id
JOIN client_packages cp ON w.package_id = cp.id
LEFT JOIN sessions s ON w.booked_session_id = s.id
LEFT JOIN waitlist_notifications wn ON w.id = wn.waitlist_id
GROUP BY
  w.id, u.full_name, u.email, u.phone, t.full_name,
  w.priority_score, w.status, w.auto_book,
  w.preferred_dates, w.preferred_times, w.preferred_days_of_week,
  w.session_type, w.duration_minutes, w.location,
  cp.package_name, cp.sessions_remaining, w.min_hours_notice,
  w.created_at, w.expires_at, w.notified_at, w.booked_at,
  s.scheduled_start
ORDER BY
  CASE w.status
    WHEN 'active' THEN 1
    WHEN 'notified' THEN 2
    WHEN 'booked' THEN 3
    ELSE 4
  END,
  w.priority_score DESC,
  w.created_at ASC;

-- STEP 10: Verification queries
-- ============================================================================

SELECT '📋 WAITLIST SYSTEM TABLES' as info;

SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('waitlist', 'waitlist_notifications')
ORDER BY table_name;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Phase 4 Complete: Waitlist Management & Auto-Booking Implemented!' as message;
SELECT 'Features enabled:' as info,
       '- Priority-based waitlist queue' as feature_1,
       '- Automatic slot notification on cancellations' as feature_2,
       '- Auto-booking for waitlisted clients' as feature_3,
       '- Smart preference matching (time, day, location)' as feature_4,
       '- Expiring waitlist entries' as feature_5,
       '- Waitlist analytics dashboard' as feature_6;

SELECT 'Usage example:' as example,
       'SELECT * FROM add_to_waitlist(' as line_1,
       '  client_id => ''uuid-here'',' as line_2,
       '  trainer_id => ''uuid-here'',' as line_3,
       '  package_id => ''uuid-here'',' as line_4,
       '  preferred_dates => ARRAY[''2025-01-30'', ''2025-02-01'']::DATE[],' as line_5,
       '  preferred_times => ARRAY[''14:00'', ''15:00'']::TIME[],' as line_6,
       '  preferred_days_of_week => ARRAY[1, 3, 5], -- Mon, Wed, Fri' as line_7,
       '  auto_book => TRUE -- Auto-book when slot available' as line_8,
       ');' as line_9;
