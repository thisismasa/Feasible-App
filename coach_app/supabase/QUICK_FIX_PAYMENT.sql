-- ============================================================================
-- QUICK FIX FOR PAYMENT SYSTEM
-- ============================================================================
-- Run this if diagnostic shows issues with payment_transactions table
-- ============================================================================

-- 1. Fix payment_transactions table (ensure correct foreign key)
DROP TABLE IF EXISTS payment_transactions CASCADE;

CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys (CORRECTED)
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  package_id UUID REFERENCES packages(id) ON DELETE SET NULL,  -- ✅ References packages (template) table
  contract_id UUID,
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,

  -- Payment fields
  payment_method TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'THB',
  payment_status TEXT DEFAULT 'pending',
  transaction_date TIMESTAMPTZ DEFAULT NOW(),

  -- Additional fields
  description TEXT,
  reference_number TEXT,
  notes TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,

  -- Audit fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_payment_transactions_client_id ON payment_transactions(client_id);
CREATE INDEX idx_payment_transactions_trainer_id ON payment_transactions(trainer_id);
CREATE INDEX idx_payment_transactions_package_id ON payment_transactions(package_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(payment_status);

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own payment transactions"
  ON payment_transactions FOR SELECT
  USING (
    auth.uid() = client_id OR
    auth.uid() = trainer_id OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'trainer'))
  );

CREATE POLICY "Trainers can insert payment transactions"
  ON payment_transactions FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'trainer'))
  );

-- 2. Ensure client_packages has correct columns
DO $$
BEGIN
  -- Add sessions_used as GENERATED column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'sessions_used'
  ) THEN
    ALTER TABLE client_packages
      ADD COLUMN sessions_used INTEGER
      GENERATED ALWAYS AS (used_sessions) STORED;
    RAISE NOTICE '✅ Added sessions_used as generated column';
  END IF;

  -- Ensure used_sessions column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'used_sessions'
  ) THEN
    ALTER TABLE client_packages ADD COLUMN used_sessions INTEGER DEFAULT 0;
    RAISE NOTICE '✅ Added used_sessions column';
  END IF;
END $$;

-- Verify
SELECT '========== VERIFICATION ==========' as status;

SELECT 'payment_transactions table:' as check;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'payment_transactions'
ORDER BY ordinal_position;

SELECT 'Foreign keys:' as check;
SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'payment_transactions'
  AND tc.constraint_type = 'FOREIGN KEY';

SELECT '✅ Payment system ready!' as status;
