-- ============================================================================
-- INSERT SAMPLE PACKAGES INTO SUPABASE
-- Copy and paste this into Supabase SQL Editor and click RUN
-- ============================================================================

-- First, create the packages table if it doesn't exist
CREATE TABLE IF NOT EXISTS packages (
  id TEXT PRIMARY KEY,  -- Changed from UUID to TEXT for custom IDs
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  session_count INTEGER NOT NULL,
  validity_days INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Recurring package fields
  is_recurring BOOLEAN DEFAULT false,
  recurring_type TEXT,
  sessions_per_week INTEGER,
  minimum_commitment_months INTEGER,
  price_per_session DECIMAL(10,2)
);

-- Enable RLS
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Anyone can view active packages" ON packages;
DROP POLICY IF EXISTS "Trainers can manage packages" ON packages;

-- Create policies (without IF NOT EXISTS - not supported in Postgres)
CREATE POLICY "Anyone can view active packages"
ON packages FOR SELECT
USING (is_active = true);

CREATE POLICY "Trainers can manage packages"
ON packages FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Clear existing packages (if any)
DELETE FROM packages;

-- Insert the 5 packages with your pricing
INSERT INTO packages (
  id,
  name,
  description,
  price,
  session_count,
  validity_days,
  is_active,
  is_recurring,
  recurring_type,
  sessions_per_week,
  minimum_commitment_months,
  price_per_session,
  created_at
) VALUES

-- Recurring Subscription Package 1: 1x/Week
(
  'pkg-recurring-1x',
  '1x/Week Recurring',
  'Weekly subscription - 1 session per week. Minimum 3-month commitment.',
  1800.00,
  4,
  30,
  true,
  true,
  'flexible',
  1,
  3,
  1800.00,
  NOW()
),

-- Recurring Subscription Package 2: 2x/Week
(
  'pkg-recurring-2x',
  '2x/Week Recurring',
  'Weekly subscription - 2 sessions per week. Minimum 3-month commitment.',
  3400.00,
  8,
  30,
  true,
  true,
  'flexible',
  2,
  3,
  1700.00,
  NOW()
),

-- Recurring Subscription Package 3: 3x/Week
(
  'pkg-recurring-3x',
  '3x/Week Recurring',
  'Weekly subscription - 3 sessions per week. Minimum 3-month commitment.',
  4800.00,
  12,
  30,
  true,
  true,
  'flexible',
  3,
  3,
  1600.00,
  NOW()
),

-- One-Time Package 1: Single Session
(
  'pkg-single',
  'Single Session',
  'One personal training session - no commitment required.',
  1900.00,
  1,
  30,
  true,
  false,
  NULL,
  NULL,
  NULL,
  1900.00,
  NOW()
),

-- One-Time Package 2: 10-Session Bundle
(
  'pkg-bundle-10',
  '10-Session Bundle',
  'Save ฿1,000! 10 personal training sessions. Valid for 90 days.',
  18000.00,
  10,
  90,
  true,
  false,
  NULL,
  NULL,
  NULL,
  1800.00,
  NOW()
);

-- Verify the packages were inserted
SELECT 
  name,
  price,
  is_recurring,
  sessions_per_week,
  session_count,
  is_active
FROM packages
ORDER BY is_recurring DESC, price;

-- ============================================================================
-- SUCCESS! You should see 5 packages listed in the results
-- ============================================================================

