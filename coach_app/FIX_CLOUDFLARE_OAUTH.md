# Fix Google OAuth for Cloudflare Tunnel + Multiple Users

## Problem
When using Cloudflare tunnel, Google OAuth shows "Access Blocked" because:
1. Your Cloudflare URL is not in authorized origins
2. Cloudflare URL changes each session (e.g., `https://tones-dancing-patches-searching.trycloudflare.com`)
3. App is in "Testing" mode - only specific emails can sign in
4. Multiple users can't access

## Your Current Cloudflare URL
```
https://tones-dancing-patches-searching.trycloudflare.com
```

---

## Solution 1: Add Cloudflare URL to OAuth (Quick Fix)

### Step 1: Add Current Cloudflare URL to Authorized Origins

1. **Open OAuth Client Settings**:
   ```
   https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
   ```

2. **Scroll to "Authorized JavaScript origins"**

3. **Click "+ ADD URI"** and add:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

4. **Scroll to "Authorized redirect URIs"**

5. **Click "+ ADD URI"** and add:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

6. **Click "SAVE"**

7. **Wait 5 minutes** for changes to propagate

8. **Test** by opening the Cloudflare URL and clicking "Sign in with Google"

### ⚠️ Important: Cloudflare URL Changes
- The free Cloudflare tunnel URL changes every time you restart
- You'll need to update OAuth settings each time (annoying!)
- See Solution 2 for permanent fix

---

## Solution 2: Enable Multiple Users (Recommended!)

This allows ANY Google user to sign in, no matter which Cloudflare URL you use.

### Option A: Publish App to Production (Best for Multiple Users)

1. **Open OAuth Consent Screen**:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. **Check current status** at the top:
   - If it says "Testing" → Continue to step 3
   - If it says "In production" → Already done!

3. **Click "PUBLISH APP"** button at the top

4. **Read the warning**, then click "CONFIRM"

5. **Google will show warning**: "Your app will be available to anyone with a Google Account"

6. **Click "PUBLISH"** to confirm

7. **Result**:
   - ✅ ANY user with Google account can sign in
   - ✅ Works with any Cloudflare URL
   - ✅ No need to add test users
   - ✅ No verification required (for sensitive scopes only)

### Option B: Stay in Testing Mode + Add Test Users

If you want to restrict access to specific users:

1. **Open OAuth Consent Screen**:
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. **Scroll to "Test users"** section

3. **Click "+ ADD USERS"**

4. **Add Gmail addresses** (one per line) for all users who should access:
   ```
   masathomard@gmail.com
   friend1@gmail.com
   friend2@gmail.com
   tester@gmail.com
   ```

5. **Click "SAVE"**

6. **Limit**: Max 100 test users in Testing mode

---

## Solution 3: Use Named Cloudflare Tunnel (Advanced)

Create a permanent Cloudflare tunnel with fixed URL.

### Benefits
- Same URL every time
- Professional domain (e.g., `feasible-app.yourname.com`)
- No need to update OAuth each time
- Free with Cloudflare account

### Setup Steps

1. **Create Cloudflare account** (free):
   ```
   https://dash.cloudflare.com/sign-up
   ```

2. **Login to Cloudflare tunnel**:
   ```bash
   cloudflared tunnel login
   ```

3. **Create named tunnel**:
   ```bash
   cloudflared tunnel create feasible-app
   ```

4. **Create tunnel configuration file**: `cloudflare-tunnel.yml`
   ```yaml
   tunnel: feasible-app
   credentials-file: C:\Users\masathomard\.cloudflared\<tunnel-id>.json

   ingress:
     - hostname: feasible-app.your-domain.com
       service: http://localhost:8080
     - service: http_status:404
   ```

5. **Route DNS to tunnel**:
   ```bash
   cloudflared tunnel route dns feasible-app feasible-app.your-domain.com
   ```

6. **Run tunnel with config**:
   ```bash
   cloudflared tunnel run feasible-app
   ```

7. **Add permanent URL to OAuth**:
   ```
   https://feasible-app.your-domain.com
   ```

---

## Quick Fix Summary

### For RIGHT NOW (Fastest):

**1. Add current Cloudflare URL to OAuth** (5 minutes):
   - Go to: https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
   - Add: `https://tones-dancing-patches-searching.trycloudflare.com` to both sections
   - Save and wait 5 mins

**2. Enable multiple users** (1 minute):
   - Go to: https://console.cloud.google.com/apis/credentials/consent
   - Click "PUBLISH APP" → "CONFIRM"
   - Done! Any Google user can now sign in

### For PERMANENT (Best):
   - Set up named Cloudflare tunnel with custom domain
   - Publish app to production
   - Configure OAuth once with permanent URL

---

## Current OAuth Configuration

**Client ID:**
```
576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
```

**API Key:**
```
AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
```

**Current Authorized Origins:**
- http://localhost:8080
- http://localhost:8081
- http://127.0.0.1:8080
- http://127.0.0.1:8081

**Need to Add:**
- https://tones-dancing-patches-searching.trycloudflare.com

---

## Testing After Fix

### Test Flow:

1. **Open Cloudflare URL** in browser:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

2. **Click "Sign in with Google"**

3. **You should see**:
   - ✅ Google account selection
   - ✅ "coach_app wants to access..."
   - ✅ Permissions list (Calendar, Email, Profile)

4. **Click "Allow"**

5. **Should redirect** to trainer dashboard

6. **Check browser console** (F12) for:
   - ✅ "Successfully signed in with Google!"
   - ✅ Your email displayed

### If Still Blocked:

Check the exact error:
- **"Access blocked: This app's request is invalid"** → Add test user OR publish app
- **"redirect_uri_mismatch"** → Add Cloudflare URL to authorized URIs
- **"origin_mismatch"** → Add Cloudflare URL to authorized JavaScript origins
- **"invalid_client"** → Check Client ID matches in web/index.html

---

## Automation Script

I'll create a helper script that:
1. Detects your current Cloudflare URL
2. Opens Google Cloud Console pages
3. Copies URL to clipboard for easy pasting

Run: `OPEN_OAUTH_CONSOLE.bat`

---

## Recommended Approach

**For Development (Now):**
1. ✅ Publish app to production (allows any Google user)
2. ✅ Add current Cloudflare URL to OAuth
3. ✅ Test with multiple Google accounts

**For Production (Later):**
1. Set up named Cloudflare tunnel with custom domain
2. Configure OAuth with permanent URL
3. Implement proper user management in Supabase
4. Add user roles and permissions

---

## Quick Links

**Google Cloud Console:**
- [OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent) - Publish app here
- [OAuth Client Settings](https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com) - Add Cloudflare URL here

**Your App:**
- Current Cloudflare URL: `https://tones-dancing-patches-searching.trycloudflare.com`

**Cloudflare:**
- [Cloudflare Dashboard](https://dash.cloudflare.com/)
- [Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

---

**Last Updated:** October 27, 2025
**Status:** Cloudflare tunnel running, OAuth needs configuration for multiple users
