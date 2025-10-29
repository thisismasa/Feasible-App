# Google Calendar Sync Issue - Diagnosis & Fix

## Problem Summary
**Users cannot see Google Calendar when booking sessions.**

## Database Analysis Results

### Finding 1: NO Calendar Sync
```
✅ Checked 10 most recent sessions
❌ ALL sessions have google_calendar_event_id = NULL
❌ 0 sessions successfully synced to Google Calendar
```

### Finding 2: All Sessions Cancelled
```
Status: All recent sessions are "cancelled"
Active Sessions: 0 scheduled/confirmed sessions
```

### Finding 3: Users in System
- Trainer: Masa Thomard (masathomardforwork@gmail.com)
- Trainer: Numfon Kaewma (beenarak2534@gmail.com)
- Client: Nuttapon Kaewepsof (nattapon@gmail.com)
- Client: Nadtaporn Koeiftj (nutgaporn@gmail.com)
- Client: Khun Miew (khunmiew@gmail.com)

## Root Cause Analysis

### The Calendar Sync Flow:
```
1. User books session → DatabaseService.bookSession()
2. Session saved to Supabase ✅
3. GoogleCalendarService.createEvent() called
4. ❌ FAILS: User not signed in with Google
5. Returns null (fails silently)
6. Booking succeeds, but google_calendar_event_id remains NULL
```

### Why It Fails:
1. **Google Sign-In not completed**: Users click "Google" button but OAuth fails
2. **Falls back to Demo Mode**: Login screen has fallback to demo (line 1574 in enhanced_login_screen.dart)
3. **No Google access token**: Without OAuth, GoogleCalendarService can't create events
4. **Silent failure**: Code returns null instead of showing error to user

## Current OAuth Configuration

**File**: `web/index.html`
```javascript
OAuth Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
API Key: AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
```

## Solutions

### Option 1: Fix Google OAuth Sign-In (Recommended)

**Step 1**: Verify Google Cloud Console Setup
1. Go to: https://console.cloud.google.com/
2. Select your project
3. Go to **APIs & Services > Credentials**
4. Check OAuth 2.0 Client ID: `576001465184-...`
5. Add authorized JavaScript origins:
   - `http://localhost:8080`
   - `http://localhost:PORT` (whatever port you use)
   - Your production domain
6. Add authorized redirect URIs:
   - `http://localhost:8080/auth/callback`
   - Your production domain + `/auth/callback`

**Step 2**: Enable Google Calendar API
1. In Google Cloud Console
2. Go to **APIs & Services > Library**
3. Search "Google Calendar API"
4. Click **Enable**

**Step 3**: Test Google Sign-In
1. Run your app
2. Click "Google" button on login screen
3. Should see Google OAuth popup
4. Sign in with Google account
5. Grant calendar permissions

**Step 4**: Verify in Browser Console
Open F12 and look for:
```
✅ Google Calendar API initialized
✅ Got access token for web calendar API
✅ Calendar event created: <event-id>
```

If you see errors, that's the issue!

### Option 2: Add Calendar Sync Status to UI

Show users whether calendar sync is working:

**Add to booking screen**:
```dart
// Show calendar sync status
if (googleCalendarEventId != null) {
  Icon(Icons.check_circle, color: Colors.green)
  Text('✓ Synced to Google Calendar')
} else {
  Icon(Icons.warning, color: Colors.orange)
  Text('⚠ Not synced (Sign in with Google to enable)')
}
```

### Option 3: Add "Sign in with Google" Reminder

**Add to booking confirmation**:
```dart
if (eventId == null) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Calendar Sync Not Enabled'),
      content: Text(
        'This session was booked successfully, but could not be added to your Google Calendar.\n\n'
        'To enable calendar sync, please sign in with your Google account.'
      ),
      actions: [
        TextButton(
          child: Text('Sign in with Google'),
          onPressed: () => _handleGoogleSignIn(),
        ),
        TextButton(
          child: Text('Skip'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

## Quick Test

### Test 1: Check Browser Console
1. Open your app
2. Press F12 to open Developer Console
3. Try to book a session
4. Look for these messages:

**If working:**
```
✅ Google Calendar API initialized
📅 Creating calendar event...
✅ Calendar event created: evt_abc123
✅ Synced to Google Calendar: evt_abc123
```

**If failing:**
```
⚠️ Google Calendar unavailable (non-critical)
❌ No access token set
⚠️ Calendar event created but ID not returned
```

### Test 2: Check Google Calendar
1. Go to https://calendar.google.com
2. Look for event: "PT Session - [Client Name]"
3. Should appear at booked time

### Test 3: Check Database
Run this SQL in Supabase:
```sql
SELECT
  id,
  scheduled_start,
  google_calendar_event_id,
  CASE
    WHEN google_calendar_event_id IS NOT NULL THEN '✅ Synced'
    ELSE '❌ Not Synced'
  END as status
FROM sessions
ORDER BY created_at DESC
LIMIT 5;
```

## Expected vs. Actual

### What You Might Be Expecting:
**Option A**: See actual Google Calendar embedded in booking screen
- Shows your real calendar events
- Can pick empty time slots
- Avoids conflicts automatically

### What Currently Happens:
**Option B**: Calendar sync after booking
- Book session with date picker
- Calendar event created in background
- Appears in https://calendar.google.com
- Requires Google Sign-In to work

## Next Steps

**Choose your path:**

1. **If you want calendar sync to work**: Fix Google OAuth (Option 1)
2. **If you want to show Google Calendar IN the booking UI**: This requires additional feature development
3. **If you just want to test**: Use Demo mode (calendar sync disabled)

## Quick Fix to Test Right Now

If you want to test if calendar sync would work, temporarily add this to the booking screen to force Google Sign-In:

```dart
// Before booking
final googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/calendar']);
final account = await googleSignIn.signIn();

if (account == null) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Google Sign-In Required'),
      content: Text('Please sign in with Google to enable calendar sync'),
    ),
  );
  return;
}

// Then proceed with booking...
```

---

## Summary

**The Issue**: Google Calendar events are NOT being created because users are not signed in with Google OAuth.

**The Fix**: Ensure Google OAuth is properly configured and users sign in with Google before booking.

**Status**:
- ❌ 0 / 10 recent sessions synced to Google Calendar
- ✅ Google OAuth client ID configured
- ⚠️ Need to verify OAuth is working
- ⚠️ Need to test Google Sign-In flow

**Impact**: Bookings work fine, but calendar sync is disabled. Users don't see sessions in their Google Calendar.
