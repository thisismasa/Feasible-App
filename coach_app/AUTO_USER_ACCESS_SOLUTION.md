# Automatic User Access Without Manual Email Entry

## Your Question:
"Can my 5 friends access via Google auth without me manually adding their emails to Google Cloud Console?"

## Short Answer:
**Yes! Using a hybrid approach with Supabase database + automated workflows.**

---

## 🎯 The Challenge

**Google's Testing Mode Limitation:**
- Requires manual addition of test users in Google Cloud Console
- You must add each email before they can sign in
- Max 100 users
- Manual process for each new user

**What You Want:**
- Friends can sign in automatically
- No manual email entry in Google Cloud Console
- Database-driven access control
- Auto-approval for trusted users

---

## ✅ SOLUTION 1: Two-Stage OAuth + Supabase Control (Recommended)

### How It Works:

**Stage 1: Initial Sign-In (Email/Profile Only)**
```
User clicks "Sign in with Google"
  ↓
Google OAuth (email + profile scopes only)
  ↓
User info stored in Supabase
  ↓
Check if user is approved in database
  ↓
If approved → Full access
If not approved → Pending screen
```

**Stage 2: Calendar Permissions (After Approval)**
```
Admin approves user in app
  ↓
User requests Calendar access
  ↓
Google OAuth (Calendar scope)
  ↓
Full features unlocked
```

### Database Schema:

```sql
-- Create allowed_users table
CREATE TABLE allowed_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  google_id TEXT,
  display_name TEXT,
  photo_url TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'denied'
  auto_approve_domain TEXT, -- e.g., '@company.com'
  calendar_access BOOLEAN DEFAULT false,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create auto-approval rules
CREATE TABLE auto_approval_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rule_type TEXT NOT NULL, -- 'domain', 'email_pattern', 'invite_code'
  rule_value TEXT NOT NULL,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-approve based on domain
CREATE OR REPLACE FUNCTION auto_approve_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if email matches any auto-approval rules
  IF EXISTS (
    SELECT 1 FROM auto_approval_rules
    WHERE rule_type = 'domain'
    AND NEW.email LIKE '%' || rule_value
  ) THEN
    NEW.status := 'approved';
    NEW.approved_at := NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_approve_user_trigger
  BEFORE INSERT ON allowed_users
  FOR EACH ROW
  EXECUTE FUNCTION auto_approve_user();
```

### App Implementation:

**Modified Login Flow:**

```dart
Future<void> _handleGoogleSignIn() async {
  try {
    // Sign in with Google (email + profile only)
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) return;

    final email = account.email;
    final displayName = account.displayName;
    final photoUrl = account.photoUrl;
    final googleId = account.id;

    // Check/create user in Supabase
    final response = await Supabase.instance.client
        .from('allowed_users')
        .upsert({
          'email': email,
          'google_id': googleId,
          'display_name': displayName,
          'photo_url': photoUrl,
        })
        .select()
        .single();

    final userStatus = response['status'];

    if (userStatus == 'approved') {
      // User is approved - full access
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrainerDashboard(userId: email),
        ),
      );
    } else if (userStatus == 'pending') {
      // Show pending approval screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PendingApprovalScreen(email: email),
        ),
      );
    } else {
      // Denied
      showDialog(/*...*/);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

**Pending Approval Screen:**

```dart
class PendingApprovalScreen extends StatelessWidget {
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Access Pending',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Your account ($email) is pending approval.'),
            SizedBox(height: 10),
            Text('An admin will review your request shortly.'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Check status again
                Navigator.pop(context);
              },
              child: Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Admin Dashboard:**

```dart
class AdminApprovalDashboard extends StatelessWidget {
  Future<void> approveUser(String userId) async {
    await Supabase.instance.client
        .from('allowed_users')
        .update({
          'status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    // Optionally: Send email notification
    // Optionally: Add to Google Cloud test users via API
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client
          .from('allowed_users')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final pendingUsers = snapshot.data as List;

        return ListView.builder(
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user['photo_url']),
              ),
              title: Text(user['display_name']),
              subtitle: Text(user['email']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => approveUser(user['id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => denyUser(user['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

### Auto-Approval Rules:

```dart
// Add auto-approval rule for specific domain
Future<void> addAutoApprovalDomain(String domain) async {
  await Supabase.instance.client
      .from('auto_approval_rules')
      .insert({
        'rule_type': 'domain',
        'rule_value': domain, // e.g., '@yourcompany.com'
      });

  // Anyone with @yourcompany.com email will be auto-approved!
}

// Example: Auto-approve all Gmail addresses
await addAutoApprovalDomain('@gmail.com');

// Example: Auto-approve specific domain
await addAutoApprovalDomain('@feasiblecoaching.com');
```

---

## ✅ SOLUTION 2: Automated Google Cloud Test User Management

### Using Google Cloud API to Add Test Users Programmatically

**⚠️ Limitation:** Google's OAuth Consent Screen API has very limited support for test user management.

**What's Possible:**
- Read current OAuth configuration
- Enable/disable APIs
- Some project settings

**What's NOT Possible:**
- Directly add test users via API
- Publish OAuth consent screen via API
- Modify consent screen settings programmatically

**Workaround Using Service Account:**

```javascript
// Node.js backend service
const { google } = require('googleapis');

async function addTestUserToOAuth(userEmail) {
  try {
    // This is a conceptual approach - actual API support is limited
    const auth = new google.auth.GoogleAuth({
      keyFile: 'service-account-key.json',
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });

    const client = await auth.getClient();
    const iap = google.iap({ version: 'v1', auth: client });

    // Note: This API is for Identity-Aware Proxy, not OAuth Consent Screen
    // There's currently no direct API to add test users to OAuth consent screen

    console.log('Test user management via API is currently not supported');
    console.log('Use database-driven approach instead');

  } catch (error) {
    console.error('Error:', error);
  }
}
```

**Reality:** Google doesn't provide a straightforward API for managing OAuth consent screen test users. The recommended approach is database-driven access control (Solution 1).

---

## ✅ SOLUTION 3: Invite Code System (Best for Limited Access)

### How It Works:

**Generate Invite Codes:**

```dart
// Generate unique invite code
Future<String> generateInviteCode() async {
  final code = Uuid().v4().substring(0, 8).toUpperCase();

  await Supabase.instance.client
      .from('invite_codes')
      .insert({
        'code': code,
        'max_uses': 1,
        'expires_at': DateTime.now().add(Duration(days: 7)),
        'created_by': currentUserId,
      });

  return code;
}

// Share invite code with friend
final inviteLink = 'https://your-app.com/?invite=$code';
```

**User Redeems Invite:**

```dart
Future<void> redeemInviteCode(String code, String userEmail) async {
  // Check if code is valid
  final invite = await Supabase.instance.client
      .from('invite_codes')
      .select()
      .eq('code', code)
      .single();

  if (invite == null || invite['used_count'] >= invite['max_uses']) {
    throw Exception('Invalid or expired invite code');
  }

  // Auto-approve user
  await Supabase.instance.client
      .from('allowed_users')
      .upsert({
        'email': userEmail,
        'status': 'approved',
        'invited_by_code': code,
      });

  // Increment used count
  await Supabase.instance.client
      .from('invite_codes')
      .update({
        'used_count': invite['used_count'] + 1,
      })
      .eq('code', code);
}
```

**Database Schema:**

```sql
CREATE TABLE invite_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  max_uses INTEGER DEFAULT 1,
  used_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE invite_redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL,
  redeemed_by_email TEXT NOT NULL,
  redeemed_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🚀 RECOMMENDED IMPLEMENTATION

### For Your 5 Friends (Quick Setup):

**Option A: Invite Codes (Fastest)**

1. Generate 5 invite codes in your app
2. Send each friend their unique link
3. They click link, sign in with Google
4. Automatically approved via invite code
5. No manual email entry needed!

**Option B: Auto-Approval Domain**

1. Add auto-approval rule for `@gmail.com`
2. Anyone with Gmail can sign in
3. Automatically approved in database
4. Access granted immediately

**Option C: Manual Approval (Most Control)**

1. Friends sign in with Google
2. They see "pending approval" screen
3. You see notification in admin dashboard
4. One-click approve in your app
5. They refresh and get access

---

## 📋 Implementation Steps

### Step 1: Create Database Tables

```bash
# Run in Supabase SQL Editor
cd "Feasible-App/coach_app/supabase"
# I'll create the SQL file for you
```

### Step 2: Modify Sign-In Flow

```bash
# Update lib/screens/enhanced_login_screen.dart
# Add Supabase check after Google sign-in
```

### Step 3: Create Admin Dashboard

```bash
# Create lib/screens/admin_approval_dashboard.dart
# Show pending users, approve/deny buttons
```

### Step 4: Add Invite Code System

```bash
# Create lib/services/invite_code_service.dart
# Generate and validate invite codes
```

---

## 🎯 Which Solution to Use?

| Scenario | Best Solution |
|----------|---------------|
| **5-10 trusted friends** | Invite Codes |
| **Open to anyone you approve** | Manual Approval Dashboard |
| **Specific email domains** | Auto-Approval Rules |
| **Mix of trusted + approval** | Hybrid (Auto + Manual) |

---

## ⚡ Quick Start: Invite Code System

This is perfect for your 5 friends!

**What I'll Create:**
1. SQL migration for invite codes
2. Invite code service
3. Modified login screen
4. Admin page to generate codes

**How It Works:**
```
You: Generate 5 invite codes in app
  ↓
You: Share links with friends
  ↓
Friend: Clicks link, signs in with Google
  ↓
App: Validates invite code, auto-approves user
  ↓
Friend: Gets full access immediately!
```

**No manual email entry needed!**

---

Would you like me to implement the invite code system right now? It's the fastest way to give your 5 friends automatic access!
