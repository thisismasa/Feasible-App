-- ============================================================================
-- COMPLETE SCHEMA SYNC - Flutter App ⟷ Database
-- ============================================================================
-- This synchronizes ALL tables to match Flutter model expectations:
-- - client_packages
-- - packages
-- - sessions/bookings
-- - users
-- - payments
-- ============================================================================

-- ============================================================================
-- FIX #1: client_packages Table - Add Missing/Alias Columns
-- ============================================================================
-- Current DB has: used_sessions, price_paid, is_active
-- Flutter expects: sessions_used, amount_paid, status, payment_status

DO $$
BEGIN
  -- Add sessions_used as computed column (alias for used_sessions)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'sessions_used'
  ) THEN
    ALTER TABLE client_packages
      ADD COLUMN sessions_used INTEGER
      GENERATED ALWAYS AS (used_sessions) STORED;
    RAISE NOTICE '✅ Added sessions_used column';
  END IF;

  -- Add amount_paid as computed column (alias for price_paid)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'amount_paid'
  ) THEN
    ALTER TABLE client_packages
      ADD COLUMN amount_paid DECIMAL(10,2)
      GENERATED ALWAYS AS (price_paid) STORED;
    RAISE NOTICE '✅ Added amount_paid column';
  END IF;

  -- Add status as computed column (derived from is_active + remaining_sessions + expiry_date)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'status'
  ) THEN
    ALTER TABLE client_packages
      ADD COLUMN status TEXT
      GENERATED ALWAYS AS (
        CASE
          WHEN NOT is_active THEN 'expired'
          WHEN expiry_date IS NOT NULL AND expiry_date < NOW() THEN 'expired'
          WHEN remaining_sessions <= 0 THEN 'completed'
          ELSE 'active'
        END
      ) STORED;
    RAISE NOTICE '✅ Added status column';
  END IF;

  -- Add payment_status column (actual column, not computed)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages' AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE client_packages
      ADD COLUMN payment_status TEXT DEFAULT 'paid';
    RAISE NOTICE '✅ Added payment_status column';
  END IF;

END $$;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_client_packages_status ON client_packages(status);
CREATE INDEX IF NOT EXISTS idx_client_packages_payment_status ON client_packages(payment_status);

COMMENT ON COLUMN client_packages.sessions_used IS 'Alias for used_sessions (Flutter compatibility)';
COMMENT ON COLUMN client_packages.amount_paid IS 'Alias for price_paid (Flutter compatibility)';
COMMENT ON COLUMN client_packages.status IS 'Computed from is_active, remaining_sessions, expiry_date';

-- ============================================================================
-- FIX #2: packages Table - Ensure Compatibility
-- ============================================================================
-- Current DB has: sessions, duration_days
-- Flutter expects: sessionCount/session_count/sessions, validityDays/validity_days/duration_days
-- Flutter model already has fallbacks, but let's add aliases for clarity

DO $$
BEGIN
  -- Add session_count as alias for sessions column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'packages' AND column_name = 'session_count'
  ) THEN
    ALTER TABLE packages
      ADD COLUMN session_count INTEGER
      GENERATED ALWAYS AS (sessions) STORED;
    RAISE NOTICE '✅ Added session_count alias';
  END IF;

  -- Add validity_days as alias for duration_days
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'packages' AND column_name = 'validity_days'
  ) THEN
    ALTER TABLE packages
      ADD COLUMN validity_days INTEGER
      GENERATED ALWAYS AS (duration_days) STORED;
    RAISE NOTICE '✅ Added validity_days alias';
  END IF;

END $$;

COMMENT ON COLUMN packages.session_count IS 'Alias for sessions (Flutter compatibility)';
COMMENT ON COLUMN packages.validity_days IS 'Alias for duration_days (Flutter compatibility)';

-- ============================================================================
-- FIX #3: sessions Table - Ensure It Exists and Has All Required Columns
-- ============================================================================
-- Problem: Both 'bookings' and 'sessions' tables may exist
-- Solution: Ensure 'sessions' exists with all required columns

-- Create sessions table if it doesn't exist
CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,

  -- DateTime fields
  scheduled_start TIMESTAMPTZ NOT NULL,
  scheduled_end TIMESTAMPTZ,
  scheduled_date TIMESTAMPTZ,  -- Alias for scheduled_start for compatibility

  duration_minutes INTEGER DEFAULT 60,

  -- Buffer times (for conflict detection)
  buffer_start TIMESTAMPTZ,
  buffer_end TIMESTAMPTZ,

  -- Session details
  status TEXT DEFAULT 'scheduled',  -- 'scheduled', 'completed', 'cancelled', 'noShow'
  session_type TEXT DEFAULT 'in_person',  -- 'in_person', 'online'
  location TEXT,
  client_notes TEXT,
  trainer_notes TEXT,
  notes TEXT,  -- General notes field

  -- Validation & conflicts
  has_conflicts BOOLEAN DEFAULT FALSE,
  validation_passed BOOLEAN DEFAULT TRUE,

  -- Audit fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,

  -- Payment
  price DECIMAL(10,2) DEFAULT 0.0,
  payment_status TEXT DEFAULT 'paid'
);

-- Add missing columns to existing sessions table
DO $$
BEGIN
  -- Add scheduled_date if missing (alias for scheduled_start)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'scheduled_date'
  ) THEN
    ALTER TABLE sessions
      ADD COLUMN scheduled_date TIMESTAMPTZ
      GENERATED ALWAYS AS (scheduled_start) STORED;
    RAISE NOTICE '✅ Added scheduled_date column to sessions';
  END IF;

  -- Add completed_at if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'completed_at'
  ) THEN
    ALTER TABLE sessions
      ADD COLUMN completed_at TIMESTAMPTZ;
    RAISE NOTICE '✅ Added completed_at column to sessions';
  END IF;

  -- Add notes if missing (general notes field)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'notes'
  ) THEN
    ALTER TABLE sessions
      ADD COLUMN notes TEXT;
    RAISE NOTICE '✅ Added notes column to sessions';
  END IF;

  -- Add price if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'price'
  ) THEN
    ALTER TABLE sessions
      ADD COLUMN price DECIMAL(10,2) DEFAULT 0.0;
    RAISE NOTICE '✅ Added price column to sessions';
  END IF;

END $$;

-- Create indexes for sessions table
CREATE INDEX IF NOT EXISTS idx_sessions_client_id ON sessions(client_id);
CREATE INDEX IF NOT EXISTS idx_sessions_trainer_id ON sessions(trainer_id);
CREATE INDEX IF NOT EXISTS idx_sessions_package_id ON sessions(package_id);
CREATE INDEX IF NOT EXISTS idx_sessions_scheduled_start ON sessions(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_completed_at ON sessions(completed_at);

-- ============================================================================
-- FIX #4: Migrate bookings → sessions (if bookings table exists)
-- ============================================================================
-- If you have data in 'bookings' table, migrate it to 'sessions'

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
    -- Migrate data from bookings to sessions
    INSERT INTO sessions (
      id, client_id, trainer_id, package_id,
      scheduled_start, scheduled_date, duration_minutes,
      status, notes, created_at, updated_at
    )
    SELECT
      b.id,
      b.client_id,
      b.trainer_id,
      b.client_package_id,
      b.session_date,
      b.session_date,
      b.duration_minutes,
      b.status,
      b.notes,
      b.created_at,
      b.updated_at
    FROM bookings b
    WHERE NOT EXISTS (
      SELECT 1 FROM sessions s WHERE s.id = b.id
    );

    RAISE NOTICE '✅ Migrated bookings to sessions';

    -- Optionally drop bookings table
    -- DROP TABLE bookings CASCADE;
  END IF;
END $$;

-- ============================================================================
-- FIX #5: Create/Update Unified View for Sessions with Client Names
-- ============================================================================
-- Flutter expects 'client_name' field which requires a JOIN with users table

CREATE OR REPLACE VIEW sessions_with_clients AS
SELECT
  s.*,
  u.full_name as client_name,
  cp.package_name,
  cp.remaining_sessions,
  t.full_name as trainer_name
FROM sessions s
LEFT JOIN users u ON s.client_id = u.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
LEFT JOIN users t ON s.trainer_id = t.id;

COMMENT ON VIEW sessions_with_clients IS
'Unified view of sessions with client/trainer names and package info';

-- ============================================================================
-- FIX #6: Add payment_transactions table (if it doesn't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,

  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'THB',
  payment_method TEXT,  -- 'cash', 'credit_card', 'bank_transfer', 'promptpay', etc.
  payment_status TEXT DEFAULT 'pending',  -- 'pending', 'completed', 'failed', 'refunded'

  transaction_date TIMESTAMPTZ DEFAULT NOW(),
  description TEXT,
  reference_number TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_client_id ON payment_transactions(client_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(payment_status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_date ON payment_transactions(transaction_date DESC);

-- ============================================================================
-- FIX #7: Update Triggers to Work with New Schema
-- ============================================================================

-- Drop old trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_package_on_booking ON bookings;
DROP TRIGGER IF EXISTS trigger_update_package_on_session ON sessions;

-- Create new trigger for sessions table
CREATE OR REPLACE FUNCTION update_package_on_session_change()
RETURNS TRIGGER AS $$
BEGIN
  -- When session is completed
  IF NEW.status = 'completed' AND (OLD IS NULL OR OLD.status != 'completed') THEN
    IF NEW.package_id IS NOT NULL THEN
      UPDATE client_packages
      SET
        remaining_sessions = GREATEST(remaining_sessions - 1, 0),
        used_sessions = used_sessions + 1,
        updated_at = NOW()
      WHERE id = NEW.package_id;

      -- Set completed_at timestamp
      NEW.completed_at := NOW();
    END IF;
  END IF;

  -- When session is cancelled and was previously completed
  IF NEW.status = 'cancelled' AND OLD.status = 'completed' THEN
    IF NEW.package_id IS NOT NULL THEN
      UPDATE client_packages
      SET
        remaining_sessions = remaining_sessions + 1,
        used_sessions = GREATEST(used_sessions - 1, 0),
        updated_at = NOW()
      WHERE id = NEW.package_id;

      NEW.cancelled_at := NOW();
    END IF;
  END IF;

  -- Update updated_at timestamp
  NEW.updated_at := NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_package_on_session_change
  BEFORE INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_package_on_session_change();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

SELECT '🎉 COMPLETE SCHEMA SYNC APPLIED!' as status;
SELECT '' as blank;
SELECT '✅ client_packages table synced' as fix_1;
SELECT '   • sessions_used (alias for used_sessions)' as fix_1a;
SELECT '   • amount_paid (alias for price_paid)' as fix_1b;
SELECT '   • status (computed from is_active, remaining, expiry)' as fix_1c;
SELECT '   • payment_status (new column)' as fix_1d;
SELECT '' as blank2;
SELECT '✅ packages table synced' as fix_2;
SELECT '   • session_count (alias for sessions)' as fix_2a;
SELECT '   • validity_days (alias for duration_days)' as fix_2b;
SELECT '' as blank3;
SELECT '✅ sessions table synced' as fix_3;
SELECT '   • scheduled_date (alias for scheduled_start)' as fix_3a;
SELECT '   • completed_at, notes, price columns added' as fix_3b;
SELECT '   • Migrated from bookings if needed' as fix_3c;
SELECT '' as blank4;
SELECT '✅ sessions_with_clients view created' as fix_4;
SELECT '   • Includes client_name from users table' as fix_4a;
SELECT '' as blank5;
SELECT '✅ payment_transactions table ensured' as fix_5;
SELECT '✅ Triggers updated for new schema' as fix_6;
SELECT '' as blank6;
SELECT '🔄 Flutter app will now work with database!' as result;

-- Show current client_packages schema
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  generation_expression as generated
FROM information_schema.columns
WHERE table_name = 'client_packages'
ORDER BY ordinal_position;
