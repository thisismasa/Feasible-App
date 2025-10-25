-- ============================================================================
-- PHASE 5: MULTI-LOCATION & RESOURCE MANAGEMENT
-- ============================================================================
-- Implements comprehensive location and resource management:
-- 1. Multiple training locations (gyms, studios, outdoor spaces)
-- 2. Equipment/resource booking (machines, rooms, equipment)
-- 3. Location-specific availability
-- 4. Travel time between locations
-- 5. Capacity management per location
-- 6. Location-based pricing modifiers
-- ============================================================================

-- STEP 1: Create locations table
-- ============================================================================

CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Location Details
  location_name TEXT NOT NULL,
  location_type TEXT NOT NULL, -- 'gym', 'studio', 'outdoor', 'home', 'virtual'
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state_province TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'Thailand',

  -- Coordinates
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),

  -- Contact
  phone TEXT,
  email TEXT,
  website TEXT,

  -- Capacity & Facilities
  max_concurrent_sessions INTEGER DEFAULT 1,
  available_equipment TEXT[],
  amenities TEXT[],
  accessibility_features TEXT[],

  -- Operating Hours (JSON format for flexibility)
  operating_hours JSONB, -- { "monday": {"open": "06:00", "close": "22:00"}, ... }

  -- Pricing
  price_modifier_percent DECIMAL(5,2) DEFAULT 0.00, -- +/- % on base price
  rental_fee_per_session DECIMAL(10,2) DEFAULT 0.00,

  -- Status & Settings
  is_active BOOLEAN DEFAULT TRUE,
  requires_booking BOOLEAN DEFAULT TRUE,
  booking_buffer_minutes INTEGER DEFAULT 15, -- Travel/setup time

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  CONSTRAINT valid_location_type CHECK (location_type IN ('gym', 'studio', 'outdoor', 'home', 'virtual')),
  CONSTRAINT valid_max_concurrent CHECK (max_concurrent_sessions > 0)
);

CREATE INDEX IF NOT EXISTS idx_locations_active ON locations(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(location_type);
CREATE INDEX IF NOT EXISTS idx_locations_coordinates ON locations(latitude, longitude) WHERE latitude IS NOT NULL;

COMMENT ON TABLE locations IS 'Training locations with capacity and resource management';

-- STEP 2: Create resources table
-- ============================================================================

CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,

  -- Resource Details
  resource_name TEXT NOT NULL,
  resource_type TEXT NOT NULL, -- 'equipment', 'room', 'trainer', 'vehicle'
  description TEXT,
  resource_code TEXT, -- Internal tracking code

  -- Capacity
  quantity_available INTEGER DEFAULT 1,
  is_shareable BOOLEAN DEFAULT FALSE, -- Can be used by multiple sessions simultaneously

  -- Booking
  requires_advance_booking BOOLEAN DEFAULT FALSE,
  min_booking_duration_minutes INTEGER DEFAULT 60,
  max_booking_duration_minutes INTEGER,

  -- Pricing
  rental_fee_per_hour DECIMAL(10,2) DEFAULT 0.00,
  deposit_required DECIMAL(10,2) DEFAULT 0.00,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_available BOOLEAN DEFAULT TRUE,
  maintenance_schedule JSONB,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_resource_type CHECK (resource_type IN ('equipment', 'room', 'trainer', 'vehicle', 'other')),
  CONSTRAINT valid_quantity CHECK (quantity_available > 0),
  CONSTRAINT unique_resource_code UNIQUE(location_id, resource_code)
);

CREATE INDEX IF NOT EXISTS idx_resources_location ON resources(location_id);
CREATE INDEX IF NOT EXISTS idx_resources_type ON resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_resources_available ON resources(is_active, is_available) WHERE is_active = TRUE;

-- STEP 3: Create resource_bookings table
-- ============================================================================

CREATE TABLE IF NOT EXISTS resource_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES resources(id),
  location_id UUID NOT NULL REFERENCES locations(id),

  -- Booking Details
  booked_start TIMESTAMPTZ NOT NULL,
  booked_end TIMESTAMPTZ NOT NULL,
  quantity_booked INTEGER DEFAULT 1,

  -- Status
  status TEXT DEFAULT 'confirmed', -- 'confirmed', 'pending', 'cancelled', 'completed'

  -- Fees
  rental_fee DECIMAL(10,2) DEFAULT 0.00,
  deposit_paid DECIMAL(10,2) DEFAULT 0.00,
  deposit_refunded BOOLEAN DEFAULT FALSE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,

  CONSTRAINT valid_booking_status CHECK (status IN ('confirmed', 'pending', 'cancelled', 'completed'))
);

CREATE INDEX IF NOT EXISTS idx_resource_bookings_session ON resource_bookings(session_id);
CREATE INDEX IF NOT EXISTS idx_resource_bookings_resource ON resource_bookings(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_bookings_time ON resource_bookings(booked_start, booked_end);

-- STEP 4: Create trainer_locations table (trainer availability per location)
-- ============================================================================

CREATE TABLE IF NOT EXISTS trainer_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,

  -- Availability
  is_primary_location BOOLEAN DEFAULT FALSE,
  availability_days INTEGER[], -- 0=Sunday, 1=Monday, etc.
  availability_start_time TIME,
  availability_end_time TIME,

  -- Travel
  travel_time_minutes INTEGER DEFAULT 0, -- Time to get to this location
  travel_cost DECIMAL(10,2) DEFAULT 0.00,

  -- Preferences
  preferred_session_types TEXT[], -- Which session types trainer offers here
  max_sessions_per_day INTEGER,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_trainer_location UNIQUE(trainer_id, location_id)
);

CREATE INDEX IF NOT EXISTS idx_trainer_locations_trainer ON trainer_locations(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_locations_location ON trainer_locations(location_id);
CREATE INDEX IF NOT EXISTS idx_trainer_locations_active ON trainer_locations(is_active) WHERE is_active = TRUE;

-- STEP 5: Add location to sessions table
-- ============================================================================

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES locations(id),
ADD COLUMN IF NOT EXISTS location_rental_fee DECIMAL(10,2) DEFAULT 0.00;

CREATE INDEX IF NOT EXISTS idx_sessions_location ON sessions(location_id) WHERE location_id IS NOT NULL;

-- STEP 6: Function to check location capacity
-- ============================================================================

CREATE OR REPLACE FUNCTION check_location_capacity(
  p_location_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
) RETURNS JSONB AS $$
DECLARE
  v_location RECORD;
  v_concurrent_sessions INTEGER;
BEGIN
  -- Get location details
  SELECT * INTO v_location
  FROM locations
  WHERE id = p_location_id AND is_active = TRUE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('available', FALSE, 'error', 'Location not found or inactive');
  END IF;

  -- Check operating hours
  -- (Simplified - would need full day-of-week logic)

  -- Count concurrent sessions at this location
  SELECT COUNT(*) INTO v_concurrent_sessions
  FROM sessions
  WHERE location_id = p_location_id
    AND status NOT IN ('cancelled', 'no_show', 'completed')
    AND tstzrange(scheduled_start, scheduled_end) && tstzrange(p_start_time, p_end_time);

  IF v_concurrent_sessions >= v_location.max_concurrent_sessions THEN
    RETURN jsonb_build_object(
      'available', FALSE,
      'error', 'Location at capacity',
      'current_sessions', v_concurrent_sessions,
      'max_capacity', v_location.max_concurrent_sessions
    );
  END IF;

  RETURN jsonb_build_object(
    'available', TRUE,
    'location_name', v_location.location_name,
    'current_sessions', v_concurrent_sessions,
    'max_capacity', v_location.max_concurrent_sessions,
    'slots_remaining', v_location.max_concurrent_sessions - v_concurrent_sessions
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 7: Function to check resource availability
-- ============================================================================

CREATE OR REPLACE FUNCTION check_resource_availability(
  p_resource_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ,
  p_quantity_needed INTEGER DEFAULT 1
) RETURNS JSONB AS $$
DECLARE
  v_resource RECORD;
  v_booked_quantity INTEGER;
  v_available_quantity INTEGER;
BEGIN
  -- Get resource details
  SELECT * INTO v_resource
  FROM resources
  WHERE id = p_resource_id AND is_active = TRUE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('available', FALSE, 'error', 'Resource not found or inactive');
  END IF;

  IF NOT v_resource.is_available THEN
    RETURN jsonb_build_object('available', FALSE, 'error', 'Resource currently unavailable');
  END IF;

  -- Calculate booked quantity during requested time
  SELECT COALESCE(SUM(quantity_booked), 0) INTO v_booked_quantity
  FROM resource_bookings
  WHERE resource_id = p_resource_id
    AND status IN ('confirmed', 'pending')
    AND tstzrange(booked_start, booked_end) && tstzrange(p_start_time, p_end_time);

  v_available_quantity := v_resource.quantity_available - v_booked_quantity;

  IF v_available_quantity < p_quantity_needed THEN
    RETURN jsonb_build_object(
      'available', FALSE,
      'error', 'Insufficient quantity',
      'requested', p_quantity_needed,
      'available', v_available_quantity,
      'resource_name', v_resource.resource_name
    );
  END IF;

  RETURN jsonb_build_object(
    'available', TRUE,
    'resource_name', v_resource.resource_name,
    'quantity_available', v_available_quantity,
    'rental_fee', v_resource.rental_fee_per_hour * EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 8: Function to calculate travel time between sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_travel_buffer(
  p_trainer_id UUID,
  p_from_location_id UUID,
  p_to_location_id UUID
) RETURNS INTEGER AS $$
DECLARE
  v_travel_time INTEGER := 0;
  v_from_location RECORD;
  v_to_location RECORD;
  v_distance_km DECIMAL;
BEGIN
  -- If same location, no travel time
  IF p_from_location_id = p_to_location_id OR p_from_location_id IS NULL OR p_to_location_id IS NULL THEN
    RETURN 0;
  END IF;

  -- Get trainer's configured travel time for destination
  SELECT travel_time_minutes INTO v_travel_time
  FROM trainer_locations
  WHERE trainer_id = p_trainer_id
    AND location_id = p_to_location_id;

  IF FOUND AND v_travel_time > 0 THEN
    RETURN v_travel_time;
  END IF;

  -- Calculate distance-based travel time using coordinates
  SELECT * INTO v_from_location FROM locations WHERE id = p_from_location_id;
  SELECT * INTO v_to_location FROM locations WHERE id = p_to_location_id;

  IF v_from_location.latitude IS NOT NULL AND v_to_location.latitude IS NOT NULL THEN
    -- Haversine formula for distance
    v_distance_km := 6371 * acos(
      cos(radians(v_from_location.latitude)) *
      cos(radians(v_to_location.latitude)) *
      cos(radians(v_to_location.longitude) - radians(v_from_location.longitude)) +
      sin(radians(v_from_location.latitude)) *
      sin(radians(v_to_location.latitude))
    );

    -- Estimate travel time: 30 km/h average in Bangkok traffic
    v_travel_time := CEIL((v_distance_km / 30.0) * 60)::INTEGER;

    -- Add buffer for parking/setup
    v_travel_time := v_travel_time + 15;

    RETURN v_travel_time;
  END IF;

  -- Default buffer if no data available
  RETURN 30;
END;
$$ LANGUAGE plpgsql;

-- STEP 9: Enhanced conflict detection with location/travel time
-- ============================================================================

CREATE OR REPLACE FUNCTION check_booking_conflicts_with_location(
  p_trainer_id UUID,
  p_client_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_scheduled_end TIMESTAMPTZ,
  p_location_id UUID,
  p_excluded_session_id UUID DEFAULT NULL
) RETURNS TABLE (
  conflict_type TEXT,
  conflict_description TEXT,
  conflicting_session_id UUID,
  additional_info JSONB
) AS $$
DECLARE
  v_buffer_minutes INTEGER;
  v_prev_session RECORD;
  v_next_session RECORD;
  v_travel_time_before INTEGER;
  v_travel_time_after INTEGER;
BEGIN
  -- Get base buffer time
  v_buffer_minutes := get_buffer_minutes(p_trainer_id);

  -- Check previous session for travel time
  SELECT * INTO v_prev_session
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status NOT IN ('cancelled', 'no_show')
    AND scheduled_end <= p_scheduled_start
    AND (p_excluded_session_id IS NULL OR id != p_excluded_session_id)
  ORDER BY scheduled_end DESC
  LIMIT 1;

  IF FOUND THEN
    v_travel_time_before := calculate_travel_buffer(
      p_trainer_id,
      v_prev_session.location_id,
      p_location_id
    );

    -- Check if enough time between sessions
    IF v_prev_session.scheduled_end + (v_travel_time_before || ' minutes')::INTERVAL > p_scheduled_start THEN
      RETURN QUERY SELECT
        'insufficient_travel_time'::TEXT,
        'Not enough time to travel from previous location'::TEXT,
        v_prev_session.id,
        jsonb_build_object(
          'required_travel_minutes', v_travel_time_before,
          'available_minutes', EXTRACT(EPOCH FROM (p_scheduled_start - v_prev_session.scheduled_end)) / 60,
          'previous_location', v_prev_session.location_id
        );
    END IF;
  END IF;

  -- Check next session for travel time
  SELECT * INTO v_next_session
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status NOT IN ('cancelled', 'no_show')
    AND scheduled_start >= p_scheduled_end
    AND (p_excluded_session_id IS NULL OR id != p_excluded_session_id)
  ORDER BY scheduled_start ASC
  LIMIT 1;

  IF FOUND THEN
    v_travel_time_after := calculate_travel_buffer(
      p_trainer_id,
      p_location_id,
      v_next_session.location_id
    );

    IF p_scheduled_end + (v_travel_time_after || ' minutes')::INTERVAL > v_next_session.scheduled_start THEN
      RETURN QUERY SELECT
        'insufficient_travel_time'::TEXT,
        'Not enough time to travel to next location'::TEXT,
        v_next_session.id,
        jsonb_build_object(
          'required_travel_minutes', v_travel_time_after,
          'available_minutes', EXTRACT(EPOCH FROM (v_next_session.scheduled_start - p_scheduled_end)) / 60,
          'next_location', v_next_session.location_id
        );
    END IF;
  END IF;

  -- Check location capacity
  DECLARE
    v_capacity_check JSONB;
  BEGIN
    v_capacity_check := check_location_capacity(p_location_id, p_scheduled_start, p_scheduled_end);

    IF NOT (v_capacity_check->>'available')::BOOLEAN THEN
      RETURN QUERY SELECT
        'location_capacity'::TEXT,
        (v_capacity_check->>'error')::TEXT,
        NULL::UUID,
        v_capacity_check;
    END IF;
  END;

  -- Run standard conflict checks (from Phase 1)
  RETURN QUERY
  SELECT * FROM check_booking_conflicts(
    p_trainer_id,
    p_client_id,
    p_scheduled_start,
    p_scheduled_end,
    p_excluded_session_id
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 10: Function to get available locations for time slot
-- ============================================================================

CREATE OR REPLACE FUNCTION get_available_locations(
  p_trainer_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
) RETURNS TABLE (
  location_id UUID,
  location_name TEXT,
  location_type TEXT,
  address TEXT,
  is_primary BOOLEAN,
  travel_time_minutes INTEGER,
  rental_fee DECIMAL,
  capacity_available INTEGER,
  distance_km DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    l.location_name,
    l.location_type,
    COALESCE(l.address_line1 || ', ' || l.city, 'No address'),
    tl.is_primary_location,
    tl.travel_time_minutes,
    l.rental_fee_per_session,
    (check_location_capacity(l.id, p_start_time, p_end_time)->>'slots_remaining')::INTEGER,
    NULL::DECIMAL -- Could calculate from trainer's current location
  FROM locations l
  JOIN trainer_locations tl ON l.id = tl.location_id
  WHERE tl.trainer_id = p_trainer_id
    AND l.is_active = TRUE
    AND tl.is_active = TRUE
    AND (check_location_capacity(l.id, p_start_time, p_end_time)->>'available')::BOOLEAN = TRUE
  ORDER BY
    tl.is_primary_location DESC,
    tl.travel_time_minutes ASC;
END;
$$ LANGUAGE plpgsql;

-- STEP 11: Create view for location analytics
-- ============================================================================

CREATE OR REPLACE VIEW location_analytics AS
SELECT
  l.id as location_id,
  l.location_name,
  l.location_type,
  l.city,
  l.max_concurrent_sessions,
  COUNT(DISTINCT s.id) as total_sessions,
  COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'completed') as completed_sessions,
  COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'cancelled') as cancelled_sessions,
  COUNT(DISTINCT s.trainer_id) as unique_trainers,
  COUNT(DISTINCT s.client_id) as unique_clients,
  SUM(s.location_rental_fee) as total_rental_revenue,
  AVG(EXTRACT(EPOCH FROM (s.scheduled_end - s.scheduled_start)) / 60) as avg_session_duration_minutes,
  MIN(s.scheduled_start) as first_session_date,
  MAX(s.scheduled_start) as last_session_date,
  ROUND(
    COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'completed')::NUMERIC /
    NULLIF(COUNT(DISTINCT s.id), 0) * 100,
    2
  ) as completion_rate_percent,
  ROUND(
    COUNT(DISTINCT DATE(s.scheduled_start))::NUMERIC /
    GREATEST(EXTRACT(DAYS FROM (NOW() - MIN(s.scheduled_start)))::INTEGER, 1),
    2
  ) as avg_sessions_per_day
FROM locations l
LEFT JOIN sessions s ON l.id = s.location_id
WHERE l.is_active = TRUE
GROUP BY
  l.id, l.location_name, l.location_type, l.city, l.max_concurrent_sessions
ORDER BY total_sessions DESC;

-- STEP 12: Insert sample locations
-- ============================================================================

INSERT INTO locations (
  location_name, location_type, address_line1, city,
  latitude, longitude, max_concurrent_sessions,
  available_equipment, operating_hours, is_active
) VALUES
(
  'Main Fitness Studio',
  'studio',
  '123 Sukhumvit Road',
  'Bangkok',
  13.7563,
  100.5018,
  3,
  ARRAY['dumbbells', 'kettlebells', 'resistance_bands', 'yoga_mats', 'treadmill'],
  '{"monday": {"open": "06:00", "close": "22:00"}, "tuesday": {"open": "06:00", "close": "22:00"}, "wednesday": {"open": "06:00", "close": "22:00"}, "thursday": {"open": "06:00", "close": "22:00"}, "friday": {"open": "06:00", "close": "22:00"}, "saturday": {"open": "08:00", "close": "20:00"}, "sunday": {"open": "08:00", "close": "18:00"}}'::JSONB,
  TRUE
),
(
  'Outdoor Training Park',
  'outdoor',
  'Lumpini Park, Rama IV Road',
  'Bangkok',
  13.7307,
  100.5418,
  5,
  ARRAY['pull_up_bars', 'parallel_bars', 'running_track'],
  '{"monday": {"open": "05:00", "close": "20:00"}, "tuesday": {"open": "05:00", "close": "20:00"}, "wednesday": {"open": "05:00", "close": "20:00"}, "thursday": {"open": "05:00", "close": "20:00"}, "friday": {"open": "05:00", "close": "20:00"}, "saturday": {"open": "05:00", "close": "20:00"}, "sunday": {"open": "05:00", "close": "20:00"}}'::JSONB,
  TRUE
),
(
  'Virtual Training',
  'virtual',
  NULL,
  'Online',
  NULL,
  NULL,
  10,
  ARRAY['video_conferencing'],
  '{"monday": {"open": "00:00", "close": "23:59"}, "tuesday": {"open": "00:00", "close": "23:59"}, "wednesday": {"open": "00:00", "close": "23:59"}, "thursday": {"open": "00:00", "close": "23:59"}, "friday": {"open": "00:00", "close": "23:59"}, "saturday": {"open": "00:00", "close": "23:59"}, "sunday": {"open": "00:00", "close": "23:59"}}'::JSONB,
  TRUE
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Phase 5 Complete: Multi-Location & Resource Management Implemented!' as message;
SELECT 'Features enabled:' as info,
       '- Multiple training locations with capacity management' as feature_1,
       '- Equipment and resource booking' as feature_2,
       '- Location-specific trainer availability' as feature_3,
       '- Automatic travel time calculation between locations' as feature_4,
       '- Location capacity and concurrent session limits' as feature_5,
       '- Location analytics and reporting' as feature_6,
       '- Sample locations created (Studio, Park, Virtual)' as feature_7;

SELECT 'Next steps:' as todo,
       '1. Link trainers to locations via trainer_locations table' as step_1,
       '2. Add resources (equipment, rooms) via resources table' as step_2,
       '3. Update booking flow to select location' as step_3,
       '4. Test conflict detection with travel time' as step_4;
