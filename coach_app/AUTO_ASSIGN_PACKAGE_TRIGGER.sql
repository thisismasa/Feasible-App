-- ============================================================================
-- AUTO-ASSIGN PACKAGE TO NEW CLIENTS - DATABASE TRIGGER
-- ============================================================================
-- This trigger automatically assigns a default "No Package" to every new client
-- Runs AFTER a new user with role='client' is created
-- ============================================================================

-- Step 1: Create the trigger function
-- ============================================================================
CREATE OR REPLACE FUNCTION auto_assign_default_package()
RETURNS TRIGGER AS $$
DECLARE
  v_default_package_id UUID;
  v_trainer_id UUID;
BEGIN
  -- Only process if the new user is a client
  IF NEW.role = 'client' THEN

    -- Get the first available trainer (or you can make this configurable)
    SELECT id INTO v_trainer_id
    FROM users
    WHERE role = 'trainer'
    LIMIT 1;

    -- Find or create the default "No Package" package
    SELECT id INTO v_default_package_id
    FROM packages
    WHERE name = 'No Package'
      AND is_active = true
    LIMIT 1;

    -- If "No Package" doesn't exist, create it
    IF v_default_package_id IS NULL THEN
      INSERT INTO packages (
        name,
        description,
        session_count,
        price,
        validity_days,
        is_active,
        created_at,
        updated_at
      ) VALUES (
        'No Package',
        'Default package for new clients - Please assign a real package',
        0,
        0,
        30,
        true,
        NOW(),
        NOW()
      ) RETURNING id INTO v_default_package_id;

      RAISE NOTICE 'Created default "No Package" with ID: %', v_default_package_id;
    END IF;

    -- Auto-assign the default package to the new client
    INSERT INTO client_packages (
      client_id,
      package_id,
      package_name,
      trainer_id,
      status,
      total_sessions,
      remaining_sessions,
      used_sessions,
      sessions_scheduled,
      price_paid,
      amount_paid,
      payment_method,
      payment_status,
      is_active,
      is_subscription,
      purchase_date,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,                    -- new client's user ID
      v_default_package_id,      -- default package ID
      'No Package',              -- package name
      v_trainer_id,              -- trainer ID
      'active',                  -- status
      0,                         -- total_sessions
      0,                         -- remaining_sessions
      0,                         -- used_sessions
      0,                         -- sessions_scheduled
      0,                         -- price_paid
      0,                         -- amount_paid
      'none',                    -- payment_method
      'pending',                 -- payment_status
      true,                      -- is_active
      false,                     -- is_subscription
      NOW(),                     -- purchase_date
      NOW(),                     -- created_at
      NOW()                      -- updated_at
    );

    RAISE NOTICE 'Auto-assigned default package to client: % (ID: %)', NEW.full_name, NEW.id;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create the trigger
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_auto_assign_package ON users;

CREATE TRIGGER trigger_auto_assign_package
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_default_package();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 'Trigger created successfully! Now every new client will automatically get a default package.' as status;

-- Check if trigger exists
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_assign_package';

-- ============================================================================
-- WHAT THIS DOES:
-- ============================================================================
-- ✅ Automatically triggers when a new user is created
-- ✅ Checks if the new user is a client (role='client')
-- ✅ Creates "No Package" if it doesn't exist
-- ✅ Assigns "No Package" to the new client
-- ✅ Works for ALL future clients automatically
-- ✅ No code changes needed - database handles it
-- ============================================================================
