-- Migration: Add amount_paid column to client_packages table
-- Date: 2025-10-20
-- Description: Fixes PostgreSQL error "Could not find the 'amount_paid' column"
-- by adding the missing column that the Flutter app expects.

-- Add amount_paid column if it doesn't exist
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(10, 2) DEFAULT 0.0;

-- Update existing records to copy price_paid to amount_paid
UPDATE client_packages
SET amount_paid = price_paid
WHERE amount_paid = 0.0 OR amount_paid IS NULL;

-- Add a comment to document the column
COMMENT ON COLUMN client_packages.amount_paid IS 'Amount actually paid by client for this package (may differ from price_paid due to discounts, prorating, etc.)';

-- Optional: Create index if needed for queries filtering by amount_paid
-- CREATE INDEX IF NOT EXISTS idx_client_packages_amount_paid ON client_packages(amount_paid);
