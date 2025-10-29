# 🔴 CRITICAL: Database Column Name Mismatch

## Error Found:
```
PostgrestException: column "sessions_remaining" does not exist
```

## Root Cause Analysis:

### ❌ Wrong Column Names in SQL Functions:

| **SQL Code Uses** | **Actual Column Name** | **Status** |
|------------------|----------------------|-----------|
| `sessions_remaining` | `remaining_sessions` | ❌ WRONG |
| `status = 'active'` | `is_active = true` | ❌ WRONG |
| `sessions_scheduled` | (doesn't exist) | ❌ WRONG |

### ✅ Correct Schema (from migrations/004):

```sql
CREATE TABLE client_packages (
  id UUID,
  client_id UUID,
  package_id UUID,
  package_name TEXT,
  total_sessions INTEGER,      -- Total in package
  remaining_sessions INTEGER,  -- ✅ Sessions left to book
  used_sessions INTEGER,       -- ✅ Sessions already used
  price_paid DECIMAL,
  purchase_date TIMESTAMPTZ,
  start_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  is_active BOOLEAN,           -- ✅ Active status (not "status")
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

### 🐛 Files with Wrong Column Names:

1. ✅ `supabase/FIX_TODAY_BOOKING_V3.sql` - FIXED
2. ❌ `supabase/PHASE1_CONFLICT_DETECTION.sql` - Has wrong names
3. ❌ `supabase/UPDATE_BOOKING_RULES.sql` - Has wrong names

---

## ✅ THE FIX: FIX_BOOKING_COMPLETE.sql

This new file fixes EVERYTHING:

### Issue #1: Wrong Column Names
```sql
-- OLD (WRONG):
SELECT sessions_remaining INTO v_package_sessions
FROM client_packages
WHERE status = 'active'

UPDATE client_packages
SET sessions_scheduled = sessions_scheduled + 1

-- NEW (CORRECT):
SELECT remaining_sessions INTO v_package_sessions
FROM client_packages
WHERE is_active = true

UPDATE client_packages
SET remaining_sessions = remaining_sessions - 1,
    used_sessions = used_sessions + 1
```

### Issue #2: Can't Book Today
```sql
-- OLD: Required 2 hours advance
IF p_scheduled_start < NOW() + INTERVAL '2 hours' THEN

-- NEW: Allow same-day (0 hours)
IF p_scheduled_start < NOW() THEN
```

### Issue #3: Current Time Blocked
```sql
-- OLD: Blocked slots AT current time
IF v_current_time <= NOW() THEN

-- NEW: Allow slots AT current time
IF v_current_time < NOW() THEN
```

---

## 🎯 HOW TO APPLY THE FIX:

### 1. Database (REQUIRED!)
The SQL is already copied to clipboard and Supabase SQL editor is open.

**Just:**
1. Press **Ctrl+V** in SQL editor
2. Click **RUN**
3. Wait for "🎉 COMPLETE FIX APPLIED!"

### 2. Flutter App (Already fixed!)
✅ Flutter code already updated (hot restart required)

### 3. Test
1. **Hot restart** Flutter app (press `R`)
2. Go to booking screen
3. Select October 28 (today)
4. Select a time slot
5. Click Book
6. Should work! 🎉

---

## Files Changed:

### Database:
- ✅ `supabase/FIX_BOOKING_COMPLETE.sql` - Ready to apply

### Flutter (Already Updated):
- ✅ `lib/services/booking_service.dart` - minAdvanceHours = 0
- ✅ `lib/screens/booking_screen_enhanced.dart` - DateUtils.dateOnly fixes

---

## Summary:

**3 Critical Issues Fixed:**
1. ✅ Wrong column names (sessions_remaining → remaining_sessions)
2. ✅ Can't book today (2 hours → 0 hours)
3. ✅ Current time blocked (<= → <)

**Apply:** `FIX_BOOKING_COMPLETE.sql` in Supabase now!
