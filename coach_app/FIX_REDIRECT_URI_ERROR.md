# Fix Error 400: redirect_uri_mismatch

## The Error You're Seeing

```
Error 400: redirect_uri_mismatch
```

**What this means:**
Google is trying to redirect back to:
```
https://tones-dancing-patches-searching.trycloudflare.com
```

But your OAuth client only has:
```
http://localhost:8080
http://localhost:8081
```

**Solution:** Add the Cloudflare URL to BOTH sections!

---

## Quick Fix (1 Minute)

### Step 1: Open OAuth Client

Already open? Good! If not:
```
https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
```

### Step 2: Add to "Authorized JavaScript origins"

1. Scroll to **"Authorized JavaScript origins"** section
2. Click **"+ ADD URI"**
3. Paste: `https://tones-dancing-patches-searching.trycloudflare.com`
4. Press Enter

**Should now have:**
- http://localhost:8080
- http://localhost:8081
- http://127.0.0.1:8080
- http://127.0.0.1:8081
- **https://tones-dancing-patches-searching.trycloudflare.com** ← New!

### Step 3: Add to "Authorized redirect URIs"

1. Scroll to **"Authorized redirect URIs"** section
2. Click **"+ ADD URI"**
3. Paste: `https://tones-dancing-patches-searching.trycloudflare.com`
4. Press Enter

**Should now have:**
- http://localhost:8080
- http://localhost:8081
- **https://tones-dancing-patches-searching.trycloudflare.com** ← New!

### Step 4: SAVE!

1. Scroll to **bottom** of page
2. Click **"SAVE"** button (blue button)
3. Wait for "OAuth client updated" confirmation

### Step 5: Wait 2-5 Minutes

Google needs to propagate the changes.

### Step 6: Test Again

1. Open: https://tones-dancing-patches-searching.trycloudflare.com
2. Press Ctrl+Shift+N (incognito mode)
3. Paste the URL
4. Click "Sign in with Google"
5. Should work now!

---

## Why This Happens

**Cloudflare Tunnel:**
- Your app runs on: `https://tones-dancing-patches-searching.trycloudflare.com`
- This is NOT localhost
- This is a public HTTPS URL

**Google OAuth:**
- Checks: "Is the redirect URI in my list?"
- Your list only has localhost
- Cloudflare URL is NOT in the list
- Result: Error 400: redirect_uri_mismatch

**Fix:**
- Add Cloudflare URL to the allowed list
- Google allows the redirect
- OAuth works!

---

## Exact URLs to Add

Copy these EXACTLY:

```
https://tones-dancing-patches-searching.trycloudflare.com
```

**NOT:**
- ~~http://tones-dancing...~~ (must be HTTPS)
- ~~https://tones-dancing.../~~ (no trailing slash)
- ~~Https://Tones-Dancing...~~ (lowercase only)

**Correct:**
```
https://tones-dancing-patches-searching.trycloudflare.com
```

---

## Screenshot Guide

**"Authorized JavaScript origins" section:**
```
[http://localhost:8080]                                    [X]
[http://localhost:8081]                                    [X]
[http://127.0.0.1:8080]                                    [X]
[http://127.0.0.1:8081]                                    [X]
[https://tones-dancing-patches-searching.trycloudflare.com] [X] ← Add this
                                                    [+ ADD URI]
```

**"Authorized redirect URIs" section:**
```
[http://localhost:8080]                                    [X]
[http://localhost:8081]                                    [X]
[https://tones-dancing-patches-searching.trycloudflare.com] [X] ← Add this
                                                    [+ ADD URI]
```

**Bottom of page:**
```
                                            [CANCEL] [SAVE]
                                                       ↑
                                                Click here!
```

---

## After Saving

You'll see:
```
✓ OAuth 2.0 Client updated
```

**Then wait 2-5 minutes** for Google to update its servers.

---

## Testing

### Method 1: Incognito (Best)
1. Press Ctrl+Shift+N
2. Go to: https://tones-dancing-patches-searching.trycloudflare.com
3. Click "Sign in with Google"
4. Should work!

### Method 2: Clear Cache
1. Press Ctrl+Shift+Delete
2. Clear "Last hour"
3. Go to Cloudflare URL
4. Try again

### Method 3: Revoke Access
1. Go to: https://myaccount.google.com/permissions
2. Remove "coach_app" if exists
3. Go to Cloudflare URL
4. Try again

---

## Still Getting Error?

### Check Exact Error Message

Press F12 in browser, check Console tab:

**If you see:**
```
redirect_uri_mismatch
```
→ Cloudflare URL not added to redirect URIs yet

**If you see:**
```
origin_mismatch
```
→ Cloudflare URL not added to JavaScript origins

**If you see:**
```
access_blocked: This app's request is invalid
```
→ Your email not added to test users

---

## Double-Check Your Settings

### OAuth Consent Screen:
- [ ] Status: "Testing" (not "In production")
- [ ] Test users includes YOUR email
- [ ] Scopes include: email, profile, calendar

### OAuth Client:
- [ ] Authorized JavaScript origins includes Cloudflare URL
- [ ] Authorized redirect URIs includes Cloudflare URL
- [ ] Clicked "SAVE"
- [ ] Waited 5 minutes

### Testing:
- [ ] Using incognito mode OR cleared cache
- [ ] Going to correct Cloudflare URL
- [ ] Clicking "Sign in with Google"

---

## Success Looks Like

1. Click "Sign in with Google"
2. Google account selection screen appears
3. May see "unverified app" warning (normal)
   - Click "Continue" or "Advanced"
4. Permission request screen:
   - View email
   - View profile
   - Access calendar
5. Click "Allow"
6. Redirected to app dashboard
7. Success!

---

**The KEY is adding the Cloudflare URL to BOTH sections and clicking SAVE!**
