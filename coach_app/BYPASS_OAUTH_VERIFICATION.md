# Bypass Google OAuth Verification Requirement

## The Problem

When trying to publish your OAuth app to Production, Google shows:

> "Your app requires verification. When you have finished configuring your information, please submit your app for review."

**Why This Happens:**
- Your app uses **Calendar API** (`https://www.googleapis.com/auth/calendar`)
- Calendar is a **sensitive scope** in Google's eyes
- Google requires verification for sensitive scopes in Production mode
- Verification process takes **weeks** and requires:
  - Privacy policy URL
  - Terms of service URL
  - App homepage URL
  - YouTube demo video
  - Detailed justification
  - Domain verification
  - $$$ (sometimes)

---

## ✅ SOLUTION: Use Testing Mode with Multiple Users

**Good News:** You can have up to **100 test users** in Testing mode WITHOUT verification!

This is perfect for:
- Development and testing
- Internal team access
- Beta testing with real users
- Running on Cloudflare tunnel

### How It Works:

**Testing Mode:**
- ✅ No verification required
- ✅ Up to 100 test users
- ✅ Full Calendar API access
- ✅ Works with Cloudflare URLs
- ✅ All features work normally
- ✅ Users just need to be added to test user list

**Production Mode:**
- ❌ Requires verification (weeks of review)
- ❌ Privacy policy required
- ❌ Terms of service required
- ❌ Video demo required
- ❌ Not worth it for testing/internal apps

---

## 🎯 Step-by-Step: Enable Multiple Users (No Verification)

### Step 1: Keep App in Testing Mode

**DO NOT publish to Production!** Keep it in Testing mode.

1. Go to OAuth Consent Screen:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. Verify status shows: **"Testing"** (should already be this)

3. If you accidentally clicked "Publish", click **"BACK TO TESTING"**

### Step 2: Add Test Users (Up to 100)

1. On the OAuth Consent Screen page, scroll to **"Test users"** section

2. Click **"+ ADD USERS"** button

3. Enter Gmail addresses (one per line):
   ```
   masathomard@gmail.com
   friend1@gmail.com
   colleague@gmail.com
   tester1@gmail.com
   tester2@gmail.com
   ```

4. Click **"SAVE"**

5. Repeat until you've added all your users (max 100)

### Step 3: Add Cloudflare URL to OAuth Client

1. Go to OAuth Client Settings:
   ```
   https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
   ```

2. Add to **"Authorized JavaScript origins"**:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

3. Add to **"Authorized redirect URIs"**:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

4. Click **"SAVE"**

5. Wait **5 minutes**

### Step 4: Test with Test Users

1. Share Cloudflare URL with test users:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

2. Test users can now:
   - Open the URL
   - Click "Sign in with Google"
   - Sign in with their Gmail account (that you added)
   - Get full access to your app!

---

## 🚀 Automated Script: Add Test Users

I'll create a script that helps you manage test users easily.

### Quick Commands:

**View current test users:**
```bash
gcloud alpha iap oauth-brands describe <brand-id>
```

**Add test user (manual):**
- Use OAuth Consent Screen web interface
- Much easier than CLI for this

---

## 📊 Testing Mode vs Production Mode

| Feature | Testing Mode | Production Mode |
|---------|-------------|-----------------|
| **Verification Required** | ❌ No | ✅ Yes (weeks) |
| **Max Users** | 100 test users | Unlimited |
| **Privacy Policy** | ❌ Not required | ✅ Required |
| **Terms of Service** | ❌ Not required | ✅ Required |
| **Calendar API Access** | ✅ Full access | ✅ Full access |
| **Cloudflare Tunnel** | ✅ Works | ✅ Works |
| **Setup Time** | 2 minutes | 2-6 weeks |
| **Cost** | Free | Free (but time-consuming) |
| **Best For** | Development, internal, beta | Public apps |

---

## 🔒 Understanding Sensitive Scopes

**Your app requests:**
```
https://www.googleapis.com/auth/calendar
```

This is classified as **SENSITIVE** because:
- Full read/write access to user's calendar
- Can create, modify, delete events
- Access to personal scheduling data
- Privacy implications

**Google's Scope Classifications:**

**Non-sensitive (no verification):**
- `userinfo.email`
- `userinfo.profile`
- `openid`

**Sensitive (requires verification in Production):**
- `calendar` ← Your app uses this
- `gmail.readonly`
- `gmail.send`
- `drive`
- `contacts`

**Restricted (extra verification):**
- `gmail.modify`
- `drive.readonly` (for sensitive files)

---

## 🎯 Recommended Approach

### For Development/Beta Testing (Now):

**Use Testing Mode with Test Users**

✅ **Advantages:**
- No verification needed
- Fast setup (2 minutes)
- Works immediately
- 100 users is plenty for testing
- Full Calendar API access
- Works with Cloudflare

❌ **Limitations:**
- Must manually add each test user
- Max 100 users
- Users see "This app hasn't been verified" warning (but can proceed)

**Perfect for your use case!**

### For Production Launch (Later):

**Go through Google Verification**

✅ **Advantages:**
- Unlimited users
- No "unverified app" warning
- Professional appearance
- Public app store listing (if desired)

❌ **Requirements:**
- Privacy policy (hosted on your domain)
- Terms of service (hosted on your domain)
- App homepage with description
- YouTube demo video showing OAuth flow
- Detailed scope justification
- 2-6 week review process
- Domain verification

**Only do this when ready to launch publicly!**

---

## 🔧 Quick Fix Commands

Run these to automate the setup:

### Add Test Users (Web Interface - Recommended):
```bash
start https://console.cloud.google.com/apis/credentials/consent
```

Then manually add test users in the "Test users" section.

### Add Cloudflare URL (Already Created Script):
```bash
.\OPEN_OAUTH_CONSOLE.bat
```

---

## ⚠️ What Users Will See

### In Testing Mode:

When a test user signs in, they'll see:

1. **Google account selection**
2. **Warning message**:
   > "This app hasn't been verified by Google"
   >
   > "This app hasn't been verified by Google yet. Only proceed if you know and trust the developer."

3. **"Advanced" or "Continue" button** (must click)
4. **Permission request**:
   > "coach_app wants to access your Google Account"
   >
   > - View and manage events in all your calendars
   > - View your email address
   > - View your basic profile info

5. **"Allow" button** (user must click)

6. **Success!** - User is signed in

### The Warning is Normal!

- All apps in Testing mode show this warning
- Users who trust you can click "Continue" → "Allow"
- Once they allow, they won't see the warning again
- This is NOT an error - it's expected behavior

---

## 📝 Managing Test Users

### Adding Users:
- Go to OAuth Consent Screen
- Scroll to "Test users"
- Click "+ ADD USERS"
- Enter Gmail addresses
- Click "SAVE"

### Removing Users:
- Go to OAuth Consent Screen
- Scroll to "Test users"
- Click the "X" next to email to remove
- Click "SAVE"

### Checking Current Users:
- Go to OAuth Consent Screen
- Scroll to "Test users" section
- All current test users are listed

### User Limit:
- **Maximum: 100 test users**
- Includes developer's own email
- Can add/remove as needed
- No limit on how often you change the list

---

## 🚀 Next Steps

### Immediate (2 minutes):

1. **Keep app in Testing mode** (do NOT publish)

2. **Add test users**:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```
   Click "+ ADD USERS" and add Gmail addresses

3. **Add Cloudflare URL**:
   ```
   https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
   ```
   Add to both "Authorized JavaScript origins" and "Authorized redirect URIs"

4. **Wait 5 minutes**

5. **Test with added users**

### Later (when ready for public launch):

1. Create privacy policy page
2. Create terms of service page
3. Create app homepage
4. Record OAuth flow demo video
5. Submit for Google verification
6. Wait 2-6 weeks for approval
7. Publish to Production

---

## 📞 Helper Scripts

I'll create automated scripts to help:

**1. OPEN_OAUTH_CONSOLE.bat**
- Opens OAuth consent screen
- Opens OAuth client settings
- Copies Cloudflare URL to clipboard

**2. ADD_TEST_USER_GUIDE.md**
- Step-by-step guide with screenshots
- Common issues and solutions

**3. TESTING_MODE_GUIDE.md**
- Complete guide to Testing mode
- User experience walkthrough
- FAQ

---

## ❓ FAQ

### Q: Can I have more than 100 test users?
**A:** No, Testing mode has a hard limit of 100 users. For more users, you must go through Google verification and publish to Production.

### Q: Will test users see a warning?
**A:** Yes, they'll see "This app hasn't been verified by Google" but can click "Continue" to proceed. This is normal for Testing mode.

### Q: How long does verification take?
**A:** Typically 2-6 weeks, sometimes longer if Google requests additional information.

### Q: Can I use Testing mode for a long time?
**A:** Yes! Testing mode has no time limit. You can stay in Testing mode indefinitely.

### Q: Do test users need special Google accounts?
**A:** No, any Gmail or Google Workspace account works. Just add their email to the test users list.

### Q: Will Cloudflare tunnel work in Testing mode?
**A:** Yes! Testing mode works perfectly with Cloudflare tunnel. Just add the Cloudflare URL to authorized origins.

---

## ✅ Checklist

Use this to set up Testing mode with multiple users:

### OAuth Consent Screen
- [ ] App is in "Testing" mode (NOT "In production")
- [ ] Test users section shows your email
- [ ] All your testers' emails are added (up to 100)
- [ ] App name is set (e.g., "Feasible Coach App")
- [ ] Support email is set
- [ ] Scopes include: email, profile, calendar

### OAuth Client
- [ ] Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r
- [ ] Authorized JavaScript origins includes Cloudflare URL
- [ ] Authorized redirect URIs includes Cloudflare URL
- [ ] Both localhost URLs are still there (for local testing)
- [ ] Clicked "SAVE"
- [ ] Waited 5 minutes

### Testing
- [ ] Opened Cloudflare URL in browser
- [ ] Clicked "Sign in with Google"
- [ ] Saw "unverified app" warning (expected!)
- [ ] Clicked "Continue" → "Allow"
- [ ] Successfully signed in
- [ ] Calendar sync works
- [ ] Tested with second test user
- [ ] Both users can access

---

## 🎯 Summary

**Don't publish to Production!**

Instead:
1. Keep app in **Testing mode**
2. Add users to **Test users list** (up to 100)
3. Add **Cloudflare URL** to authorized origins
4. Users can access with "unverified app" warning (normal!)
5. Full Calendar API works
6. No verification needed
7. Works indefinitely

**This is the recommended approach for development and beta testing!**

---

**Last Updated:** October 27, 2025
**Status:** Testing Mode - Up to 100 Users
**Verification:** Not Required
