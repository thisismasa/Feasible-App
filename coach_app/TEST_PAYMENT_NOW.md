# 🧪 TEST PAYMENT FLOW - STEP BY STEP

## ✅ **What Was Fixed:**
1. **payment_service.dart line 139**: Changed `'sessions_used': 0` → `'used_sessions': 0`
2. **Why**: `sessions_used` is a GENERATED column (read-only), `used_sessions` is the real column

---

## 📋 **Pre-Test Checklist:**

### **1. Verify Database (Supabase SQL Editor)**
Run the diagnostic SQL (already in clipboard):
1. Press **Ctrl+V** in Supabase SQL Editor
2. Click **RUN**
3. Check results:
   - ✅ payment_transactions table exists
   - ✅ package_id references `packages` table (NOT client_packages)
   - ✅ client_packages has both `used_sessions` and `sessions_used` columns

**If Issues Found:**
- Copy contents of `QUICK_FIX_PAYMENT.sql`
- Paste in Supabase SQL Editor
- Click RUN

---

## 🎯 **Test Payment Flow:**

### **Step 1: Start App**
```bash
cd "D:\Users\masathomard\Desktop\Feasible APP v.2\Feasible-App\coach_app"
flutter run
```

### **Step 2: Navigate to Payment**
1. Sign in as trainer (masathomardforwork@gmail.com)
2. Go to "New Package Payment" or similar screen
3. Select client: **Poon** (ac6b34af-77e4-41c0-a0de-59ef190fab41)
4. Select package: **10-Session Package** or any available package
5. Select payment method: **PromptPay**

### **Step 3: Complete PromptPay Payment**
1. PromptPay screen shows:
   - QR Code
   - PromptPay ID: 1095535268
   - Amount to pay
   - Instructions
2. Click **"I've Paid"** button
3. Confirmation dialog appears: "Did you complete the payment?"
4. Click **"Yes, I Paid"**

### **Step 4: Check Console Output**

**✅ SUCCESS - You should see:**
```
✅ Payment transaction created: [transaction-id]
📦 Creating new client package...
   Package ID: [package-id]
   Package Name: 10-Session Package
   Session Count: 10
   Price: [price]
✅ Package assigned to client
   Package ID: [client-package-id]
✅ Payment recorded: [transaction-id]
```

**Then:**
- Success dialog: "Payment Recorded!" ✓
- Returns to payment screen
- Client now has active package with sessions

**❌ FAILURE - You would see:**
```
❌ Error assigning package: [error message]
⚠️ Failed to record payment
```

---

## 🔍 **Verify in Database (After Test):**

Run this SQL in Supabase:

```sql
-- Check payment transaction
SELECT * FROM payment_transactions
WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
ORDER BY created_at DESC
LIMIT 1;

-- Check client package
SELECT
  id,
  package_name,
  total_sessions,
  used_sessions,  -- Real column
  sessions_used,  -- Generated alias (should show same as used_sessions)
  remaining_sessions,
  status,
  payment_status
FROM client_packages
WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- 1 new payment_transactions record with status = 'paid'
- 1 new client_packages record with:
  - used_sessions = 0
  - sessions_used = 0 (auto-computed)
  - total_sessions = 10
  - remaining_sessions = 10
  - status = 'active'
  - payment_status = 'paid'

---

## 🎉 **Success Criteria:**
- ✅ No errors in console
- ✅ Payment transaction created in database
- ✅ Client package created in database
- ✅ Success dialog shows
- ✅ Client can now book sessions using this package

---

## ⚠️ **If Still Failing:**
1. Check console error message
2. Run diagnostic SQL again
3. Check if packages table has data (package templates)
4. Check if payment_transactions table has correct foreign key
5. Send me the exact error message
