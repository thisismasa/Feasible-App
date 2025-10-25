-- =====================================================
-- BOOKING INTEGRATION - FINAL FIX (No Foreign Key Issues)
-- =====================================================
-- This version creates tables WITHOUT inline foreign keys
-- and adds them manually afterward
-- =====================================================

-- =====================================================
-- STEP 1: Drop existing tables if they have issues
-- =====================================================
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS client_packages CASCADE;
DROP TABLE IF EXISTS packages CASCADE;

-- =====================================================
-- STEP 2: Create packages table
-- =====================================================
CREATE TABLE packages (
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
-- STEP 3: Create client_packages table (NO inline FKs)
-- =====================================================
CREATE TABLE client_packages (
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

-- =====================================================
-- STEP 4: Create bookings table (NO inline FKs)
-- =====================================================
CREATE TABLE bookings (
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

-- =====================================================
-- STEP 5: Add foreign keys AFTER tables are created
-- =====================================================
-- Foreign keys for client_packages
ALTER TABLE client_packages
  ADD CONSTRAINT fk_client_packages_client
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE client_packages
  ADD CONSTRAINT fk_client_packages_package
  FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL;

-- Foreign keys for bookings
ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_client
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_trainer
  FOREIGN KEY (trainer_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE bookings
  ADD CONSTRAINT fk_bookings_package
  FOREIGN KEY (client_package_id) REFERENCES client_packages(id) ON DELETE SET NULL;

-- =====================================================
-- STEP 6: Create indexes
-- =====================================================
CREATE INDEX idx_client_packages_client_id ON client_packages(client_id);
CREATE INDEX idx_client_packages_is_active ON client_packages(is_active);
CREATE INDEX idx_client_packages_expiry_date ON client_packages(expiry_date);

CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_trainer_id ON bookings(trainer_id);
CREATE INDEX idx_bookings_session_date ON bookings(session_date);
CREATE INDEX idx_bookings_status ON bookings(status);

-- =====================================================
-- STEP 7: Auto-create package when client is created
-- =====================================================
CREATE OR REPLACE FUNCTION auto_create_client_package()
RETURNS TRIGGER AS $$
BEGIN
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

DROP TRIGGER IF EXISTS trigger_auto_create_client_package ON users;
CREATE TRIGGER trigger_auto_create_client_package
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_client_package();

-- =====================================================
-- STEP 8: Auto-update sessions when booking changes
-- =====================================================
CREATE OR REPLACE FUNCTION update_package_on_booking()
RETURNS TRIGGER AS $$
BEGIN
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

DROP TRIGGER IF EXISTS trigger_update_package_on_booking ON bookings;
CREATE TRIGGER trigger_update_package_on_booking
  AFTER INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_package_on_booking();

-- =====================================================
-- STEP 9: View for client selection
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
  AND (u.is_active IS NULL OR u.is_active = true)
  AND (u.is_deleted IS NULL OR u.is_deleted = false)
ORDER BY u.full_name;

-- =====================================================
-- STEP 10: RLS Policies
-- =====================================================
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS "Clients view own packages" ON client_packages;
CREATE POLICY "Clients view own packages" ON client_packages
  FOR SELECT USING (auth.uid() = client_id);

DROP POLICY IF EXISTS "Clients view own bookings" ON bookings;
CREATE POLICY "Clients view own bookings" ON bookings
  FOR SELECT USING (auth.uid() = client_id);

-- =====================================================
-- STEP 11: Insert default packages
-- =====================================================
INSERT INTO packages (name, description, sessions, price, duration_days, is_active) VALUES
('Starter Package', 'Perfect for beginners', 4, 1200.00, 30, true),
('Basic Package', 'Great for regular training', 8, 2200.00, 30, true),
('Premium Package', 'Most popular choice', 12, 3000.00, 60, true),
('Elite Package', 'For serious athletes', 20, 4800.00, 90, true);

-- =====================================================
-- STEP 12: Helper function to purchase package
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
  SELECT name, sessions, price INTO v_package_name, v_sessions, v_price
  FROM packages
  WHERE id = p_package_id AND is_active = true;

  IF v_package_name IS NULL THEN
    RAISE EXCEPTION 'Package not found or not active';
  END IF;

  IF p_duration_days IS NOT NULL THEN
    v_expiry_date := NOW() + (p_duration_days || ' days')::INTERVAL;
  END IF;

  UPDATE client_packages
  SET is_active = false, updated_at = NOW()
  WHERE client_id = p_client_id
    AND package_name = 'No Package'
    AND is_active = true;

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
-- STEP 13: Create packages for existing clients
-- =====================================================
-- Auto-create "No Package" for any existing clients without packages
INSERT INTO client_packages (client_id, package_name, total_sessions, remaining_sessions, used_sessions, price_paid, is_active)
SELECT
  u.id,
  'No Package',
  0,
  0,
  0,
  0.0,
  true
FROM users u
WHERE u.role = 'client'
  AND NOT EXISTS (
    SELECT 1 FROM client_packages cp WHERE cp.client_id = u.id
  );

-- =====================================================
-- MIGRATION COMPLETE ✅
-- =====================================================
-- What was created:
-- ✅ packages table (4 default packages)
-- ✅ client_packages table
-- ✅ bookings table
-- ✅ Auto-trigger: Creates "No Package" with 0 sessions
-- ✅ Auto-trigger: Updates sessions on booking complete
-- ✅ View: clients_with_packages
-- ✅ Function: purchase_package_for_client()
-- ✅ Packages created for all existing clients
--
-- Test it:
-- SELECT * FROM packages;
-- SELECT * FROM client_packages;
-- SELECT * FROM clients_with_packages;
-- =====================================================
