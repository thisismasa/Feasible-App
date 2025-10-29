-- ============================================================================
-- MULTI-TRAINER SYSTEM - COMPLETE UPGRADE
-- ============================================================================
-- Transform database to support MULTIPLE trainers (PTs) for the future
-- Not just for one trainer, but for unlimited trainers in your business
-- ============================================================================
-- Features:
-- ✅ Multiple trainer accounts
-- ✅ Trainer-specific client assignments
-- ✅ Trainer-specific bookings and schedules
-- ✅ Trainer-specific packages
-- ✅ Trainer availability/working hours
-- ✅ Trainer performance metrics
-- ✅ Admin can manage all trainers
-- ✅ Trainers only see their own clients
-- ✅ Client transfer between trainers
-- ============================================================================

-- ============================================================================
-- SECTION 1: TRAINER PROFILE & MANAGEMENT
-- ============================================================================

-- Add trainer-specific fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS specialization TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS certifications TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS experience_years INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS languages TEXT[];

-- Create trainer_profiles table for extended trainer information
CREATE TABLE IF NOT EXISTS trainer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Professional info
  license_number TEXT,
  license_expiry_date DATE,
  insurance_provider TEXT,
  insurance_policy_number TEXT,

  -- Business info
  commission_rate DECIMAL(5,2) DEFAULT 0.0, -- % of revenue
  max_clients_capacity INTEGER DEFAULT 50,
  current_clients_count INTEGER DEFAULT 0,

  -- Ratings & performance
  average_rating DECIMAL(3,2) DEFAULT 5.0,
  total_sessions_completed INTEGER DEFAULT 0,
  total_clients_served INTEGER DEFAULT 0,

  -- Availability
  is_accepting_new_clients BOOLEAN DEFAULT true,
  preferred_working_hours JSONB, -- {"monday": ["09:00-17:00"], ...}

  -- Social & contact
  website_url TEXT,
  instagram_handle TEXT,
  facebook_url TEXT,
  linkedin_url TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_trainer_profiles_trainer_id ON trainer_profiles(trainer_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- ============================================================================
-- SECTION 2: TRAINER AVAILABILITY & SCHEDULING
-- ============================================================================

-- Create trainer_availability table for working hours
CREATE TABLE IF NOT EXISTS trainer_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, ..., 6=Saturday
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,

  is_active BOOLEAN DEFAULT true,
  location TEXT, -- 'gym', 'online', 'home_visit', etc.

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT check_valid_day CHECK (day_of_week BETWEEN 0 AND 6),
  CONSTRAINT check_valid_time CHECK (start_time < end_time)
);

CREATE INDEX IF NOT EXISTS idx_trainer_availability_trainer ON trainer_availability(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_availability_day ON trainer_availability(day_of_week);

-- Create trainer_time_off table for vacation/sick days
CREATE TABLE IF NOT EXISTS trainer_time_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  type TEXT, -- 'vacation', 'sick', 'personal', 'conference'

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT check_valid_date_range CHECK (start_date <= end_date)
);

CREATE INDEX IF NOT EXISTS idx_trainer_time_off_trainer ON trainer_time_off(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_time_off_dates ON trainer_time_off(start_date, end_date);

-- ============================================================================
-- SECTION 3: UPGRADE EXISTING TABLES FOR MULTI-TRAINER
-- ============================================================================

-- Ensure client_packages has trainer_id
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_client_packages_trainer_id ON client_packages(trainer_id);

-- Add trainer_id to bookings if not exists (already exists, but ensure index)
CREATE INDEX IF NOT EXISTS idx_bookings_trainer_id ON bookings(trainer_id);

-- Create location column for bookings
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS location TEXT DEFAULT 'gym';

-- ============================================================================
-- SECTION 4: PACKAGES - TRAINER-SPECIFIC PRICING
-- ============================================================================

-- Add trainer-specific package pricing
CREATE TABLE IF NOT EXISTS trainer_package_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,

  -- Custom pricing for this trainer
  custom_price DECIMAL(10,2),
  custom_sessions INTEGER,
  is_available BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(trainer_id, package_id)
);

CREATE INDEX IF NOT EXISTS idx_trainer_package_pricing_trainer ON trainer_package_pricing(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_package_pricing_package ON trainer_package_pricing(package_id);

-- ============================================================================
-- SECTION 5: CLIENT TRANSFER BETWEEN TRAINERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS client_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  transfer_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reason TEXT,
  notes TEXT,

  -- Transfer metadata
  sessions_transferred INTEGER DEFAULT 0,
  packages_transferred INTEGER DEFAULT 0,

  initiated_by UUID REFERENCES users(id), -- Who initiated the transfer (admin/trainer)

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_transfers_client ON client_transfers(client_id);
CREATE INDEX IF NOT EXISTS idx_client_transfers_trainers ON client_transfers(from_trainer_id, to_trainer_id);

-- ============================================================================
-- SECTION 6: TRAINER PERFORMANCE METRICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS trainer_session_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Session feedback
  trainer_notes TEXT,
  client_performance_rating INTEGER, -- 1-5
  exercises_performed TEXT[],
  goals_achieved TEXT[],

  -- Next session planning
  recommended_next_focus TEXT,
  homework_assigned TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT check_valid_rating CHECK (client_performance_rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_trainer_session_notes_booking ON trainer_session_notes(booking_id);
CREATE INDEX IF NOT EXISTS idx_trainer_session_notes_trainer ON trainer_session_notes(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_session_notes_client ON trainer_session_notes(client_id);

-- ============================================================================
-- SECTION 7: ROW LEVEL SECURITY (RLS) - MULTI-TRAINER AWARE
-- ============================================================================

-- Enable RLS on all trainer-related tables
ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_time_off ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_package_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_session_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES: TRAINER PROFILES
-- ============================================================================

DROP POLICY IF EXISTS "Trainers manage their own profile" ON trainer_profiles;
CREATE POLICY "Trainers manage their own profile" ON trainer_profiles
  FOR ALL USING (
    auth.uid() = trainer_id OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Public can view active trainers" ON trainer_profiles;
CREATE POLICY "Public can view active trainers" ON trainer_profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = trainer_id AND is_active = true)
  );

-- ============================================================================
-- RLS POLICIES: TRAINER AVAILABILITY
-- ============================================================================

DROP POLICY IF EXISTS "Trainers manage their availability" ON trainer_availability;
CREATE POLICY "Trainers manage their availability" ON trainer_availability
  FOR ALL USING (
    auth.uid() = trainer_id OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Clients view trainer availability" ON trainer_availability;
CREATE POLICY "Clients view trainer availability" ON trainer_availability
  FOR SELECT USING (is_active = true);

-- ============================================================================
-- RLS POLICIES: CLIENT PACKAGES (TRAINER-SPECIFIC)
-- ============================================================================

DROP POLICY IF EXISTS "Trainers view their client packages" ON client_packages;
CREATE POLICY "Trainers view their client packages" ON client_packages
  FOR SELECT USING (
    auth.uid() = trainer_id OR
    auth.uid() = client_id OR
    EXISTS (
      SELECT 1 FROM trainer_clients
      WHERE trainer_id = auth.uid() AND client_id = client_packages.client_id
    ) OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Trainers manage their client packages" ON client_packages;
CREATE POLICY "Trainers manage their client packages" ON client_packages
  FOR ALL USING (
    auth.uid() = trainer_id OR
    EXISTS (
      SELECT 1 FROM trainer_clients
      WHERE trainer_id = auth.uid() AND client_id = client_packages.client_id
    ) OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- RLS POLICIES: BOOKINGS (TRAINER-SPECIFIC)
-- ============================================================================

DROP POLICY IF EXISTS "Trainers view their bookings" ON bookings;
CREATE POLICY "Trainers view their bookings" ON bookings
  FOR SELECT USING (
    auth.uid() = trainer_id OR
    auth.uid() = client_id OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Trainers manage their bookings" ON bookings;
CREATE POLICY "Trainers manage their bookings" ON bookings
  FOR ALL USING (
    auth.uid() = trainer_id OR
    EXISTS (
      SELECT 1 FROM trainer_clients
      WHERE trainer_id = auth.uid() AND client_id = bookings.client_id
    ) OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- SECTION 8: DATABASE FUNCTIONS - MULTI-TRAINER AWARE
-- ============================================================================

-- Function: Get trainer's clients with package info
CREATE OR REPLACE FUNCTION get_trainer_clients(p_trainer_id UUID)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  client_email TEXT,
  client_phone TEXT,
  active_packages INTEGER,
  total_sessions_remaining INTEGER,
  last_session_date TIMESTAMP WITH TIME ZONE,
  next_scheduled_session TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS client_id,
    u.full_name AS client_name,
    u.email AS client_email,
    u.phone AS client_phone,
    COUNT(DISTINCT cp.id)::INTEGER AS active_packages,
    COALESCE(SUM(cp.remaining_sessions), 0)::INTEGER AS total_sessions_remaining,
    MAX(b.session_date) AS last_session_date,
    MIN(CASE WHEN b.session_date > NOW() THEN b.session_date END) AS next_scheduled_session
  FROM users u
  INNER JOIN trainer_clients tc ON tc.client_id = u.id
  LEFT JOIN client_packages cp ON cp.client_id = u.id AND cp.is_active = true
  LEFT JOIN bookings b ON b.client_id = u.id AND b.trainer_id = p_trainer_id
  WHERE tc.trainer_id = p_trainer_id
    AND tc.is_active = true
    AND u.role = 'client'
  GROUP BY u.id, u.full_name, u.email, u.phone
  ORDER BY u.full_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Check trainer availability for booking
CREATE OR REPLACE FUNCTION is_trainer_available(
  p_trainer_id UUID,
  p_session_date TIMESTAMP WITH TIME ZONE,
  p_duration_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN AS $$
DECLARE
  v_day_of_week INTEGER;
  v_session_time TIME;
  v_session_end_time TIME;
  v_is_available BOOLEAN := false;
  v_has_time_off BOOLEAN := false;
  v_has_conflict BOOLEAN := false;
BEGIN
  -- Get day of week and time
  v_day_of_week := EXTRACT(DOW FROM p_session_date);
  v_session_time := p_session_date::TIME;
  v_session_end_time := (p_session_date + (p_duration_minutes || ' minutes')::INTERVAL)::TIME;

  -- Check if trainer has working hours for this day/time
  SELECT EXISTS (
    SELECT 1 FROM trainer_availability
    WHERE trainer_id = p_trainer_id
      AND day_of_week = v_day_of_week
      AND is_active = true
      AND v_session_time >= start_time
      AND v_session_end_time <= end_time
  ) INTO v_is_available;

  -- Check if trainer has time off on this date
  SELECT EXISTS (
    SELECT 1 FROM trainer_time_off
    WHERE trainer_id = p_trainer_id
      AND p_session_date::DATE BETWEEN start_date AND end_date
  ) INTO v_has_time_off;

  -- Check for booking conflicts
  SELECT EXISTS (
    SELECT 1 FROM bookings
    WHERE trainer_id = p_trainer_id
      AND status NOT IN ('cancelled', 'no_show')
      AND (
        -- New session starts during existing booking
        (p_session_date BETWEEN session_date AND session_date + (duration_minutes || ' minutes')::INTERVAL) OR
        -- New session ends during existing booking
        ((p_session_date + (p_duration_minutes || ' minutes')::INTERVAL) BETWEEN session_date AND session_date + (duration_minutes || ' minutes')::INTERVAL) OR
        -- New session completely contains existing booking
        (session_date BETWEEN p_session_date AND p_session_date + (p_duration_minutes || ' minutes')::INTERVAL)
      )
  ) INTO v_has_conflict;

  -- Return true only if available, not on time off, and no conflicts
  RETURN v_is_available AND NOT v_has_time_off AND NOT v_has_conflict;
END;
$$ LANGUAGE plpgsql;

-- Function: Transfer client to another trainer
CREATE OR REPLACE FUNCTION transfer_client_to_trainer(
  p_client_id UUID,
  p_from_trainer_id UUID,
  p_to_trainer_id UUID,
  p_reason TEXT DEFAULT NULL,
  p_initiated_by UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_sessions_count INTEGER;
  v_packages_count INTEGER;
  v_transfer_id UUID;
BEGIN
  -- Count sessions and packages being transferred
  SELECT COUNT(*) INTO v_packages_count
  FROM client_packages
  WHERE client_id = p_client_id AND trainer_id = p_from_trainer_id;

  -- Update trainer_clients assignment
  UPDATE trainer_clients
  SET trainer_id = p_to_trainer_id, updated_at = NOW()
  WHERE client_id = p_client_id AND trainer_id = p_from_trainer_id;

  -- Update client_packages trainer
  UPDATE client_packages
  SET trainer_id = p_to_trainer_id, updated_at = NOW()
  WHERE client_id = p_client_id AND trainer_id = p_from_trainer_id;

  -- Update future bookings trainer
  UPDATE bookings
  SET trainer_id = p_to_trainer_id, updated_at = NOW()
  WHERE client_id = p_client_id
    AND trainer_id = p_from_trainer_id
    AND session_date > NOW()
    AND status = 'scheduled';

  GET DIAGNOSTICS v_sessions_count = ROW_COUNT;

  -- Log the transfer
  INSERT INTO client_transfers (
    client_id, from_trainer_id, to_trainer_id,
    reason, sessions_transferred, packages_transferred, initiated_by
  ) VALUES (
    p_client_id, p_from_trainer_id, p_to_trainer_id,
    p_reason, v_sessions_count, v_packages_count, p_initiated_by
  ) RETURNING id INTO v_transfer_id;

  RETURN jsonb_build_object(
    'success', true,
    'transfer_id', v_transfer_id,
    'sessions_transferred', v_sessions_count,
    'packages_transferred', v_packages_count
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- Function: Get trainer dashboard stats
CREATE OR REPLACE FUNCTION get_trainer_dashboard_stats(p_trainer_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_clients', (
      SELECT COUNT(*) FROM trainer_clients
      WHERE trainer_id = p_trainer_id AND is_active = true
    ),
    'active_packages', (
      SELECT COUNT(*) FROM client_packages
      WHERE trainer_id = p_trainer_id AND is_active = true
        AND remaining_sessions > 0
        AND expiry_date > NOW()
    ),
    'today_sessions', (
      SELECT COUNT(*) FROM bookings
      WHERE trainer_id = p_trainer_id
        AND session_date::DATE = CURRENT_DATE
        AND status = 'scheduled'
    ),
    'this_week_sessions', (
      SELECT COUNT(*) FROM bookings
      WHERE trainer_id = p_trainer_id
        AND session_date >= DATE_TRUNC('week', NOW())
        AND session_date < DATE_TRUNC('week', NOW()) + INTERVAL '1 week'
        AND status = 'scheduled'
    ),
    'this_month_sessions', (
      SELECT COUNT(*) FROM bookings
      WHERE trainer_id = p_trainer_id
        AND session_date >= DATE_TRUNC('month', NOW())
        AND session_date < DATE_TRUNC('month', NOW()) + INTERVAL '1 month'
        AND status != 'cancelled'
    ),
    'total_sessions_remaining', (
      SELECT COALESCE(SUM(remaining_sessions), 0)
      FROM client_packages
      WHERE trainer_id = p_trainer_id AND is_active = true
    ),
    'total_revenue_this_month', (
      SELECT COALESCE(SUM(cp.price_paid), 0)
      FROM client_packages cp
      WHERE cp.trainer_id = p_trainer_id
        AND cp.purchase_date >= DATE_TRUNC('month', NOW())
    )
  ) INTO v_stats;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 9: UPDATE EXISTING DATA FOR MULTI-TRAINER
-- ============================================================================

-- Assign existing packages to trainer (from trainer_clients relationship)
UPDATE client_packages cp
SET trainer_id = (
  SELECT tc.trainer_id
  FROM trainer_clients tc
  WHERE tc.client_id = cp.client_id
  LIMIT 1
)
WHERE cp.trainer_id IS NULL;

-- Assign existing bookings to trainer (from trainer_clients relationship)
UPDATE bookings b
SET trainer_id = (
  SELECT tc.trainer_id
  FROM trainer_clients tc
  WHERE tc.client_id = b.client_id
  LIMIT 1
)
WHERE b.trainer_id IS NULL;

-- ============================================================================
-- SECTION 10: HELPFUL VIEWS FOR MULTI-TRAINER SYSTEM
-- ============================================================================

-- View: Trainer schedule overview
CREATE OR REPLACE VIEW trainer_schedule_overview AS
SELECT
  u.id AS trainer_id,
  u.full_name AS trainer_name,
  u.email AS trainer_email,
  COUNT(DISTINCT tc.client_id) AS total_clients,
  COUNT(DISTINCT CASE WHEN b.session_date::DATE = CURRENT_DATE THEN b.id END) AS today_sessions,
  COUNT(DISTINCT CASE WHEN b.session_date >= NOW() THEN b.id END) AS upcoming_sessions,
  COALESCE(SUM(cp.remaining_sessions), 0) AS total_sessions_available
FROM users u
LEFT JOIN trainer_clients tc ON tc.trainer_id = u.id AND tc.is_active = true
LEFT JOIN client_packages cp ON cp.trainer_id = u.id AND cp.is_active = true
LEFT JOIN bookings b ON b.trainer_id = u.id AND b.status = 'scheduled'
WHERE u.role = 'trainer' AND u.is_active = true
GROUP BY u.id, u.full_name, u.email
ORDER BY u.full_name;

-- View: Client assignment overview
CREATE OR REPLACE VIEW client_assignment_overview AS
SELECT
  c.id AS client_id,
  c.full_name AS client_name,
  c.email AS client_email,
  t.id AS trainer_id,
  t.full_name AS trainer_name,
  tc.assigned_at,
  COUNT(DISTINCT cp.id) AS active_packages,
  COALESCE(SUM(cp.remaining_sessions), 0) AS sessions_remaining,
  MAX(b.session_date) AS last_session_date,
  MIN(CASE WHEN b.session_date > NOW() THEN b.session_date END) AS next_session_date
FROM users c
INNER JOIN trainer_clients tc ON tc.client_id = c.id AND tc.is_active = true
INNER JOIN users t ON t.id = tc.trainer_id
LEFT JOIN client_packages cp ON cp.client_id = c.id AND cp.is_active = true
LEFT JOIN bookings b ON b.client_id = c.id
WHERE c.role = 'client'
GROUP BY c.id, c.full_name, c.email, t.id, t.full_name, tc.assigned_at
ORDER BY t.full_name, c.full_name;

-- ============================================================================
-- SECTION 11: TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Trigger: Update trainer profile stats after booking
CREATE OR REPLACE FUNCTION update_trainer_stats_after_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total sessions completed for completed bookings
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE trainer_profiles
    SET
      total_sessions_completed = total_sessions_completed + 1,
      updated_at = NOW()
    WHERE trainer_id = NEW.trainer_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_trainer_stats ON bookings;
CREATE TRIGGER trigger_update_trainer_stats
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_trainer_stats_after_booking();

-- Trigger: Update client count in trainer profile
CREATE OR REPLACE FUNCTION update_trainer_client_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE trainer_profiles
    SET current_clients_count = (
      SELECT COUNT(*) FROM trainer_clients
      WHERE trainer_id = NEW.trainer_id AND is_active = true
    ),
    total_clients_served = total_clients_served + 1
    WHERE trainer_id = NEW.trainer_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE trainer_profiles
    SET current_clients_count = (
      SELECT COUNT(*) FROM trainer_clients
      WHERE trainer_id = OLD.trainer_id AND is_active = true
    )
    WHERE trainer_id = OLD.trainer_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_trainer_client_count ON trainer_clients;
CREATE TRIGGER trigger_update_trainer_client_count
  AFTER INSERT OR DELETE ON trainer_clients
  FOR EACH ROW
  EXECUTE FUNCTION update_trainer_client_count();

-- ============================================================================
-- SECTION 12: INITIALIZE TRAINER PROFILES FOR EXISTING TRAINERS
-- ============================================================================

-- Create trainer profiles for all existing trainers
INSERT INTO trainer_profiles (trainer_id, created_at, updated_at)
SELECT
  id,
  NOW(),
  NOW()
FROM users
WHERE role = 'trainer'
ON CONFLICT (trainer_id) DO NOTHING;

-- ============================================================================
-- VERIFICATION & SUMMARY
-- ============================================================================

SELECT
  '✅ MULTI-TRAINER SYSTEM INSTALLED' as status,
  (SELECT COUNT(*) FROM users WHERE role = 'trainer') as total_trainers,
  (SELECT COUNT(*) FROM trainer_profiles) as trainer_profiles_created,
  (SELECT COUNT(*) FROM trainer_clients) as trainer_client_assignments,
  (SELECT COUNT(DISTINCT trainer_id) FROM bookings WHERE trainer_id IS NOT NULL) as trainers_with_bookings,
  (SELECT COUNT(DISTINCT trainer_id) FROM client_packages WHERE trainer_id IS NOT NULL) as trainers_with_packages;

-- Show all trainers
SELECT
  '🎯 ALL TRAINERS' as section,
  u.id,
  u.full_name,
  u.email,
  u.is_active,
  COALESCE(tp.current_clients_count, 0) as current_clients,
  COALESCE(tp.total_sessions_completed, 0) as sessions_completed,
  COALESCE(tp.average_rating, 5.0) as rating
FROM users u
LEFT JOIN trainer_profiles tp ON tp.trainer_id = u.id
WHERE u.role = 'trainer'
ORDER BY u.full_name;

-- ============================================================================
-- WHAT WAS CREATED:
-- ============================================================================
-- ✅ trainer_profiles - Extended trainer information
-- ✅ trainer_availability - Working hours per trainer
-- ✅ trainer_time_off - Vacation/sick days tracking
-- ✅ trainer_package_pricing - Custom pricing per trainer
-- ✅ client_transfers - Track client transfers between trainers
-- ✅ trainer_session_notes - Session feedback and notes
-- ✅ Updated RLS policies for multi-trainer access control
-- ✅ Database functions for trainer operations
-- ✅ Views for reporting and dashboards
-- ✅ Triggers for automatic stat updates
-- ============================================================================
-- FEATURES ENABLED:
-- ============================================================================
-- 🎯 Multiple trainer accounts with profiles
-- 🎯 Trainer-specific client assignments
-- 🎯 Trainer-specific bookings and schedules
-- 🎯 Trainer availability management
-- 🎯 Client transfer between trainers
-- 🎯 Trainer performance tracking
-- 🎯 Trainer-specific package pricing
-- 🎯 Row-level security (trainers only see their data)
-- 🎯 Admin can see and manage everything
-- 🎯 Dashboard functions for each trainer
-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 1. Run QUICK_FIX_NOW.sql to fix current booking issues
-- 2. Run CREATE_TRAINER_ACCOUNT.sql to create your trainer account
-- 3. Run this MULTI_TRAINER_UPGRADE.sql for future multi-trainer support
-- 4. Add more trainers via Supabase dashboard or app
-- 5. Assign clients to specific trainers
-- 6. Each trainer logs in and sees only their clients
-- 7. Admin account can manage all trainers and clients
-- ============================================================================
