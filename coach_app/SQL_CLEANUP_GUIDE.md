# 🗑️ SQL FILES CLEANUP GUIDE

## 📊 ANALYSIS: 133 Saved Queries in Supabase

Based on your local SQL files and screenshot, here's what to DELETE:

---

## ✅ KEEP THESE (ESSENTIAL - DO NOT DELETE)

### Production Schema (7 files)
1. **supabase_schema.sql** - Main database schema
2. **supabase/migrations/004_booking_integration_final.sql** - Current booking system
3. **INSERT_PACKAGES.sql** - Package data
4. **FINAL_FIX_ALL_ISSUES.sql** - Latest fix (just created!)
5. **supabase_storage_setup.sql** - Storage configuration
6. **supabase_booking_function.sql** - Booking logic
7. **supabase/CALENDAR_SYNC_ENHANCED.sql** - Calendar integration

### User Management (2 files)
8. **COMPLETE_USER_SETUP.sql** - User setup
9. **CREATE_TRAINER_USER.sql** - Trainer creation

---

## ❌ DELETE THESE (DUPLICATES & OLD FIXES)

### Old Database Fixes (DELETE ALL 15)
These are OLD fixes that were already applied or superseded by FINAL_FIX_ALL_ISSUES.sql:

1. ❌ **FIX_ALL_DATABASE_ISSUES.sql** - Old version (wrong column names)
2. ❌ **ULTIMATE_FIX_ALL_61_ISSUES.sql** - Old version (had errors)
3. ❌ **ULTIMATE_FIX_CORRECT_COLUMNS.sql** - Old version (had confirmed_at error)
4. ❌ **FIX_DATABASE_COMPLETE.sql** - Superseded
5. ❌ **FIX_SUPABASE_SECURITY_ISSUES.sql** - Superseded
6. ❌ **FIX_CLIENT_PACKAGES_SCHEMA.sql** - Superseded
7. ❌ **FIX_MISSING_COLUMN.sql** - Superseded
8. ❌ **FIX_PHOTO_URL_COLUMN.sql** - Superseded
9. ❌ **FIX_INFINITE_RECURSION_RLS.sql** - Old RLS fix
10. ❌ **DIAGNOSE_AND_FIX_ALL.sql** - Diagnostic script (no longer needed)
11. ❌ **supabase/FIX_ALL_DATABASE_ISSUES.sql** - Duplicate
12. ❌ **supabase/FIX_PACKAGE_BOOKING_SYNC.sql** - Old sync fix
13. ❌ **supabase/VERIFY_PACKAGE_FIX.sql** - Verification only
14. ❌ **supabase/FIX_PACKAGE_ASSIGNMENT_BUG.sql** - Already fixed
15. ❌ **supabase/FIX_OCT27_BOOKINGS.sql** - Already fixed (superseded by FINAL_FIX)

### Temporary Test Files (DELETE ALL 12)
16. ❌ **CHECK_SCHEMA_FIRST.sql** - Temporary check
17. ❌ **CHECK_CLIENTS_DATA.sql** - Temporary check
18. ❌ **CHECK_KHUN_BIE.sql** - One-time check for specific user
19. ❌ **ASSIGN_KHUN_BIE_PACKAGE.sql** - One-time fix for specific user
20. ❌ **FIX_ALL_CLIENTS_WITHOUT_PACKAGES.sql** - One-time fix
21. ❌ **VERIFY_EXISTING_USER.sql** - Verification only
22. ❌ **supabase/VERIFY_PACKAGE_FIX.sql** - Verification only (duplicate)
23. ❌ **supabase/DATABASE_HEALTH_CHECK.sql** - Can run when needed
24. ❌ **supabase/COMPREHENSIVE_END_TO_END_TEST.sql** - Test only
25. ❌ **COPY_THIS_SQL.sql** - Temporary
26. ❌ **GENERATE_INVITE_CODES.sql** - One-time generation
27. ❌ **AUTO_ASSIGN_PACKAGE_TRIGGER.sql** - If trigger not in use

### RLS & Security Experiments (DELETE ALL 6)
28. ❌ **DISABLE_RLS_TEMPORARILY.sql** - Dangerous! Don't keep
29. ❌ **FORCE_REMOVE_ALL_POLICIES.sql** - Dangerous! Don't keep
30. ❌ **FIX_RLS_USERS_ONLY.sql** - Old RLS setup
31. ❌ **CLEAN_STORAGE_POLICIES.sql** - One-time cleanup
32. ❌ **supabase/AUTO_USER_ACCESS_SYSTEM.sql** - If not implemented

### User Deletion Scripts (DELETE ALL 4)
33. ❌ **DELETE_USER_AND_START_FRESH.sql** - Dangerous! Don't keep
34. ❌ **DELETE_TEST_USERS.sql** - One-time cleanup
35. ❌ **DELETE_ALL_TRAINER_CLIENTS.sql** - Dangerous! Don't keep
36. ❌ **FIX_TRAINER_CLIENTS_DUPLICATES.sql** - One-time fix

### Email Confirmation Fixes (DELETE ALL 3)
37. ❌ **FIXED_CONFIRM_EMAIL.sql** - Old version
38. ❌ **FORCE_CONFIRM_EMAIL.sql** - Duplicate
39. ❌ **supabase/FINAL_FUNCTION_UPDATE.sql** - If already applied

### Old Migration Files (MAYBE KEEP)
These might have historical value, but likely superseded:
40. ⚠️ **supabase/migrations/001_enterprise_client_schema.sql** - Superseded by 004
41. ⚠️ **supabase/migrations/002_complete_enterprise_schema_sync.sql** - Superseded by 004
42. ⚠️ **supabase/migrations/003_booking_integration_fix.sql** - Superseded by 004
43. ⚠️ **supabase/migrations/005_add_trainer_clients_table.sql** - May still be needed
44. ⚠️ **supabase/migrations/006_add_amount_paid_column.sql** - May still be needed
45. ⚠️ **supabase_migrations/001_enterprise_package_system.sql** - Check if needed

### Future Feature Files (KEEP IF PLANNING TO USE)
46. ⚠️ **supabase/PHASE1_CONFLICT_DETECTION.sql** - Future feature
47. ⚠️ **supabase/PHASE2_CANCELLATION_POLICIES.sql** - Future feature
48. ⚠️ **supabase/PHASE3_RECURRING_SESSIONS.sql** - Future feature
49. ⚠️ **supabase/PHASE4_WAITLIST_MANAGEMENT.sql** - Future feature
50. ⚠️ **supabase/PHASE5_MULTI_LOCATION_RESOURCES.sql** - Future feature

### Enterprise Features (KEEP IF USING)
51. ⚠️ **supabase_client_onboarding_schema.sql** - If using client onboarding
52. ⚠️ **Enterprise Invoice System Schema for Coaching App** - If using invoicing
53. ⚠️ **Trainer KYC Schema** - If using KYC verification
54. ⚠️ **Coach App Revenue & Booking Management** - If using revenue tracking

### Booking/Calendar Features (REVIEW)
55. ⚠️ **supabase/GOOGLE_CALENDAR_SYNC_SETUP.sql** - If already set up, delete
56. ⚠️ **supabase/UPDATE_BOOKING_RULES.sql** - If rules are updated, delete
57. ⚠️ **Google Calendar Sync Integration for Sessions** - May be duplicate
58. ⚠️ **Enhanced Calendar Sync Toolkit** - May be duplicate

---

## 📋 CLEANUP ACTION PLAN

### STEP 1: Delete from Supabase Dashboard (Safe to Delete Immediately)

**Total to delete: ~40 queries**

#### Old Fixes (15 files)
- FIX_ALL_DATABASE_ISSUES.sql
- ULTIMATE_FIX_ALL_61_ISSUES.sql
- ULTIMATE_FIX_CORRECT_COLUMNS.sql
- All old FIX_* files
- All old VERIFY_* files

#### Temporary/Test Files (12 files)
- CHECK_* files
- ASSIGN_KHUN_BIE_PACKAGE.sql
- All verification scripts

#### Dangerous Scripts (10 files)
- DELETE_* files
- DISABLE_RLS_TEMPORARILY.sql
- FORCE_REMOVE_ALL_POLICIES.sql

### STEP 2: Review These Before Deleting (Check if still needed)

#### Future Features (5 PHASE files)
- Only delete if you're NOT planning to implement these features

#### Enterprise Features
- Only delete if you're NOT using invoicing/KYC/revenue tracking

#### Migration Files
- Keep migrations 004, 005, 006
- Delete migrations 001, 002, 003 (superseded)

---

## 🎯 RECOMMENDED ACTIONS

### In Supabase Dashboard:

1. **Delete immediately (40 queries):**
   - All queries with "FIX_", "CHECK_", "VERIFY_", "DELETE_", "TEMP_", "OLD_" in names
   - All queries from Oct 27 or earlier (except production schema)

2. **Keep these (~20 queries):**
   - Main schema files
   - Latest migration (004)
   - Active features (calendar sync, booking)
   - User management
   - FINAL_FIX_ALL_ISSUES.sql (newest!)

3. **Review before deleting (~10 queries):**
   - Future features (PHASE1-5)
   - Enterprise features
   - Calendar/booking duplicates

---

## 📝 FINAL RECOMMENDATION

**You can safely delete 70-80 of the 133 queries!**

Keep only:
- ✅ Production schema
- ✅ Latest fixes (FINAL_FIX_ALL_ISSUES.sql)
- ✅ Active features you're using
- ✅ Latest migration files

Delete:
- ❌ All old fixes (40+ files)
- ❌ All test/temporary files (12+ files)
- ❌ All dangerous deletion scripts (10+ files)
- ❌ Old migration files (3 files)

---

## 🚀 HOW TO DELETE IN SUPABASE

1. Go to SQL Editor in Supabase Dashboard
2. Look for the 3-dot menu (⋮) next to each query name
3. Click "Delete"
4. Start with files containing:
   - "FIX_" (old fixes)
   - "CHECK_" (temporary checks)
   - "DELETE_" (dangerous!)
   - "VERIFY_" (one-time verifications)
   - "TEMP_" or "OLD_" (obvious)

---

**After cleanup, you should have ~50-60 queries instead of 133!**
