-- ============================================================================
-- DELETE ALL TRAINER_CLIENTS - SIMPLE VERSION
-- ============================================================================
-- This will completely empty the trainer_clients table for a fresh start
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Show current count
SELECT COUNT(*) as total_relationships
FROM trainer_clients;

-- Step 2: Delete ALL trainer_clients relationships (complete fresh start)
DELETE FROM trainer_clients;

-- Step 3: Verify all deleted
SELECT COUNT(*) as remaining_relationships,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ ALL DELETED - FRESH START'
    ELSE '❌ SOME STILL EXIST'
  END as status
FROM trainer_clients;

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- remaining_relationships: 0
-- status: ✅ ALL DELETED - FRESH START
--
-- NOW RESTART YOUR FLUTTER APP AND ADD CLIENTS!
-- ============================================================================
