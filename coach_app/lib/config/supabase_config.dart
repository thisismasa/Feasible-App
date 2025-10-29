class SupabaseConfig {
  // Real Supabase Configuration - Flutter App, Feasible
  // ✅ CONFIGURED - Production Ready!
  static const String supabaseUrl = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

  // Note: This is the publishable (anon) key - safe to use in Flutter app
  // Protected by Row Level Security (RLS) policies in Supabase
  
  // Google OAuth configuration
  static const String googleWebClientId = '576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com';
  static const String googleIosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID'; // Not needed for web app
  
  // Realtime channel names
  static const String sessionsChannel = 'sessions-channel';
  static const String clientsChannel = 'clients-channel';
  static const String metricsChannel = 'metrics-channel';
  static const String chatChannel = 'chat-channel';
  static const String notificationsChannel = 'notifications-channel';
  
  /// Check if Supabase is properly configured with real credentials
  static bool get isRealConfig {
    return supabaseUrl != 'https://demo-project.supabase.co' &&
           supabaseAnonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo-key' &&
           supabaseUrl.contains('.supabase.co') &&
           supabaseAnonKey.length > 50;
  }
  
  /// Demo mode flag
  static bool get isDemoMode => !isRealConfig;
}