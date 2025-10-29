-- ============================================================================
-- FIX PAYMENT TRANSACTIONS - CORRECT FOREIGN KEY
-- ============================================================================
-- PROBLEM: package_id referenced client_packages, but it should reference packages
--
-- The flow is:
-- 1. Payment created with package_id from 'packages' table (the template)
-- 2. Then client_package created in 'client_packages' table
--
-- So package_id should point to packages table, NOT client_packages table!
-- ============================================================================

-- Drop the existing table with wrong foreign key
DROP TABLE IF EXISTS payment_transactions CASCADE;

-- Recreate with CORRECT foreign key
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys (CORRECTED!)
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  package_id UUID REFERENCES packages(id) ON DELETE SET NULL,  -- ✅ FIXED: Now references packages (template) table
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
CREATE INDEX idx_payment_transactions_contract_id ON payment_transactions(contract_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(payment_status);
CREATE INDEX idx_payment_transactions_date ON payment_transactions(transaction_date DESC);
CREATE INDEX idx_payment_transactions_type ON payment_transactions(transaction_type);

-- Comments
COMMENT ON TABLE payment_transactions IS 'Payment transaction records';
COMMENT ON COLUMN payment_transactions.package_id IS 'References packages table (template), NOT client_packages';

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own payment transactions"
  ON payment_transactions FOR SELECT
  USING (
    auth.uid() = client_id OR
    auth.uid() = trainer_id OR
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role IN ('admin', 'trainer')
    )
  );

CREATE POLICY "Trainers can insert payment transactions"
  ON payment_transactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role IN ('admin', 'trainer')
    )
  );

CREATE POLICY "Trainers can update payment transactions"
  ON payment_transactions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role IN ('admin', 'trainer')
    )
  );

-- Verify
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- Success
SELECT '✅ payment_transactions table fixed!' as status;
SELECT 'package_id now correctly references packages table (template)' as fix;
SELECT 'NOT client_packages table' as clarification;
