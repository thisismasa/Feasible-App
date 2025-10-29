-- ============================================================================
-- FIX PACKAGE-BOOKING SYNC ISSUE
-- ============================================================================
-- Date: October 26, 2025
-- Issue: Package payments not syncing to booking system
-- Root Causes:
--   1. Duplicate column names in client_packages (remaining_sessions vs sessions_remaining)
--   2. No trigger to update package sessions when booking created
--   3. package_deducted flag not being set
--   4. Flutter code not using database function for package assignment
-- ============================================================================

-- FIX 1: Standardize client_packages column names
-- ============================================================================
-- Keep: remaining_sessions, used_sessions, total_sessions (newer naming)
-- Remove: sessions_remaining, sessions_used (duplicate old naming)

DO $$
BEGIN
  -- Sync data from old columns to new columns if they differ
  UPDATE client_packages
  SET remaining_sessions = COALESCE(sessions_remaining, remaining_sessions),
      used_sessions = COALESCE(sessions_used, used_sessions)
  WHERE remaining_sessions IS NULL
     OR used_sessions IS NULL
     OR remaining_sessions != sessions_remaining
     OR used_sessions != sessions_used;

  RAISE NOTICE '✅ Synced data from old columns to new columns';
END $$;

-- FIX 1B: Update dependent views to use new column names
-- ============================================================================
-- Drop old views first (they have wrong column names)
DROP VIEW IF EXISTS series_overview CASCADE;
DROP VIEW IF EXISTS waitlist_dashboard CASCADE;

-- Recreate series_overview view with correct column name
CREATE VIEW series_overview AS
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
  cp.remaining_sessions,  -- CHANGED from sessions_remaining
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
  cp.package_name, cp.remaining_sessions, ss.created_at  -- CHANGED from sessions_remaining
ORDER BY ss.start_date DESC;

-- Recreate waitlist_dashboard view with correct column name
CREATE VIEW waitlist_dashboard AS
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
  cp.remaining_sessions,  -- CHANGED from sessions_remaining
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
  cp.package_name, cp.remaining_sessions, w.min_hours_notice,  -- CHANGED from sessions_remaining
  w.created_at, w.expires_at, w.notified_at, w.booked_at,
  s.scheduled_start
ORDER BY
  CASE w.status
    WHEN 'active' THEN 1
    WHEN 'notified' THEN 2
    WHEN 'booked' THEN 3
    WHEN 'expired' THEN 4
    WHEN 'cancelled' THEN 5
  END,
  w.priority_score DESC,
  w.created_at ASC;

-- FIX 1C: Now drop duplicate columns after views are updated
-- ============================================================================
DO $$
BEGIN
  -- Drop duplicate columns if they exist
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'sessions_remaining'
  ) THEN
    ALTER TABLE client_packages DROP COLUMN sessions_remaining;
    RAISE NOTICE '✅ Dropped duplicate column: sessions_remaining';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'sessions_used'
  ) THEN
    ALTER TABLE client_packages DROP COLUMN sessions_used;
    RAISE NOTICE '✅ Dropped duplicate column: sessions_used';
  END IF;
END $$;

-- FIX 2: Add computed column for remaining_sessions if not exists
-- ============================================================================
DO $$
BEGIN
  -- Ensure remaining_sessions is calculated correctly
  UPDATE client_packages
  SET remaining_sessions = total_sessions - used_sessions
  WHERE remaining_sessions != (total_sessions - used_sessions)
     OR remaining_sessions IS NULL;

  RAISE NOTICE '✅ Recalculated remaining_sessions for all packages';
END $$;

-- FIX 3: Create trigger to update package when session is booked
-- ============================================================================
CREATE OR REPLACE FUNCTION update_package_on_session_create()
RETURNS TRIGGER AS $$
DECLARE
  v_package_id UUID;
BEGIN
  -- Only process scheduled or confirmed sessions
  IF NEW.status IN ('scheduled', 'confirmed') AND NEW.package_id IS NOT NULL THEN

    -- Find the client_package record
    SELECT id INTO v_package_id
    FROM client_packages
    WHERE client_id = NEW.client_id
      AND package_id = NEW.package_id
      AND status = 'active'
      AND remaining_sessions > 0
    ORDER BY purchase_date DESC
    LIMIT 1;

    IF v_package_id IS NOT NULL THEN
      -- Increment sessions_scheduled
      UPDATE client_packages
      SET sessions_scheduled = sessions_scheduled + 1,
          updated_at = NOW()
      WHERE id = v_package_id;

      RAISE NOTICE 'Package updated: sessions_scheduled incremented for package %', v_package_id;
    ELSE
      RAISE WARNING 'No active package found for client % with package_id %', NEW.client_id, NEW.package_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS trigger_update_package_on_session_create ON sessions;

-- Create new trigger
CREATE TRIGGER trigger_update_package_on_session_create
  AFTER INSERT ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_package_on_session_create();

-- FIX 4: Create trigger to update package when session is completed
-- ============================================================================
CREATE OR REPLACE FUNCTION update_package_on_session_complete()
RETURNS TRIGGER AS $$
DECLARE
  v_package_id UUID;
BEGIN
  -- Only process when status changes to 'completed'
  IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.package_deducted = FALSE THEN

    -- Find the client_package record
    SELECT id INTO v_package_id
    FROM client_packages
    WHERE client_id = NEW.client_id
      AND package_id = NEW.package_id
      AND status = 'active'
    ORDER BY purchase_date DESC
    LIMIT 1;

    IF v_package_id IS NOT NULL THEN
      -- Deduct session from package
      UPDATE client_packages
      SET used_sessions = used_sessions + 1,
          remaining_sessions = remaining_sessions - 1,
          sessions_scheduled = GREATEST(sessions_scheduled - 1, 0),
          last_used_at = NOW(),
          updated_at = NOW()
      WHERE id = v_package_id;

      -- Mark session as deducted
      UPDATE sessions
      SET package_deducted = TRUE
      WHERE id = NEW.id;

      RAISE NOTICE 'Package updated: session deducted from package %', v_package_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS trigger_update_package_on_session_complete ON sessions;

-- Create new trigger
CREATE TRIGGER trigger_update_package_on_session_complete
  AFTER UPDATE ON sessions
  FOR EACH ROW
  WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
  EXECUTE FUNCTION update_package_on_session_complete();

-- FIX 5: Create trigger to restore package when session is cancelled
-- ============================================================================
CREATE OR REPLACE FUNCTION restore_package_on_session_cancel()
RETURNS TRIGGER AS $$
DECLARE
  v_package_id UUID;
BEGIN
  -- Only process when status changes to 'cancelled'
  IF NEW.status = 'cancelled' AND OLD.status IN ('scheduled', 'confirmed') THEN

    -- Find the client_package record
    SELECT id INTO v_package_id
    FROM client_packages
    WHERE client_id = NEW.client_id
      AND package_id = NEW.package_id
      AND status = 'active'
    ORDER BY purchase_date DESC
    LIMIT 1;

    IF v_package_id IS NOT NULL THEN
      -- Decrement sessions_scheduled
      UPDATE client_packages
      SET sessions_scheduled = GREATEST(sessions_scheduled - 1, 0),
          updated_at = NOW()
      WHERE id = v_package_id;

      RAISE NOTICE 'Package updated: sessions_scheduled decremented for package %', v_package_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS trigger_restore_package_on_session_cancel ON sessions;

-- Create new trigger
CREATE TRIGGER trigger_restore_package_on_session_cancel
  AFTER UPDATE ON sessions
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status IN ('scheduled', 'confirmed'))
  EXECUTE FUNCTION restore_package_on_session_cancel();

-- FIX 6: Create function to assign package to client (for Flutter to call)
-- ============================================================================
CREATE OR REPLACE FUNCTION assign_package_to_client(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_payment_method TEXT,
  p_amount_paid DECIMAL,
  p_transaction_id TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_package_name TEXT;
  v_total_sessions INTEGER;
  v_price DECIMAL;
  v_validity_days INTEGER;
  v_client_package_id UUID;
BEGIN
  -- Get package details from packages table
  SELECT
    name,
    sessions,
    price,
    validity_days
  INTO v_package_name, v_total_sessions, v_price, v_validity_days
  FROM packages
  WHERE id = p_package_id AND is_active = TRUE;

  IF v_package_name IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package not found or inactive'
    );
  END IF;

  -- Insert into client_packages
  INSERT INTO client_packages (
    client_id,
    trainer_id,
    package_id,
    package_name,
    total_sessions,
    remaining_sessions,
    used_sessions,
    sessions_scheduled,
    price_paid,
    amount_paid,
    payment_method,
    payment_status,
    purchase_date,
    expiry_date,
    status,
    is_subscription,
    auto_billing_enabled,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    v_package_name,
    v_total_sessions,
    v_total_sessions, -- remaining_sessions = total at start
    0, -- used_sessions starts at 0
    0, -- sessions_scheduled starts at 0
    p_amount_paid,
    p_amount_paid,
    p_payment_method,
    'paid',
    NOW(),
    NOW() + (v_validity_days || ' days')::INTERVAL,
    'active',
    FALSE,
    FALSE,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_client_package_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Package assigned successfully',
    'client_package_id', v_client_package_id,
    'total_sessions', v_total_sessions
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Failed to assign package: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- FIX 7: Fix existing data - recalculate package sessions based on actual sessions
-- ============================================================================
-- For each active package, count completed sessions and update counters
DO $$
DECLARE
  v_package RECORD;
  v_completed_count INTEGER;
  v_scheduled_count INTEGER;
BEGIN
  FOR v_package IN
    SELECT id, client_id, package_id, total_sessions
    FROM client_packages
    WHERE status = 'active'
  LOOP
    -- Count completed sessions
    SELECT COUNT(*) INTO v_completed_count
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'completed';

    -- Count scheduled/confirmed sessions
    SELECT COUNT(*) INTO v_scheduled_count
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status IN ('scheduled', 'confirmed');

    -- Update package
    UPDATE client_packages
    SET used_sessions = v_completed_count,
        remaining_sessions = v_package.total_sessions - v_completed_count,
        sessions_scheduled = v_scheduled_count,
        updated_at = NOW()
    WHERE id = v_package.id;

    -- Mark completed sessions as deducted
    UPDATE sessions
    SET package_deducted = TRUE
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'completed'
      AND package_deducted = FALSE;

  END LOOP;

  RAISE NOTICE '✅ Fixed existing package session counts';
END $$;

-- FIX 8: Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION assign_package_to_client TO authenticated;
GRANT EXECUTE ON FUNCTION assign_package_to_client TO anon;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT '✅ ALL FIXES APPLIED!' as status;

-- Show package summary
SELECT
  cp.id,
  cp.package_name,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.used_sessions,
  cp.sessions_scheduled,
  cp.status,
  u.full_name as client_name
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.status = 'active'
ORDER BY cp.updated_at DESC
LIMIT 5;

-- Show summary stats
SELECT
  COUNT(*) as total_active_packages,
  SUM(total_sessions) as total_sessions_purchased,
  SUM(remaining_sessions) as total_sessions_remaining,
  SUM(used_sessions) as total_sessions_used,
  SUM(sessions_scheduled) as total_sessions_scheduled
FROM client_packages
WHERE status = 'active';
