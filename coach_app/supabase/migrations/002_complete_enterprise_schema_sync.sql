-- =====================================================
-- COMPLETE ENTERPRISE CLIENT SCHEMA - DART TO SQL SYNC
-- =====================================================
-- This migration ensures 100% synchronization between:
-- - Dart Client model (add_client_screen_enhanced.dart)
-- - Supabase database schema
--
-- Generated: 2025-10-18
-- Dart Model Lines: 227-387 (Client class)
-- =====================================================

-- =====================================================
-- STEP 1: ENSURE USERS TABLE EXISTS
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: PERSONAL INFORMATION
-- =====================================================
-- Maps to Dart: fullName, email, phone, alternativePhone, birthDate, gender, profileImageUrl
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS alternative_phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'client';

-- =====================================================
-- STEP 3: ADDRESS INFORMATION
-- =====================================================
-- Maps to Dart: addressLine1, addressLine2, city, state, zipCode, country
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line1 TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line2 TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS zip_code TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'Thailand';

-- =====================================================
-- STEP 4: PROFESSIONAL INFORMATION
-- =====================================================
-- Maps to Dart: occupation, company, workPhone
ALTER TABLE users ADD COLUMN IF NOT EXISTS occupation TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS company TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS work_phone TEXT;

-- =====================================================
-- STEP 5: FITNESS INFORMATION
-- =====================================================
-- Maps to Dart: fitnessGoals[], fitnessLevel, currentGym, yearsOfExperience, preferredActivities[]
ALTER TABLE users ADD COLUMN IF NOT EXISTS fitness_goals TEXT[]; -- ['weightLoss', 'muscleGain', etc.]
ALTER TABLE users ADD COLUMN IF NOT EXISTS fitness_level TEXT; -- 'sedentary', 'beginner', 'intermediate', 'advanced', 'elite'
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_gym TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS years_of_experience INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_activities TEXT[]; -- ['Running', 'Swimming', etc.]

-- =====================================================
-- STEP 6: MEDICAL INFORMATION (SIMPLE FIELDS)
-- =====================================================
-- Maps to Dart: bloodType, hasHealthInsurance, insuranceProvider, insuranceNumber
ALTER TABLE users ADD COLUMN IF NOT EXISTS blood_type TEXT DEFAULT 'Unknown';
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_health_insurance BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS insurance_provider TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS insurance_number TEXT;

-- Note: medicalConditions[], allergies[], injuries[] are stored in separate tables below

-- =====================================================
-- STEP 7: CURRENT MEASUREMENTS (SNAPSHOT)
-- =====================================================
-- Maps to Dart: currentMeasurements (latest values)
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_weight_kg DECIMAL(5,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_height_cm DECIMAL(5,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_body_fat_percentage DECIMAL(4,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_muscle_mass_kg DECIMAL(5,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_bmi DECIMAL(4,2);

-- =====================================================
-- STEP 8: SUBSCRIPTION & BILLING
-- =====================================================
-- Maps to Dart: status, currentPlan, subscriptionStartDate, subscriptionEndDate, accountBalance, paymentMethods[]
ALTER TABLE users ADD COLUMN IF NOT EXISTS client_status TEXT DEFAULT 'prospect'; -- 'prospect', 'onboarding', 'active', 'inactive', 'suspended', 'terminated', 'vip', 'premium'
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_plan_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_plan_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_plan_price DECIMAL(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_end_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_balance DECIMAL(10,2) DEFAULT 0.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS payment_methods TEXT[]; -- ['credit_card', 'paypal', etc.]

-- =====================================================
-- STEP 9: PREFERENCES
-- =====================================================
-- Maps to Dart: preferences.preferredTrainingTimes[], preferredTrainers[], communicationPreference, receivesPromotions, receivesReminders, languagePreference
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_training_times TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_trainers TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS communication_preference TEXT DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS receives_promotions BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS receives_reminders BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS language_preference TEXT DEFAULT 'en';
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{"email": true, "sms": false, "push": true}'::jsonb;

-- =====================================================
-- STEP 10: RISK & COMPLIANCE
-- =====================================================
-- Maps to Dart: riskLevel, hasSignedWaiver, waiverSignedDate, hasCompletedPARQ, parqCompletedDate
ALTER TABLE users ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'low'; -- 'low', 'medium', 'high', 'critical'
ALTER TABLE users ADD COLUMN IF NOT EXISTS risk_score INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_signed_waiver BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS waiver_signed_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_completed_parq BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS parq_completed_date TIMESTAMP WITH TIME ZONE;

-- =====================================================
-- STEP 11: RELATIONSHIPS
-- =====================================================
-- Maps to Dart: trainerId, nutritionistId, physiotherapistId, groupIds[]
ALTER TABLE users ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS nutritionist_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS physiotherapist_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS group_ids TEXT[];

-- =====================================================
-- STEP 12: ANALYTICS & TRACKING
-- =====================================================
-- Maps to Dart: totalSessions, completedSessions, attendanceRate, lastSessionDate, satisfactionScore, customFields{}
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_sessions INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS completed_sessions INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS attendance_rate DECIMAL(5,2) DEFAULT 0.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_session_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS satisfaction_score DECIMAL(3,2) DEFAULT 0.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS custom_fields JSONB DEFAULT '{}'::jsonb;

-- =====================================================
-- STEP 13: AUDIT & COMPLIANCE
-- =====================================================
-- Maps to Dart: tags[], referralSource, referredBy, gdprConsent, gdprConsentDate, createdAt, updatedAt, createdBy, updatedBy, metadata{}, isDeleted
ALTER TABLE users ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_source TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gdpr_consent BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gdpr_consent_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- =====================================================
-- STEP 14: MEDICAL CONDITIONS TABLE
-- =====================================================
-- Maps to Dart: MedicalCondition class (lines 72-97)
CREATE TABLE IF NOT EXISTS medical_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  severity TEXT NOT NULL, -- 'low', 'medium', 'high', 'critical'
  diagnosed_date DATE,
  medication TEXT,
  restrictions TEXT,
  requires_monitoring BOOLEAN DEFAULT false,
  is_current BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medical_conditions_client_id ON medical_conditions(client_id);
CREATE INDEX IF NOT EXISTS idx_medical_conditions_severity ON medical_conditions(severity);
CREATE INDEX IF NOT EXISTS idx_medical_conditions_is_current ON medical_conditions(is_current);

-- =====================================================
-- STEP 15: EMERGENCY CONTACTS TABLE
-- =====================================================
-- Maps to Dart: EmergencyContact class (lines 100-125)
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT NOT NULL,
  alternative_phone TEXT,
  email TEXT,
  is_primary BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_client_id ON emergency_contacts(client_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);

-- =====================================================
-- STEP 16: BODY MEASUREMENTS TABLE (WITH HISTORY)
-- =====================================================
-- Maps to Dart: BodyMeasurements class (lines 128-178)
CREATE TABLE IF NOT EXISTS body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  measurement_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  weight DECIMAL(5,2),
  height DECIMAL(5,2),
  body_fat_percentage DECIMAL(4,2),
  muscle_mass DECIMAL(5,2),
  bmi DECIMAL(4,2),
  waist DECIMAL(5,2),
  chest DECIMAL(5,2),
  arms DECIMAL(5,2),
  thighs DECIMAL(5,2),
  calves DECIMAL(5,2),
  notes TEXT,
  measured_by UUID REFERENCES users(id), -- trainer who took measurements
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_body_measurements_client_id ON body_measurements(client_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_date ON body_measurements(measurement_date DESC);

-- =====================================================
-- STEP 17: CLIENT ALLERGIES TABLE
-- =====================================================
-- Maps to Dart: allergies[] (string array in Client)
CREATE TABLE IF NOT EXISTS client_allergies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  allergen TEXT NOT NULL,
  severity TEXT NOT NULL, -- 'mild', 'moderate', 'severe', 'anaphylaxis'
  reaction TEXT, -- description of allergic reaction
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_allergies_client_id ON client_allergies(client_id);
CREATE INDEX IF NOT EXISTS idx_client_allergies_severity ON client_allergies(severity);

-- =====================================================
-- STEP 18: CLIENT INJURIES TABLE
-- =====================================================
-- Maps to Dart: injuries[] (string array in Client)
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
  recovery_status TEXT, -- 'recovering', 'recovered', 'chronic'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_injuries_client_id ON client_injuries(client_id);
CREATE INDEX IF NOT EXISTS idx_client_injuries_is_current ON client_injuries(is_current);
CREATE INDEX IF NOT EXISTS idx_client_injuries_requires_modification ON client_injuries(requires_modification);

-- =====================================================
-- STEP 19: SUBSCRIPTION PLANS TABLE
-- =====================================================
-- Maps to Dart: SubscriptionPlan class (lines 181-203)
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  features TEXT[],
  sessions_per_month INTEGER NOT NULL,
  has_nutrition_plan BOOLEAN DEFAULT false,
  has_online_support BOOLEAN DEFAULT false,
  has_priority_booking BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_is_active ON subscription_plans(is_active);

-- =====================================================
-- STEP 20: RISK ASSESSMENTS HISTORY
-- =====================================================
-- Track risk assessment changes over time
CREATE TABLE IF NOT EXISTS risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assessed_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  risk_level TEXT NOT NULL, -- 'low', 'medium', 'high', 'critical'
  risk_score INTEGER NOT NULL,
  age_factor INTEGER DEFAULT 0,
  medical_factor INTEGER DEFAULT 0,
  injury_factor INTEGER DEFAULT 0,
  fitness_factor INTEGER DEFAULT 0,
  bmi_factor INTEGER DEFAULT 0,
  assessment_notes TEXT,
  recommendations TEXT[],
  assessed_by UUID REFERENCES users(id), -- trainer who assessed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_client_id ON risk_assessments(client_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_date ON risk_assessments(assessed_date DESC);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_level ON risk_assessments(risk_level);

-- =====================================================
-- STEP 21: CLIENT ONBOARDING PROGRESS
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
-- STEP 22: UPDATED_AT TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
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

DROP TRIGGER IF EXISTS update_subscription_plans_updated_at ON subscription_plans;
CREATE TRIGGER update_subscription_plans_updated_at
  BEFORE UPDATE ON subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_onboarding_progress_updated_at ON client_onboarding_progress;
CREATE TRIGGER update_onboarding_progress_updated_at
  BEFORE UPDATE ON client_onboarding_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 23: ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Users can view their own data
DROP POLICY IF EXISTS "Users can view their own data" ON users;
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Trainers can view all clients
DROP POLICY IF EXISTS "Trainers can view all clients" ON users;
CREATE POLICY "Trainers can view all clients" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Trainers can insert clients
DROP POLICY IF EXISTS "Trainers can insert clients" ON users;
CREATE POLICY "Trainers can insert clients" ON users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Trainers can update clients
DROP POLICY IF EXISTS "Trainers can update clients" ON users;
CREATE POLICY "Trainers can update clients" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Trainers can manage all related data
DROP POLICY IF EXISTS "Trainers can manage medical conditions" ON medical_conditions;
CREATE POLICY "Trainers can manage medical conditions" ON medical_conditions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage emergency contacts" ON emergency_contacts;
CREATE POLICY "Trainers can manage emergency contacts" ON emergency_contacts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage body measurements" ON body_measurements;
CREATE POLICY "Trainers can manage body measurements" ON body_measurements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage allergies" ON client_allergies;
CREATE POLICY "Trainers can manage allergies" ON client_allergies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage injuries" ON client_injuries;
CREATE POLICY "Trainers can manage injuries" ON client_injuries
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage risk assessments" ON risk_assessments;
CREATE POLICY "Trainers can manage risk assessments" ON risk_assessments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

DROP POLICY IF EXISTS "Trainers can manage onboarding progress" ON client_onboarding_progress;
CREATE POLICY "Trainers can manage onboarding progress" ON client_onboarding_progress
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Everyone can view active subscription plans
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON subscription_plans;
CREATE POLICY "Anyone can view subscription plans" ON subscription_plans
  FOR SELECT USING (is_active = true);

-- =====================================================
-- STEP 24: HELPFUL VIEWS
-- =====================================================

-- Complete client profile with latest measurements
CREATE OR REPLACE VIEW client_profiles_complete AS
SELECT
  u.*,
  (SELECT COUNT(*) FROM medical_conditions WHERE client_id = u.id AND is_current = true) as active_medical_conditions,
  (SELECT COUNT(*) FROM client_injuries WHERE client_id = u.id AND is_current = true) as active_injuries,
  (SELECT COUNT(*) FROM client_allergies WHERE client_id = u.id) as allergies_count,
  (SELECT COUNT(*) FROM emergency_contacts WHERE client_id = u.id) as emergency_contacts_count,
  bm.measurement_date as last_measurement_date,
  bm.weight as latest_weight,
  bm.bmi as latest_bmi,
  sp.name as subscription_plan_name,
  sp.price as subscription_plan_price
FROM users u
LEFT JOIN LATERAL (
  SELECT * FROM body_measurements
  WHERE client_id = u.id
  ORDER BY measurement_date DESC
  LIMIT 1
) bm ON true
LEFT JOIN subscription_plans sp ON (
  CASE
    WHEN u.current_plan_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN u.current_plan_id::uuid
    ELSE NULL
  END
) = sp.id
WHERE u.role = 'client' AND (u.is_deleted = false OR u.is_deleted IS NULL);

-- High-risk clients requiring attention
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
  (SELECT COUNT(*) FROM medical_conditions WHERE client_id = u.id AND is_current = true AND severity IN ('high', 'critical')) as critical_conditions,
  (SELECT COUNT(*) FROM client_injuries WHERE client_id = u.id AND is_current = true) as active_injuries
FROM users u
WHERE u.role = 'client'
  AND u.risk_level IN ('high', 'critical')
  AND u.is_active = true
  AND u.is_deleted = false
ORDER BY u.risk_score DESC;

-- Clients with incomplete onboarding
CREATE OR REPLACE VIEW incomplete_onboarding AS
SELECT
  u.id,
  u.full_name,
  u.email,
  u.phone,
  u.created_at,
  cop.completion_percentage,
  cop.current_step,
  CASE
    WHEN NOT cop.step_personal_info THEN 'Personal Info'
    WHEN NOT cop.step_contact_info THEN 'Contact Info'
    WHEN NOT cop.step_fitness_info THEN 'Fitness Info'
    WHEN NOT cop.step_medical_info THEN 'Medical Info'
    WHEN NOT cop.step_measurements THEN 'Measurements'
    WHEN NOT cop.step_compliance THEN 'Compliance'
    ELSE 'Complete'
  END as next_step
FROM users u
LEFT JOIN client_onboarding_progress cop ON u.id = cop.client_id
WHERE u.role = 'client'
  AND u.is_active = true
  AND u.is_deleted = false
  AND (cop.completed_at IS NULL OR cop.completion_percentage < 100)
ORDER BY u.created_at DESC;

-- =====================================================
-- STEP 25: INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_client_status ON users(client_status);
CREATE INDEX IF NOT EXISTS idx_users_risk_level ON users(risk_level);
CREATE INDEX IF NOT EXISTS idx_users_trainer_id ON users(trainer_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_is_deleted ON users(is_deleted);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- =====================================================
-- STEP 26: BOOKING SYSTEM INTEGRATION
-- =====================================================
-- Ensure packages table exists for booking system
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

-- Client packages table to track purchased packages
CREATE TABLE IF NOT EXISTS client_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES packages(id) ON DELETE SET NULL,
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

-- Add foreign key constraint separately to avoid type mismatch issues
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'client_packages_package_id_fkey'
  ) THEN
    ALTER TABLE client_packages
    ADD CONSTRAINT client_packages_package_id_fkey
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_client_packages_client_id ON client_packages(client_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_is_active ON client_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_client_packages_expiry_date ON client_packages(expiry_date);

-- Bookings table for session management
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  client_package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
  session_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT DEFAULT 'scheduled', -- 'scheduled', 'completed', 'cancelled', 'no_show'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_client_id ON bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trainer_id ON bookings(trainer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_session_date ON bookings(session_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- =====================================================
-- STEP 27: AUTO-CREATE PACKAGE WITH 0 SESSIONS ON CLIENT CREATION
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

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS trigger_auto_create_client_package ON users;
CREATE TRIGGER trigger_auto_create_client_package
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_client_package();

-- =====================================================
-- STEP 28: UPDATE PACKAGE SESSIONS ON BOOKING
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

DROP TRIGGER IF EXISTS trigger_update_package_on_booking ON bookings;
CREATE TRIGGER trigger_update_package_on_booking
  AFTER INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_package_on_booking();

-- =====================================================
-- STEP 29: BOOKING VIEWS FOR CLIENT SELECTION
-- =====================================================
-- View for client selection in booking screen (shows remaining sessions)
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
  ) as total_sessions_purchased,
  (SELECT jsonb_agg(
    jsonb_build_object(
      'id', cp.id,
      'package_name', cp.package_name,
      'remaining_sessions', cp.remaining_sessions,
      'total_sessions', cp.total_sessions,
      'expiry_date', cp.expiry_date
    )
  )
  FROM client_packages cp
  WHERE cp.client_id = u.id AND cp.is_active = true
  ) as active_packages
FROM users u
WHERE u.role = 'client'
  AND u.is_active = true
  AND u.is_deleted = false
ORDER BY u.full_name;

-- =====================================================
-- STEP 30: RLS POLICIES FOR BOOKING TABLES
-- =====================================================
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Trainers can manage packages
DROP POLICY IF EXISTS "Trainers can manage packages" ON packages;
CREATE POLICY "Trainers can manage packages" ON packages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Trainers can manage client packages
DROP POLICY IF EXISTS "Trainers can manage client packages" ON client_packages;
CREATE POLICY "Trainers can manage client packages" ON client_packages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Clients can view their own packages
DROP POLICY IF EXISTS "Clients can view their packages" ON client_packages;
CREATE POLICY "Clients can view their packages" ON client_packages
  FOR SELECT USING (auth.uid() = client_id);

-- Trainers can manage bookings
DROP POLICY IF EXISTS "Trainers can manage bookings" ON bookings;
CREATE POLICY "Trainers can manage bookings" ON bookings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'trainer'
    )
  );

-- Clients can view their own bookings
DROP POLICY IF EXISTS "Clients can view their bookings" ON bookings;
CREATE POLICY "Clients can view their bookings" ON bookings
  FOR SELECT USING (auth.uid() = client_id);

-- =====================================================
-- STEP 31: HELPER FUNCTION TO PURCHASE PACKAGE
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

  -- Update client status to active if they were prospect
  UPDATE users
  SET
    client_status = CASE WHEN client_status = 'prospect' THEN 'active' ELSE client_status END,
    current_plan_name = v_package_name,
    current_plan_price = v_price,
    subscription_start_date = NOW(),
    subscription_end_date = v_expiry_date,
    updated_at = NOW()
  WHERE id = p_client_id;

  RETURN v_new_package_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 32: SAMPLE PACKAGES (OPTIONAL)
-- =====================================================
-- Insert some default packages if they don't exist
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
-- MIGRATION COMPLETE
-- =====================================================
-- This schema is now 100% synchronized with:
-- ✅ Dart Client model (add_client_screen_enhanced.dart)
-- ✅ Booking system with auto-package creation
-- ✅ When client is created → auto-creates package with 0 sessions
-- ✅ Package sessions auto-update when bookings are completed
-- ✅ Client selection view shows remaining sessions
--
-- Next steps:
-- 1. Run this migration in Supabase SQL editor
-- 2. Create a new client in Flutter app
-- 3. Check client_packages table - should have 1 row with 0 sessions
-- 4. Go to booking screen - client should appear with "0 sessions left"
-- =====================================================
