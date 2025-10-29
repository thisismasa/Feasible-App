-- ============================================================================
-- FINAL UPDATE: Database Functions for 7 AM - 10 PM Hours
-- ============================================================================
-- This updates the get_available_slots function to show 7 AM - 10 PM slots
-- (The booking_rules table has already been updated via API)
-- ============================================================================

-- Update get_available_slots function
CREATE OR REPLACE FUNCTION get_available_slots(
  p_trainer_id UUID,
  p_date DATE,
  p_duration_minutes INTEGER DEFAULT 60
) RETURNS TABLE (
  slot_start TIMESTAMPTZ,
  slot_end TIMESTAMPTZ,
  is_available BOOLEAN,
  reason TEXT
) AS $$
DECLARE
  v_current_time TIMESTAMPTZ;
  v_end_of_day TIMESTAMPTZ;
  v_slot_end TIMESTAMPTZ;
  v_buffer_minutes INTEGER;
  v_conflicts INTEGER;
BEGIN
  v_buffer_minutes := get_buffer_minutes(p_trainer_id);

  -- Start from 7 AM (changed from 6 AM)
  v_current_time := (p_date || ' 07:00:00')::TIMESTAMPTZ;
  -- End at 10 PM
  v_end_of_day := (p_date || ' 22:00:00')::TIMESTAMPTZ;

  WHILE v_current_time < v_end_of_day LOOP
    v_slot_end := v_current_time + (p_duration_minutes || ' minutes')::INTERVAL;

    -- Only check if time has passed (no 2-hour minimum)
    IF v_current_time <= NOW() THEN
      RETURN QUERY SELECT
        v_current_time,
        v_slot_end,
        FALSE,
        'Time has already passed'::TEXT;
    ELSE
      -- Check for conflicts
      SELECT COUNT(*) INTO v_conflicts
      FROM check_booking_conflicts(
        p_trainer_id,
        NULL::UUID,
        v_current_time,
        v_slot_end
      );

      IF v_conflicts > 0 THEN
        RETURN QUERY SELECT
          v_current_time,
          v_slot_end,
          FALSE,
          'Trainer unavailable (conflict or buffer)'::TEXT;
      ELSE
        RETURN QUERY SELECT
          v_current_time,
          v_slot_end,
          TRUE,
          'Available'::TEXT;
      END IF;
    END IF;

    v_current_time := v_current_time + INTERVAL '30 minutes';
  END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

-- Success message
SELECT '✅ Function updated successfully!' as status;
SELECT 'Working hours now: 7:00 AM - 10:00 PM' as hours;
SELECT 'Same-day booking: ENABLED (0 hours advance)' as booking_policy;
