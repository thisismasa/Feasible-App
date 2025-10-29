# Testing Mode - User Guide

## For App Users (Beta Testers)

You've been invited to test the Feasible Coach App!

---

## How to Access the App

### Step 1: Make Sure You're Added

The developer needs to add your Gmail address to the test users list. Confirm with them that your email is added.

**Your Gmail address must be on the test users list to access the app.**

### Step 2: Open the App URL

You'll receive a link that looks like:
```
https://[random-name].trycloudflare.com
```

Open this link in your browser (Chrome, Safari, Firefox, etc.)

### Step 3: Click "Sign in with Google"

On the login screen, click the "Sign in with Google" button.

### Step 4: Handle the "Unverified App" Warning

**You will see a warning screen**:

> ⚠️ **This app hasn't been verified by Google**
>
> This app hasn't been verified by Google yet. Only proceed if you know and trust the developer.

**This is NORMAL!** Here's what to do:

1. **Look for "Advanced" or "Continue" link** (may vary by browser)
2. **Click "Advanced"** or **"Continue"**
3. **You'll see**: "Go to [app name] (unsafe)"
4. **Click that link**

### Step 5: Grant Permissions

You'll now see the permission request screen:

> **[App Name] wants to access your Google Account**
>
> This will allow [App Name] to:
> - View and manage events in all your calendars
> - View your email address
> - View your basic profile info

**Click "Allow"**

### Step 6: You're In!

You should now be logged into the app and can start using it!

---

## Why the Warning?

**Q: Is this app unsafe?**

**A:** No! The warning appears because the app is in "Testing" mode. This is normal for apps in development.

**Q: What does "unverified" mean?**

**A:** Google hasn't verified the app yet because it's still in beta testing. Once the app launches publicly, the developer will go through Google's verification process.

**Q: Is it safe to click "Continue"?**

**A:** Yes, if you trust the developer. The app is secure, it's just in testing phase.

**Q: Will I see this warning every time?**

**A:** No! After you allow access once, you won't see the warning again (unless you revoke access).

---

## Troubleshooting

### "Access Blocked: This app's request is invalid"

**Problem:** Your email is not on the test users list.

**Solution:** Contact the developer and ask them to add your Gmail address to the test users list.

### "redirect_uri_mismatch"

**Problem:** The app URL has changed (common with Cloudflare tunnel).

**Solution:** Ask the developer for the updated URL. They may need to update the OAuth configuration.

### "Access Denied"

**Problem:** You clicked "Cancel" or "Deny" instead of "Allow".

**Solution:** Try signing in again and click "Allow" this time.

### Can't See the "Continue" or "Advanced" Link

**Problem:** Browser variation.

**Solution:**
- Look carefully at the warning screen
- May be labeled "Advanced" or "Continue" or "Proceed anyway"
- Usually at the bottom of the warning message
- Try a different browser if you can't find it

---

## What the App Can Access

When you grant permissions, the app can:

✅ **View your email address** - Used for your account
✅ **View your basic profile** - Shows your name and photo
✅ **Access your Google Calendar** - Creates events for your coaching sessions

The app CANNOT:
❌ Send emails on your behalf
❌ Access other Google services (Drive, Photos, etc.)
❌ Access calendars you haven't shared
❌ Modify your Google account settings

---

## Revoking Access

If you want to remove the app's access later:

1. Go to: https://myaccount.google.com/permissions
2. Find the app in your connected apps list
3. Click on it
4. Click "Remove Access"

---

## Privacy

- Your data is protected by Google's OAuth system
- The app only sees what you explicitly allow
- You can revoke access anytime
- Your Google password is never shared with the app

---

## Getting Help

If you encounter issues:

1. **Check your email is on test users list** - Most common issue!
2. **Try incognito/private browsing** - Clears cached OAuth tokens
3. **Try a different browser** - Sometimes helps with UI differences
4. **Contact the developer** - They can help troubleshoot

---

## Expected User Experience

### First Time Sign-In:
1. Click "Sign in with Google"
2. See warning screen (normal!)
3. Click "Continue" or "Advanced"
4. Click "Allow" on permission screen
5. Redirected to app dashboard
6. Start using the app!

### Subsequent Sign-Ins:
1. Click "Sign in with Google"
2. Select your account
3. Immediately logged in (no warnings!)

---

## Technical Details (For Curious Users)

**Why Testing Mode?**
- Allows 100 test users without Google verification
- Perfect for beta testing
- Full functionality, just not publicly published yet

**What's OAuth?**
- Industry standard for secure authorization
- Used by millions of apps
- Your password never shared
- You control access permissions

**Google Verification:**
- Required for public apps with 100+ users
- Takes weeks to complete
- Not needed for testing phase
- Will happen before public launch

---

## Summary

1. ✅ Make sure you're on the test users list
2. ✅ Open the app URL
3. ✅ Click "Sign in with Google"
4. ✅ Click "Continue" on the warning (expected!)
5. ✅ Click "Allow" for permissions
6. ✅ You're in!

**The "unverified app" warning is completely normal for apps in testing!**

---

**Questions?** Contact the developer.

**Last Updated:** October 27, 2025
