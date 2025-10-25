-- ================================================
-- ENHANCED CLIENT ONBOARDING SCHEMA
-- ================================================
-- Complete database schema for production-ready client management
-- ================================================

-- ================================================
-- 1. CLIENT HEALTH INFORMATION
-- ================================================
CREATE TABLE IF NOT EXISTS client_health_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  health_conditions TEXT[],
  medications TEXT[],
  injuries TEXT[],
  fitness_level TEXT CHECK (fitness_level IN ('Beginner', 'Intermediate', 'Advanced', 'Athlete')),
  requires_medical_clearance BOOLEAN DEFAULT false,
  medical_clearance_doc_url TEXT,
  clearance_verified BOOLEAN DEFAULT false,
  clearance_verified_by UUID REFERENCES auth.users(id),
  clearance_verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(client_id)
);

-- ================================================
-- 2. CLIENT PREFERENCES
-- ================================================
CREATE TABLE IF NOT EXISTS client_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_days TEXT[],
  preferred_times TEXT[],
  preferred_location TEXT,
  session_type_preference TEXT DEFAULT 'In-Person',
  communication_method TEXT DEFAULT 'Email',
  marketing_opt_in BOOLEAN DEFAULT true,
  referral_source TEXT,
  goals TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(client_id)
);

-- ================================================
-- 3. CLIENT AGREEMENTS
-- ================================================
CREATE TABLE IF NOT EXISTS client_agreements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  agreement_type TEXT NOT NULL CHECK (agreement_type IN (
    'terms_of_service',
    'liability_waiver',
    'photo_release',
    'cancellation_policy',
    'parental_consent',
    'health_declaration'
  )),
  signed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address INET,
  version TEXT DEFAULT '1.0',
  signature_data TEXT, -- For e-signature storage
  is_active BOOLEAN DEFAULT true,
  revoked_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(client_id, agreement_type, version)
);

-- ================================================
-- 4. CASH PAYMENTS
-- ================================================
CREATE TABLE IF NOT EXISTS cash_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_number TEXT UNIQUE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  client_id UUID REFERENCES auth.users(id),
  collected_by UUID REFERENCES auth.users(id),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT,
  verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE
);

-- ================================================
-- 5. PENDING BANK TRANSFERS
-- ================================================
CREATE TABLE IF NOT EXISTS pending_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  client_email TEXT NOT NULL,
  client_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'failed', 'cancelled')),
  expected_date DATE,
  confirmed_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 6. INVOICES (if not exists)
-- ================================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE NOT NULL,
  client_id UUID REFERENCES auth.users(id),
  client_email TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) GENERATED ALWAYS AS (amount + tax) STORED,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
  due_date DATE,
  paid_date TIMESTAMP WITH TIME ZONE,
  payment_method TEXT,
  items JSONB,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 7. AUDIT LOG
-- ================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action TEXT NOT NULL,
  performed_by UUID REFERENCES auth.users(id),
  target_user_id UUID REFERENCES auth.users(id),
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 8. EMAIL QUEUE
-- ================================================
CREATE TABLE IF NOT EXISTS email_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  to_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  attempts INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMP WITH TIME ZONE,
  sent_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 9. NOTIFICATIONS
-- ================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_health_info_client ON client_health_info(client_id);
CREATE INDEX IF NOT EXISTS idx_preferences_client ON client_preferences(client_id);
CREATE INDEX IF NOT EXISTS idx_agreements_client ON client_agreements(client_id, agreement_type);
CREATE INDEX IF NOT EXISTS idx_agreements_active ON client_agreements(client_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cash_payments_client ON cash_payments(client_id);
CREATE INDEX IF NOT EXISTS idx_transfers_status ON pending_transfers(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status) WHERE status IN ('pending', 'overdue');
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(target_user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_email_queue_status ON email_queue(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC) WHERE read = false;

-- ================================================
-- TRIGGERS
-- ================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_health_info_timestamp
BEFORE UPDATE ON client_health_info
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_preferences_timestamp
BEFORE UPDATE ON client_preferences
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transfers_timestamp
BEFORE UPDATE ON pending_transfers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_timestamp
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Auto-mark overdue invoices
CREATE OR REPLACE FUNCTION mark_overdue_invoices()
RETURNS void AS $$
BEGIN
  UPDATE invoices
  SET status = 'overdue'
  WHERE status = 'pending'
  AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- ROW LEVEL SECURITY
-- ================================================

-- Client Health Info
ALTER TABLE client_health_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own health info"
ON client_health_info FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Trainers can view client health info"
ON client_health_info FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'trainer'
  )
);

CREATE POLICY "Trainers can insert health info"
ON client_health_info FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'trainer'
  )
);

-- Client Preferences
ALTER TABLE client_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preferences"
ON client_preferences FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Users can update their own preferences"
ON client_preferences FOR UPDATE
USING (auth.uid() = client_id);

CREATE POLICY "Trainers can view all preferences"
ON client_preferences FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'trainer'
  )
);

-- Client Agreements
ALTER TABLE client_agreements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own agreements"
ON client_agreements FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Trainers can view all agreements"
ON client_agreements FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'trainer'
  )
);

-- Notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- ================================================
-- HELPER FUNCTIONS
-- ================================================

-- Check if client has active medical clearance
CREATE OR REPLACE FUNCTION has_valid_medical_clearance(p_client_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_requires_clearance BOOLEAN;
  v_clearance_verified BOOLEAN;
BEGIN
  SELECT 
    requires_medical_clearance,
    clearance_verified
  INTO 
    v_requires_clearance,
    v_clearance_verified
  FROM client_health_info
  WHERE client_id = p_client_id;
  
  IF v_requires_clearance AND NOT v_clearance_verified THEN
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Check if client can book sessions
CREATE OR REPLACE FUNCTION can_book_sessions(p_client_id UUID)
RETURNS JSON AS $$
DECLARE
  v_can_book BOOLEAN := true;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
BEGIN
  -- Check medical clearance
  IF NOT has_valid_medical_clearance(p_client_id) THEN
    v_can_book := false;
    v_reasons := array_append(v_reasons, 'Medical clearance required');
  END IF;
  
  -- Check active package
  IF NOT EXISTS (
    SELECT 1 FROM client_packages
    WHERE client_id = p_client_id
    AND status = 'active'
    AND remaining_sessions > 0
    AND expiry_date > NOW()
  ) THEN
    v_can_book := false;
    v_reasons := array_append(v_reasons, 'No active package with sessions');
  END IF;
  
  -- Check agreements
  IF NOT EXISTS (
    SELECT 1 FROM client_agreements
    WHERE client_id = p_client_id
    AND agreement_type = 'liability_waiver'
    AND is_active = true
  ) THEN
    v_can_book := false;
    v_reasons := array_append(v_reasons, 'Liability waiver not signed');
  END IF;
  
  RETURN json_build_object(
    'can_book', v_can_book,
    'reasons', v_reasons
  );
END;
$$ LANGUAGE plpgsql;

-- Get client onboarding progress
CREATE OR REPLACE FUNCTION get_onboarding_progress(p_client_id UUID)
RETURNS JSON AS $$
DECLARE
  v_progress JSON;
BEGIN
  SELECT json_build_object(
    'basic_info_complete', EXISTS (
      SELECT 1 FROM users WHERE id = p_client_id AND name IS NOT NULL
    ),
    'health_info_complete', EXISTS (
      SELECT 1 FROM client_health_info WHERE client_id = p_client_id
    ),
    'preferences_complete', EXISTS (
      SELECT 1 FROM client_preferences WHERE client_id = p_client_id
    ),
    'package_assigned', EXISTS (
      SELECT 1 FROM client_packages WHERE client_id = p_client_id AND status = 'active'
    ),
    'agreements_signed', (
      SELECT COUNT(*) FROM client_agreements 
      WHERE client_id = p_client_id AND is_active = true
    ) >= 4,
    'can_start_training', has_valid_medical_clearance(p_client_id)
  ) INTO v_progress;
  
  RETURN v_progress;
END;
$$ LANGUAGE plpgsql;

-- Send notification
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- VIEWS FOR EASY QUERYING
-- ================================================

-- Complete client profile view
CREATE OR REPLACE VIEW client_profiles AS
SELECT 
  u.id,
  u.email,
  u.created_at,
  (u.raw_user_meta_data->>'full_name') AS name,
  (u.raw_user_meta_data->>'phone') AS phone,
  (u.raw_user_meta_data->>'birth_date')::TIMESTAMP AS birth_date,
  (u.raw_user_meta_data->>'gender') AS gender,
  (u.raw_user_meta_data->>'emergency_contact') AS emergency_contact,
  (u.raw_user_meta_data->>'emergency_phone') AS emergency_phone,
  h.health_conditions,
  h.medications,
  h.injuries,
  h.fitness_level,
  h.requires_medical_clearance,
  h.clearance_verified,
  p.goals,
  p.preferred_days,
  p.preferred_times,
  p.preferred_location,
  p.communication_method,
  p.referral_source,
  (
    SELECT COUNT(*) FROM client_packages cp
    WHERE cp.client_id = u.id AND cp.status = 'active'
  ) AS active_packages_count,
  (
    SELECT SUM(remaining_sessions) FROM client_packages cp
    WHERE cp.client_id = u.id AND cp.status = 'active'
  ) AS total_sessions_remaining
FROM auth.users u
LEFT JOIN client_health_info h ON h.client_id = u.id
LEFT JOIN client_preferences p ON p.client_id = u.id
WHERE (u.raw_user_meta_data->>'role') = 'client';

-- Active clients with package info
CREATE OR REPLACE VIEW active_clients AS
SELECT 
  cp.*,
  u.email,
  (u.raw_user_meta_data->>'full_name') AS client_name,
  (u.raw_user_meta_data->>'phone') AS client_phone,
  pkg.name AS package_name,
  pkg.price AS package_price
FROM client_packages cp
JOIN auth.users u ON u.id = cp.client_id
JOIN packages pkg ON pkg.id = cp.package_id
WHERE cp.status = 'active'
AND cp.remaining_sessions > 0
AND cp.expiry_date > NOW();

-- ================================================
-- SCHEDULED JOBS (using pg_cron extension)
-- ================================================

-- Mark overdue invoices (run daily at midnight)
-- SELECT cron.schedule('mark-overdue-invoices', '0 0 * * *', $$SELECT mark_overdue_invoices()$$);

-- Send session reminders (run hourly)
-- SELECT cron.schedule('send-reminders', '0 * * * *', $$SELECT send_session_reminders()$$);

-- Process email queue (run every 5 minutes)
-- SELECT cron.schedule('process-emails', '*/5 * * * *', $$SELECT process_email_queue()$$);

-- ================================================
-- SAMPLE DATA INSERT (for testing)
-- ================================================

-- Insert sample packages if none exist
INSERT INTO packages (id, name, description, price, session_count, validity_days, is_active)
SELECT 
  gen_random_uuid(),
  'Starter Package',
  'Perfect for beginners',
  199.99,
  8,
  30,
  true
WHERE NOT EXISTS (SELECT 1 FROM packages LIMIT 1);

INSERT INTO packages (id, name, description, price, session_count, validity_days, is_active)
SELECT 
  gen_random_uuid(),
  'Premium Package',
  'Most popular choice',
  349.99,
  16,
  60,
  true
WHERE (SELECT COUNT(*) FROM packages) = 1;

INSERT INTO packages (id, name, description, price, session_count, validity_days, is_active)
SELECT 
  gen_random_uuid(),
  'Elite Package',
  'Maximum results',
  599.99,
  32,
  90,
  true
WHERE (SELECT COUNT(*) FROM packages) = 2;

-- ================================================
-- COMMENTS FOR DOCUMENTATION
-- ================================================
COMMENT ON TABLE client_health_info IS 'Stores medical history and health conditions for liability protection';
COMMENT ON TABLE client_agreements IS 'Legal agreements and waivers with e-signature support';
COMMENT ON TABLE audit_log IS 'Complete audit trail for compliance and security';
COMMENT ON FUNCTION can_book_sessions IS 'Validates if client meets all requirements to book sessions';
COMMENT ON VIEW client_profiles IS 'Complete client profile with all related information';

-- ================================================
-- GRANT PERMISSIONS
-- ================================================
GRANT ALL ON client_health_info TO authenticated;
GRANT ALL ON client_preferences TO authenticated;
GRANT ALL ON client_agreements TO authenticated;
GRANT ALL ON cash_payments TO authenticated;
GRANT ALL ON pending_transfers TO authenticated;
GRANT ALL ON invoices TO authenticated;
GRANT ALL ON audit_log TO authenticated;
GRANT ALL ON email_queue TO authenticated;
GRANT ALL ON notifications TO authenticated;

GRANT SELECT ON client_profiles TO authenticated;
GRANT SELECT ON active_clients TO authenticated;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================
DO $$
BEGIN
  RAISE NOTICE '✓ Client Onboarding Schema Created Successfully';
  RAISE NOTICE '✓ Tables: 9 created';
  RAISE NOTICE '✓ Indexes: 10 created';
  RAISE NOTICE '✓ Functions: 4 created';
  RAISE NOTICE '✓ Views: 2 created';
  RAISE NOTICE '✓ Policies: 9 created';
  RAISE NOTICE '✓ Ready for production use!';
END $$;

