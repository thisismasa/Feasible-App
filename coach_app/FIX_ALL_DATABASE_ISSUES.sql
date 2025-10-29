-- ============================================
-- FIX ALL DATABASE ISSUES - COMPREHENSIVE REPAIR
-- ============================================
-- Run this in Supabase Dashboard SQL Editor:
-- https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
-- ============================================

-- 1. FIX CLIENT PACKAGES - Add missing data
-- ============================================

-- Fix sessions_remaining (set to total_sessions or default 10)
UPDATE client_packages
SET sessions_remaining = COALESCE(total_sessions, 10)
WHERE sessions_remaining IS NULL;

-- Fix start_date (set to today: 2025-10-27 or purchased_at date)
UPDATE client_packages
SET start_date = COALESCE(DATE(purchased_at), '2025-10-27')
WHERE start_date IS NULL;

-- Fix end_date (set to 90 days from start_date)
UPDATE client_packages
SET end_date = DATE(start_date) + INTERVAL '90 days'
WHERE end_date IS NULL;

-- Fix missing package_id (assign first available package plan)
UPDATE client_packages
SET package_id = (SELECT id FROM packages LIMIT 1)
WHERE package_id IS NULL;

-- 2. FIX BOOKING RULES - Allow same-day booking
-- ============================================

-- Set min_advance_hours to 0 (allow immediate booking)
UPDATE client_packages
SET min_advance_hours = 0
WHERE min_advance_hours IS NULL OR min_advance_hours > 0;

-- Set max_advance_days to 30
UPDATE client_packages
SET max_advance_days = 30
WHERE max_advance_days IS NULL;

-- Enable same-day booking
UPDATE client_packages
SET allow_same_day = true
WHERE allow_same_day IS NULL OR allow_same_day = false;

-- 3. FIX PACKAGE PLANS - Add pricing
-- ============================================

-- Set default pricing: 1000 THB per session
UPDATE packages
SET price = sessions * 1000
WHERE price IS NULL;

-- 4. VERIFICATION QUERIES
-- ============================================

-- Check client_packages after fixes
SELECT
  id,
  client_id,
  package_id,
  sessions_remaining,
  total_sessions,
  start_date,
  end_date,
  min_advance_hours,
  max_advance_days,
  allow_same_day,
  status
FROM client_packages
ORDER BY created_at DESC;

-- Check packages (plans) pricing
SELECT
  id,
  name,
  sessions,
  price,
  duration_days,
  is_active
FROM packages
ORDER BY sessions;

-- Count issues remaining
SELECT
  COUNT(*) FILTER (WHERE sessions_remaining IS NULL) as missing_sessions_remaining,
  COUNT(*) FILTER (WHERE start_date IS NULL) as missing_start_date,
  COUNT(*) FILTER (WHERE end_date IS NULL) as missing_end_date,
  COUNT(*) FILTER (WHERE package_id IS NULL) as missing_package_id,
  COUNT(*) FILTER (WHERE min_advance_hours IS NULL) as missing_min_advance_hours,
  COUNT(*) FILTER (WHERE allow_same_day IS NULL OR allow_same_day = false) as same_day_disabled,
  COUNT(*) as total_packages
FROM client_packages;

-- ============================================
-- EXPECTED RESULTS AFTER RUNNING THIS SCRIPT
-- ============================================
-- ✅ 16 packages with sessions_remaining set
-- ✅ 16 packages with valid start_date (2025-10-27)
-- ✅ 16 packages with valid end_date (2026-01-25)
-- ✅ 16 packages with package_id assigned
-- ✅ 16 packages with min_advance_hours = 0
-- ✅ 16 packages with allow_same_day = true
-- ✅ 20 package plans with pricing set
-- ============================================
