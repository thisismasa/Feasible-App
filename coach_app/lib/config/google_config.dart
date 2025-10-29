/// Google Cloud API Configuration
///
/// IMPORTANT SECURITY NOTES:
/// 1. DO NOT commit this file with real credentials to version control
/// 2. Add this file to .gitignore
/// 3. Use environment-specific configuration files
/// 4. For production, use secure key management (e.g., Google Secret Manager)
///
/// Setup Instructions:
/// 1. Go to: https://console.cloud.google.com/apis/credentials
/// 2. Create OAuth 2.0 Client ID for Web Application
/// 3. Create API Key with Calendar API restrictions
/// 4. Replace the placeholder values below with your actual credentials
/// 5. Ensure this file is added to .gitignore

class GoogleConfig {
  /// OAuth 2.0 Client ID for Google Sign-In
  /// Get from: https://console.cloud.google.com/apis/credentials
  static const String oauthClientId =
      '576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com';

  /// Google Calendar API Key
  /// Get from: https://console.cloud.google.com/apis/credentials
  static const String apiKey =
      'AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk';

  /// Validate that credentials are configured
  static bool get isConfigured {
    return oauthClientId.isNotEmpty &&
           !oauthClientId.contains('your-') &&
           apiKey.isNotEmpty &&
           !apiKey.contains('your-');
  }

  /// Get configuration warnings
  static String? getConfigWarning() {
    if (!isConfigured) {
      return 'Google Calendar credentials not configured. Please update lib/config/google_config.dart';
    }
    return null;
  }
}
