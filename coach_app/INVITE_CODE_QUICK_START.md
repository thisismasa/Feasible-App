# Invite Code System - Quick Start Guide

## 🎯 The Solution to Your Problem

**Your Goal:** Let 5 friends access your app via Google auth WITHOUT manually adding their emails to Google Cloud Console.

**The Solution:** Invite Code System using Supabase database.

---

## How It Works

```
Traditional Way (Manual):
  You: Add friend's email to Google Cloud Console
  Friend: Signs in with Google
  Result: Access granted
  Problem: Manual work for each friend

New Way (Automatic):
  You: Generate invite code in database
  You: Send link to friend
  Friend: Clicks link, signs in with Google
  Database: Auto-approves user
  Result: Access granted
  Benefit: Zero manual work!
```

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Install Database Schema

**Run this command:**
```bash
cd Feasible-App/coach_app
SETUP_AUTO_ACCESS.bat
```

**Or manually:**
1. Open: https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
2. Copy contents of `supabase/AUTO_USER_ACCESS_SYSTEM.sql`
3. Paste in SQL Editor
4. Click "Run"
5. Wait for "Success" message

**This creates:**
- `allowed_users` table - Who can access the app
- `invite_codes` table - Generated invite codes
- `auto_approval_rules` table - Automatic approval rules
- `access_log` table - Audit trail
- Helper functions for generating codes

### Step 2: Generate 5 Invite Codes

**Run in Supabase SQL Editor:**
```sql
-- Copy and paste GENERATE_INVITE_CODES.sql
-- Or run these commands:

SELECT generate_invite_code(1, 30, NULL, 'Friend 1');
SELECT generate_invite_code(1, 30, NULL, 'Friend 2');
SELECT generate_invite_code(1, 30, NULL, 'Friend 3');
SELECT generate_invite_code(1, 30, NULL, 'Friend 4');
SELECT generate_invite_code(1, 30, NULL, 'Friend 5');

-- View all codes with links:
SELECT
  code,
  'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code as invite_link,
  expires_at
FROM invite_codes
WHERE used_count < max_uses
ORDER BY created_at DESC;
```

**You'll get output like:**
```
ABC12345 | https://.../?invite=ABC12345 | 2025-11-26
DEF67890 | https://.../?invite=DEF67890 | 2025-11-26
GHI24680 | https://.../?invite=GHI24680 | 2025-11-26
JKL13579 | https://.../?invite=JKL13579 | 2025-11-26
MNO97531 | https://.../?invite=MNO97531 | 2025-11-26
```

### Step 3: Share Links with Friends

**Send each friend their unique link:**
```
Hey! Join my coaching app:
https://tones-dancing-patches-searching.trycloudflare.com/?invite=ABC12345

Just click the link and sign in with Google. You'll get instant access!
```

**That's it!** When they click and sign in, they're automatically approved.

---

## 📱 User Experience

### What Your Friend Sees:

1. **Clicks invite link**
   - Opens your app URL with invite code

2. **Clicks "Sign in with Google"**
   - Standard Google OAuth flow

3. **Sees "unverified app" warning**
   - Clicks "Continue" → "Allow"
   - (Normal for Testing mode)

4. **Automatically approved!**
   - Database validates invite code
   - User status set to "approved"
   - Gets full access immediately

5. **Can use the app**
   - No waiting for approval
   - No "pending" screen
   - Works instantly!

---

## 🔧 How the Database System Works

### Invite Code Redemption Flow:

```sql
-- When user signs in with invite code:

1. User clicks: https://app.com/?invite=ABC12345

2. App calls:
   SELECT redeem_invite_code(
     'ABC12345',          -- invite code
     'friend@gmail.com',  -- their Google email
     '1234567890',        -- Google ID
     'Friend Name',       -- Display name
     'https://photo.url'  -- Photo URL
   );

3. Database validates:
   - Code exists? ✓
   - Not expired? ✓
   - Not max uses? ✓

4. Database auto-approves user:
   INSERT INTO allowed_users (
     email,
     status,  -- Set to 'approved'
     invite_code_used
   ) VALUES (...);

5. Returns success:
   {
     "success": true,
     "user_id": "uuid",
     "status": "approved"
   }

6. User gets access!
```

### Checking User Access:

```sql
-- Check if user has access:
SELECT check_user_access('friend@gmail.com');

-- Returns:
{
  "exists": true,
  "status": "approved",
  "calendar_access": false,
  "display_name": "Friend Name",
  "photo_url": "..."
}
```

---

## 🎨 Alternative: Auto-Approve All Gmail Users

**Want to allow ANY Gmail user without invite codes?**

```sql
-- Run this in Supabase SQL Editor:
INSERT INTO auto_approval_rules (rule_type, rule_value, notes)
VALUES ('domain', '@gmail.com', 'Auto-approve all Gmail users');
```

**Now:**
- Anyone with `@gmail.com` email can sign in
- Automatically approved (no invite code needed)
- Great for open beta testing

**Examples of auto-approval rules:**

```sql
-- Auto-approve specific domain
INSERT INTO auto_approval_rules (rule_type, rule_value)
VALUES ('domain', '@yourcompany.com');

-- Auto-approve email pattern (regex)
INSERT INTO auto_approval_rules (rule_type, rule_value)
VALUES ('email_pattern', '^[a-z]+@gmail\.com$');

-- Auto-approve EVERYONE (use with caution!)
INSERT INTO auto_approval_rules (rule_type, rule_value)
VALUES ('wildcard', '*');
```

---

## 📊 Managing Users

### View Pending Approvals:

```sql
SELECT * FROM pending_approvals;
```

### View Active Invite Codes:

```sql
SELECT * FROM active_invite_codes;
```

### Manually Approve User:

```sql
UPDATE allowed_users
SET status = 'approved',
    approved_at = NOW()
WHERE email = 'user@gmail.com';
```

### Deny User:

```sql
UPDATE allowed_users
SET status = 'denied',
    denied_at = NOW()
WHERE email = 'user@gmail.com';
```

### Generate More Invite Codes:

```sql
SELECT generate_invite_code(
  5,              -- max_uses (this code can be used 5 times)
  30,             -- expires_in_days
  NULL,           -- created_by (your user ID)
  'Beta testers'  -- notes
);
```

---

## 🔐 Security Features

### Invite Code Validation:

- ✅ Unique 8-character codes
- ✅ Expiration dates
- ✅ Max use limits
- ✅ Cannot be reused beyond limit
- ✅ Audit trail in access_log

### Access Control:

- ✅ User must sign in with Google
- ✅ Google provides verified email
- ✅ Database controls approval
- ✅ Row Level Security (RLS) enabled
- ✅ Audit log for all actions

### What This Does NOT Bypass:

- ❌ Google OAuth (still required)
- ❌ Google's "unverified app" warning
- ❌ Testing mode test users requirement

**Wait, what?**

---

## ⚠️ Important Limitation

**You still need to add users to Google Cloud Console test users list!**

Here's why:

1. **Google's Testing Mode Rule:**
   - ANY user signing in must be on test users list
   - Even with invite codes
   - This is a Google requirement, not app limitation

2. **What the Invite System Does:**
   - Manages WHO should have access (your database)
   - Auto-approves users after they sign in
   - Provides better user management than manual
   - Prepares for when you publish to Production

3. **Combined Approach (Best):**

```
You: Generate invite code
You: Send link to friend
You: Also add friend's email to Google Cloud Console test users
Friend: Clicks link, signs in
Google: Checks test users list ✓
Database: Checks invite code ✓
Friend: Gets access!
```

**But wait, isn't this still manual?**

Yes, for Testing mode. BUT:

### Option 1: Use Invite Codes + Testing Mode
- Generate invite codes (database)
- Add same emails to Google Cloud test users (manual)
- Users get instant approval after sign-in
- Better tracking and management

### Option 2: Publish to Production + Invite Codes (Recommended!)
- Remove Google test users requirement
- Only database controls access
- Fully automated invite system
- Requires Google verification (one-time, 2-6 weeks)

---

## 🎯 Recommended Path Forward

### For Immediate Testing (Your 5 Friends):

**Option A: Hybrid (Best for Now)**
1. Generate 5 invite codes in database
2. Get friends' Gmail addresses
3. Add those 5 emails to Google Cloud Console test users
4. Send invite links to friends
5. They sign in and get instant access

**Time:** 5 minutes setup + 2 minutes per friend
**Benefit:** Database tracking, better management

**Option B: Manual Only**
1. Get friends' Gmail addresses
2. Add to Google Cloud Console test users
3. Send them Cloudflare URL
4. They sign in and you approve in app

**Time:** 2 minutes per friend
**Benefit:** Simpler, no database setup

### For Long-Term (100+ Users):

**Publish to Production**
1. Complete Google verification (one-time)
2. Publish OAuth app to Production
3. Now invite code system is fully automatic
4. No more Google Cloud Console test users management
5. Pure database-driven access control

**Time:** 2-6 weeks for verification
**Benefit:** Fully automated, unlimited users

---

## 🚀 Quick Decision Matrix

| Your Situation | Best Approach |
|----------------|---------------|
| **5 friends, need access now** | Invite codes + add to test users |
| **10-50 beta testers** | Auto-approve Gmail + test users |
| **Want to test system** | Set up database, use later |
| **100+ users planned** | Verify & publish to Production |
| **Internal company tool** | Auto-approve company domain |
| **Open beta** | Publish to Production + invite codes |

---

## 📝 Summary

### What You Built:

✅ **Invite Code System**
- Generate unique invite links
- Track who has access
- Auto-approve on sign-in
- Audit trail of access

✅ **Auto-Approval Rules**
- Auto-approve by email domain
- Auto-approve by email pattern
- Flexible rule system

✅ **User Management**
- Pending approvals view
- Manual approve/deny
- Access status checking
- Better than Google Console alone

### What You Still Need:

⚠️ **For Testing Mode:**
- Add users to Google Cloud Console test users
- This is Google's requirement
- Invite system complements this

✅ **For Production Mode:**
- Get Google verification
- Then invite system is fully automatic!
- No more test users management

---

## 🎉 Next Steps

1. **Run setup script:**
   ```bash
   SETUP_AUTO_ACCESS.bat
   ```

2. **Generate 5 invite codes**

3. **Decide your approach:**
   - Quick: Manual test users + invite codes
   - Long-term: Publish to Production

4. **Send links to friends!**

---

**The invite code system is ready. It will be FULLY automatic once you publish to Production mode!**

For now, it provides better tracking and management while you're in Testing mode.
