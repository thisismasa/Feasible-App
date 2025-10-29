# Google Calendar API Credentials Setup

## Security Best Practices

This app now uses a **secure configuration system** for Google Cloud credentials instead of hardcoding them in source files.

## Current Status

**IMPORTANT:** The credentials are currently stored in `lib/config/google_config.dart` for your convenience, but this file should **NOT be committed to public repositories**.

## Recommended Setup for Production

### Option 1: Environment-Specific Config Files (Recommended)

1. **Add to `.gitignore`:**
   ```
   lib/config/google_config.dart
   .env
   ```

2. **Create Template File:**
   ```dart
   // lib/config/google_config.template.dart
   class GoogleConfig {
     static const String oauthClientId = 'YOUR_OAUTH_CLIENT_ID_HERE';
     static const String apiKey = 'YOUR_API_KEY_HERE';

     static bool get isConfigured =>
       !oauthClientId.contains('YOUR_') && !apiKey.contains('YOUR_');
   }
   ```

3. **Each Developer:**
   - Copy `google_config.template.dart` to `google_config.dart`
   - Fill in their own credentials
   - File stays local (not committed)

### Option 2: Use Flutter Environment Variables

1. **Install flutter_dotenv package:**
   ```bash
   flutter pub add flutter_dotenv
   ```

2. **Create `.env` file:**
   ```
   GOOGLE_OAUTH_CLIENT_ID=your-client-id
   GOOGLE_API_KEY=your-api-key
   ```

3. **Add to `.gitignore`:**
   ```
   .env
   ```

4. **Load in app:**
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   Future main() async {
     await dotenv.load(fileName: ".env");
     runApp(MyApp());
   }
   ```

### Option 3: Google Secret Manager (Production)

For production deployment:

1. **Store credentials in Google Secret Manager**
2. **Access via API:**
   ```dart
   import 'package:googleapis/secretmanager/v1.dart';

   Future<String> getApiKey() async {
     final secretManager = SecretManagerApi(authClient);
     final secret = await secretManager.projects.secrets.versions
       .access('projects/PROJECT_ID/secrets/google-api-key/versions/latest');
     return utf8.decode(base64Decode(secret.payload.data));
   }
   ```

## Getting Your Credentials

### 1. Google Cloud Console Setup

1. Go to: https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Enable **Google Calendar API**

### 2. Create OAuth 2.0 Client ID

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click **"Create Credentials"** → **"OAuth 2.0 Client ID"**
3. Application type: **Web application**
4. Authorized JavaScript origins:
   - `http://localhost:8080` (for development)
   - Your production domain
5. Copy the **Client ID**

### 3. Create API Key

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click **"Create Credentials"** → **"API Key"**
3. Click **"Restrict Key"**:
   - API restrictions: **Google Calendar API**
   - Application restrictions: **HTTP referrers**
   - Add allowed referrers (your domains)
4. Copy the **API Key**

## Current Configuration

The app currently uses these credentials from `lib/config/google_config.dart`:

- **OAuth Client ID:** `576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com`
- **API Key:** `AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk`

**⚠️ Security Warning:**
- These credentials are **publicly visible** in the codebase
- Anyone with these can use your API quota
- Consider rotating these keys and using Option 1, 2, or 3 above

## Web Configuration

The web app (`web/index.html`) now uses **placeholders**:
- `PLACEHOLDER_OAUTH_CLIENT_ID`
- `PLACEHOLDER_API_KEY`

These should be replaced at build time or app startup with values from secure config.

## Verification

Check if credentials are configured:
```dart
if (GoogleConfig.isConfigured) {
  print('✅ Google credentials configured');
} else {
  print('❌ ${GoogleConfig.getConfigWarning()}');
}
```

## Next Steps

1. ✅ Credentials moved to separate config file
2. ✅ HTML file uses placeholders
3. ⏳ **TODO:** Add `lib/config/google_config.dart` to `.gitignore`
4. ⏳ **TODO:** Choose and implement Option 1, 2, or 3 above
5. ⏳ **TODO:** Rotate current credentials if they were exposed in git history

## Git History Cleanup (If Needed)

If credentials were committed to git:

```bash
# Remove sensitive file from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/config/google_config.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: Rewrites history)
git push origin --force --all
```

Then rotate your credentials immediately!
