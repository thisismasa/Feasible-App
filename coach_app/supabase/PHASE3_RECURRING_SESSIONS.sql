-- ============================================================================
-- PHASE 3: RECURRING SESSIONS & SERIES MANAGEMENT
-- ============================================================================
-- Implements automated recurring session booking with:
-- 1. Weekly, bi-weekly, monthly patterns
-- 2. Series-wide conflict detection
-- 3. Package session allocation validation
-- 4. Bulk operations (create, update, cancel series)
-- 5. Exception handling (skip specific dates)
-- ============================================================================

-- STEP 1: Create session_series table
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_series (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES client_packages(id) ON DELETE CASCADE,

  -- Series Configuration
  series_name TEXT,
  recurrence_pattern TEXT NOT NULL, -- 'weekly', 'biweekly', 'monthly', 'custom'
  start_date DATE NOT NULL,
  end_date DATE, -- NULL = ongoing until package expires

  -- Session Details
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, etc.
  start_time TIME NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  session_type TEXT DEFAULT 'in_person',
  location TEXT,
  notes TEXT,

  -- Series Status
  status TEXT DEFAULT 'active', -- 'active', 'paused', 'completed', 'cancelled'
  total_sessions_planned INTEGER,
  sessions_created INTEGER DEFAULT 0,
  sessions_completed INTEGER DEFAULT 0,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  CONSTRAINT valid_series_status CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  CONSTRAINT valid_recurrence CHECK (recurrence_pattern IN ('weekly', 'biweekly', 'monthly', 'custom')),
  CONSTRAINT valid_day_of_week CHECK (day_of_week BETWEEN 0 AND 6),
  CONSTRAINT valid_duration CHECK (duration_minutes BETWEEN 15 AND 240)
);

CREATE INDEX IF NOT EXISTS idx_session_series_client ON session_series(client_id);
CREATE INDEX IF NOT EXISTS idx_session_series_trainer ON session_series(trainer_id);
CREATE INDEX IF NOT EXISTS idx_session_series_status ON session_series(status);
CREATE INDEX IF NOT EXISTS idx_session_series_dates ON session_series(start_date, end_date);

COMMENT ON TABLE session_series IS 'Defines recurring session patterns for automated booking';

-- STEP 2: Create series_exceptions table
-- ============================================================================

CREATE TABLE IF NOT EXISTS series_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id UUID NOT NULL REFERENCES session_series(id) ON DELETE CASCADE,

  -- Exception Details
  exception_date DATE NOT NULL,
  exception_type TEXT NOT NULL, -- 'skip', 'reschedule', 'custom_time'
  reason TEXT,

  -- Rescheduling
  rescheduled_date DATE,
  rescheduled_time TIME,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  CONSTRAINT valid_exception_type CHECK (exception_type IN ('skip', 'reschedule', 'custom_time')),
  CONSTRAINT unique_series_date UNIQUE(series_id, exception_date)
);

CREATE INDEX IF NOT EXISTS idx_series_exceptions_series ON series_exceptions(series_id);
CREATE INDEX IF NOT EXISTS idx_series_exceptions_date ON series_exceptions(exception_date);

-- STEP 3: Link sessions to series
-- ============================================================================

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS series_id UUID REFERENCES session_series(id) ON DELETE SET NULL;

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS series_occurrence_number INTEGER;

CREATE INDEX IF NOT EXISTS idx_sessions_series ON sessions(series_id) WHERE series_id IS NOT NULL;

COMMENT ON COLUMN sessions.series_id IS 'Links individual session to its recurring series';
COMMENT ON COLUMN sessions.series_occurrence_number IS 'Order within series (1st, 2nd, 3rd occurrence)';

-- STEP 4: Function to calculate next occurrence date
-- ============================================================================

CREATE OR REPLACE FUNCTION get_next_occurrence_date(
  p_current_date DATE,
  p_day_of_week INTEGER,
  p_recurrence_pattern TEXT
) RETURNS DATE AS $$
DECLARE
  v_days_until_next INTEGER;
  v_next_date DATE;
BEGIN
  -- Calculate days until next occurrence of day_of_week
  v_days_until_next := (p_day_of_week - EXTRACT(DOW FROM p_current_date)::INTEGER + 7) % 7;

  -- If same day of week, move to next week
  IF v_days_until_next = 0 THEN
    v_days_until_next := 7;
  END IF;

  v_next_date := p_current_date + v_days_until_next;

  -- Apply recurrence pattern
  CASE p_recurrence_pattern
    WHEN 'biweekly' THEN
      v_next_date := v_next_date + INTERVAL '1 week';
    WHEN 'monthly' THEN
      v_next_date := v_next_date + INTERVAL '3 weeks'; -- Approximate monthly
    ELSE
      -- 'weekly' or 'custom' - no adjustment
      NULL;
  END CASE;

  RETURN v_next_date;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- STEP 5: Function to validate series booking
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_series_booking(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_recurrence_pattern TEXT
) RETURNS JSONB AS $$
DECLARE
  v_package RECORD;
  v_estimated_sessions INTEGER;
  v_weeks INTEGER;
BEGIN
  -- Get package details
  SELECT * INTO v_package
  FROM client_packages
  WHERE id = p_package_id AND client_id = p_client_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', FALSE, 'error', 'Package not found');
  END IF;

  IF v_package.status != 'active' THEN
    RETURN jsonb_build_object('valid', FALSE, 'error', 'Package is not active');
  END IF;

  IF v_package.sessions_remaining <= 0 THEN
    RETURN jsonb_build_object('valid', FALSE, 'error', 'No sessions remaining in package');
  END IF;

  -- Estimate number of sessions in series
  v_weeks := EXTRACT(DAYS FROM (COALESCE(p_end_date, v_package.expiry_date) - p_start_date))::INTEGER / 7;

  v_estimated_sessions := CASE p_recurrence_pattern
    WHEN 'weekly' THEN v_weeks
    WHEN 'biweekly' THEN v_weeks / 2
    WHEN 'monthly' THEN v_weeks / 4
    ELSE v_weeks -- Default to weekly
  END;

  IF v_estimated_sessions > v_package.sessions_remaining THEN
    RETURN jsonb_build_object(
      'valid', FALSE,
      'error', 'Not enough sessions remaining',
      'required', v_estimated_sessions,
      'available', v_package.sessions_remaining
    );
  END IF;

  -- Check trainer availability pattern
  -- (Would integrate with booking_rules here)

  RETURN jsonb_build_object(
    'valid', TRUE,
    'estimated_sessions', v_estimated_sessions,
    'sessions_available', v_package.sessions_remaining,
    'package_expiry', v_package.expiry_date
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 6: Function to create recurring session series
-- ============================================================================

CREATE OR REPLACE FUNCTION create_recurring_sessions(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_series_name TEXT,
  p_recurrence_pattern TEXT,
  p_start_date DATE,
  p_end_date DATE,
  p_day_of_week INTEGER,
  p_start_time TIME,
  p_duration_minutes INTEGER DEFAULT 60,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_max_sessions INTEGER DEFAULT NULL -- Limit number of sessions to create
) RETURNS JSONB AS $$
DECLARE
  v_series_id UUID;
  v_validation JSONB;
  v_current_date DATE;
  v_scheduled_start TIMESTAMPTZ;
  v_scheduled_end TIMESTAMPTZ;
  v_session_id UUID;
  v_sessions_created INTEGER := 0;
  v_conflicts RECORD;
  v_conflict_count INTEGER := 0;
  v_created_sessions UUID[] := ARRAY[]::UUID[];
  v_package RECORD;
BEGIN
  -- Validate series parameters
  v_validation := validate_series_booking(
    p_client_id, p_trainer_id, p_package_id,
    p_start_date, p_end_date, p_recurrence_pattern
  );

  IF NOT (v_validation->>'valid')::BOOLEAN THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', v_validation->>'error',
      'validation', v_validation
    );
  END IF;

  -- Get package for expiry date
  SELECT * INTO v_package
  FROM client_packages
  WHERE id = p_package_id;

  -- Create series record
  INSERT INTO session_series (
    client_id, trainer_id, package_id,
    series_name, recurrence_pattern,
    start_date, end_date,
    day_of_week, start_time, duration_minutes,
    session_type, location, notes,
    status, total_sessions_planned
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_series_name, p_recurrence_pattern,
    p_start_date, COALESCE(p_end_date, v_package.expiry_date),
    p_day_of_week, p_start_time, p_duration_minutes,
    p_session_type, p_location, p_notes,
    'active', (v_validation->>'estimated_sessions')::INTEGER
  ) RETURNING id INTO v_series_id;

  -- Generate individual sessions
  v_current_date := p_start_date;

  -- Find first occurrence of day_of_week on or after start_date
  v_current_date := get_next_occurrence_date(v_current_date - 1, p_day_of_week, 'weekly');

  WHILE v_current_date <= COALESCE(p_end_date, v_package.expiry_date)
    AND (p_max_sessions IS NULL OR v_sessions_created < p_max_sessions)
    AND v_sessions_created < v_package.sessions_remaining LOOP

    -- Check for exceptions
    IF NOT EXISTS (
      SELECT 1 FROM series_exceptions
      WHERE series_id = v_series_id
        AND exception_date = v_current_date
        AND exception_type = 'skip'
    ) THEN

      -- Build timestamp
      v_scheduled_start := (v_current_date::TEXT || ' ' || p_start_time::TEXT)::TIMESTAMPTZ;
      v_scheduled_end := v_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

      -- Check for conflicts
      SELECT * INTO v_conflicts
      FROM check_booking_conflicts(
        p_trainer_id,
        p_client_id,
        v_scheduled_start,
        v_scheduled_end
      )
      LIMIT 1;

      IF FOUND THEN
        v_conflict_count := v_conflict_count + 1;
        RAISE NOTICE 'Conflict detected for %: %', v_current_date, v_conflicts.conflict_description;
      ELSE
        -- Create session
        INSERT INTO sessions (
          client_id, trainer_id, package_id,
          scheduled_start, scheduled_end,
          status, session_type, location, notes,
          series_id, series_occurrence_number
        ) VALUES (
          p_client_id, p_trainer_id, p_package_id,
          v_scheduled_start, v_scheduled_end,
          'scheduled', p_session_type, p_location, p_notes,
          v_series_id, v_sessions_created + 1
        ) RETURNING id INTO v_session_id;

        v_sessions_created := v_sessions_created + 1;
        v_created_sessions := array_append(v_created_sessions, v_session_id);

        -- Update package scheduled count
        UPDATE client_packages
        SET sessions_scheduled = sessions_scheduled + 1
        WHERE id = p_package_id;
      END IF;
    END IF;

    -- Move to next occurrence
    v_current_date := get_next_occurrence_date(v_current_date, p_day_of_week, p_recurrence_pattern);
  END LOOP;

  -- Update series with actual count
  UPDATE session_series
  SET sessions_created = v_sessions_created
  WHERE id = v_series_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'series_id', v_series_id,
    'sessions_created', v_sessions_created,
    'conflicts_detected', v_conflict_count,
    'created_session_ids', v_created_sessions,
    'sessions_remaining', v_package.sessions_remaining - v_sessions_created
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 7: Function to cancel entire series
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_series(
  p_series_id UUID,
  p_cancelled_by UUID,
  p_reason TEXT DEFAULT NULL,
  p_cancel_future_only BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
  v_series RECORD;
  v_cancelled_count INTEGER := 0;
  v_refunded_sessions INTEGER := 0;
BEGIN
  -- Get series details
  SELECT * INTO v_series FROM session_series WHERE id = p_series_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Series not found');
  END IF;

  -- Cancel sessions
  IF p_cancel_future_only THEN
    -- Only cancel future sessions
    UPDATE sessions
    SET
      status = 'cancelled',
      cancelled_at = NOW(),
      cancelled_by = p_cancelled_by,
      cancellation_reason = COALESCE(p_reason, 'Series cancelled by ' || CASE WHEN p_cancelled_by = v_series.trainer_id THEN 'trainer' ELSE 'client' END)
    WHERE series_id = p_series_id
      AND status = 'scheduled'
      AND scheduled_start > NOW();

    GET DIAGNOSTICS v_cancelled_count = ROW_COUNT;
  ELSE
    -- Cancel all sessions in series (past and future)
    UPDATE sessions
    SET
      status = 'cancelled',
      cancelled_at = NOW(),
      cancelled_by = p_cancelled_by,
      cancellation_reason = COALESCE(p_reason, 'Series cancelled')
    WHERE series_id = p_series_id
      AND status IN ('scheduled', 'in_progress');

    GET DIAGNOSTICS v_cancelled_count = ROW_COUNT;
  END IF;

  -- Refund sessions to package
  UPDATE client_packages
  SET sessions_scheduled = sessions_scheduled - v_cancelled_count
  WHERE id = v_series.package_id;

  v_refunded_sessions := v_cancelled_count;

  -- Update series status
  UPDATE session_series
  SET
    status = 'cancelled',
    updated_at = NOW()
  WHERE id = p_series_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'series_id', p_series_id,
    'sessions_cancelled', v_cancelled_count,
    'sessions_refunded', v_refunded_sessions
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 8: Function to add series exception
-- ============================================================================

CREATE OR REPLACE FUNCTION add_series_exception(
  p_series_id UUID,
  p_exception_date DATE,
  p_exception_type TEXT,
  p_reason TEXT DEFAULT NULL,
  p_rescheduled_date DATE DEFAULT NULL,
  p_rescheduled_time TIME DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_session_id UUID;
BEGIN
  -- Validate exception type
  IF p_exception_type NOT IN ('skip', 'reschedule', 'custom_time') THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Invalid exception type');
  END IF;

  -- Create exception
  INSERT INTO series_exceptions (
    series_id, exception_date, exception_type, reason,
    rescheduled_date, rescheduled_time
  ) VALUES (
    p_series_id, p_exception_date, p_exception_type, p_reason,
    p_rescheduled_date, p_rescheduled_time
  )
  ON CONFLICT (series_id, exception_date)
  DO UPDATE SET
    exception_type = EXCLUDED.exception_type,
    reason = EXCLUDED.reason,
    rescheduled_date = EXCLUDED.rescheduled_date,
    rescheduled_time = EXCLUDED.rescheduled_time;

  -- Find and update/cancel existing session for this date
  SELECT id INTO v_session_id
  FROM sessions
  WHERE series_id = p_series_id
    AND DATE(scheduled_start) = p_exception_date
    AND status = 'scheduled';

  IF FOUND THEN
    CASE p_exception_type
      WHEN 'skip' THEN
        -- Cancel this session
        UPDATE sessions
        SET
          status = 'cancelled',
          cancelled_at = NOW(),
          cancellation_reason = COALESCE(p_reason, 'Skipped in recurring series')
        WHERE id = v_session_id;

        -- Refund to package
        UPDATE client_packages cp
        SET sessions_scheduled = sessions_scheduled - 1
        FROM sessions s
        WHERE s.id = v_session_id AND cp.id = s.package_id;

      WHEN 'reschedule' THEN
        -- Reschedule to new date/time
        IF p_rescheduled_date IS NOT NULL THEN
          UPDATE sessions
          SET
            scheduled_start = (p_rescheduled_date::TEXT || ' ' || COALESCE(p_rescheduled_time, scheduled_start::TIME)::TEXT)::TIMESTAMPTZ,
            scheduled_end = (p_rescheduled_date::TEXT || ' ' || COALESCE(p_rescheduled_time, scheduled_start::TIME)::TEXT)::TIMESTAMPTZ
              + (EXTRACT(EPOCH FROM (scheduled_end - scheduled_start)) || ' seconds')::INTERVAL
          WHERE id = v_session_id;
        END IF;

      ELSE
        -- Custom time - just update time on same date
        NULL;
    END CASE;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'exception_created', TRUE,
    'session_updated', FOUND,
    'session_id', v_session_id
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 9: Create view for series overview
-- ============================================================================

CREATE OR REPLACE VIEW series_overview AS
SELECT
  ss.id as series_id,
  ss.series_name,
  u_client.full_name as client_name,
  u_client.email as client_email,
  u_trainer.full_name as trainer_name,
  ss.recurrence_pattern,
  ss.day_of_week,
  TO_CHAR(ss.start_time, 'HH24:MI') as start_time,
  ss.duration_minutes || ' min' as duration,
  ss.start_date,
  ss.end_date,
  ss.status,
  ss.sessions_created,
  ss.sessions_completed,
  COUNT(s.id) FILTER (WHERE s.status = 'scheduled') as upcoming_sessions,
  COUNT(s.id) FILTER (WHERE s.status = 'cancelled') as cancelled_sessions,
  COUNT(se.id) as exceptions_count,
  cp.package_name,
  cp.sessions_remaining,
  ss.created_at
FROM session_series ss
JOIN users u_client ON ss.client_id = u_client.id
JOIN users u_trainer ON ss.trainer_id = u_trainer.id
JOIN client_packages cp ON ss.package_id = cp.id
LEFT JOIN sessions s ON ss.id = s.series_id
LEFT JOIN series_exceptions se ON ss.id = se.series_id
GROUP BY
  ss.id, ss.series_name, u_client.full_name, u_client.email,
  u_trainer.full_name, ss.recurrence_pattern, ss.day_of_week,
  ss.start_time, ss.duration_minutes, ss.start_date, ss.end_date,
  ss.status, ss.sessions_created, ss.sessions_completed,
  cp.package_name, cp.sessions_remaining, ss.created_at
ORDER BY ss.start_date DESC;

-- STEP 10: Verification queries
-- ============================================================================

-- Show table structure
SELECT
  '📋 SESSION_SERIES TABLE' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'session_series'
ORDER BY ordinal_position;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Phase 3 Complete: Recurring Sessions & Series Management Implemented!' as message;
SELECT 'Features enabled:' as info,
       '- Create recurring session series (weekly, bi-weekly, monthly)' as feature_1,
       '- Automated session generation with conflict detection' as feature_2,
       '- Series-wide cancellation and refunds' as feature_3,
       '- Exception handling (skip/reschedule specific dates)' as feature_4,
       '- Package session validation for entire series' as feature_5,
       '- Series overview analytics' as feature_6;

SELECT 'Usage example:' as example,
       'SELECT * FROM create_recurring_sessions(' as line_1,
       '  client_id => ''uuid-here'',' as line_2,
       '  trainer_id => ''uuid-here'',' as line_3,
       '  package_id => ''uuid-here'',' as line_4,
       '  series_name => ''Weekly Training'',' as line_5,
       '  recurrence_pattern => ''weekly'',' as line_6,
       '  start_date => ''2025-01-27'',' as line_7,
       '  end_date => ''2025-04-27'',' as line_8,
       '  day_of_week => 2, -- Tuesday' as line_9,
       '  start_time => ''14:00'',' as line_10,
       '  duration_minutes => 60' as line_11,
       ');' as line_12;
