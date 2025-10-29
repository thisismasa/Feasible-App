# Complete OAuth Fix Checklist

## Current Cloudflare URL
```
https://notes-injuries-comparing-programming.trycloudflare.com
```

## ⚠️ MUST Complete ALL Steps Below

### Step 1: OAuth Consent Screen - Add Your Email

1. Go to: https://console.cloud.google.com/apis/credentials/consent

2. **Check "Publishing status"** at top:
   - If "In production" → Click "BACK TO TESTING"
   - Should say "Testing"

3. **Scroll to "Test users"** section

4. **Click "+ ADD USERS"**

5. **Enter YOUR Gmail address**:
   ```
   your-email@gmail.com
   ```

6. **Click "SAVE"**

7. **Verify** your email appears in the list

✅ **Checkpoint:** Your email should be visible in test users list

---

### Step 2: OAuth Client - Add Cloudflare URL

1. Go to: https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

2. **Scroll to "Authorized JavaScript origins"**

3. **Click "+ ADD URI"**

4. **Paste EXACTLY** (no spaces):
   ```
   https://notes-injuries-comparing-programming.trycloudflare.com
   ```

5. **Press Tab** (don't press Space or Enter)

6. **Keep scrolling to "Authorized redirect URIs"**

7. **Click "+ ADD URI"** again

8. **Paste EXACTLY** (same URL):
   ```
   https://notes-injuries-comparing-programming.trycloudflare.com
   ```

9. **Press Tab**

10. **Scroll to bottom** of page

11. **Click "SAVE"** (blue button)

12. **Wait for confirmation**: "OAuth 2.0 Client updated"

✅ **Checkpoint:** Both sections should have the Cloudflare URL

---

### Step 3: Wait 5 Minutes

Google needs time to propagate changes.

**Do NOT test before 5 minutes!**

Set a timer or wait until: [Current time + 5 minutes]

---

### Step 4: Test in Incognito Mode

**Why incognito?** Clears cached OAuth errors

1. **Press Ctrl+Shift+N** (opens incognito Chrome)

2. **Go to**:
   ```
   https://notes-injuries-comparing-programming.trycloudflare.com
   ```

3. **Click "Sign in with Google"**

4. **Select your Google account**

5. **You MAY see**: "This app hasn't been verified by Google"
   - This is NORMAL for Testing mode
   - Click **"Continue"** or **"Advanced"**
   - Then click **"Go to [app name] (unsafe)"**

6. **Permission screen**:
   - "coach_app wants to access your Google Account"
   - Shows: Email, Profile, Calendar
   - Click **"Allow"**

7. **Should redirect** to app dashboard

8. ✅ **SUCCESS!** You're signed in

---

## Common Errors & Fixes

### Error: "Access blocked: This app's request is invalid"

**Cause:** Your email NOT in test users list

**Fix:** Complete Step 1 above

---

### Error: "400: redirect_uri_mismatch"

**Cause:** Cloudflare URL NOT in OAuth client

**Fix:** Complete Step 2 above

---

### Error: "403: disallowed_useragent"

**Cause:** Using embedded webview, not real browser

**Fix:**
- Close any embedded browser windows
- Open in standalone Chrome (not from another app)
- Use incognito: Ctrl+Shift+N

---

### Error: "Invalid Origin: cannot contain whitespace"

**Cause:** Extra spaces when pasting URL

**Fix:**
- Delete the entry
- Copy from here (no spaces):
  ```
  https://notes-injuries-comparing-programming.trycloudflare.com
  ```
- Paste again, press Tab immediately

---

### Error: "Google Sign-In failed" (generic)

**Possible causes:**

1. **Didn't wait 5 minutes after saving**
   - Wait full 5 minutes

2. **Using cached browser session**
   - Use incognito mode (Ctrl+Shift+N)
   - OR clear browser cache (Ctrl+Shift+Delete)

3. **Wrong URL**
   - Make sure using NEW URL:
     `https://notes-injuries-comparing-programming.trycloudflare.com`
   - NOT old URL:
     `https://tones-dancing-patches-searching.trycloudflare.com`

4. **Wrong OAuth Client ID**
   - Should be: `576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com`

---

## Debug: Check Browser Console

If still failing:

1. **Press F12** in Chrome

2. **Click "Console" tab**

3. **Click "Sign in with Google"**

4. **Look for errors** (red text)

Common error messages:
- `popup_closed_by_user` → You closed the popup, try again
- `access_denied` → You clicked "Cancel", try again
- `idpiframe_initialization_failed` → Cookies blocked, enable cookies
- `redirect_uri_mismatch` → URL not in OAuth client
- `access_blocked` → Email not in test users

---

## Final Verification

### Before Testing:

- [ ] App is in "Testing" mode (NOT "In production")
- [ ] Your email is in test users list
- [ ] New Cloudflare URL added to "Authorized JavaScript origins"
- [ ] New Cloudflare URL added to "Authorized redirect URIs"
- [ ] Clicked "SAVE" in OAuth client
- [ ] Waited 5 minutes
- [ ] Using incognito mode (Ctrl+Shift+N)
- [ ] Going to correct URL: https://notes-injuries-comparing-programming.trycloudflare.com

### During Testing:

- [ ] Clicked "Sign in with Google"
- [ ] Google account selection appeared
- [ ] Clicked "Continue" on unverified app warning (if shown)
- [ ] Clicked "Allow" on permission screen
- [ ] Redirected to dashboard
- [ ] No error messages
- [ ] Signed in successfully

---

## Quick Links

**OAuth Consent Screen (Add Email):**
```
https://console.cloud.google.com/apis/credentials/consent
```

**OAuth Client (Add URL):**
```
https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
```

**Your App (Test Here):**
```
https://notes-injuries-comparing-programming.trycloudflare.com
```

**Check Connected Apps:**
```
https://myaccount.google.com/permissions
```

---

## Still Not Working?

1. **Take a screenshot** of the exact error

2. **Check browser console** (F12 → Console)

3. **Verify ALL steps** above completed

4. **Try different browser**

5. **Try different Google account** (if you have one)

---

## What Happens After Success

Once signed in successfully:

1. ✅ Dashboard loads
2. ✅ Your name/photo shows
3. ✅ Can book sessions
4. ✅ Calendar sync works
5. ✅ Full app access

---

**Complete ALL steps above, wait 5 minutes, then test in incognito mode!**
