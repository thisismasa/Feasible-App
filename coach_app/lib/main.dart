import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart';  // Removed - using Supabase only
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'services/supabase_service.dart';
import 'services/real_supabase_service.dart';
import 'providers/dashboard_provider.dart';
import 'screens/enhanced_login_screen.dart';
import 'screens/biometric_auth_screen.dart';
import 'screens/trainer_dashboard_enhanced.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with real multi-user support
  try {
    debugPrint('⏳ Initializing Supabase...');
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    
    // Initialize services
    await SupabaseService.instance.initialize(); // Demo service
    await RealSupabaseService.instance.initialize(); // Real service
    
    debugPrint('✓ Supabase initialized - Mode: ${SupabaseConfig.isDemoMode ? 'Demo' : 'Real'}');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization error: $e');
    debugPrint('📱 App will run in demo mode');
  }

  // Firebase removed - using Supabase only
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   debugPrint('Firebase initialization error: $e');
  // }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Only in debug mode
      builder: (context) => const CoachApp(),
    ),
  );
}

class CoachApp extends StatelessWidget {
  const CoachApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'PT Coach Dashboard',
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        // Add route generation
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
            case '/login':
              return MaterialPageRoute(builder: (_) => const EnhancedLoginScreen());
            case '/biometric':
              return MaterialPageRoute(builder: (_) => const BiometricAuthScreen());
            case '/dashboard':
              // Get trainer ID from arguments or current user
              final args = settings.arguments as Map<String, dynamic>?;
              final trainerId = args?['trainerId'] as String? ??
                  SupabaseService.instance.currentUser?.id ??
                  'demo-trainer-id';
              return MaterialPageRoute(
                builder: (_) => TrainerDashboardEnhanced(trainerId: trainerId),
              );
            default:
              return MaterialPageRoute(builder: (_) => const EnhancedLoginScreen());
          }
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue[700],
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade200,
            thickness: 1,
          ),
        ),
        initialRoute: '/',
      ),
    );
  }
}

class UserRole {
  static const String trainer = 'trainer';
  static const String client = 'client';
}