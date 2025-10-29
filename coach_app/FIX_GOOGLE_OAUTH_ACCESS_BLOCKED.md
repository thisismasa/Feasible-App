# Fix Google OAuth "Access Blocked" Error

## Problem
When you click "Sign in with Google", you get:
- ❌ "Access blocked: This app's request is invalid"
- ❌ "Access blocked: coach_app has not completed the Google verification process"
- ❌ "Access blocked: You can't sign in to this app because it doesn't comply with Google's OAuth 2.0 policy"

---

## Root Causes & Solutions

### Cause 1: App in "Testing" Mode Without Your Email (MOST COMMON) ⭐

**Why:** When your OAuth app is in "Testing" mode, ONLY emails explicitly added as "test users" can sign in.

**Fix:**

1. Open OAuth Consent Screen:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. Check **"Publishing status"** at the top:
   - If it says **"Testing"** → Continue to step 3
   - If it says **"In production"** → Skip to Cause 2

3. Scroll down to **"Test users"** section

4. Click **"+ ADD USERS"** button

5. **Enter YOUR Gmail address** (the one you're trying to sign in with)
   - Example: `masathomard@gmail.com` or `yourname@gmail.com`

6. Click **"SAVE"**

7. Try signing in again (use incognito mode)

---

### Cause 2: Missing Redirect URIs for Port 8081

**Why:** Your app now runs on port 8081, but Google OAuth only allows port 8080.

**Fix:**

1. Open OAuth Client Configuration:
   ```
   https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
   ```

2. Scroll to **"Authorized JavaScript origins"**

3. Make sure these URIs are listed:
   ```
   http://localhost:8080
   http://localhost:8081
   http://127.0.0.1:8080
   http://127.0.0.1:8081
   ```

4. If missing, click **"+ ADD URI"** and add them one by one

5. Scroll to **"Authorized redirect URIs"**

6. Make sure these are listed:
   ```
   http://localhost:8080
   http://localhost:8081
   ```

7. Click **"SAVE"** at the bottom

---

### Cause 3: Missing Required Scopes

**Why:** Google Calendar API requires specific OAuth scopes.

**Fix:**

1. Go back to OAuth Consent Screen:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. Click **"EDIT APP"** button at the top

3. Click **"NEXT"** until you reach **"Scopes"** page

4. Make sure these scopes are added:

   **User Info Scopes (Required):**
   - ✅ `https://www.googleapis.com/auth/userinfo.email`
   - ✅ `https://www.googleapis.com/auth/userinfo.profile`

   **Calendar Scopes (Required):**
   - ✅ `https://www.googleapis.com/auth/calendar`
   - ✅ `https://www.googleapis.com/auth/calendar.events`

5. If any are missing:
   - Click **"ADD OR REMOVE SCOPES"**
   - Search for "Google Calendar API"
   - Check the required scopes
   - Click **"UPDATE"**

6. Click **"SAVE AND CONTINUE"** through the rest of the wizard

7. Click **"BACK TO DASHBOARD"**

---

### Cause 4: App Domain Not Verified

**Why:** Google requires domain verification for public apps.

**For Development (Recommended):**
Keep your app in "Testing" mode and add yourself as a test user (see Cause 1).

**For Production:**

1. Go to OAuth Consent Screen

2. Click **"PUBLISH APP"**

3. Click **"CONFIRM"**

**⚠️ Warning:** Publishing makes your app available to ANY Google user. Only do this if:
- Your app is ready for production
- You have proper user management
- You understand the security implications

**For development, stay in Testing mode!**

---

## After Making Changes

### Important: Clear OAuth Cache

Google caches OAuth tokens in your browser. You MUST clear cache or use incognito mode:

**Option 1: Use Incognito Mode (Easiest)**
```bash
# Run this command:
powershell.exe -Command "Start-Process chrome -ArgumentList '--incognito','http://localhost:8081'"
```

Or manually:
1. Press `Ctrl + Shift + N` in Chrome
2. Go to `http://localhost:8081`
3. Try signing in with Google

**Option 2: Clear Browser Cache**
1. Press `Ctrl + Shift + Delete` in Chrome
2. Select:
   - ✅ Cookies and other site data
   - ✅ Cached images and files
3. Time range: **Last hour**
4. Click **"Clear data"**
5. Refresh app page
6. Try signing in again

**Option 3: Revoke App Access**
1. Go to: https://myaccount.google.com/permissions
2. Find your app "coach_app"
3. Click **"Remove Access"**
4. Go back to your app
5. Try signing in again (will ask for permissions again)

---

## Testing the Fix

### Test Sign-In Flow

1. Open app in **incognito mode**: http://localhost:8081

2. Click **"Sign in with Google"** button

3. You should see:
   - ✅ Google account selection screen
   - ✅ "coach_app wants to access your Google Account"
   - ✅ List of permissions (Calendar, email, profile)

4. Click **"Allow"**

5. You should be redirected to the app dashboard

6. Check browser console (F12) for:
   - ✅ "Successfully signed in with Google!"
   - ✅ Your email address shown

### If Still Blocked

**Check the exact error message:**

1. When you see "Access blocked", look for:
   - **"app has not completed verification"** → Your app is in Testing mode, add your email as test user (Cause 1)
   - **"redirect_uri_mismatch"** → Add localhost:8081 to authorized URIs (Cause 2)
   - **"invalid_scope"** → Add required Calendar scopes (Cause 3)
   - **"access_denied"** → You clicked "Cancel" or denied permissions

2. Open browser console (F12) → "Console" tab

3. Look for errors starting with:
   - `OAuth error:`
   - `Google sign-in failed:`

4. Share the error message for further help

---

## Quick Checklist

Use this to verify all settings:

### Google Cloud Console - OAuth Consent Screen
- [ ] Publishing status is "Testing" (for development)
- [ ] Your email added to "Test users" list
- [ ] App name set: "coach_app" or your preferred name
- [ ] Support email set
- [ ] Scopes include: email, profile, calendar, calendar.events

### Google Cloud Console - OAuth Client
- [ ] Client ID: `576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r`
- [ ] Application type: Web application
- [ ] Authorized JavaScript origins include: `http://localhost:8081`
- [ ] Authorized redirect URIs include: `http://localhost:8081`

### App Configuration
- [ ] App running on: http://localhost:8081
- [ ] OAuth Client ID in `web/index.html` matches Google Cloud Console
- [ ] API Key in `web/index.html` is valid

### Testing
- [ ] Tested in incognito mode
- [ ] Browser cache cleared
- [ ] Previous app access revoked (if needed)

---

## Common Errors & Solutions

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Access blocked: This app's request is invalid" | Not added as test user | Add email to test users |
| "redirect_uri_mismatch" | Port 8081 not authorized | Add localhost:8081 to authorized origins |
| "invalid_client" | Wrong OAuth Client ID | Check Client ID in web/index.html |
| "access_denied" | User clicked Cancel | Try again, click Allow |
| "unauthorized_client" | Missing scopes | Add Calendar API scopes |
| "admin_policy_enforced" | Workspace admin blocked app | Contact your Google Workspace admin |

---

## Your Current Configuration

**OAuth Client ID:**
```
576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
```

**API Key:**
```
AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
```

**App URL:**
```
http://localhost:8081
```

**Required Scopes:**
- `https://www.googleapis.com/auth/userinfo.email`
- `https://www.googleapis.com/auth/userinfo.profile`
- `https://www.googleapis.com/auth/calendar`
- `https://www.googleapis.com/auth/calendar.events`

---

## Quick Links

**Google Cloud Console:**
- [OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent)
- [OAuth Client Settings](https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com)
- [API Credentials Dashboard](https://console.cloud.google.com/apis/credentials)
- [API Library (Enable APIs)](https://console.cloud.google.com/apis/library)

**Google Account:**
- [Connected Apps & Sites](https://myaccount.google.com/permissions)
- [Security Checkup](https://myaccount.google.com/security-checkup)

**App:**
- [Local App (Port 8081)](http://localhost:8081)
- [Open in Incognito](javascript:window.open('http://localhost:8081','_blank'))

---

## Need More Help?

If you're still blocked after trying all fixes:

1. **Take a screenshot** of the exact error message

2. **Check browser console** (F12 → Console tab) and copy any errors

3. **Verify your email** is in the test users list

4. **Try a different Google account** to test if it's account-specific

5. **Check Google Cloud Console quotas:**
   ```
   https://console.cloud.google.com/apis/api/calendar-json.googleapis.com/quotas
   ```

---

## After OAuth is Working

Once you can sign in successfully:

1. ✅ Test booking a session
2. ✅ Verify Calendar API creates events
3. ✅ Check package sessions decrement
4. ✅ Apply database fixes (see DATABASE_HEALTH_REPORT.md)

---

**Last Updated:** October 27, 2025
**Status:** Testing Mode - Development Only
