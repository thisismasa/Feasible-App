# How to Login - IMPORTANT!

## ❌ Wrong Way (What You're Doing)

You're using **Email/Password login**:
- Entering: `masathomardforwork@gmail.com`
- Entering: password
- Clicking: "Sign In to Dashboard"
- **Result:** "Invalid login credentials" error ❌

**Why it fails:**
- You don't have a password-based account in Supabase
- We set up **Google OAuth** login, not email/password
- These are two different authentication methods

---

## ✅ Correct Way (What You Should Do)

Use **Google Sign-In**:

### Step 1: Look at the Bottom Section

Below "Or continue with", you'll see buttons:

- **[G] Google** ← Click THIS one!
- [D] Demo Login
- [Fingerprint] Biometric
- [Face] Face ID

### Step 2: Click the "Google" Button

The button with the "G" logo.

### Step 3: Google OAuth Flow

1. Popup window opens
2. Select: `masathomardforwork@gmail.com`
3. May see "unverified app" warning → Click "Continue"
4. Click "Allow" for permissions
5. Redirects to dashboard
6. ✅ Success!

---

## Visual Guide

```
+----------------------------------+
|       Welcome Back               |
|  Sign in to your training...     |
|                                  |
|  Email: [              ]         | ← DON'T use this
|  Password: [           ]         | ← DON'T use this
|  [Sign In to Dashboard]          | ← DON'T click this
|                                  |
|     Or continue with             |
|                                  |
|  [G Google]  [D Demo]           | ← CLICK "Google"!
|  [🔒 Bio]    [👤 Face]          |
+----------------------------------+
```

---

## Why Google OAuth?

**Google OAuth provides:**
- ✅ Secure authentication (no password storage)
- ✅ Calendar API access (for booking sync)
- ✅ Email and profile info
- ✅ Single sign-on

**Email/Password would need:**
- ❌ Separate account creation
- ❌ Password management
- ❌ Email verification
- ❌ Manual setup in Supabase

---

## Quick Test

1. Refresh the page: `https://notes-injuries-comparing-programming.trycloudflare.com`

2. **IGNORE** the email/password fields

3. **Scroll down** to "Or continue with"

4. **Click** the **"Google"** button (red button with "G")

5. **Sign in** with: `masathomardforwork@gmail.com`

6. **Click "Allow"** when asked for permissions

7. ✅ Should work!

---

## If Google Button Doesn't Work

Make sure you completed OAuth setup:

- [ ] Email added to test users: `masathomardforwork@gmail.com`
- [ ] Cloudflare URL added to "Authorized JavaScript origins"
- [ ] Cloudflare URL added to "Authorized redirect URIs"
- [ ] Clicked "SAVE" in OAuth Client
- [ ] Waited 5 minutes
- [ ] Testing in real browser (Chrome), not webview

URL to add:
```
https://notes-injuries-comparing-programming.trycloudflare.com
```

---

## Summary

**DON'T:** Use email/password login (top section)
**DO:** Click "Google" button (bottom section)

**The Google button is your login method!**
