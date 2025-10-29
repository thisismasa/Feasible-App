# 🚀 Google Calendar Integration - Your Next Steps

## ✅ Completed So Far

1. ✅ **Database Setup** - `google_calendar_event_id` column created
2. ✅ **SQL Functions** - Monitoring and sync functions created
3. ✅ **Flutter Code** - Calendar sync enabled for web & mobile
4. ✅ **web/index.html** - Google Sign-In meta tag added (placeholder)

---

## 📋 What You Need to Do Next

### Option A: Quick Test (Without Google Calendar - For Now)

If you want to test booking functionality **without** calendar sync first:

1. **Book a session** in your app
2. It will work, but show this warning:
   ```
   ⚠️ Google Calendar sync failed: ClientID not set
   💡 To enable Google Calendar on web:
      1. Get OAuth Client ID from Google Cloud Console
      2. Add to web/index.html
   ```
3. Session will be **successfully booked** in database
4. Just won't sync to Google Calendar yet

### Option B: Full Setup (With Google Calendar Working)

Follow these steps to get **complete Google Calendar sync**:

---

## 🔧 Step-by-Step Setup

### Step 1: Get Google OAuth Client ID

#### 1.1 Go to Google Cloud Console
- Visit: https://console.cloud.google.com/
- Create a new project or select existing one
- Name it something like: **"PT Coach Calendar"**

#### 1.2 Enable Calendar API
1. Go to **APIs & Services** → **Library**
2. Search for **"Google Calendar API"**
3. Click **Enable**

#### 1.3 Create OAuth Client ID
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Choose **Web application**
4. Name: **"PT Coach Web Client"**
5. **Authorized JavaScript origins:**
   ```
   http://localhost:8080
   http://localhost:3000
   https://your-production-domain.com
   ```
6. **Authorized redirect URIs:**
   ```
   http://localhost:8080
   https://your-production-domain.com
   ```
7. Click **Create**
8. **COPY YOUR CLIENT ID** - it looks like:
   ```
   123456789-abcdefg.apps.googleusercontent.com
   ```

### Step 2: Update web/index.html

1. Open: `coach_app/web/index.html`
2. Find this line (around line 26):
   ```html
   <meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID_HERE.apps.googleusercontent.com">
   ```
3. Replace `YOUR_GOOGLE_CLIENT_ID_HERE` with your actual Client ID:
   ```html
   <meta name="google-signin-client_id" content="123456789-abcdefg.apps.googleusercontent.com">
   ```

### Step 3: Restart Flutter App

```bash
# In your terminal, press 'q' to quit current app
# Then restart:
cd "Feasible APP v.2/Feasible-App/coach_app"
flutter run -d chrome --web-port 8080
```

### Step 4: Test Calendar Sync

1. **Login** to your trainer account
2. **Book a test session**:
   - Select a client
   - Choose date/time
   - Click "Book Session"

3. **Watch console logs** for:
   ```
   ⏳ Booking session for client: xxx
   ✓ Session booked successfully
   📅 Attempting Google Calendar sync...
   ✅ Synced to Google Calendar: abc123xyz
      Session will appear in trainer's Google Calendar
   ```

4. **Check Google Calendar**:
   - Go to: https://calendar.google.com
   - Look for: **"PT Session - [Client Name]"**
   - Should show: date, time, location, notes

---

## 🔍 Verify Everything is Working

### Check in Database (Supabase SQL Editor)

```sql
-- Run this to see sync status:
SELECT * FROM calendar_sync_status
ORDER BY scheduled_start;

-- Should show sessions with:
-- ✅ Synced (if google_calendar_event_id has a value)
-- ⏳ Not Synced (if google_calendar_event_id is NULL)
```

### Check in Google Calendar

- Events should appear automatically
- Event color: Flame red (#4)
- Reminders: 30 min & 2 hours before
- Client invited (if email provided)

---

## 🐛 Troubleshooting

### Issue: "ClientID not set" Error

**Symptom:**
```
⚠️ Google Calendar sync failed: ClientID not set
```

**Solution:**
1. Verify Client ID is correct in `web/index.html`
2. Make sure you restarted the Flutter app after editing
3. Check there are no extra spaces or quotes in the Client ID

### Issue: "Access Denied" or "Permission Denied"

**Solution:**
1. Make sure Calendar API is enabled in Google Cloud Console
2. Check OAuth consent screen is configured
3. Try signing out and signing back in to grant permissions

### Issue: Sessions Book But Don't Sync

**Symptom:**
- Booking succeeds
- No error shown
- But event doesn't appear in calendar

**Solution:**
1. Check console logs for detailed error
2. Verify you're signed in with the correct Google account
3. Run this SQL to see which sessions didn't sync:
   ```sql
   SELECT * FROM get_unsynced_sessions('your-trainer-id', 10);
   ```

---

## 📊 Monitoring Calendar Sync Health

### Quick Status Check

```sql
-- In Supabase SQL Editor:
SELECT * FROM check_calendar_sync_status('your-trainer-id-uuid-here');

-- Shows:
-- - Total sessions
-- - Synced sessions
-- - Unsynced sessions
-- - Sync rate percentage
```

### Find Unsynced Sessions

```sql
SELECT * FROM get_unsynced_sessions('your-trainer-id-uuid-here', 20);

-- Returns sessions that need manual sync
```

---

## 🎯 Current Status Summary

| Component | Status | Action Needed |
|-----------|--------|---------------|
| Database Schema | ✅ Ready | None |
| SQL Functions | ✅ Created | None |
| Flutter Code | ✅ Updated | None |
| web/index.html | ⚠️ Needs Client ID | **Add your Google OAuth Client ID** |
| Google Cloud Setup | ❌ Not Done | **Create OAuth credentials** |

---

## 💡 Quick Decision Tree

**Do you have a Google Cloud project with Calendar API enabled?**
- ✅ **YES** → Go get OAuth Client ID → Update web/index.html → Restart app → Test
- ❌ **NO** → Follow "Step 1: Get Google OAuth Client ID" above

**Want to test booking without calendar sync first?**
- ✅ **YES** → Just book a session, it will work (with warning)
- ❌ **NO** → Complete all setup steps first

---

## 🎉 Success Checklist

After completing setup, you should have:

- [ ] Google OAuth Client ID created
- [ ] Client ID added to `web/index.html`
- [ ] Flutter app restarted
- [ ] Test session booked
- [ ] Event appears in Google Calendar
- [ ] Console shows "✅ Synced to Google Calendar"
- [ ] Database shows `google_calendar_event_id` populated
- [ ] Sync rate > 90% in monitoring query

---

## 📚 Additional Resources

- **Full Setup Guide**: `GOOGLE_CALENDAR_SETUP_GUIDE.md`
- **Database Setup**: `supabase/GOOGLE_CALENDAR_SYNC_SETUP.sql`
- **Quick Check**: `supabase/QUICK_CALENDAR_CHECK.sql`
- **Google Cloud Console**: https://console.cloud.google.com/

---

## 🆘 Need Help?

1. Check `GOOGLE_CALENDAR_SETUP_GUIDE.md` for detailed troubleshooting
2. Run `QUICK_CALENDAR_CHECK.sql` to verify database setup
3. Check console logs for specific error messages
4. Verify OAuth Client ID is correctly configured

---

**Last Updated:** 2025-10-26
**Your Current Step:** Get Google OAuth Client ID and update web/index.html
