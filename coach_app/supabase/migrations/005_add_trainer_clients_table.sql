-- =====================================================
-- ADD TRAINER_CLIENTS TABLE
-- =====================================================
-- This migration adds the missing trainer_clients table
-- which is required for the booking system to work properly
-- =====================================================

-- =====================================================
-- STEP 1: Create trainer_clients table
-- =====================================================
CREATE TABLE IF NOT EXISTS trainer_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(trainer_id, client_id)
);

-- =====================================================
-- STEP 2: Create indexes for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer_id ON trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client_id ON trainer_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_is_active ON trainer_clients(is_active);

-- =====================================================
-- STEP 3: Enable Row Level Security
-- =====================================================
ALTER TABLE trainer_clients ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 4: Create RLS Policies
-- =====================================================
-- Trainers can view and manage their own client assignments
DROP POLICY IF EXISTS "Trainers manage their clients" ON trainer_clients;
CREATE POLICY "Trainers manage their clients" ON trainer_clients
  FOR ALL USING (
    auth.uid() = trainer_id OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer')
  );

-- Clients can view their trainer assignments
DROP POLICY IF EXISTS "Clients view their trainers" ON trainer_clients;
CREATE POLICY "Clients view their trainers" ON trainer_clients
  FOR SELECT USING (auth.uid() = client_id);

-- =====================================================
-- STEP 5: Create trigger to auto-assign clients to trainer
-- =====================================================
-- When a new client is created, automatically assign them to a trainer
-- This ensures all clients appear in the booking screen

CREATE OR REPLACE FUNCTION auto_assign_client_to_trainer()
RETURNS TRIGGER AS $$
DECLARE
  v_trainer_id UUID;
BEGIN
  -- Only process if this is a new client user
  IF NEW.role = 'client' THEN
    -- Find the first active trainer (you may want to customize this logic)
    -- For single-trainer apps, this works perfectly
    SELECT id INTO v_trainer_id
    FROM users
    WHERE role = 'trainer' AND (is_active IS NULL OR is_active = true)
    LIMIT 1;

    -- If a trainer exists, assign this client to them
    IF v_trainer_id IS NOT NULL THEN
      INSERT INTO trainer_clients (trainer_id, client_id, assigned_at, is_active)
      VALUES (v_trainer_id, NEW.id, NOW(), true)
      ON CONFLICT (trainer_id, client_id) DO NOTHING;

      RAISE NOTICE 'Auto-assigned client % to trainer %', NEW.id, v_trainer_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_auto_assign_client_to_trainer ON users;

-- Create trigger that fires after a new user is inserted
CREATE TRIGGER trigger_auto_assign_client_to_trainer
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_client_to_trainer();

-- =====================================================
-- STEP 6: Assign all existing clients to trainers
-- =====================================================
-- This ensures existing clients also appear in the booking screen

DO $$
DECLARE
  v_trainer_id UUID;
  v_client_record RECORD;
  v_assigned_count INTEGER := 0;
BEGIN
  -- Get the first active trainer
  SELECT id INTO v_trainer_id
  FROM users
  WHERE role = 'trainer' AND (is_active IS NULL OR is_active = true)
  LIMIT 1;

  IF v_trainer_id IS NOT NULL THEN
    -- Assign all existing clients to this trainer
    FOR v_client_record IN
      SELECT id FROM users WHERE role = 'client'
    LOOP
      INSERT INTO trainer_clients (trainer_id, client_id, assigned_at, is_active)
      VALUES (v_trainer_id, v_client_record.id, NOW(), true)
      ON CONFLICT (trainer_id, client_id) DO NOTHING;

      v_assigned_count := v_assigned_count + 1;
    END LOOP;

    RAISE NOTICE 'Assigned % existing clients to trainer %', v_assigned_count, v_trainer_id;
  ELSE
    RAISE NOTICE 'No active trainer found - skipping client assignment';
  END IF;
END $$;

-- =====================================================
-- STEP 7: Create helpful views
-- =====================================================
-- View to see all trainer-client relationships with details
CREATE OR REPLACE VIEW trainer_client_details AS
SELECT
  tc.id,
  tc.trainer_id,
  t.full_name AS trainer_name,
  t.email AS trainer_email,
  tc.client_id,
  c.full_name AS client_name,
  c.email AS client_email,
  c.phone AS client_phone,
  tc.assigned_at,
  tc.is_active,
  tc.notes,
  -- Count of client's packages
  COALESCE(
    (SELECT SUM(remaining_sessions)
     FROM client_packages
     WHERE client_id = tc.client_id AND is_active = true),
    0
  ) as client_sessions_remaining
FROM trainer_clients tc
INNER JOIN users t ON tc.trainer_id = t.id
INNER JOIN users c ON tc.client_id = c.id
WHERE tc.is_active = true
ORDER BY c.full_name;

-- =====================================================
-- MIGRATION COMPLETE ✅
-- =====================================================
-- What was created:
-- ✅ trainer_clients table with proper foreign keys
-- ✅ Indexes for performance
-- ✅ Row Level Security policies
-- ✅ Auto-assignment trigger for new clients
-- ✅ Existing clients assigned to trainers
-- ✅ trainer_client_details view
--
-- Test it:
-- SELECT * FROM trainer_clients;
-- SELECT * FROM trainer_client_details;
--
-- Now when you add a new client:
-- 1. They will automatically be assigned to the trainer
-- 2. They will appear in the booking screen client list
-- 3. You can book sessions for them immediately
-- =====================================================
