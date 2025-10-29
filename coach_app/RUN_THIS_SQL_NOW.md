# 🚀 RUN THIS SQL NOW - ULTRATHINK MODE

## ⚡ QUICK STEPS (2 minutes):

### 1. Open Supabase SQL Editor

**Direct Link**: https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new

OR

1. Go to https://supabase.com/dashboard
2. Click your project: **dkdnpceoanwbeulhkvdh**
3. Click **"SQL Editor"** in left sidebar
4. Click **"New query"** button

### 2. Copy SQL Below

```sql
-- ============================================================================
-- FIX DOUBLE BOOKING: REJECT conflicting bookings instead of just warning
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

-- Recreate with STRICT conflict rejection
CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_package_sessions INTEGER;
  v_client_package_id UUID;
  v_session_id UUID;
  v_has_conflicts BOOLEAN;
  v_scheduled_end TIMESTAMPTZ;
  v_conflict_count INTEGER;
BEGIN
  -- Calculate session end time
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::interval;

  -- Check package for THIS specific client
  SELECT cp.remaining_sessions, cp.id
  INTO v_package_sessions, v_client_package_id
  FROM client_packages cp
  WHERE cp.package_id = p_package_id
    AND cp.client_id = p_client_id
    AND cp.status = 'active'
  LIMIT 1;

  -- Validate package exists and is active
  IF v_client_package_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Package not found or inactive',
      'details', 'No active package found for this client with package_id: ' || p_package_id::text
    );
  END IF;

  -- Validate remaining sessions
  IF v_package_sessions IS NULL OR v_package_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No remaining sessions',
      'remaining_sessions', COALESCE(v_package_sessions, 0)
    );
  END IF;

  -- ============================================================================
  -- CRITICAL FIX: REJECT bookings with conflicts (don't just warn)
  -- ============================================================================

  -- Count conflicting sessions
  SELECT COUNT(*)
  INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (
      -- New session starts during existing session
      (p_scheduled_start >= scheduled_start AND p_scheduled_start < scheduled_end)
      OR
      -- New session ends during existing session
      (v_scheduled_end > scheduled_start AND v_scheduled_end <= scheduled_end)
      OR
      -- New session completely encompasses existing session
      (p_scheduled_start <= scheduled_start AND v_scheduled_end >= scheduled_end)
    );

  -- REJECT if conflicts found
  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Time slot conflict',
      'details', 'This time slot is already booked. Please choose a different time.',
      'conflict_count', v_conflict_count,
      'suggested_action', 'Select a different time slot or check trainer availability'
    );
  END IF;

  -- ============================================================================
  -- No conflicts - proceed with booking
  -- ============================================================================

  -- Create session record
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    session_type,
    location,
    notes,
    status,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    p_scheduled_start,
    v_scheduled_end,
    p_duration_minutes,
    COALESCE(p_session_type, 'in_person'),
    p_location,
    p_notes,
    'scheduled',
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  -- Return success
  RETURN jsonb_build_object(
    'success', true,
    'session_id', v_session_id,
    'has_conflicts', false,
    'remaining_sessions', v_package_sessions - 1,
    'message', 'Session booked successfully! No conflicts detected.'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'error_detail', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION book_session_with_validation TO authenticated;
GRANT EXECUTE ON FUNCTION book_session_with_validation TO anon;

-- Verify function was created successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'book_session_with_validation'
  ) THEN
    RAISE NOTICE '✅ Function book_session_with_validation updated successfully';
    RAISE NOTICE '✅ Double booking prevention: ACTIVE';
    RAISE NOTICE '✅ Conflicting time slots will now be REJECTED';
  ELSE
    RAISE EXCEPTION '❌ Function was not created properly';
  END IF;
END $$;
```

### 3. Click "RUN" Button

You should see:
```
✅ Function book_session_with_validation updated successfully
✅ Double booking prevention: ACTIVE
✅ Conflicting time slots will now be REJECTED
```

### 4. DONE! ✅

Now go test in your app!

---

## 🧪 TESTING

Your app is running at: http://localhost:8080

### Test 1: Calendar Sync
1. Book session at Oct 28, 3:30 PM
2. Open browser console (F12)
3. Look for: `✅ Calendar event created`
4. Check https://calendar.google.com
5. Event should be there! 📅

### Test 2: Double Booking Prevention
1. Try to book Oct 28, 3:30 PM again
2. Should see error: "Time slot conflict"
3. Try Oct 28, 4:00 PM instead
4. Should work! ✅

---

**Status**: SQL ready to run
**Time required**: 2 minutes
**Next**: Test the app!
