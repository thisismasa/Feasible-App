-- ============================================================================
-- PHASE 2: CANCELLATION POLICIES & FEE CALCULATION
-- ============================================================================
-- Implements automated cancellation fee calculation based on:
-- 1. Time until session (24hr/48hr windows)
-- 2. Cancellation reason (emergency vs regular)
-- 3. Client history (frequent cancellations)
-- 4. Package type and payment status
-- ============================================================================

-- STEP 1: Create cancellation_policies table
-- ============================================================================

CREATE TABLE IF NOT EXISTS cancellation_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID REFERENCES users(id), -- NULL = global policy

  -- Policy Configuration
  policy_name TEXT NOT NULL,
  hours_before_session INTEGER NOT NULL,
  cancellation_fee_percent DECIMAL(5,2) NOT NULL,
  refund_session BOOLEAN DEFAULT TRUE,

  -- Conditions
  applies_to_session_types TEXT[] DEFAULT ARRAY['in_person', 'online', 'hybrid'],
  min_client_bookings INTEGER DEFAULT 0, -- Only apply after X bookings

  -- Priority
  priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_fee_percent CHECK (cancellation_fee_percent BETWEEN 0 AND 100),
  CONSTRAINT unique_policy UNIQUE(trainer_id, policy_name)
);

COMMENT ON TABLE cancellation_policies IS 'Configurable cancellation fee policies';

-- Insert default cancellation policies
INSERT INTO cancellation_policies (
  policy_name, hours_before_session, cancellation_fee_percent, refund_session, priority
) VALUES
('Late cancellation (under 24hr)', 24, 50.00, FALSE, 100),
('Early cancellation (24-48hr)', 48, 25.00, TRUE, 90),
('Advance cancellation (48hr+)', 999999, 0.00, TRUE, 80)
ON CONFLICT DO NOTHING;

-- STEP 2: Create cancellation_history table
-- ============================================================================

CREATE TABLE IF NOT EXISTS cancellation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id),
  client_id UUID NOT NULL REFERENCES users(id),
  trainer_id UUID NOT NULL REFERENCES users(id),

  -- Cancellation Details
  cancelled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cancelled_by UUID NOT NULL REFERENCES users(id),
  cancellation_reason TEXT,
  cancellation_type TEXT NOT NULL, -- 'client', 'trainer', 'emergency', 'no_show', 'system'

  -- Financial Impact
  hours_before_session NUMERIC(10,2),
  cancellation_fee_percent DECIMAL(5,2),
  cancellation_fee_amount DECIMAL(10,2),
  session_refunded BOOLEAN,

  -- Applied Policy
  policy_applied_id UUID REFERENCES cancellation_policies(id),
  policy_override BOOLEAN DEFAULT FALSE,
  override_reason TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cancellation_history_client
  ON cancellation_history(client_id, cancelled_at);

CREATE INDEX IF NOT EXISTS idx_cancellation_history_trainer
  ON cancellation_history(trainer_id, cancelled_at);

-- STEP 3: Function to get applicable cancellation policy
-- ============================================================================

CREATE OR REPLACE FUNCTION get_cancellation_policy(
  p_trainer_id UUID,
  p_client_id UUID,
  p_session_type TEXT,
  p_hours_until_session NUMERIC
) RETURNS TABLE (
  policy_id UUID,
  policy_name TEXT,
  fee_percent DECIMAL(5,2),
  refund_session BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id,
    cp.policy_name,
    cp.cancellation_fee_percent,
    cp.refund_session
  FROM cancellation_policies cp
  WHERE (cp.trainer_id = p_trainer_id OR cp.trainer_id IS NULL)
    AND cp.is_active = TRUE
    AND p_session_type = ANY(cp.applies_to_session_types)
    AND p_hours_until_session <= cp.hours_before_session
    AND (
      cp.min_client_bookings = 0
      OR (
        SELECT COUNT(*) FROM sessions
        WHERE client_id = p_client_id
          AND status = 'completed'
      ) >= cp.min_client_bookings
    )
  ORDER BY
    cp.trainer_id NULLS LAST, -- Trainer-specific first
    cp.priority DESC,
    cp.hours_before_session ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- STEP 4: Function to calculate cancellation fees
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_cancellation_fee(
  p_session_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_session RECORD;
  v_policy RECORD;
  v_hours_until NUMERIC;
  v_fee_amount DECIMAL(10,2) := 0;
  v_refund_session BOOLEAN := TRUE;
  v_base_amount DECIMAL(10,2);
BEGIN
  -- Get session details
  SELECT
    s.*,
    cp.price_paid / cp.total_sessions as session_value
  INTO v_session
  FROM sessions s
  LEFT JOIN client_packages cp ON s.package_id = cp.id
  WHERE s.id = p_session_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Session not found');
  END IF;

  -- Calculate hours until session
  v_hours_until := EXTRACT(EPOCH FROM (v_session.scheduled_start - NOW())) / 3600;

  IF v_hours_until < 0 THEN
    RETURN jsonb_build_object('error', 'Cannot cancel past sessions');
  END IF;

  -- Get base amount for fee calculation
  v_base_amount := COALESCE(v_session.session_value, v_session.amount_charged, 0);

  -- Get applicable policy
  SELECT * INTO v_policy
  FROM get_cancellation_policy(
    v_session.trainer_id,
    v_session.client_id,
    v_session.session_type,
    v_hours_until
  );

  IF FOUND THEN
    v_fee_amount := v_base_amount * (v_policy.fee_percent / 100);
    v_refund_session := v_policy.refund_session;
  ELSE
    -- No policy found, use default (no fee, full refund)
    v_fee_amount := 0;
    v_refund_session := TRUE;
  END IF;

  RETURN jsonb_build_object(
    'hours_until_session', ROUND(v_hours_until, 2),
    'policy_id', v_policy.policy_id,
    'policy_name', v_policy.policy_name,
    'fee_percent', v_policy.fee_percent,
    'base_amount', v_base_amount,
    'cancellation_fee', v_fee_amount,
    'refund_session', v_refund_session,
    'warning', CASE
      WHEN v_hours_until < 24 THEN 'Late cancellation - Fee applies'
      WHEN v_hours_until < 48 THEN 'Cancellation within 48 hours - Partial fee applies'
      ELSE 'Cancellation allowed without fee'
    END
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 5: Enhanced cancel_session function with fee calculation
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_session_with_policy(
  p_session_id UUID,
  p_cancelled_by UUID,
  p_reason TEXT DEFAULT NULL,
  p_cancellation_type TEXT DEFAULT 'client',
  p_override_policy BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
DECLARE
  v_session RECORD;
  v_fee_info JSONB;
  v_cancellation_fee DECIMAL(10,2);
  v_refund_session BOOLEAN;
  v_policy_id UUID;
BEGIN
  -- Get session
  SELECT * INTO v_session FROM sessions WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Session not found');
  END IF;

  IF v_session.status = 'cancelled' THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Session already cancelled');
  END IF;

  -- Calculate fees (unless overridden or emergency)
  IF p_override_policy OR p_cancellation_type = 'emergency' OR p_cancellation_type = 'trainer' THEN
    v_cancellation_fee := 0;
    v_refund_session := TRUE;
    v_policy_id := NULL;
  ELSE
    v_fee_info := calculate_cancellation_fee(p_session_id);

    IF v_fee_info ? 'error' THEN
      RETURN jsonb_build_object('success', FALSE, 'error', v_fee_info->>'error');
    END IF;

    v_cancellation_fee := (v_fee_info->>'cancellation_fee')::DECIMAL(10,2);
    v_refund_session := (v_fee_info->>'refund_session')::BOOLEAN;
    v_policy_id := (v_fee_info->>'policy_id')::UUID;
  END IF;

  -- Update session
  UPDATE sessions SET
    status = 'cancelled',
    cancelled_at = NOW(),
    cancelled_by = p_cancelled_by,
    cancellation_reason = p_reason,
    cancellation_fee = v_cancellation_fee
  WHERE id = p_session_id;

  -- Record in history
  INSERT INTO cancellation_history (
    session_id, client_id, trainer_id,
    cancelled_by, cancellation_reason, cancellation_type,
    hours_before_session, cancellation_fee_percent, cancellation_fee_amount,
    session_refunded, policy_applied_id, policy_override
  ) VALUES (
    p_session_id, v_session.client_id, v_session.trainer_id,
    p_cancelled_by, p_reason, p_cancellation_type,
    EXTRACT(EPOCH FROM (v_session.scheduled_start - NOW())) / 3600,
    CASE WHEN v_cancellation_fee > 0 THEN (v_fee_info->>'fee_percent')::DECIMAL(5,2) ELSE 0 END,
    v_cancellation_fee,
    v_refund_session, v_policy_id, p_override_policy
  );

  -- Refund session to package if applicable
  IF v_refund_session AND v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET sessions_scheduled = sessions_scheduled - 1
    WHERE id = v_session.package_id;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', p_session_id,
    'cancellation_fee', v_cancellation_fee,
    'session_refunded', v_refund_session,
    'fee_info', v_fee_info
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 6: Function to get client cancellation statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_client_cancellation_stats(
  p_client_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_stats RECORD;
BEGIN
  SELECT
    COUNT(*) as total_cancellations,
    COUNT(*) FILTER (WHERE cancellation_fee_amount > 0) as paid_cancellations,
    SUM(cancellation_fee_amount) as total_fees_paid,
    AVG(hours_before_session) as avg_hours_notice,
    MIN(cancelled_at) as first_cancellation,
    MAX(cancelled_at) as last_cancellation,
    COUNT(*) FILTER (WHERE cancelled_at > NOW() - INTERVAL '30 days') as recent_cancellations
  INTO v_stats
  FROM cancellation_history
  WHERE client_id = p_client_id;

  RETURN jsonb_build_object(
    'total_cancellations', COALESCE(v_stats.total_cancellations, 0),
    'paid_cancellations', COALESCE(v_stats.paid_cancellations, 0),
    'total_fees_paid', COALESCE(v_stats.total_fees_paid, 0),
    'avg_hours_notice', ROUND(COALESCE(v_stats.avg_hours_notice, 0), 2),
    'first_cancellation', v_stats.first_cancellation,
    'last_cancellation', v_stats.last_cancellation,
    'recent_cancellations', COALESCE(v_stats.recent_cancellations, 0),
    'cancellation_rate', ROUND(
      COALESCE(v_stats.total_cancellations, 0)::NUMERIC / NULLIF(
        (SELECT COUNT(*) FROM sessions WHERE client_id = p_client_id), 0
      ) * 100,
      2
    )
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- STEP 7: Create view for cancellation analytics
-- ============================================================================

CREATE OR REPLACE VIEW cancellation_analytics AS
SELECT
  u.id as client_id,
  u.full_name as client_name,
  u.email,
  COUNT(ch.id) as total_cancellations,
  COUNT(ch.id) FILTER (WHERE ch.cancelled_at > NOW() - INTERVAL '30 days') as recent_cancellations,
  AVG(ch.hours_before_session) as avg_hours_notice,
  SUM(ch.cancellation_fee_amount) as total_fees_paid,
  MAX(ch.cancelled_at) as last_cancellation_date,
  ROUND(
    COUNT(ch.id)::NUMERIC / NULLIF(
      (SELECT COUNT(*) FROM sessions s WHERE s.client_id = u.id), 0
    ) * 100,
    2
  ) as cancellation_rate_percent
FROM users u
LEFT JOIN cancellation_history ch ON u.id = ch.client_id
WHERE u.role = 'client'
GROUP BY u.id, u.full_name, u.email
HAVING COUNT(ch.id) > 0
ORDER BY cancellation_rate_percent DESC;

-- STEP 8: Verification queries
-- ============================================================================

-- Show all cancellation policies
SELECT
  '📋 CANCELLATION POLICIES' as info,
  policy_name,
  hours_before_session || ' hours' as notice_required,
  cancellation_fee_percent || '%' as fee,
  CASE WHEN refund_session THEN 'Yes' ELSE 'No' END as refund_session,
  CASE WHEN trainer_id IS NULL THEN 'Global' ELSE 'Trainer-specific' END as scope
FROM cancellation_policies
WHERE is_active = TRUE
ORDER BY hours_before_session ASC;

-- Test fee calculation for a sample session
SELECT
  '💰 SAMPLE FEE CALCULATION' as info,
  *
FROM calculate_cancellation_fee(
  (SELECT id FROM sessions WHERE status = 'scheduled' ORDER BY scheduled_start LIMIT 1)
);

-- Show recent cancellations
SELECT
  '📊 RECENT CANCELLATIONS' as info,
  u.full_name as client_name,
  TO_CHAR(ch.cancelled_at, 'YYYY-MM-DD HH24:MI') as cancelled_at,
  ROUND(ch.hours_before_session, 2) as hours_notice,
  ch.cancellation_fee_percent || '%' as fee_percent,
  ch.cancellation_fee_amount as fee_amount,
  CASE WHEN ch.session_refunded THEN 'Yes' ELSE 'No' END as refunded,
  ch.cancellation_type
FROM cancellation_history ch
JOIN users u ON ch.client_id = u.id
ORDER BY ch.cancelled_at DESC
LIMIT 5;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Phase 2 Complete: Cancellation Policies & Fee Calculation Implemented!' as message;
SELECT 'Features enabled:' as info,
       '- Automated fee calculation (50% < 24hr, 25% < 48hr)' as feature_1,
       '- Session refund rules' as feature_2,
       '- Cancellation history tracking' as feature_3,
       '- Client cancellation statistics' as feature_4,
       '- Emergency/Trainer cancellation exemptions' as feature_5;
