# 🔍 COMPLETE DATABASE SCHEMA AUDIT - Oct 28, 2025

## Critical Findings

### ❌ **MAJOR MISMATCH: client_packages Table**

#### Database Schema (Actual):
```sql
CREATE TABLE client_packages (
  id UUID PRIMARY KEY,
  client_id UUID NOT NULL,
  package_id UUID,
  package_name TEXT NOT NULL,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  remaining_sessions INTEGER NOT NULL DEFAULT 0,   -- ✅ EXISTS
  used_sessions INTEGER DEFAULT 0,                -- ✅ EXISTS
  price_paid DECIMAL(10,2) DEFAULT 0.0,
  purchase_date TIMESTAMPTZ DEFAULT NOW(),
  start_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,                 -- ✅ EXISTS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Flutter Model Expects (package_model.dart:118-158):
```dart
factory ClientPackage.fromSupabaseMap(Map<String, dynamic> map) {
  return ClientPackage(
    id: map['id'] ?? '',
    clientId: map['client_id'] ?? '',
    packageId: map['package_id'] ?? '',
    packageName: map['package_name'] ?? 'Unknown Package',
    totalSessions: map['total_sessions'] ?? 0,      // ✅ OK
    sessionsUsed: map['sessions_used'] ?? 0,         // ❌ WRONG: expects sessions_used
    purchaseDate: map['purchase_date'] ?? DateTime.now(),
    expiryDate: map['expiry_date'] ?? DateTime.now(),
    amountPaid: map['amount_paid'] ?? 0,             // ❌ WRONG: expects amount_paid
    status: PackageStatus.values.firstWhere(
      (e) => e.name == map['status'],                // ❌ WRONG: expects status column
      orElse: () => PackageStatus.active,
    ),
    paymentStatus: map['payment_status'] ?? 'paid',  // ❌ WRONG: expects payment_status
  );
}
```

### 📊 Column Name Mismatches:

| **Flutter Model Expects** | **Actual Database Column** | **Status** |
|---------------------------|---------------------------|-----------|
| `sessions_used` | `used_sessions` | ❌ MISMATCH |
| `amount_paid` | `price_paid` | ❌ MISMATCH |
| `status` (enum) | `is_active` (boolean) | ❌ TYPE MISMATCH |
| `payment_status` | (doesn't exist) | ❌ MISSING |

---

## 🔧 Required Fixes

### Option 1: Add Aliases/Columns to Database (RECOMMENDED)

Add these columns to match Flutter expectations:

```sql
-- Add missing/alias columns to client_packages
ALTER TABLE client_packages
  ADD COLUMN IF NOT EXISTS sessions_used INTEGER
  GENERATED ALWAYS AS (used_sessions) STORED;

ALTER TABLE client_packages
  ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(10,2)
  GENERATED ALWAYS AS (price_paid) STORED;

ALTER TABLE client_packages
  ADD COLUMN IF NOT EXISTS status TEXT
  GENERATED ALWAYS AS (
    CASE
      WHEN NOT is_active THEN 'expired'
      WHEN remaining_sessions <= 0 THEN 'completed'
      ELSE 'active'
    END
  ) STORED;

ALTER TABLE client_packages
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'paid';
```

### Option 2: Fix Flutter Model (ALTERNATIVE)

Update `lib/models/package_model.dart:140-145`:

```dart
// Change from:
sessionsUsed: map['sessions_used'] ?? 0,
amountPaid: map['amount_paid'] ?? 0,

// To:
sessionsUsed: map['used_sessions'] ?? 0,        // ✅ Match DB
amountPaid: map['price_paid']?.toDouble() ?? 0.0, // ✅ Match DB
```

And fix status mapping:

```dart
// Change from:
status: PackageStatus.values.firstWhere(
  (e) => e.name == map['status'],
  orElse: () => PackageStatus.active,
),

// To:
status: _getStatusFromDatabase(
  isActive: map['is_active'] ?? true,
  remainingSessions: map['remaining_sessions'] ?? 0,
  expiryDate: map['expiry_date'],
),

// Add helper method:
static PackageStatus _getStatusFromDatabase({
  required bool isActive,
  required int remainingSessions,
  required String? expiryDate,
}) {
  if (!isActive || (expiryDate != null && DateTime.parse(expiryDate).isBefore(DateTime.now()))) {
    return PackageStatus.expired;
  }
  if (remainingSessions <= 0) {
    return PackageStatus.completed;
  }
  return PackageStatus.active;
}
```

---

## 📦 packages Table Analysis

### Database Schema:
```sql
CREATE TABLE packages (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  sessions INTEGER NOT NULL DEFAULT 0,       -- ❌ Flutter expects: sessionCount
  price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
  duration_days INTEGER,                      -- ❌ Flutter expects: validity_days
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Flutter Model (package_model.dart:34-66):
```dart
sessionCount: map['sessionCount'] ??
              map['session_count'] ??
              map['sessions'] ??           // ✅ GOOD: Has fallback
              map['total_sessions'] ?? 0,

validityDays: map['validityDays'] ??
              map['validity_days'] ??
              map['duration_days'] ?? 30,  // ✅ GOOD: Has fallback
```

**Status**: ✅ **OK** - Flutter model has fallbacks that handle the database column names.

---

## 🎯 sessions/bookings Table Analysis

### Issue: Two Different Tables Exist!

#### 1. `bookings` Table (from migrations/004):
```sql
CREATE TABLE bookings (
  id UUID,
  client_id UUID,
  trainer_id UUID,
  client_package_id UUID,
  session_date TIMESTAMPTZ,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

#### 2. `sessions` Table (from PHASE1_CONFLICT_DETECTION):
```sql
-- Used by book_session_with_validation function
INSERT INTO sessions (
  client_id, trainer_id, package_id,
  scheduled_start, scheduled_end, duration_minutes,
  buffer_start, buffer_end,
  status, session_type, location, client_notes,
  has_conflicts, validation_passed
) VALUES (...);
```

#### Flutter Model Expects (session_model.dart:51-73):
```dart
factory SessionModel.fromSupabaseMap(Map<String, dynamic> map) {
  return SessionModel(
    id: map['id'] ?? '',
    clientId: map['client_id'] ?? '',
    clientName: map['client_name'] ?? 'Unknown',    // ❌ Not in either table
    trainerId: map['trainer_id'] ?? '',
    scheduledDate: map['scheduled_date'] ?? DateTime.now(), // vs bookings.session_date
    durationMinutes: map['duration_minutes'] ?? 60,
    status: SessionStatus.values.firstWhere(...),
    notes: map['notes'],
    clientPackageId: map['client_package_id'],
    createdAt: map['created_at'] ?? DateTime.now(),
    completedAt: map['completed_at'] ?? null,       // ❌ Not in bookings table
  );
}
```

**Problem**: Unclear which table is the primary table for sessions/bookings!

---

## 🚨 **RECOMMENDATION**

### 1. **Standardize on ONE table name**: Choose either `sessions` OR `bookings`
   - Recommendation: Use `sessions` (matches Flutter model name)
   - Rename/migrate `bookings` → `sessions`

### 2. **Fix client_packages immediately** (causing current error):
   ```sql
   -- Quick fix: Add alias columns
   ALTER TABLE client_packages
     ADD COLUMN sessions_used INTEGER
     GENERATED ALWAYS AS (used_sessions) STORED;

   ALTER TABLE client_packages
     ADD COLUMN amount_paid DECIMAL(10,2)
     GENERATED ALWAYS AS (price_paid) STORED;
   ```

### 3. **Add missing columns**:
   ```sql
   ALTER TABLE client_packages
     ADD COLUMN payment_status TEXT DEFAULT 'paid';

   -- For sessions table:
   ALTER TABLE sessions
     ADD COLUMN completed_at TIMESTAMPTZ;
   ```

---

## Next Steps

1. ✅ Run `FIX_BOOKING_COMPLETE.sql` (already created - fixes column names)
2. 🔄 Create `COMPLETE_SCHEMA_SYNC.sql` (comprehensive fix for ALL tables)
3. 📱 Update Flutter models to match OR add database aliases
4. 🧪 Test all CRUD operations

