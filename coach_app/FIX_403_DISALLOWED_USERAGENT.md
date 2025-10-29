# Fix Error 403: disallowed_useragent

## The Error

```
Error 403: disallowed_useragent
```

## What This Means

**Google's Security Policy:**
- Google Sign-In does NOT work in embedded webviews
- Only works in real browsers (Chrome, Safari, Firefox, Edge)
- This protects against OAuth phishing

**You're probably:**
- Using an in-app browser/webview
- Using Flutter's device preview
- Using an embedded browser window
- Not using a real standalone browser

---

## ✅ SOLUTION: Use a Real Browser

### Step 1: Open Your App URL in Chrome/Edge/Safari

**Do NOT open from:**
- ❌ Flutter app's embedded browser
- ❌ Device preview window
- ❌ In-app browser
- ❌ WebView component

**DO open from:**
- ✅ Google Chrome (new window)
- ✅ Microsoft Edge
- ✅ Safari
- ✅ Firefox
- ✅ Any standalone browser

---

## 🚀 Quick Fix

### Method 1: Open in Chrome (Recommended)

```bash
# Windows
start chrome https://tones-dancing-patches-searching.trycloudflare.com

# Or just click this:
```

1. Open **Google Chrome** (not from your app)
2. Type in address bar: `https://tones-dancing-patches-searching.trycloudflare.com`
3. Press Enter
4. Click "Sign in with Google"
5. Should work now!

### Method 2: Copy/Paste URL

1. Copy this URL:
   ```
   https://tones-dancing-patches-searching.trycloudflare.com
   ```

2. Open a **new browser window** (Chrome/Edge/Safari)

3. Paste the URL in the address bar

4. Press Enter

5. Try Google Sign-In again

---

## Why This Happens

### Google's Detection

Google checks the User-Agent header:

**Blocked User-Agents (403 error):**
```
Mozilla/5.0 ... WebView ...
Mozilla/5.0 ... Flutter ...
Mozilla/5.0 ... Embedded ...
```

**Allowed User-Agents (works):**
```
Mozilla/5.0 ... Chrome/120.0 ...
Mozilla/5.0 ... Safari/537.36 ...
Mozilla/5.0 ... Firefox/121.0 ...
Mozilla/5.0 ... Edge/120.0 ...
```

### Why Google Blocks WebViews

**Security Reasons:**
1. **Phishing Protection** - Apps can't intercept OAuth flow
2. **User Trust** - Users see real browser UI
3. **Session Security** - Browser handles cookies properly
4. **Industry Standard** - OAuth best practices

---

## How to Test

### ✅ Correct Way:

1. **Open standalone browser** (Chrome icon on desktop/taskbar)
2. **Type URL** in address bar
3. **Press Enter**
4. **Click "Sign in with Google"**
5. **Should work!**

### ❌ Wrong Way:

1. Click link from app
2. Opens in embedded webview
3. Try Google Sign-In
4. **Error 403!**

---

## If You're Using Flutter Desktop

### The Issue:

Flutter Desktop apps might use embedded webview for OAuth.

### The Fix:

**For Windows:**
```dart
import 'package:url_launcher/url_launcher.dart';

// Open in external browser, not embedded webview
await launchUrl(
  Uri.parse('https://your-auth-url.com'),
  mode: LaunchMode.externalApplication, // ← Important!
);
```

**For Flutter Web:**
Should work automatically since it IS running in a browser.

---

## For iPhone/Mobile Testing

### If Using Physical iPhone:

1. **Open Safari** on iPhone
2. **Type URL**: `https://tones-dancing-patches-searching.trycloudflare.com`
3. **Bookmark it** for easy access
4. **Click "Sign in with Google"**
5. Should work!

### If Using Flutter App on iPhone:

Need to configure Google Sign-In properly:

```dart
// In your flutter app
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile', 'calendar'],
  // Make sure you're using the iOS client ID
  clientId: 'YOUR_IOS_CLIENT_ID',
);
```

---

## Testing Checklist

Before trying Google Sign-In:

- [ ] Using standalone browser (Chrome/Safari/Edge/Firefox)
- [ ] Not using embedded webview or in-app browser
- [ ] URL is correct: https://tones-dancing-patches-searching.trycloudflare.com
- [ ] Added Cloudflare URL to Google OAuth settings
- [ ] Added your email to test users
- [ ] Waited 5 minutes after saving OAuth settings
- [ ] Using incognito mode OR cleared cache

---

## Error Messages Comparison

### Error 400: redirect_uri_mismatch
→ Cloudflare URL not added to OAuth client
→ **Fix:** Add URL to "Authorized redirect URIs"

### Error 403: disallowed_useragent
→ Using webview instead of real browser
→ **Fix:** Open in Chrome/Safari/Edge directly

### Error 403: access_blocked
→ Email not in test users list
→ **Fix:** Add email to "Test users"

### Invalid Origin: cannot contain whitespace
→ Extra spaces in URL
→ **Fix:** Copy from clean text file

---

## Quick Test Right Now

**I'll open it in Chrome for you:**

Run this:
```bash
start chrome https://tones-dancing-patches-searching.trycloudflare.com
```

Or manually:
1. Open Chrome (Ctrl+Shift+N for incognito)
2. Paste: `https://tones-dancing-patches-searching.trycloudflare.com`
3. Click "Sign in with Google"
4. Should work!

---

## For Mobile/iPhone Testing

### Best Approach:

**Don't use embedded webview!**

Use one of these:

1. **Safari on iPhone** (recommended)
   - Open Safari
   - Type the Cloudflare URL
   - Bookmark it
   - Test Google Sign-In

2. **Chrome on iPhone**
   - Open Chrome app
   - Type the Cloudflare URL
   - Test Google Sign-In

3. **Flutter native Google Sign-In**
   - Use `google_sign_in` package
   - Native OAuth (not webview)
   - Requires iOS client ID configured

---

## Summary

**The Problem:**
- You're opening the app in a webview/embedded browser
- Google blocks OAuth in webviews for security

**The Solution:**
- Open the Cloudflare URL in a REAL browser
- Chrome, Safari, Edge, Firefox - any of these
- NOT from an embedded browser window

**How to Test:**
1. Open Chrome manually
2. Type/paste the Cloudflare URL
3. Press Enter
4. Try Google Sign-In
5. Should work now!

---

**Try opening in Chrome right now and test again!**
