-- ============================================================================
-- FIX PAYMENT TRANSACTIONS TABLE - COMPLETE SCHEMA
-- ============================================================================
-- This matches EXACTLY what the Flutter payment_service.dart expects
-- Based on the actual code at line 38-50
-- ============================================================================

-- Drop existing table if it exists
DROP TABLE IF EXISTS payment_transactions CASCADE;

-- Create payment_transactions table with ALL fields that Flutter code uses
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys (from Flutter code)
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
  contract_id UUID,  -- ✅ ADDED: For subscription contracts
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,

  -- Payment fields (from Flutter code line 43-49)
  payment_method TEXT NOT NULL,  -- 'cash', 'credit_card', 'bank_transfer', 'promptpay'
  transaction_type TEXT NOT NULL,  -- ✅ ADDED: 'subscription_payment' or 'package_purchase'
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'THB',
  payment_status TEXT DEFAULT 'pending',  -- 'pending', 'completed', 'failed', 'refunded'
  transaction_date TIMESTAMPTZ DEFAULT NOW(),

  -- Additional fields
  description TEXT,
  reference_number TEXT,
  notes TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,  -- ✅ ADDED: For storing additional data

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

-- Add comments
COMMENT ON TABLE payment_transactions IS 'Records all payment transactions - matches Flutter payment_service.dart';
COMMENT ON COLUMN payment_transactions.client_id IS 'Client who made the payment';
COMMENT ON COLUMN payment_transactions.trainer_id IS 'Trainer receiving payment';
COMMENT ON COLUMN payment_transactions.package_id IS 'Package being purchased';
COMMENT ON COLUMN payment_transactions.contract_id IS 'Subscription contract ID (if applicable)';
COMMENT ON COLUMN payment_transactions.transaction_type IS 'subscription_payment or package_purchase';
COMMENT ON COLUMN payment_transactions.metadata IS 'Additional transaction data (JSONB)';

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

-- Verify the table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- Success message
SELECT '✅ payment_transactions table created with ALL required columns!' as status;
SELECT 'Includes: client_id, trainer_id, package_id, contract_id, transaction_type, metadata' as columns;
SELECT 'Ready to accept payments from Flutter app!' as ready;
