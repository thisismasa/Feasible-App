# Final Test Guide - Google Auth

## ✅ Step 1: DONE
- Email added: `masathomardforwork@gmail.com` ✓

## 🔄 Step 2: Verify OAuth Client URL

Go back to the OAuth Client page and verify:

**Check "Authorized JavaScript origins":**
- Should include: `https://notes-injuries-comparing-programming.trycloudflare.com`

**Check "Authorized redirect URIs":**
- Should include: `https://notes-injuries-comparing-programming.trycloudflare.com`

**If not added yet:**
1. Click "+ ADD URI" in both sections
2. Paste: `https://notes-injuries-comparing-programming.trycloudflare.com`
3. Click "SAVE" at bottom
4. Wait for confirmation

## ⏱️ Step 3: Wait 5 Minutes

Google needs time to propagate changes.

**Set timer for 5 minutes from when you clicked SAVE.**

## 🧪 Step 4: Test (After 5 Minutes)

### Open Incognito Mode:
```
Press: Ctrl + Shift + N
```

### Go to Your App:
```
https://notes-injuries-comparing-programming.trycloudflare.com
```

### Click "Sign in with Google"

### Expected Flow:

1. **Google account selection**
   - Select: `masathomardforwork@gmail.com`

2. **"This app hasn't been verified" warning** (Normal!)
   - Click: **"Continue"** or **"Advanced"**
   - Then: **"Go to coach_app (unsafe)"**

3. **Permission screen**
   - "coach_app wants to access your Google Account"
   - Permissions: Email, Profile, Calendar
   - Click: **"Allow"**

4. **Success!**
   - Should redirect to dashboard
   - You're signed in!

## ✅ Success Indicators

- Dashboard loads
- Your name shows in app
- No error messages
- Can navigate the app

## ❌ If Still Fails

### Check exact error:

1. Press **F12** in Chrome
2. Click **"Console"** tab
3. Try sign-in again
4. Look for error messages (red text)

### Common errors:

**"access_blocked"**
→ Email not saved properly. Check test users list again.

**"redirect_uri_mismatch"**
→ URL not in OAuth client. Add it to BOTH sections.

**"popup_closed_by_user"**
→ You closed the popup. Try again, don't close it.

**"idpiframe_initialization_failed"**
→ Cookies blocked. Enable cookies in Chrome settings.

## 📞 Debug Info

**Your Configuration:**
- Email: `masathomardforwork@gmail.com`
- App URL: `https://notes-injuries-comparing-programming.trycloudflare.com`
- OAuth Client ID: `576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r`
- Status: Testing mode

**What Should Be Set:**
- Test users: ✓ `masathomardforwork@gmail.com`
- JavaScript origins: `https://notes-injuries-comparing-programming.trycloudflare.com`
- Redirect URIs: `https://notes-injuries-comparing-programming.trycloudflare.com`

---

**After verifying Step 2, wait 5 minutes, then test in incognito mode!**
