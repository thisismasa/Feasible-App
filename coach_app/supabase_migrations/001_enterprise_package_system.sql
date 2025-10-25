-- ============================================================================
-- ENTERPRISE PACKAGE SYSTEM - SUPABASE MIGRATION
-- ============================================================================
-- This migration creates all tables needed for the enterprise package system
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. PACKAGES TABLE
-- ============================================================================
-- Stores package templates created by trainers

CREATE TABLE IF NOT EXISTS packages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Basic Information
  name TEXT NOT NULL,
  description TEXT,
  tier TEXT NOT NULL DEFAULT 'basic' CHECK (tier IN ('basic', 'standard', 'premium', 'elite')),
  type TEXT NOT NULL DEFAULT 'session_pack' CHECK (type IN ('session_pack', 'subscription', 'unlimited', 'class_pass', 'hybrid')),
  pricing_model TEXT NOT NULL DEFAULT 'one_time' CHECK (pricing_model IN ('one_time', 'recurring', 'pay_per_session', 'tiered')),

  -- Core Attributes
  session_count INTEGER NOT NULL CHECK (session_count > 0),
  validity_days INTEGER NOT NULL DEFAULT 30 CHECK (validity_days > 0),
  is_active BOOLEAN DEFAULT true,

  -- Pricing
  base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
  discounted_price DECIMAL(10,2) CHECK (discounted_price >= 0),
  tax_rate DECIMAL(5,4) CHECK (tax_rate >= 0 AND tax_rate <= 1),
  currency TEXT DEFAULT 'USD',

  -- Recurring Options
  is_recurring BOOLEAN DEFAULT false,
  recurring_period TEXT CHECK (recurring_period IN ('weekly', 'biweekly', 'monthly', 'quarterly', 'annually')),
  sessions_per_week INTEGER CHECK (sessions_per_week > 0),
  minimum_commitment_months INTEGER CHECK (minimum_commitment_months > 0),
  auto_renew BOOLEAN DEFAULT false,
  next_renewal_date TIMESTAMPTZ,

  -- Features & Benefits
  features JSONB DEFAULT '[]'::jsonb,
  benefits JSONB DEFAULT '{}'::jsonb,
  include_nutrition_plan BOOLEAN DEFAULT false,
  include_progress_tracking BOOLEAN DEFAULT false,
  priority_booking BOOLEAN DEFAULT false,
  reschedule_limit INTEGER CHECK (reschedule_limit >= 0),
  cancellation_notice_days INTEGER CHECK (cancellation_notice_days >= 0),

  -- Business Logic
  max_clients_per_month INTEGER CHECK (max_clients_per_month > 0),
  requires_approval BOOLEAN DEFAULT false,
  target_audience TEXT,
  prerequisites JSONB DEFAULT '[]'::jsonb,

  -- Promotional
  is_featured BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  promo_code TEXT,
  promo_expiry_date TIMESTAMPTZ,
  early_bird_discount DECIMAL(5,4) CHECK (early_bird_discount >= 0 AND early_bird_discount <= 1),

  -- Meta
  metadata JSONB DEFAULT '{}'::jsonb,
  terms_and_conditions TEXT,
  cancellation_policy TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for packages
CREATE INDEX IF NOT EXISTS idx_packages_trainer ON packages(trainer_id);
CREATE INDEX IF NOT EXISTS idx_packages_active ON packages(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_packages_featured ON packages(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_packages_tier ON packages(tier);
CREATE INDEX IF NOT EXISTS idx_packages_type ON packages(type);
CREATE INDEX IF NOT EXISTS idx_packages_display_order ON packages(display_order);

-- Comments
COMMENT ON TABLE packages IS 'Package templates created by trainers';
COMMENT ON COLUMN packages.tier IS 'Package tier: basic, standard, premium, elite';
COMMENT ON COLUMN packages.type IS 'Package type: session_pack, subscription, unlimited, class_pass, hybrid';
COMMENT ON COLUMN packages.pricing_model IS 'Pricing model: one_time, recurring, pay_per_session, tiered';

-- ============================================================================
-- 2. CLIENT_PACKAGES TABLE
-- ============================================================================
-- Stores packages purchased by clients with usage tracking

CREATE TABLE IF NOT EXISTS client_packages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- References
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_name TEXT NOT NULL,
  trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE RESTRICT,

  -- Purchase Details
  purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date TIMESTAMPTZ NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL CHECK (amount_paid >= 0),
  payment_method TEXT NOT NULL,
  transaction_id TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'completed', 'frozen', 'cancelled')),

  -- Usage Tracking
  total_sessions INTEGER NOT NULL CHECK (total_sessions > 0),
  sessions_used INTEGER DEFAULT 0 CHECK (sessions_used >= 0),
  sessions_scheduled INTEGER DEFAULT 0 CHECK (sessions_scheduled >= 0),
  sessions_cancelled INTEGER DEFAULT 0 CHECK (sessions_cancelled >= 0),
  sessions_no_show INTEGER DEFAULT 0 CHECK (sessions_no_show >= 0),
  last_session_date TIMESTAMPTZ,
  next_session_date TIMESTAMPTZ,

  -- Subscription
  is_subscription BOOLEAN DEFAULT false,
  next_billing_date TIMESTAMPTZ,
  auto_renew_enabled BOOLEAN DEFAULT false,
  subscription_id TEXT,
  subscription_status TEXT CHECK (subscription_status IN ('active', 'paused', 'cancelled', 'past_due', 'trialing')),

  -- Freeze/Pause
  has_freeze BOOLEAN DEFAULT false,
  freeze_start_date TIMESTAMPTZ,
  freeze_end_date TIMESTAMPTZ,
  freeze_days_remaining INTEGER CHECK (freeze_days_remaining >= 0),

  -- Analytics
  utilization_rate DECIMAL(5,4) DEFAULT 0 CHECK (utilization_rate >= 0 AND utilization_rate <= 1),
  average_session_interval DECIMAL(10,2) DEFAULT 0 CHECK (average_session_interval >= 0),
  usage_stats JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT sessions_used_le_total CHECK (sessions_used <= total_sessions)
);

-- Indexes for client_packages
CREATE INDEX IF NOT EXISTS idx_client_packages_client ON client_packages(client_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_trainer ON client_packages(trainer_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_package ON client_packages(package_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_status ON client_packages(status);
CREATE INDEX IF NOT EXISTS idx_client_packages_expiry ON client_packages(expiry_date);
CREATE INDEX IF NOT EXISTS idx_client_packages_active ON client_packages(client_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_client_packages_subscription ON client_packages(subscription_id) WHERE subscription_id IS NOT NULL;

-- Comments
COMMENT ON TABLE client_packages IS 'Packages purchased by clients with usage tracking';
COMMENT ON COLUMN client_packages.status IS 'Package status: active, expired, completed, frozen, cancelled';
COMMENT ON COLUMN client_packages.utilization_rate IS 'Percentage of sessions used (0-1)';

-- ============================================================================
-- 3. PROMO_CODES TABLE
-- ============================================================================
-- Promotional discount codes for packages

CREATE TABLE IF NOT EXISTS promo_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,

  -- Scope
  trainer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES packages(id) ON DELETE CASCADE,

  -- Discount
  discount_percentage DECIMAL(5,4) NOT NULL CHECK (discount_percentage > 0 AND discount_percentage <= 1),
  discount_amount DECIMAL(10,2) CHECK (discount_amount >= 0),

  -- Usage Limits
  max_uses INTEGER CHECK (max_uses > 0),
  times_used INTEGER DEFAULT 0 CHECK (times_used >= 0),
  max_uses_per_user INTEGER DEFAULT 1 CHECK (max_uses_per_user > 0),

  -- Validity
  is_active BOOLEAN DEFAULT true,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  expiry_date TIMESTAMPTZ NOT NULL,

  -- Conditions
  minimum_purchase_amount DECIMAL(10,2) CHECK (minimum_purchase_amount >= 0),
  applicable_tiers JSONB DEFAULT '[]'::jsonb,

  -- Meta
  description TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_expiry CHECK (expiry_date > start_date),
  CONSTRAINT times_used_le_max CHECK (max_uses IS NULL OR times_used <= max_uses)
);

-- Indexes for promo_codes
CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_promo_codes_trainer ON promo_codes(trainer_id);
CREATE INDEX IF NOT EXISTS idx_promo_codes_package ON promo_codes(package_id);
CREATE INDEX IF NOT EXISTS idx_promo_codes_active ON promo_codes(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_promo_codes_expiry ON promo_codes(expiry_date);

-- Comments
COMMENT ON TABLE promo_codes IS 'Promotional discount codes for packages';
COMMENT ON COLUMN promo_codes.discount_percentage IS 'Discount as percentage (0-1, e.g., 0.2 = 20% off)';

-- ============================================================================
-- 4. PROMO_CODE_USAGE TABLE
-- ============================================================================
-- Track promo code usage by users

CREATE TABLE IF NOT EXISTS promo_code_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  promo_code_id UUID NOT NULL REFERENCES promo_codes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,

  discount_amount DECIMAL(10,2) NOT NULL,
  used_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(promo_code_id, user_id, client_package_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_promo_usage_code ON promo_code_usage(promo_code_id);
CREATE INDEX IF NOT EXISTS idx_promo_usage_user ON promo_code_usage(user_id);

-- ============================================================================
-- 5. PACKAGE_MODIFICATIONS TABLE
-- ============================================================================
-- Track all modifications to client packages

CREATE TABLE IF NOT EXISTS package_modifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_package_id UUID NOT NULL REFERENCES client_packages(id) ON DELETE CASCADE,

  -- Modification details
  modification_type TEXT NOT NULL CHECK (modification_type IN (
    'sessions_added',
    'sessions_frozen',
    'sessions_extended',
    'price_adjusted',
    'upgraded',
    'downgraded',
    'cancelled',
    'refunded'
  )),

  description TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,

  -- Who made the change
  modified_by UUID REFERENCES auth.users(id),
  modified_by_role TEXT CHECK (modified_by_role IN ('trainer', 'client', 'admin', 'system')),

  -- When
  modified_date TIMESTAMPTZ DEFAULT NOW(),

  -- Previous and new values
  previous_value JSONB,
  new_value JSONB
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_package_mods_package ON package_modifications(client_package_id);
CREATE INDEX IF NOT EXISTS idx_package_mods_type ON package_modifications(modification_type);
CREATE INDEX IF NOT EXISTS idx_package_mods_date ON package_modifications(modified_date DESC);

-- Comments
COMMENT ON TABLE package_modifications IS 'Audit trail of all package modifications';

-- ============================================================================
-- 6. TRIGGERS
-- ============================================================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to packages table
DROP TRIGGER IF EXISTS update_packages_updated_at ON packages;
CREATE TRIGGER update_packages_updated_at
    BEFORE UPDATE ON packages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply to client_packages table
DROP TRIGGER IF EXISTS update_client_packages_updated_at ON client_packages;
CREATE TRIGGER update_client_packages_updated_at
    BEFORE UPDATE ON client_packages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Auto-calculate utilization rate
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_utilization_rate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_sessions > 0 THEN
        NEW.utilization_rate = NEW.sessions_used::DECIMAL / NEW.total_sessions::DECIMAL;
    ELSE
        NEW.utilization_rate = 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS client_packages_calc_utilization ON client_packages;
CREATE TRIGGER client_packages_calc_utilization
    BEFORE INSERT OR UPDATE OF sessions_used, total_sessions ON client_packages
    FOR EACH ROW
    EXECUTE FUNCTION calculate_utilization_rate();

-- ============================================================================
-- Auto-update package status based on expiry
-- ============================================================================
CREATE OR REPLACE FUNCTION update_package_status_on_expiry()
RETURNS TRIGGER AS $$
BEGIN
    -- If expiry date has passed and status is active, mark as expired
    IF NEW.expiry_date < NOW() AND NEW.status = 'active' THEN
        NEW.status = 'expired';
    END IF;

    -- If all sessions used and status is active, mark as completed
    IF NEW.sessions_used >= NEW.total_sessions AND NEW.status = 'active' THEN
        NEW.status = 'completed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS client_packages_status_update ON client_packages;
CREATE TRIGGER client_packages_status_update
    BEFORE UPDATE ON client_packages
    FOR EACH ROW
    EXECUTE FUNCTION update_package_status_on_expiry();

-- ============================================================================
-- Track promo code usage
-- ============================================================================
CREATE OR REPLACE FUNCTION increment_promo_code_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE promo_codes
    SET times_used = times_used + 1
    WHERE id = NEW.promo_code_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS promo_code_usage_increment ON promo_code_usage;
CREATE TRIGGER promo_code_usage_increment
    AFTER INSERT ON promo_code_usage
    FOR EACH ROW
    EXECUTE FUNCTION increment_promo_code_usage();

-- ============================================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_code_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_modifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PACKAGES TABLE POLICIES
-- ============================================================================

-- Trainers can view their own packages
CREATE POLICY "Trainers can view own packages"
ON packages FOR SELECT
USING (auth.uid() = trainer_id);

-- Trainers can create packages
CREATE POLICY "Trainers can create packages"
ON packages FOR INSERT
WITH CHECK (auth.uid() = trainer_id);

-- Trainers can update their own packages
CREATE POLICY "Trainers can update own packages"
ON packages FOR UPDATE
USING (auth.uid() = trainer_id)
WITH CHECK (auth.uid() = trainer_id);

-- Trainers can delete their own packages (if no active clients)
CREATE POLICY "Trainers can delete own packages"
ON packages FOR DELETE
USING (auth.uid() = trainer_id);

-- Clients can view active packages from their trainers
CREATE POLICY "Clients can view active packages"
ON packages FOR SELECT
USING (
  is_active = true AND
  trainer_id IN (
    SELECT trainer_id FROM client_packages
    WHERE client_id = auth.uid()
  )
);

-- ============================================================================
-- CLIENT_PACKAGES TABLE POLICIES
-- ============================================================================

-- Clients can view their own packages
CREATE POLICY "Clients can view own packages"
ON client_packages FOR SELECT
USING (auth.uid() = client_id);

-- Trainers can view packages for their clients
CREATE POLICY "Trainers can view client packages"
ON client_packages FOR SELECT
USING (auth.uid() = trainer_id);

-- System/trainers can create client packages (purchases)
CREATE POLICY "Trainers can create client packages"
ON client_packages FOR INSERT
WITH CHECK (auth.uid() = trainer_id);

-- Trainers can update their client packages
CREATE POLICY "Trainers can update client packages"
ON client_packages FOR UPDATE
USING (auth.uid() = trainer_id)
WITH CHECK (auth.uid() = trainer_id);

-- Clients can update their own packages (limited fields)
CREATE POLICY "Clients can update own packages"
ON client_packages FOR UPDATE
USING (auth.uid() = client_id)
WITH CHECK (
  auth.uid() = client_id AND
  -- Clients can only update certain fields
  (OLD.sessions_used = NEW.sessions_used) -- Can't change session count
);

-- ============================================================================
-- PROMO_CODES TABLE POLICIES
-- ============================================================================

-- Trainers can view their own promo codes
CREATE POLICY "Trainers can view own promo codes"
ON promo_codes FOR SELECT
USING (auth.uid() = trainer_id);

-- Trainers can create promo codes
CREATE POLICY "Trainers can create promo codes"
ON promo_codes FOR INSERT
WITH CHECK (auth.uid() = trainer_id OR auth.uid() = created_by);

-- Trainers can update their own promo codes
CREATE POLICY "Trainers can update own promo codes"
ON promo_codes FOR UPDATE
USING (auth.uid() = trainer_id)
WITH CHECK (auth.uid() = trainer_id);

-- Trainers can delete their own promo codes
CREATE POLICY "Trainers can delete own promo codes"
ON promo_codes FOR DELETE
USING (auth.uid() = trainer_id);

-- ============================================================================
-- PROMO_CODE_USAGE TABLE POLICIES
-- ============================================================================

-- Users can view their own promo code usage
CREATE POLICY "Users can view own usage"
ON promo_code_usage FOR SELECT
USING (auth.uid() = user_id);

-- System can insert promo code usage
CREATE POLICY "System can track usage"
ON promo_code_usage FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- PACKAGE_MODIFICATIONS TABLE POLICIES
-- ============================================================================

-- Users can view modifications for their packages
CREATE POLICY "View package modifications"
ON package_modifications FOR SELECT
USING (
  client_package_id IN (
    SELECT id FROM client_packages
    WHERE client_id = auth.uid() OR trainer_id = auth.uid()
  )
);

-- Trainers can insert modifications
CREATE POLICY "Trainers can log modifications"
ON package_modifications FOR INSERT
WITH CHECK (
  client_package_id IN (
    SELECT id FROM client_packages
    WHERE trainer_id = auth.uid()
  )
);

-- ============================================================================
-- 8. FUNCTIONS FOR BUSINESS LOGIC
-- ============================================================================

-- Function to get client's active package
CREATE OR REPLACE FUNCTION get_client_active_package(p_client_id UUID)
RETURNS TABLE (
  package_id UUID,
  package_name TEXT,
  sessions_remaining INTEGER,
  expiry_date TIMESTAMPTZ,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id as package_id,
    p.name as package_name,
    (cp.total_sessions - cp.sessions_used - cp.sessions_scheduled) as sessions_remaining,
    cp.expiry_date,
    cp.status
  FROM client_packages cp
  JOIN packages p ON cp.package_id = p.id
  WHERE cp.client_id = p_client_id
    AND cp.status = 'active'
    AND cp.expiry_date > NOW()
    AND (cp.total_sessions - cp.sessions_used - cp.sessions_scheduled) > 0
  ORDER BY cp.expiry_date ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate promo code
CREATE OR REPLACE FUNCTION validate_promo_code(
  p_code TEXT,
  p_package_id UUID,
  p_user_id UUID
)
RETURNS TABLE (
  is_valid BOOLEAN,
  discount_percentage DECIMAL,
  message TEXT
) AS $$
DECLARE
  v_promo RECORD;
  v_usage_count INTEGER;
BEGIN
  -- Get promo code
  SELECT * INTO v_promo
  FROM promo_codes
  WHERE code = p_code
    AND is_active = true
    AND (package_id IS NULL OR package_id = p_package_id)
    AND start_date <= NOW()
    AND expiry_date > NOW();

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 0::DECIMAL, 'Invalid or expired promo code';
    RETURN;
  END IF;

  -- Check max uses
  IF v_promo.max_uses IS NOT NULL AND v_promo.times_used >= v_promo.max_uses THEN
    RETURN QUERY SELECT false, 0::DECIMAL, 'Promo code has reached maximum uses';
    RETURN;
  END IF;

  -- Check per-user limit
  SELECT COUNT(*) INTO v_usage_count
  FROM promo_code_usage
  WHERE promo_code_id = v_promo.id AND user_id = p_user_id;

  IF v_usage_count >= v_promo.max_uses_per_user THEN
    RETURN QUERY SELECT false, 0::DECIMAL, 'You have already used this promo code';
    RETURN;
  END IF;

  -- Valid promo code
  RETURN QUERY SELECT true, v_promo.discount_percentage, 'Valid promo code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 9. VIEWS
-- ============================================================================

-- View for package analytics
CREATE OR REPLACE VIEW package_analytics AS
SELECT
  p.id as package_id,
  p.name as package_name,
  p.trainer_id,
  p.tier,
  p.base_price,
  COUNT(cp.id) as total_clients,
  COUNT(CASE WHEN cp.status = 'active' THEN 1 END) as active_clients,
  SUM(cp.amount_paid) as total_revenue,
  AVG(cp.utilization_rate) as avg_utilization,
  AVG(cp.sessions_used::DECIMAL / NULLIF(cp.total_sessions, 0)) as completion_rate
FROM packages p
LEFT JOIN client_packages cp ON p.id = cp.package_id
GROUP BY p.id, p.name, p.trainer_id, p.tier, p.base_price;

-- View for trainer revenue summary
CREATE OR REPLACE VIEW trainer_revenue_summary AS
SELECT
  trainer_id,
  COUNT(DISTINCT client_id) as total_clients,
  COUNT(*) as total_packages_sold,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_packages,
  SUM(amount_paid) as total_revenue,
  SUM(sessions_used) as total_sessions_delivered,
  AVG(utilization_rate) as avg_utilization
FROM client_packages
GROUP BY trainer_id;

-- ============================================================================
-- 10. SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Uncomment to insert sample data for testing

/*
-- Sample trainer (use your actual trainer ID)
-- INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-000000000001');

-- Sample packages
INSERT INTO packages (trainer_id, name, description, tier, type, pricing_model, session_count, validity_days, base_price, discounted_price, is_featured, features) VALUES
('00000000-0000-0000-0000-000000000001', 'Starter Pack', 'Perfect for beginners', 'basic', 'session_pack', 'one_time', 5, 30, 200.00, NULL, false, '["5 Personal Training Sessions", "Basic Progress Tracking"]'::jsonb),
('00000000-0000-0000-0000-000000000001', 'Premium Pack', 'Best value for committed clients', 'premium', 'session_pack', 'one_time', 10, 60, 500.00, 450.00, true, '["10 Personal Training Sessions", "Nutrition Plan", "Priority Booking", "Progress Tracking"]'::jsonb),
('00000000-0000-0000-0000-000000000001', 'Elite Monthly', 'Unlimited training for serious athletes', 'elite', 'unlimited', 'recurring', 999, 30, 1200.00, NULL, true, '["Unlimited Sessions", "Nutrition Plan", "Weekly Check-ins", "Priority Booking", "24/7 Support"]'::jsonb);

-- Sample promo code
INSERT INTO promo_codes (code, trainer_id, discount_percentage, max_uses, expiry_date, description) VALUES
('WELCOME20', '00000000-0000-0000-0000-000000000001', 0.20, 100, NOW() + INTERVAL '30 days', 'Welcome discount - 20% off');
*/

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Enterprise Package System Migration Complete!';
  RAISE NOTICE '📦 Tables created: packages, client_packages, promo_codes, promo_code_usage, package_modifications';
  RAISE NOTICE '🔒 Row Level Security enabled';
  RAISE NOTICE '⚡ Triggers configured';
  RAISE NOTICE '📊 Views created for analytics';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Next steps:';
  RAISE NOTICE '1. Update your Flutter app to use the new services';
  RAISE NOTICE '2. Test package purchase flow';
  RAISE NOTICE '3. Configure promo codes';
  RAISE NOTICE '4. Set up background jobs for package expiry checks';
END $$;
