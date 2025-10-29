-- ============================================
-- Automatic User Access System
-- ============================================
-- This eliminates manual Google Cloud Console email management
-- Users can be auto-approved via invite codes, domains, or admin approval

-- ============================================
-- 1. Allowed Users Table
-- ============================================
CREATE TABLE IF NOT EXISTS allowed_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  google_id TEXT,
  display_name TEXT,
  photo_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
  calendar_access BOOLEAN DEFAULT false,
  invite_code_used TEXT,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  denied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_allowed_users_email ON allowed_users(email);
CREATE INDEX idx_allowed_users_status ON allowed_users(status);
CREATE INDEX idx_allowed_users_google_id ON allowed_users(google_id);

-- ============================================
-- 2. Invite Codes Table
-- ============================================
CREATE TABLE IF NOT EXISTS invite_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  max_uses INTEGER DEFAULT 1,
  used_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast code validation
CREATE INDEX idx_invite_codes_code ON invite_codes(code);
CREATE INDEX idx_invite_codes_created_by ON invite_codes(created_by);

-- ============================================
-- 3. Auto-Approval Rules Table
-- ============================================
CREATE TABLE IF NOT EXISTS auto_approval_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rule_type TEXT NOT NULL CHECK (rule_type IN ('domain', 'email_pattern', 'wildcard')),
  rule_value TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  created_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for rule matching
CREATE INDEX idx_auto_approval_rules_type ON auto_approval_rules(rule_type);
CREATE INDEX idx_auto_approval_rules_enabled ON auto_approval_rules(enabled);

-- ============================================
-- 4. Access Log Table (Audit Trail)
-- ============================================
CREATE TABLE IF NOT EXISTS access_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  email TEXT,
  action TEXT NOT NULL, -- 'sign_in', 'approved', 'denied', 'invite_redeemed'
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for audit queries
CREATE INDEX idx_access_log_user_id ON access_log(user_id);
CREATE INDEX idx_access_log_email ON access_log(email);
CREATE INDEX idx_access_log_action ON access_log(action);
CREATE INDEX idx_access_log_created_at ON access_log(created_at);

-- ============================================
-- FUNCTIONS
-- ============================================

-- ============================================
-- Function: Auto-approve user based on rules
-- ============================================
CREATE OR REPLACE FUNCTION auto_approve_user()
RETURNS TRIGGER AS $$
DECLARE
  rule RECORD;
BEGIN
  -- Check if email matches any auto-approval rules
  FOR rule IN
    SELECT * FROM auto_approval_rules
    WHERE enabled = true
  LOOP
    IF rule.rule_type = 'domain' THEN
      -- Check if email ends with domain (e.g., '@gmail.com')
      IF NEW.email LIKE '%' || rule.rule_value THEN
        NEW.status := 'approved';
        NEW.approved_at := NOW();

        -- Log the auto-approval
        INSERT INTO access_log (email, action, details)
        VALUES (NEW.email, 'auto_approved', jsonb_build_object(
          'rule_type', rule.rule_type,
          'rule_value', rule.rule_value
        ));

        RETURN NEW;
      END IF;

    ELSIF rule.rule_type = 'email_pattern' THEN
      -- Check if email matches pattern
      IF NEW.email ~ rule.rule_value THEN
        NEW.status := 'approved';
        NEW.approved_at := NOW();

        INSERT INTO access_log (email, action, details)
        VALUES (NEW.email, 'auto_approved', jsonb_build_object(
          'rule_type', rule.rule_type,
          'rule_value', rule.rule_value
        ));

        RETURN NEW;
      END IF;

    ELSIF rule.rule_type = 'wildcard' THEN
      -- Approve everyone (use with caution!)
      IF rule.rule_value = '*' THEN
        NEW.status := 'approved';
        NEW.approved_at := NOW();

        INSERT INTO access_log (email, action, details)
        VALUES (NEW.email, 'auto_approved', jsonb_build_object(
          'rule_type', 'wildcard'
        ));

        RETURN NEW;
      END IF;
    END IF;
  END LOOP;

  -- No auto-approval rule matched - remain pending
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-approve on user insert
DROP TRIGGER IF EXISTS auto_approve_user_trigger ON allowed_users;
CREATE TRIGGER auto_approve_user_trigger
  BEFORE INSERT ON allowed_users
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_user();

-- ============================================
-- Function: Validate and redeem invite code
-- ============================================
CREATE OR REPLACE FUNCTION redeem_invite_code(
  p_code TEXT,
  p_email TEXT,
  p_google_id TEXT DEFAULT NULL,
  p_display_name TEXT DEFAULT NULL,
  p_photo_url TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_invite RECORD;
  v_user_id UUID;
  v_result JSONB;
BEGIN
  -- Find and validate invite code
  SELECT * INTO v_invite
  FROM invite_codes
  WHERE code = p_code;

  -- Check if code exists
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid invite code'
    );
  END IF;

  -- Check if code is expired
  IF v_invite.expires_at IS NOT NULL AND v_invite.expires_at < NOW() THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invite code expired'
    );
  END IF;

  -- Check if code has reached max uses
  IF v_invite.used_count >= v_invite.max_uses THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invite code already used'
    );
  END IF;

  -- Create or update user as approved
  INSERT INTO allowed_users (
    email,
    google_id,
    display_name,
    photo_url,
    status,
    invite_code_used,
    approved_at
  )
  VALUES (
    p_email,
    p_google_id,
    p_display_name,
    p_photo_url,
    'approved',
    p_code,
    NOW()
  )
  ON CONFLICT (email) DO UPDATE SET
    status = 'approved',
    invite_code_used = p_code,
    approved_at = NOW(),
    google_id = EXCLUDED.google_id,
    display_name = EXCLUDED.display_name,
    photo_url = EXCLUDED.photo_url
  RETURNING id INTO v_user_id;

  -- Increment invite code usage
  UPDATE invite_codes
  SET used_count = used_count + 1
  WHERE code = p_code;

  -- Log redemption
  INSERT INTO access_log (user_id, email, action, details)
  VALUES (v_user_id, p_email, 'invite_redeemed', jsonb_build_object(
    'code', p_code
  ));

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_user_id,
    'status', 'approved'
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Function: Check user access status
-- ============================================
CREATE OR REPLACE FUNCTION check_user_access(p_email TEXT)
RETURNS JSONB AS $$
DECLARE
  v_user RECORD;
BEGIN
  SELECT * INTO v_user
  FROM allowed_users
  WHERE email = p_email;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'exists', false,
      'status', 'not_registered'
    );
  END IF;

  RETURN jsonb_build_object(
    'exists', true,
    'status', v_user.status,
    'calendar_access', v_user.calendar_access,
    'display_name', v_user.display_name,
    'photo_url', v_user.photo_url
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Function: Generate unique invite code
-- ============================================
CREATE OR REPLACE FUNCTION generate_invite_code(
  p_max_uses INTEGER DEFAULT 1,
  p_expires_in_days INTEGER DEFAULT 7,
  p_created_by UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  v_code TEXT;
  v_exists BOOLEAN;
BEGIN
  LOOP
    -- Generate 8-character code
    v_code := upper(substring(md5(random()::text) from 1 for 8));

    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM invite_codes WHERE code = v_code) INTO v_exists;

    -- Exit loop if code is unique
    EXIT WHEN NOT v_exists;
  END LOOP;

  -- Insert invite code
  INSERT INTO invite_codes (
    code,
    max_uses,
    expires_at,
    created_by,
    notes
  )
  VALUES (
    v_code,
    p_max_uses,
    CASE
      WHEN p_expires_in_days IS NOT NULL
      THEN NOW() + (p_expires_in_days || ' days')::INTERVAL
      ELSE NULL
    END,
    p_created_by,
    p_notes
  );

  RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE allowed_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_approval_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_log ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can check their own access status
CREATE POLICY "Users can view their own record"
  ON allowed_users FOR SELECT
  USING (auth.jwt() ->> 'email' = email);

-- Policy: Service role can manage all users
CREATE POLICY "Service role can manage users"
  ON allowed_users
  USING (auth.role() = 'service_role');

-- Policy: Admins can view all users (define admin users)
CREATE POLICY "Admins can manage users"
  ON allowed_users
  USING (
    email IN (
      SELECT email FROM allowed_users WHERE status = 'approved' AND calendar_access = true
    )
  );

-- Policy: Anyone can validate invite codes (for redemption)
CREATE POLICY "Anyone can view valid invite codes"
  ON invite_codes FOR SELECT
  USING (
    used_count < max_uses
    AND (expires_at IS NULL OR expires_at > NOW())
  );

-- Policy: Service role can manage invite codes
CREATE POLICY "Service role can manage invite codes"
  ON invite_codes
  USING (auth.role() = 'service_role');

-- ============================================
-- HELPER VIEWS
-- ============================================

-- View: Pending approvals
CREATE OR REPLACE VIEW pending_approvals AS
SELECT
  id,
  email,
  display_name,
  photo_url,
  created_at,
  extract(epoch from (NOW() - created_at)) / 3600 as hours_waiting
FROM allowed_users
WHERE status = 'pending'
ORDER BY created_at DESC;

-- View: Active invite codes
CREATE OR REPLACE VIEW active_invite_codes AS
SELECT
  code,
  max_uses,
  used_count,
  max_uses - used_count as remaining_uses,
  expires_at,
  notes,
  created_at
FROM invite_codes
WHERE
  used_count < max_uses
  AND (expires_at IS NULL OR expires_at > NOW())
ORDER BY created_at DESC;

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Example: Auto-approve all Gmail addresses
-- INSERT INTO auto_approval_rules (rule_type, rule_value, notes)
-- VALUES ('domain', '@gmail.com', 'Auto-approve all Gmail users');

-- Example: Generate invite codes for your 5 friends
-- SELECT generate_invite_code(1, 30, NULL, 'Friend 1');
-- SELECT generate_invite_code(1, 30, NULL, 'Friend 2');
-- SELECT generate_invite_code(1, 30, NULL, 'Friend 3');
-- SELECT generate_invite_code(1, 30, NULL, 'Friend 4');
-- SELECT generate_invite_code(1, 30, NULL, 'Friend 5');

-- ============================================
-- USAGE EXAMPLES
-- ============================================

/*
-- 1. Generate invite code
SELECT generate_invite_code(
  1,          -- max_uses
  7,          -- expires_in_days
  NULL,       -- created_by
  'For John'  -- notes
);
-- Returns: 'ABC12345'

-- 2. Redeem invite code
SELECT redeem_invite_code(
  'ABC12345',                    -- code
  'john@gmail.com',             -- email
  '1234567890',                  -- google_id
  'John Doe',                    -- display_name
  'https://photo.url/john.jpg'   -- photo_url
);
-- Returns: {"success": true, "user_id": "...", "status": "approved"}

-- 3. Check user access
SELECT check_user_access('john@gmail.com');
-- Returns: {"exists": true, "status": "approved", "calendar_access": false}

-- 4. View pending approvals
SELECT * FROM pending_approvals;

-- 5. View active invite codes
SELECT * FROM active_invite_codes;
*/

-- ============================================
-- SUCCESS!
-- ============================================

COMMENT ON TABLE allowed_users IS 'Users who can access the app - controlled by invite codes, auto-approval rules, or admin approval';
COMMENT ON TABLE invite_codes IS 'One-time or limited-use invite codes for granting access without manual email entry';
COMMENT ON TABLE auto_approval_rules IS 'Rules for automatically approving users based on email domain or pattern';
COMMENT ON TABLE access_log IS 'Audit trail of user access events';

SELECT 'Auto User Access System installed successfully!' as status;
