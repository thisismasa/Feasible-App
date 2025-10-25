-- =====================================================
-- ENTERPRISE CLIENT MANAGEMENT SYSTEM - DATABASE SCHEMA
-- =====================================================
-- This migration creates the complete database schema for
-- the enterprise client management system with support for:
-- - Extended client profiles (40+ fields)
-- - Medical conditions and health tracking
-- - Emergency contacts
-- - Body measurements with history
-- - Allergies and injuries tracking
-- - Fitness goals and preferences
-- - Risk assessment and compliance
-- =====================================================

-- =====================================================
-- 1. EXTENDED CLIENTS TABLE
-- =====================================================
-- Extends the existing users table with enterprise client fields
-- Note: We assume 'users' table already exists with basic auth fields

ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'client';

-- Address Information
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line1 TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line2 TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS state_province TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS postal_code TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'Thailand';

-- Professional Information
ALTER TABLE users ADD COLUMN IF NOT EXISTS occupation TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS company TEXT;

-- Fitness Information
ALTER TABLE users ADD COLUMN IF NOT EXISTS fitness_level TEXT; -- sedentary, beginner, intermediate, advanced, athlete
ALTER TABLE users ADD COLUMN IF NOT EXISTS primary_goal TEXT; -- weightLoss, muscleGain, etc.
ALTER TABLE users ADD COLUMN IF NOT EXISTS secondary_goals TEXT[]; -- array of additional goals
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_workout_times TEXT[]; -- e.g., ['morning', 'evening']
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_activities TEXT[]; -- array of activities

-- Medical Information
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_medical_clearance BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS medical_clearance_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS medical_clearance_expires DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS physician_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS physician_phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS medications TEXT[]; -- array of current medications
ALTER TABLE users ADD COLUMN IF NOT EXISTS medical_notes TEXT;

-- Current Measurements (latest snapshot)
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_weight_kg DECIMAL(5,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_height_cm DECIMAL(5,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_body_fat_percentage DECIMAL(4,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_muscle_mass_kg DECIMAL(5,2);

-- Subscription & Billing
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_price DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS billing_frequency TEXT; -- monthly, quarterly, annual
ALTER TABLE users ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_payment_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS next_payment_date TIMESTAMP WITH TIME ZONE;

-- Risk & Compliance
ALTER TABLE users ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'low'; -- low, medium, high, critical
ALTER TABLE users ADD COLUMN IF NOT EXISTS risk_score INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS liability_waiver_signed BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS liability_waiver_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS terms_accepted_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_policy_accepted BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_policy_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_consent BOOLEAN DEFAULT false;

-- Status & Analytics
ALTER TABLE users ADD COLUMN IF NOT EXISTS client_status TEXT DEFAULT 'prospect'; -- prospect, onboarding, active, inactive, suspended, terminated, vip, premium
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_sessions_completed INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS lifetime_value DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_session_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_source TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by_client_id UUID REFERENCES users(id);

-- Profile & Media
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notes TEXT; -- trainer's private notes

-- Timestamps
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Create indexes on commonly queried fields
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_client_status ON users(client_status);
CREATE INDEX IF NOT EXISTS idx_users_risk_level ON users(risk_level);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- =====================================================
-- 2. MEDICAL CONDITIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS medical_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  severity TEXT NOT NULL, -- mild, moderate, severe, critical
  diagnosed_date DATE,
  is_current BOOLEAN DEFAULT true,
  requires_monitoring BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medical_conditions_client_id ON medical_conditions(client_id);
CREATE INDEX IF NOT EXISTS idx_medical_conditions_severity ON medical_conditions(severity);
CREATE INDEX IF NOT EXISTS idx_medical_conditions_is_current ON medical_conditions(is_current);

-- =====================================================
-- 3. EMERGENCY CONTACTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT NOT NULL,
  alternate_phone TEXT,
  is_primary BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_client_id ON emergency_contacts(client_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);

-- =====================================================
-- 4. BODY MEASUREMENTS TABLE (with history)
-- =====================================================
CREATE TABLE IF NOT EXISTS body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  measured_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  weight_kg DECIMAL(5,2),
  height_cm DECIMAL(5,2),
  body_fat_percentage DECIMAL(4,2),
  muscle_mass_kg DECIMAL(5,2),
  bmi DECIMAL(4,2),
  chest_cm DECIMAL(5,2),
  waist_cm DECIMAL(5,2),
  hips_cm DECIMAL(5,2),
  thigh_cm DECIMAL(5,2),
  arm_cm DECIMAL(5,2),
  notes TEXT,
  measured_by TEXT, -- trainer name/id
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_body_measurements_client_id ON body_measurements(client_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_measured_date ON body_measurements(measured_date DESC);

-- =====================================================
-- 5. CLIENT ALLERGIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS client_allergies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  allergen TEXT NOT NULL,
  severity TEXT NOT NULL, -- mild, moderate, severe, anaphylaxis
  reaction TEXT, -- description of allergic reaction
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_allergies_client_id ON client_allergies(client_id);
CREATE INDEX IF NOT EXISTS idx_client_allergies_severity ON client_allergies(severity);

-- =====================================================
-- 6. CLIENT INJURIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS client_injuries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  injury_type TEXT NOT NULL,
  affected_area TEXT NOT NULL, -- body part
  date_occurred DATE,
  is_current BOOLEAN DEFAULT true,
  requires_modification BOOLEAN DEFAULT false, -- requires workout modifications
  description TEXT,
  treatment TEXT,
  recovery_status TEXT, -- recovering, recovered, chronic
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_injuries_client_id ON client_injuries(client_id);
CREATE INDEX IF NOT EXISTS idx_client_injuries_is_current ON client_injuries(is_current);
CREATE INDEX IF NOT EXISTS idx_client_injuries_requires_modification ON client_injuries(requires_modification);

-- =====================================================
-- 7. CLIENT ACTIVITIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS client_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_name TEXT NOT NULL,
  frequency TEXT, -- daily, weekly, etc.
  is_preferred BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_activities_client_id ON client_activities(client_id);

-- =====================================================
-- 8. RISK ASSESSMENT HISTORY TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assessed_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  risk_level TEXT NOT NULL, -- low, medium, high, critical
  risk_score INTEGER NOT NULL,
  age_factor INTEGER DEFAULT 0,
  medical_factor INTEGER DEFAULT 0,
  injury_factor INTEGER DEFAULT 0,
  fitness_factor INTEGER DEFAULT 0,
  bmi_factor INTEGER DEFAULT 0,
  assessment_notes TEXT,
  assessed_by UUID REFERENCES users(id), -- trainer who assessed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_client_id ON risk_assessments(client_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_assessed_date ON risk_assessments(assessed_date DESC);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_risk_level ON risk_assessments(risk_level);

-- =====================================================
-- 9. CLIENT ONBOARDING PROGRESS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS client_onboarding_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  step_personal_info BOOLEAN DEFAULT false,
  step_contact_info BOOLEAN DEFAULT false,
  step_fitness_info BOOLEAN DEFAULT false,
  step_medical_info BOOLEAN DEFAULT false,
  step_measurements BOOLEAN DEFAULT false,
  step_compliance BOOLEAN DEFAULT false,
  current_step INTEGER DEFAULT 0,
  completion_percentage INTEGER DEFAULT 0,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_onboarding_progress_client_id ON client_onboarding_progress(client_id);

-- =====================================================
-- 10. UPDATED_AT TRIGGER FUNCTION
-- =====================================================
-- Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to all tables with updated_at column
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_medical_conditions_updated_at ON medical_conditions;
CREATE TRIGGER update_medical_conditions_updated_at
  BEFORE UPDATE ON medical_conditions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_emergency_contacts_updated_at ON emergency_contacts;
CREATE TRIGGER update_emergency_contacts_updated_at
  BEFORE UPDATE ON emergency_contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_client_allergies_updated_at ON client_allergies;
CREATE TRIGGER update_client_allergies_updated_at
  BEFORE UPDATE ON client_allergies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_client_injuries_updated_at ON client_injuries;
CREATE TRIGGER update_client_injuries_updated_at
  BEFORE UPDATE ON client_injuries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_onboarding_progress_updated_at ON client_onboarding_progress;
CREATE TRIGGER update_onboarding_progress_updated_at
  BEFORE UPDATE ON client_onboarding_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Users table policies
DROP POLICY IF EXISTS "Users can view their own data" ON users;
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Trainers can view all clients" ON users;
CREATE POLICY "Trainers can view all clients" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can insert clients" ON users;
CREATE POLICY "Trainers can insert clients" ON users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can update clients" ON users;
CREATE POLICY "Trainers can update clients" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Medical conditions policies
DROP POLICY IF EXISTS "Trainers can manage medical conditions" ON medical_conditions;
CREATE POLICY "Trainers can manage medical conditions" ON medical_conditions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Emergency contacts policies
DROP POLICY IF EXISTS "Trainers can manage emergency contacts" ON emergency_contacts;
CREATE POLICY "Trainers can manage emergency contacts" ON emergency_contacts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Body measurements policies
DROP POLICY IF EXISTS "Trainers can manage body measurements" ON body_measurements;
CREATE POLICY "Trainers can manage body measurements" ON body_measurements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Client allergies policies
DROP POLICY IF EXISTS "Trainers can manage allergies" ON client_allergies;
CREATE POLICY "Trainers can manage allergies" ON client_allergies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Client injuries policies
DROP POLICY IF EXISTS "Trainers can manage injuries" ON client_injuries;
CREATE POLICY "Trainers can manage injuries" ON client_injuries
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Client activities policies
DROP POLICY IF EXISTS "Trainers can manage activities" ON client_activities;
CREATE POLICY "Trainers can manage activities" ON client_activities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Risk assessments policies
DROP POLICY IF EXISTS "Trainers can manage risk assessments" ON risk_assessments;
CREATE POLICY "Trainers can manage risk assessments" ON risk_assessments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Onboarding progress policies
DROP POLICY IF EXISTS "Trainers can manage onboarding progress" ON client_onboarding_progress;
CREATE POLICY "Trainers can manage onboarding progress" ON client_onboarding_progress
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- =====================================================
-- 12. HELPFUL VIEWS
-- =====================================================

-- View: Complete client profile with latest measurements
CREATE OR REPLACE VIEW client_profiles_complete AS
SELECT
  u.*,
  (SELECT COUNT(*) FROM medical_conditions WHERE client_id = u.id AND is_current = true) as active_medical_conditions_count,
  (SELECT COUNT(*) FROM client_injuries WHERE client_id = u.id AND is_current = true) as active_injuries_count,
  (SELECT COUNT(*) FROM client_allergies WHERE client_id = u.id) as allergies_count,
  (SELECT COUNT(*) FROM emergency_contacts WHERE client_id = u.id) as emergency_contacts_count,
  bm.measured_date as last_measurement_date,
  bm.weight_kg as latest_weight,
  bm.bmi as latest_bmi
FROM users u
LEFT JOIN LATERAL (
  SELECT * FROM body_measurements
  WHERE client_id = u.id
  ORDER BY measured_date DESC
  LIMIT 1
) bm ON true
WHERE u.role = 'client';

-- View: High-risk clients requiring attention
CREATE OR REPLACE VIEW high_risk_clients AS
SELECT
  u.id,
  u.full_name,
  u.email,
  u.phone,
  u.risk_level,
  u.risk_score,
  u.client_status,
  u.last_session_date,
  (SELECT COUNT(*) FROM medical_conditions WHERE client_id = u.id AND is_current = true AND severity IN ('severe', 'critical')) as critical_conditions
FROM users u
WHERE u.role = 'client'
  AND u.risk_level IN ('high', 'critical')
  AND u.is_active = true
ORDER BY u.risk_score DESC;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- You can now use this comprehensive schema to support
-- the enterprise client management system in your Flutter app.
--
-- Next steps:
-- 1. Run this migration in Supabase SQL editor
-- 2. Update supabase_service.dart to use these tables
-- 3. Test client creation with all fields
-- =====================================================
