# Google Cloud Console Setup for Calendar Sync

## 🎯 GOAL
Configure Google Cloud Console to enable Google Calendar API for your app

## 📋 CURRENT CONFIGURATION

From your `web/index.html`:
```
OAuth Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
API Key: AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
```

## 🚀 STEP-BY-STEP SETUP

### Step 1: Access Google Cloud Console

1. Go to: https://console.cloud.google.com/
2. Sign in with your Google account (masathomardforwork@gmail.com)
3. Select your project (or create a new one)

**How to find your project:**
- Look at the top bar, click the dropdown next to "Google Cloud"
- Your project ID might be related to: `576001465184`

### Step 2: Enable Google Calendar API

1. In the left menu, click **"APIs & Services"** → **"Library"**
2. Search for **"Google Calendar API"**
3. Click on it
4. Click **"Enable"** button

**Direct link:**
https://console.cloud.google.com/apis/library/calendar-json.googleapis.com

### Step 3: Configure OAuth Consent Screen

1. Go to **"APIs & Services"** → **"OAuth consent screen"**
2. If not set up, click **"Configure Consent Screen"**
3. Select **"External"** (unless you have Google Workspace)
4. Fill in:
   - App name: **"PT Coach App"** (or your app name)
   - User support email: **masathomardforwork@gmail.com**
   - Developer contact email: **masathomardforwork@gmail.com**
5. Click **"Save and Continue"**

**Add Scopes:**
1. Click **"Add or Remove Scopes"**
2. Search and add:
   - `https://www.googleapis.com/auth/calendar` (Full calendar access)
   - `https://www.googleapis.com/auth/calendar.events` (Events only)
3. Click **"Update"** and **"Save and Continue"**

**Test Users (Important!):**
1. Add test users:
   - **masathomardforwork@gmail.com**
   - **beenarak2534@gmail.com** (your trainer)
   - Any other emails you'll use for testing
2. Click **"Save and Continue"**

### Step 4: Verify OAuth Client ID Configuration

1. Go to **"APIs & Services"** → **"Credentials"**
2. Find your OAuth 2.0 Client ID: `576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r...`
3. Click on it to edit

**Authorized JavaScript origins:**
Add these URLs:
- `http://localhost:8080`
- `http://localhost` (any port)
- Your production domain (if you have one)

**Authorized redirect URIs:**
Add these URLs:
- `http://localhost:8080`
- `http://localhost:8080/auth/callback`
- `http://localhost`

Example:
```
Authorized JavaScript origins:
  http://localhost:8080
  http://localhost:3000
  http://localhost

Authorized redirect URIs:
  http://localhost:8080
  http://localhost:8080/auth/callback
  http://localhost/auth/callback
```

4. Click **"Save"**

### Step 5: Verify API Key

1. In **"APIs & Services"** → **"Credentials"**
2. Find API Key: `AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk`
3. Click on it to edit
4. **API restrictions:**
   - Select **"Restrict key"**
   - Choose **"Google Calendar API"**
5. Click **"Save"**

### Step 6: Check Quotas

1. Go to **"APIs & Services"** → **"Enabled APIs"**
2. Click **"Google Calendar API"**
3. Click **"Quotas"** tab
4. Verify:
   - Queries per day: 1,000,000 (default)
   - Queries per 100 seconds per user: 12,000

Should be plenty for testing!

## ✅ VERIFICATION CHECKLIST

After setup, verify:

- [ ] Google Calendar API is **Enabled**
- [ ] OAuth consent screen is configured
- [ ] Test users are added (at least your email)
- [ ] OAuth Client ID has correct JavaScript origins
- [ ] OAuth Client ID has correct redirect URIs
- [ ] API Key is restricted to Calendar API
- [ ] Scopes include `calendar` and `calendar.events`

## 🧪 TEST THE SETUP

### Test 1: Check OAuth Popup
1. Open your app: http://localhost:8080
2. Click **"Google"** sign-in button
3. **Expected:** Google OAuth popup appears
4. **Expected:** Shows "PT Coach App" wants to access your calendar
5. **Expected:** You can grant permissions

**If it fails:**
- "popup_blocked" → Enable popups for localhost
- "redirect_uri_mismatch" → Check Step 4 above
- "access_denied" → Check OAuth consent screen

### Test 2: Sign In and Book
1. Sign in with Google
2. Open browser console (F12)
3. Book a session
4. Look for in console:
```
✅ User signed in: your-email@gmail.com
✅ Got access token for web calendar API
✅ Calendar event created: abc123
```

### Test 3: Check Google Calendar
1. Go to https://calendar.google.com
2. Find your booked date
3. **Expected:** Event "PT Session - [Client Name]" appears

## 🐛 COMMON ERRORS & FIXES

### Error: "Origin not allowed"
**Fix:** Add `http://localhost:8080` to Authorized JavaScript origins

### Error: "redirect_uri_mismatch"
**Fix:** Add redirect URIs in Step 4

### Error: "Access blocked: This app's request is invalid"
**Fix:** Configure OAuth consent screen (Step 3)

### Error: "This app isn't verified"
**Warning:** Normal for development! Click "Advanced" → "Go to PT Coach App (unsafe)"
This is safe for your own app during testing.

### Error: "Calendar API has not been used"
**Fix:** Enable Google Calendar API (Step 2)

## 📊 EXPECTED OAUTH FLOW

```
User clicks "Sign in with Google"
    ↓
Google OAuth popup opens
    ↓
Shows: "PT Coach App wants to:"
  • See, edit, share, and permanently delete calendars
    ↓
User clicks "Allow"
    ↓
OAuth returns access token
    ↓
App can now create calendar events
```

## 🔍 HOW TO CHECK IF IT'S WORKING

Run this test in browser console after signing in:

```javascript
// Check if Google Sign-In is ready
console.log('Google Sign-In:', window.gapi ? 'Loaded' : 'Not loaded');
console.log('Calendar API:', window.calendarApiReady);
console.log('Access Token:', window.currentAccessToken ? 'Set' : 'Not set');
```

**Expected output:**
```
Google Sign-In: Loaded
Calendar API: true
Access Token: Set
```

## 📝 SUPABASE + GOOGLE CLOUD INTEGRATION

Your Supabase database stores:
- Session data (date, time, client, etc.)
- `google_calendar_event_id` (the Calendar event ID)

Your Google Calendar stores:
- The actual calendar event
- Synced with Supabase via event ID

**Flow:**
1. User books session → Saved to Supabase
2. App calls Google Calendar API → Event created in Google Calendar
3. Event ID returned → Saved to Supabase as `google_calendar_event_id`
4. Now you can update/delete via event ID

## 🎯 WHAT TO DO NOW

1. **Open Google Cloud Console:** https://console.cloud.google.com/
2. **Follow Steps 1-6 above**
3. **Test sign-in** in your app at http://localhost:8080
4. **Report back** what you see!

## 🔗 QUICK LINKS

- Google Cloud Console: https://console.cloud.google.com/
- APIs & Services: https://console.cloud.google.com/apis/dashboard
- OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent
- Credentials: https://console.cloud.google.com/apis/credentials
- Calendar API: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com

---

**Need help?** Share screenshots of any errors you see, and I'll help fix them!
