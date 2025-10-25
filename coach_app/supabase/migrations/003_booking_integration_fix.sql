-- =====================================================
-- BOOKING INTEGRATION FIX - Simple & Error-Free
-- =====================================================
-- This is a simplified version that avoids type casting issues
-- Run this AFTER running 002_complete_enterprise_schema_sync.sql
-- =====================================================

-- =====================================================
-- STEP 1: Create packages table (package templates)
-- =====================================================
CREATE TABLE IF NOT EXISTS packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  sessions INTEGER NOT NULL DEFAULT 0,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
  duration_days INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: Create client_packages table
-- =====================================================
CREATE TABLE IF NOT EXISTS client_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL,
  package_id UUID,
  package_name TEXT NOT NULL,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  remaining_sessions INTEGER NOT NULL DEFAULT 0,
  used_sessions INTEGER DEFAULT 0,
  price_paid DECIMAL(10,2) DEFAULT 0.0,
  purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  start_date TIMESTAMP WITH TIME ZONE,
  expiry_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign keys separately
DO $$
BEGIN
  -- Add FK to users table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_client_packages_client'
  ) THEN
    ALTER TABLE client_packages
    ADD CONSTRAINT fk_client_packages_client
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  -- Add FK to packages table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_client_packages_package'
  ) THEN
    ALTER TABLE client_packages
    ADD CONSTRAINT fk_client_packages_package
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_client_packages_client_id ON client_packages(client_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_is_active ON client_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_client_packages_expiry_date ON client_packages(expiry_date);

-- =====================================================
-- STEP 3: Create bookings table
-- =====================================================
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL,
  trainer_id UUID,
  client_package_id UUID,
  session_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign keys separately
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_bookings_client'
  ) THEN
    ALTER TABLE bookings
    ADD CONSTRAINT fk_bookings_client
    FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_bookings_trainer'
  ) THEN
    ALTER TABLE bookings
    ADD CONSTRAINT fk_bookings_trainer
    FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_bookings_package'
  ) THEN
    ALTER TABLE bookings
    ADD CONSTRAINT fk_bookings_package
    FOREIGN KEY (client_package_id) REFERENCES client_packages(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bookings_client_id ON bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trainer_id ON bookings(trainer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_session_date ON bookings(session_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- =====================================================
-- STEP 4: Auto-create package when client is created
-- =====================================================
CREATE OR REPLACE FUNCTION auto_create_client_package()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create package for clients (not trainers)
  IF NEW.role = 'client' THEN
    INSERT INTO client_packages (
      client_id,
      package_name,
      total_sessions,
      remaining_sessions,
      used_sessions,
      price_paid,
      purchase_date,
      is_active
    ) VALUES (
      NEW.id,
      'No Package',
      0,
      0,
      0,
      0.0,
      NOW(),
      true
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_auto_create_client_package ON users;
CREATE TRIGGER trigger_auto_create_client_package
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_client_package();

-- =====================================================
-- STEP 5: Auto-update sessions when booking changes
-- =====================================================
CREATE OR REPLACE FUNCTION update_package_on_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- When a booking is completed, decrement remaining sessions
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    IF NEW.client_package_id IS NOT NULL THEN
      UPDATE client_packages
      SET
        remaining_sessions = GREATEST(remaining_sessions - 1, 0),
        used_sessions = used_sessions + 1,
        updated_at = NOW()
      WHERE id = NEW.client_package_id;
    END IF;
  END IF;

  -- When a completed booking is cancelled, increment remaining sessions back
  IF NEW.status = 'cancelled' AND OLD.status = 'completed' THEN
    IF NEW.client_package_id IS NOT NULL THEN
      UPDATE client_packages
      SET
        remaining_sessions = remaining_sessions + 1,
        used_sessions = GREATEST(used_sessions - 1, 0),
        updated_at = NOW()
      WHERE id = NEW.client_package_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_package_on_booking ON bookings;
CREATE TRIGGER trigger_update_package_on_booking
  AFTER INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_package_on_booking();

-- =====================================================
-- STEP 6: View for client selection with session counts
-- =====================================================
CREATE OR REPLACE VIEW clients_with_packages AS
SELECT
  u.id,
  u.full_name,
  u.email,
  u.phone,
  u.profile_image_url,
  u.client_status,
  COALESCE(
    (SELECT SUM(remaining_sessions)
     FROM client_packages
     WHERE client_id = u.id AND is_active = true),
    0
  ) as total_sessions_left,
  COALESCE(
    (SELECT SUM(total_sessions)
     FROM client_packages
     WHERE client_id = u.id AND is_active = true),
    0
  ) as total_sessions_purchased
FROM users u
WHERE u.role = 'client'
  AND (u.is_active = true OR u.is_active IS NULL)
  AND (u.is_deleted = false OR u.is_deleted IS NULL)
ORDER BY u.full_name;

-- =====================================================
-- STEP 7: RLS Policies
-- =====================================================
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Trainers can manage everything
DROP POLICY IF EXISTS "Trainers manage packages" ON packages;
CREATE POLICY "Trainers manage packages" ON packages
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer')
  );

DROP POLICY IF EXISTS "Trainers manage client packages" ON client_packages;
CREATE POLICY "Trainers manage client packages" ON client_packages
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer')
  );

DROP POLICY IF EXISTS "Trainers manage bookings" ON bookings;
CREATE POLICY "Trainers manage bookings" ON bookings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer')
  );

-- Clients can view their own data
DROP POLICY IF EXISTS "Clients view own packages" ON client_packages;
CREATE POLICY "Clients view own packages" ON client_packages
  FOR SELECT USING (auth.uid() = client_id);

DROP POLICY IF EXISTS "Clients view own bookings" ON bookings;
CREATE POLICY "Clients view own bookings" ON bookings
  FOR SELECT USING (auth.uid() = client_id);

-- =====================================================
-- STEP 8: Insert default packages
-- =====================================================
INSERT INTO packages (name, description, sessions, price, duration_days, is_active)
SELECT 'Starter Package', 'Perfect for beginners', 4, 1200.00, 30, true
WHERE NOT EXISTS (SELECT 1 FROM packages WHERE name = 'Starter Package');

INSERT INTO packages (name, description, sessions, price, duration_days, is_active)
SELECT 'Basic Package', 'Great for regular training', 8, 2200.00, 30, true
WHERE NOT EXISTS (SELECT 1 FROM packages WHERE name = 'Basic Package');

INSERT INTO packages (name, description, sessions, price, duration_days, is_active)
SELECT 'Premium Package', 'Most popular choice', 12, 3000.00, 60, true
WHERE NOT EXISTS (SELECT 1 FROM packages WHERE name = 'Premium Package');

INSERT INTO packages (name, description, sessions, price, duration_days, is_active)
SELECT 'Elite Package', 'For serious athletes', 20, 4800.00, 90, true
WHERE NOT EXISTS (SELECT 1 FROM packages WHERE name = 'Elite Package');

-- =====================================================
-- STEP 9: Helper function to purchase package
-- =====================================================
CREATE OR REPLACE FUNCTION purchase_package_for_client(
  p_client_id UUID,
  p_package_id UUID,
  p_duration_days INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_package_name TEXT;
  v_sessions INTEGER;
  v_price DECIMAL(10,2);
  v_new_package_id UUID;
  v_expiry_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get package details
  SELECT name, sessions, price INTO v_package_name, v_sessions, v_price
  FROM packages
  WHERE id = p_package_id AND is_active = true;

  IF v_package_name IS NULL THEN
    RAISE EXCEPTION 'Package not found or not active';
  END IF;

  -- Calculate expiry date
  IF p_duration_days IS NOT NULL THEN
    v_expiry_date := NOW() + (p_duration_days || ' days')::INTERVAL;
  END IF;

  -- Deactivate any existing "No Package" entries
  UPDATE client_packages
  SET is_active = false, updated_at = NOW()
  WHERE client_id = p_client_id
    AND package_name = 'No Package'
    AND is_active = true;

  -- Create new client package
  INSERT INTO client_packages (
    client_id,
    package_id,
    package_name,
    total_sessions,
    remaining_sessions,
    used_sessions,
    price_paid,
    purchase_date,
    start_date,
    expiry_date,
    is_active
  ) VALUES (
    p_client_id,
    p_package_id,
    v_package_name,
    v_sessions,
    v_sessions,
    0,
    v_price,
    NOW(),
    NOW(),
    v_expiry_date,
    true
  )
  RETURNING id INTO v_new_package_id;

  RETURN v_new_package_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Booking tables created
-- ✅ Auto-trigger: Creates "No Package" (0 sessions) when client created
-- ✅ Auto-trigger: Updates sessions when bookings complete
-- ✅ View: clients_with_packages (for booking screen)
-- ✅ Function: purchase_package_for_client()
-- ✅ 4 default packages inserted
--
-- Test:
-- 1. Create a client in your app
-- 2. Run: SELECT * FROM client_packages WHERE package_name = 'No Package';
-- 3. Should see 1 row with remaining_sessions = 0
-- =====================================================
