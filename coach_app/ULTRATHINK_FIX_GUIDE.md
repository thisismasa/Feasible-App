# ULTRATHINK MODE: Fix Google Calendar Sync

## 🎯 GOAL
Make booked sessions automatically appear in https://calendar.google.com

## 🔍 PROBLEM DIAGNOSIS (COMPLETED)

Checked your database directly:
- ❌ 0 out of 10 recent sessions have `google_calendar_event_id`
- ❌ ALL calendar sync attempts failed
- ✅ Bookings work fine (sessions saved to database)
- ❌ Google Calendar events NOT created

**Root Cause**: Users not signed in with Google OAuth

## ✅ FIXES APPLIED

### 1. Enhanced Debugging
Added detailed logging to `google_calendar_service.dart`:
- Shows exact error when calendar sync fails
- Indicates if user is signed in with Google
- Provides solution steps in console

### 2. Created Calendar Sync Banner Widget
File: `lib/widgets/calendar_sync_banner.dart`
- Shows green banner when calendar sync is enabled
- Shows orange banner with "Sign In" button when disabled
- Can be added to any booking screen

### 3. Added Helper Methods
- `isGoogleSignedIn`: Check if user is signed in
- `promptGoogleSignIn()`: Prompt user to sign in with Google
- Better error messages throughout

## 🚀 HOW TO TEST (STEP-BY-STEP)

### Step 1: Open Browser Console
1. Open your app: http://localhost:8080
2. Press **F12** to open Developer Tools
3. Click on **Console** tab
4. Keep this open - you'll see all calendar sync messages here

### Step 2: Sign In with Google
1. On login screen, click **"Google"** button
2. Google OAuth popup should appear
3. Select your Google account
4. Grant calendar permissions
5. Look for in console:
   ```
   ✅ User signed in: your-email@gmail.com
   ✅ Got access token for web calendar API
   ```

**If OAuth fails:**
- Check Google Cloud Console OAuth Client ID
- Verify `http://localhost:8080` is in authorized origins
- Make sure Google Calendar API is enabled

### Step 3: Book a Session
1. Navigate to booking screen
2. Select a client
3. Pick a date and time
4. Click "Book Session"

### Step 4: Watch the Console
You should see these messages:
```
📅 Using WEB-specific calendar implementation
🔍 Checking Google Sign-In status...
✅ User signed in: your-email@gmail.com
✅ Got access token for web calendar API
🚀 Calling web calendar API...
✅ SUCCESS! Calendar event created: abc123xyz
🎉 Check your Google Calendar: https://calendar.google.com
✅ Synced to Google Calendar: abc123xyz
```

**If you see errors instead:**
```
❌ User NOT signed in with Google
💡 SOLUTION: User needs to click "Sign in with Google" button
📍 Calendar sync SKIPPED - booking will still succeed
```
↑ This means you're not signed in with Google OAuth

### Step 5: Verify in Google Calendar
1. Open https://calendar.google.com
2. Find the date you booked
3. You should see: **"PT Session - [Client Name]"**
4. Event should have:
   - Correct date/time
   - Location (if provided)
   - Client as attendee
   - 30-minute reminder

### Step 6: Check Database
Run this in Supabase SQL Editor:
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
WHERE status = 'scheduled'
ORDER BY created_at DESC
LIMIT 5;
```

You should now see `google_calendar_event_id` populated!

## 🎨 OPTIONAL: Add Calendar Sync Banner to Booking Screen

Want users to see calendar sync status?

### Edit: `lib/screens/booking_screen_enhanced.dart`

**Step 1**: Add import at the top:
```dart
import '../widgets/calendar_sync_banner.dart';
```

**Step 2**: Add banner widget after the AppBar, before the booking form:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Book Session'),
    ),
    body: Column(
      children: [
        // Add this line ↓
        const CalendarSyncBanner(),

        // Rest of your booking UI...
        Expanded(
          child: _buildBookingSteps(),
        ),
      ],
    ),
  );
}
```

This will show:
- 🟢 Green banner: "Google Calendar Sync Enabled" (when signed in)
- 🟠 Orange banner: "Sign In" button (when not signed in)

## 🐛 TROUBLESHOOTING

### Issue: "PlatformException: popup_closed_by_user"
**Cause**: User closed OAuth popup
**Fix**: Try signing in again, grant permissions

### Issue: "Google Calendar API not ready"
**Cause**: API not initialized in web/index.html
**Fix**: Already configured! Should work.

### Issue: "No access token set"
**Cause**: User not signed in with Google
**Fix**: Click "Google" button on login screen

### Issue: Calendar events appear in Google Calendar but google_calendar_event_id is NULL
**Cause**: Database update failed after event creation
**Fix**: Check Supabase connection and permissions

### Issue: "Calendar sync SKIPPED - booking will still succeed"
**This is expected!** Calendar sync is optional. Bookings work even if sync fails.

## ✅ SUCCESS CRITERIA

You've successfully fixed it when:
1. ✅ User signs in with Google OAuth (see email in console)
2. ✅ Book a session
3. ✅ Console shows: "✅ SUCCESS! Calendar event created"
4. ✅ Event appears in https://calendar.google.com
5. ✅ Database shows `google_calendar_event_id` populated
6. ✅ No more NULL values for calendar event IDs

## 📊 BEFORE vs AFTER

### BEFORE (Current State)
```
Sessions in database: 10
Calendar sync success: 0 ❌
google_calendar_event_id: NULL (all)
User sees events in Google Calendar: NO
```

### AFTER (Expected State)
```
Sessions in database: 10
Calendar sync success: 10 ✅
google_calendar_event_id: "evt_abc123" (populated)
User sees events in Google Calendar: YES
```

## 🎯 NEXT STEPS

1. **Test now**: Follow Step-by-Step guide above
2. **Check console**: Look for error messages
3. **Report back**: Share what you see in console

If you see errors, paste them here and I'll help fix!

## 🔧 CURRENT GOOGLE OAUTH CONFIG

From `web/index.html`:
```
OAuth Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
API Key: AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
```

Make sure in Google Cloud Console:
1. This OAuth Client ID exists
2. Authorized JavaScript origins: `http://localhost:8080`
3. Google Calendar API is enabled

---

**Ready to test?** Run the app and follow the steps above!

Press **F12** first to see what's happening! 🔍
