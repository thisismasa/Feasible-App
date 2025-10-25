-- ================================================
-- BOOKING TRANSACTION FUNCTION FOR SUPABASE
-- ================================================
-- This stored procedure ensures atomic booking operations
-- preventing race conditions and data inconsistencies
-- ================================================

CREATE OR REPLACE FUNCTION book_session_transaction(
  p_client_id UUID,
  p_trainer_id UUID,
  p_dates TIMESTAMP[],
  p_duration INTEGER,
  p_package_id UUID,
  p_session_type TEXT,
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_remaining_sessions INTEGER;
  v_package_expiry TIMESTAMP;
  v_package_status TEXT;
  v_session_id UUID;
  v_session_ids UUID[] := ARRAY[]::UUID[];
  v_conflict_count INTEGER;
  v_date TIMESTAMP;
BEGIN
  -- =========================
  -- 1. LOCK THE PACKAGE ROW
  -- =========================
  -- Prevents concurrent modifications
  SELECT 
    remaining_sessions,
    expiry_date,
    status
  INTO 
    v_remaining_sessions,
    v_package_expiry,
    v_package_status
  FROM client_packages
  WHERE id = p_package_id
  FOR UPDATE; -- THIS LOCKS THE ROW
  
  -- =========================
  -- 2. VALIDATE PACKAGE
  -- =========================
  
  -- Check if package exists
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Package not found'
    );
  END IF;
  
  -- Check package status
  IF v_package_status != 'active' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Package is ' || v_package_status
    );
  END IF;
  
  -- Check remaining sessions
  IF v_remaining_sessions < array_length(p_dates, 1) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Not enough sessions remaining',
      'remaining', v_remaining_sessions,
      'required', array_length(p_dates, 1)
    );
  END IF;
  
  -- Check expiration
  IF v_package_expiry < p_dates[array_upper(p_dates, 1)] THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Package expires before last session date'
    );
  END IF;
  
  -- =========================
  -- 3. CHECK TIME CONFLICTS
  -- =========================
  FOREACH v_date IN ARRAY p_dates
  LOOP
    -- Check for existing sessions at this time (with 15min buffer)
    SELECT COUNT(*) INTO v_conflict_count
    FROM sessions
    WHERE trainer_id = p_trainer_id
    AND status != 'cancelled'
    AND (
      -- Direct overlap
      (scheduled_date <= v_date AND scheduled_date + (duration_minutes || ' minutes')::INTERVAL > v_date)
      OR
      -- Within buffer time
      (scheduled_date > v_date - INTERVAL '15 minutes' 
       AND scheduled_date < v_date + (p_duration || ' minutes')::INTERVAL + INTERVAL '15 minutes')
    );
    
    IF v_conflict_count > 0 THEN
      RETURN json_build_object(
        'success', false,
        'error', 'Time slot conflict detected',
        'conflicting_date', v_date
      );
    END IF;
  END LOOP;
  
  -- =========================
  -- 4. CREATE SESSIONS
  -- =========================
  FOREACH v_date IN ARRAY p_dates
  LOOP
    INSERT INTO sessions (
      id,
      client_id,
      trainer_id,
      scheduled_date,
      duration_minutes,
      status,
      session_type,
      location,
      notes,
      client_package_id,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      p_client_id,
      p_trainer_id,
      v_date,
      p_duration,
      'scheduled',
      p_session_type,
      p_location,
      p_notes,
      p_package_id,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_session_id;
    
    -- Add to result array
    v_session_ids := array_append(v_session_ids, v_session_id);
  END LOOP;
  
  -- =========================
  -- 5. UPDATE PACKAGE
  -- =========================
  UPDATE client_packages
  SET 
    sessions_used = sessions_used + array_length(p_dates, 1),
    updated_at = NOW()
  WHERE id = p_package_id;
  
  -- =========================
  -- 6. LOG THE TRANSACTION
  -- =========================
  INSERT INTO booking_logs (
    package_id,
    action,
    sessions_booked,
    timestamp,
    metadata
  ) VALUES (
    p_package_id,
    'book_sessions',
    array_length(p_dates, 1),
    NOW(),
    json_build_object(
      'session_ids', v_session_ids,
      'duration', p_duration,
      'type', p_session_type
    )
  );
  
  -- =========================
  -- 7. RETURN SUCCESS
  -- =========================
  RETURN json_build_object(
    'success', true,
    'message', 'Sessions booked successfully',
    'session_ids', v_session_ids,
    'sessions_booked', array_length(p_dates, 1)
  );
  
EXCEPTION
  WHEN OTHERS THEN
    -- Rollback happens automatically
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- ================================================
-- CREATE BOOKING LOGS TABLE (if not exists)
-- ================================================
CREATE TABLE IF NOT EXISTS booking_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id UUID REFERENCES client_packages(id),
  action TEXT NOT NULL,
  sessions_booked INTEGER,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB
);

-- ================================================
-- CREATE UNIQUE INDEX TO PREVENT DOUBLE BOOKING
-- ================================================
CREATE UNIQUE INDEX IF NOT EXISTS unique_trainer_timeslot
ON sessions(trainer_id, scheduled_date)
WHERE status != 'cancelled';

-- ================================================
-- ROW LEVEL SECURITY POLICIES
-- ================================================

-- Allow trainers to create sessions for their clients
CREATE POLICY "Trainers can create sessions"
ON sessions FOR INSERT
WITH CHECK (
  auth.uid() = trainer_id
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'trainer'
  )
);

-- Allow users to view their own sessions
CREATE POLICY "Users can view their sessions"
ON sessions FOR SELECT
USING (
  auth.uid() = client_id 
  OR auth.uid() = trainer_id
);

-- Allow trainers to update/cancel sessions
CREATE POLICY "Trainers can update sessions"
ON sessions FOR UPDATE
USING (auth.uid() = trainer_id);

-- ================================================
-- HELPER FUNCTIONS
-- ================================================

-- Function to check trainer availability
CREATE OR REPLACE FUNCTION check_trainer_availability(
  p_trainer_id UUID,
  p_date TIMESTAMP,
  p_duration INTEGER
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_conflict_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
  AND status != 'cancelled'
  AND (
    (scheduled_date <= p_date 
     AND scheduled_date + (duration_minutes || ' minutes')::INTERVAL > p_date)
    OR
    (scheduled_date >= p_date 
     AND scheduled_date < p_date + (p_duration || ' minutes')::INTERVAL)
  );
  
  RETURN v_conflict_count = 0;
END;
$$;

-- Function to get booking stats
CREATE OR REPLACE FUNCTION get_booking_stats(
  p_trainer_id UUID,
  p_start_date TIMESTAMP,
  p_end_date TIMESTAMP
) RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_stats JSON;
BEGIN
  SELECT json_build_object(
    'total_bookings', COUNT(*),
    'completed', COUNT(*) FILTER (WHERE status = 'completed'),
    'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'scheduled', COUNT(*) FILTER (WHERE status = 'scheduled'),
    'no_show', COUNT(*) FILTER (WHERE status = 'no_show'),
    'cancellation_rate', 
      ROUND(
        (COUNT(*) FILTER (WHERE status = 'cancelled')::NUMERIC / 
         NULLIF(COUNT(*)::NUMERIC, 0) * 100),
        2
      )
  ) INTO v_stats
  FROM sessions
  WHERE trainer_id = p_trainer_id
  AND scheduled_date BETWEEN p_start_date AND p_end_date;
  
  RETURN v_stats;
END;
$$;

-- ================================================
-- TRIGGERS
-- ================================================

-- Auto-update package status when sessions used up
CREATE OR REPLACE FUNCTION update_package_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.sessions_used >= NEW.total_sessions THEN
    NEW.status := 'completed';
  END IF;
  
  IF NEW.expiry_date < NOW() THEN
    NEW.status := 'expired';
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER package_status_trigger
BEFORE UPDATE ON client_packages
FOR EACH ROW
EXECUTE FUNCTION update_package_status();

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_sessions_trainer_date 
ON sessions(trainer_id, scheduled_date) 
WHERE status != 'cancelled';

CREATE INDEX IF NOT EXISTS idx_sessions_client_date 
ON sessions(client_id, scheduled_date);

CREATE INDEX IF NOT EXISTS idx_package_client 
ON client_packages(client_id, status);

-- ================================================
-- COMMENTS
-- ================================================
COMMENT ON FUNCTION book_session_transaction IS 
'Atomically books one or more training sessions with full validation and conflict checking';

COMMENT ON FUNCTION check_trainer_availability IS 
'Quickly checks if a trainer is available at a specific time';

COMMENT ON FUNCTION get_booking_stats IS 
'Returns comprehensive booking statistics for a trainer within a date range';

