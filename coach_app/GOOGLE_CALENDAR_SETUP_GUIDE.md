# Google Calendar Integration - Complete Setup Guide

## Overview
This guide explains how to set up Google Calendar integration so that PT sessions automatically appear in your Google Calendar when booked.

## Features
- ✅ Automatic calendar sync when booking sessions
- ✅ Session details include client name, time, location, and notes
- ✅ Email invitations sent to clients (if email provided)
- ✅ 30-minute and 2-hour reminders
- ✅ Works on both Web and Mobile platforms
- ✅ Automatic cancellation sync

---

## Prerequisites

1. **Google Cloud Project** with Calendar API enabled
2. **OAuth 2.0 Credentials** (Client ID and Client Secret)
3. **Supabase Database** with sessions table configured

---

## Part 1: Database Setup

### Step 1: Run SQL Setup Script

Run the following SQL in your Supabase SQL Editor:

```bash
# Navigate to your project
cd coach_app/supabase

# The SQL file: GOOGLE_CALENDAR_SYNC_SETUP.sql
```

This script will:
- ✅ Add `google_calendar_event_id` column to sessions table
- ✅ Create indexes for performance
- ✅ Create monitoring functions
- ✅ Create sync status views

### Step 2: Verify Database Setup

```sql
-- Check if column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sessions'
  AND column_name = 'google_calendar_event_id';

-- Should return:
-- google_calendar_event_id | text
```

---

## Part 2: Google Cloud Console Setup

### Step 1: Create/Select Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Name it something like "PT Coach Calendar Integration"

### Step 2: Enable Google Calendar API

1. Go to **APIs & Services** > **Library**
2. Search for "Google Calendar API"
3. Click **Enable**

### Step 3: Create OAuth 2.0 Credentials

#### For Web Application:

1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Choose **Web application**
4. Name: "PT Coach Web Client"
5. **Authorized JavaScript origins:**
   ```
   http://localhost:8080
   http://localhost:3000
   https://your-domain.com
   ```
6. **Authorized redirect URIs:**
   ```
   http://localhost:8080
   http://localhost:3000
   https://your-domain.com
   ```
7. Click **Create**
8. **SAVE YOUR CLIENT ID** (you'll need it next)

#### For Mobile (iOS/Android):

1. Create another OAuth client ID
2. Choose **iOS** or **Android**
3. Follow platform-specific instructions
4. Download configuration files

---

## Part 3: Flutter App Configuration

### For Web Platform:

#### Step 1: Update `web/index.html`

Add the Google Sign-In meta tag inside the `<head>` section:

```html
<!DOCTYPE html>
<html>
<head>
  <!-- Existing meta tags -->
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- ADD THIS: Google Sign-In Client ID for Web -->
  <meta name="google-signin-client_id" content="YOUR_ACTUAL_CLIENT_ID_HERE.apps.googleusercontent.com">

  <!-- Rest of your head section -->
</head>
```

**Replace `YOUR_ACTUAL_CLIENT_ID_HERE` with your actual OAuth Client ID from Google Cloud Console!**

#### Step 2: Add Google Platform Script (Optional for enhanced features)

Add before closing `</body>` tag:

```html
<script src="https://apis.google.com/js/platform.js" async defer></script>
```

### For Mobile Platform:

#### iOS Setup:

1. Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>

<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

#### Android Setup:

1. Add to `android/app/build.gradle`:

```gradle
defaultConfig {
    resValue "string", "default_web_client_id", "YOUR_CLIENT_ID.apps.googleusercontent.com"
}
```

---

## Part 4: Testing the Integration

### Step 1: Restart Your App

```bash
# Stop current Flutter instance
# Then restart:
flutter run -d chrome --web-port 8080

# Or for mobile:
flutter run -d <device-id>
```

### Step 2: Book a Test Session

1. **Login** to your trainer account
2. **Select a client** to book for
3. **Choose date and time**
4. **Book the session**
5. **Check console logs** for calendar sync messages:

```
📅 Attempting Google Calendar sync...
✅ Synced to Google Calendar: abc123xyz
   Session will appear in trainer's Google Calendar
```

### Step 3: Verify in Google Calendar

1. Open [Google Calendar](https://calendar.google.com)
2. Look for event titled: **"PT Session - [Client Name]"**
3. Event should include:
   - ✅ Client name
   - ✅ Date and time
   - ✅ Duration
   - ✅ Location (if provided)
   - ✅ Notes (if provided)
   - ✅ Reminders (30 min & 2 hours before)

---

## Part 5: Monitoring & Troubleshooting

### Check Sync Status in Database

```sql
-- View calendar sync status
SELECT * FROM calendar_sync_status
WHERE trainer_id = 'your-trainer-uuid-here'
ORDER BY scheduled_start;

-- Check sync statistics
SELECT * FROM check_calendar_sync_status('your-trainer-uuid-here');

-- Find unsynced sessions
SELECT * FROM get_unsynced_sessions('your-trainer-uuid-here', 10);
```

### Common Issues & Solutions

#### Issue 1: "ClientID not set" Error

**Symptom:** Console shows:
```
⚠️ Google Calendar sync failed: ClientID not set
```

**Solution:**
- Verify you added the meta tag to `web/index.html`
- Make sure you used the correct Client ID
- Restart the Flutter app completely

#### Issue 2: Calendar Sync Skipped on Web

**Symptom:** Sessions book successfully but don't appear in calendar on web

**Solution:**
- Check browser console for errors
- Verify OAuth Client ID is correctly configured
- Try signing out and signing back in
- Check that Calendar API is enabled in Google Cloud Console

#### Issue 3: Permission Denied

**Symptom:** "Access denied" when trying to create calendar event

**Solution:**
- User needs to grant calendar permissions
- Modify `GoogleSignIn` scopes in `lib/services/google_calendar_service.dart`
- Re-authenticate user

#### Issue 4: Events Not Showing in Calendar

**Symptom:** Sync succeeds but events don't appear

**Solution:**
- Check correct Google account is logged in
- Verify event ID is stored in database:
  ```sql
  SELECT id, google_calendar_event_id
  FROM sessions
  WHERE id = 'session-uuid-here';
  ```
- Check if event was created in the correct calendar (should be 'primary')

---

## Part 6: Advanced Features

### Batch Sync Existing Sessions

If you have existing sessions without calendar events, you can batch sync them:

```dart
// In your Flutter app:
final unsyncedSessions = await RealSupabaseService.instance
  .client
  .rpc('get_unsynced_sessions', params: {
    'p_trainer_id': trainerId,
    'p_limit': 50,
  });

// Then create calendar events for each session
for (var session in unsyncedSessions) {
  // Create calendar event...
  // Update database with event ID...
}
```

### Monitor Sync Health

```sql
-- Get sync rate by trainer
SELECT
  trainer_id,
  total_sessions,
  synced_sessions,
  sync_rate || '%' as sync_percentage
FROM check_calendar_sync_status(trainer_id)
WHERE total_sessions > 0
ORDER BY sync_rate DESC;
```

### Automatic Retry for Failed Syncs

Create a background job or scheduled function to retry failed syncs:

```sql
-- Find sessions that need retry (created >5 min ago, not synced)
SELECT * FROM sessions
WHERE google_calendar_event_id IS NULL
  AND status IN ('scheduled', 'confirmed')
  AND created_at < NOW() - INTERVAL '5 minutes'
  AND scheduled_start > NOW()
ORDER BY created_at ASC;
```

---

## Security Best Practices

1. **Never commit OAuth credentials** to version control
2. **Use environment variables** for sensitive data
3. **Implement proper error handling** (already done in code)
4. **Limit API scopes** to only what's needed
5. **Rotate credentials** periodically
6. **Monitor API usage** in Google Cloud Console

---

## API Rate Limits

Google Calendar API has rate limits:
- **Queries per day:** 1,000,000
- **Queries per 100 seconds per user:** 1,000

Our implementation handles this by:
- ✅ Making sync non-blocking (bookings succeed even if sync fails)
- ✅ Caching calendar data when possible
- ✅ Using batch operations for multiple sessions

---

## Summary Checklist

- [ ] Database schema updated with `google_calendar_event_id` column
- [ ] Google Cloud Project created
- [ ] Calendar API enabled
- [ ] OAuth 2.0 credentials created
- [ ] Web: Client ID added to `web/index.html`
- [ ] Mobile: Platform-specific configuration done
- [ ] App restarted with new configuration
- [ ] Test booking created successfully
- [ ] Event appears in Google Calendar
- [ ] Monitoring queries verified

---

## Support

If you encounter issues:

1. **Check console logs** for detailed error messages
2. **Run verification queries** in Supabase SQL Editor
3. **Test with a simple booking** first
4. **Verify all configuration steps** above

## Next Steps

Once calendar sync is working:
- Test cancellation sync (events should be deleted from calendar)
- Test rescheduling (events should be updated in calendar)
- Monitor sync status regularly
- Set up alerts for failed syncs (optional)

---

**Last Updated:** 2025-10-26
**Version:** 1.0
