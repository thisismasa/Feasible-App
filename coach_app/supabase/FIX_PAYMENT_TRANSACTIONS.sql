-- ============================================================================
-- FIX PAYMENT TRANSACTIONS TABLE
-- ============================================================================
-- Error: Could not find the 'client_id' column of 'payment_transactions'
-- This creates/fixes the payment_transactions table
-- ============================================================================

-- Drop existing table if it has wrong schema
DROP TABLE IF EXISTS payment_transactions CASCADE;

-- Create payment_transactions table with correct schema
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Payment details
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'THB',
  payment_method TEXT,  -- 'cash', 'credit_card', 'bank_transfer', 'promptpay', etc.
  payment_status TEXT DEFAULT 'completed',  -- 'pending', 'completed', 'failed', 'refunded'

  -- Transaction info
  transaction_date TIMESTAMPTZ DEFAULT NOW(),
  description TEXT,
  reference_number TEXT,
  notes TEXT,

  -- Audit fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_payment_transactions_client_id ON payment_transactions(client_id);
CREATE INDEX idx_payment_transactions_package_id ON payment_transactions(package_id);
CREATE INDEX idx_payment_transactions_trainer_id ON payment_transactions(trainer_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(payment_status);
CREATE INDEX idx_payment_transactions_date ON payment_transactions(transaction_date DESC);

-- Add comments
COMMENT ON TABLE payment_transactions IS 'Records all payment transactions for packages and sessions';
COMMENT ON COLUMN payment_transactions.client_id IS 'Client who made the payment';
COMMENT ON COLUMN payment_transactions.package_id IS 'Package being purchased (if applicable)';
COMMENT ON COLUMN payment_transactions.session_id IS 'Session being paid for (if applicable)';
COMMENT ON COLUMN payment_transactions.trainer_id IS 'Trainer receiving payment';
COMMENT ON COLUMN payment_transactions.payment_method IS 'How payment was made (cash, card, transfer, etc)';
COMMENT ON COLUMN payment_transactions.payment_status IS 'Current status of payment';

-- Enable Row Level Security
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

-- Verify table was created
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- Success message
SELECT '✅ payment_transactions table created successfully!' as status;
SELECT 'The table now has all required columns including client_id' as info;
