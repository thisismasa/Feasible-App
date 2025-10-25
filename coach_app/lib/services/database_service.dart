import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../services/real_supabase_service.dart';

/// Unified Database Service
/// Automatically uses RealSupabaseService if configured, otherwise works in demo mode
class DatabaseService {
  static DatabaseService? _instance;
  late final RealSupabaseService _realService;
  final bool _isRealMode;

  DatabaseService._()
      : _isRealMode = SupabaseConfig.isRealConfig,
        _realService = RealSupabaseService.instance;

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  bool get isRealMode => _isRealMode;
  bool get isDemoMode => !_isRealMode;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isRealMode) {
      await _realService.initialize();
      debugPrint('✅ Database Service: REAL MODE');
    } else {
      debugPrint('📱 Database Service: DEMO MODE');
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  dynamic get currentUser => _realService.currentUser;

  /// Get current user's ID (works for both real and demo mode)
  String? get currentUserId {
    if (_isRealMode) {
      return _realService.currentUser?.id;
    } else {
      return 'demo-trainer'; // Demo mode fallback
    }
  }

  Future<void> signOut() async {
    if (_isRealMode) {
      await _realService.signOut();
    } else {
      debugPrint('📱 Demo: Sign out');
    }
  }

  // ============================================================================
  // CLIENTS
  // ============================================================================

  /// Get all clients for a trainer
  Future<List<Map<String, dynamic>>> getClientsForTrainer(String trainerId) async {
    if (_isRealMode) {
      // Use real Supabase - returns List<UserModel>
      try {
        final users = await _realService.getClientsForTrainer(trainerId);
        // Convert UserModel list to Map list
        return users.map((user) => user.toJson()).cast<Map<String, dynamic>>().toList();
      } catch (e) {
        debugPrint('❌ Error loading clients: $e');
        // In real mode, return empty list on error (don't show demo data to real users!)
        return [];
      }
    } else {
      // Demo mode - return sample clients
      return _getDemoClients();
    }
  }

  List<Map<String, dynamic>> _getDemoClients() {
    return [
      {
        'id': 'demo-client-1',
        'email': 'john.doe@example.com',
        'full_name': 'John Doe',
        'name': 'John Doe', // Add 'name' for compatibility
        'phone': '+1234567890',
        'role': 'client',
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'demo-client-2',
        'email': 'jane.smith@example.com',
        'full_name': 'Jane Smith',
        'name': 'Jane Smith',
        'phone': '+1234567891',
        'role': 'client',
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': 'demo-client-3',
        'email': 'mike.johnson@example.com',
        'full_name': 'Mike Johnson',
        'name': 'Mike Johnson',
        'phone': '+1234567892',
        'role': 'client',
        'is_active': true,
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
  }

  // ============================================================================
  // PACKAGES
  // ============================================================================

  /// Get client packages
  Future<List<Map<String, dynamic>>> getClientPackages({
    required String clientId,
    String? status,
  }) async {
    if (_isRealMode) {
      return await _realService.getClientPackages(
        clientId: clientId,
        status: status,
      );
    } else {
      return _getDemoPackages(clientId);
    }
  }

  List<Map<String, dynamic>> _getDemoPackages(String clientId) {
    final now = DateTime.now();

    // Return active packages for demo clients
    switch (clientId) {
      case 'demo-client-1':
        return [
          {
            'id': 'cp-1',
            'client_id': 'demo-client-1',
            'package_id': 'demo-pkg-3',
            'purchase_date': now.subtract(const Duration(days: 30)).toIso8601String(),
            'expiry_date': now.add(const Duration(days: 60)).toIso8601String(),
            'total_sessions': 24,
            'sessions_used': 8,
            'remaining_sessions': 16,
            'sessions_remaining': 16, // Alias for compatibility
            'status': 'active',
            'is_recurring': false,
          },
        ];
      case 'demo-client-2':
        return [
          {
            'id': 'cp-2',
            'client_id': 'demo-client-2',
            'package_id': 'demo-pkg-2',
            'purchase_date': now.subtract(const Duration(days: 20)).toIso8601String(),
            'expiry_date': now.add(const Duration(days: 40)).toIso8601String(),
            'total_sessions': 16,
            'sessions_used': 6,
            'remaining_sessions': 10,
            'sessions_remaining': 10,
            'status': 'active',
            'is_recurring': false,
          },
        ];
      case 'demo-client-3':
        return [
          {
            'id': 'cp-3',
            'client_id': 'demo-client-3',
            'package_id': 'demo-pkg-1',
            'purchase_date': now.subtract(const Duration(days: 10)).toIso8601String(),
            'expiry_date': now.add(const Duration(days: 20)).toIso8601String(),
            'total_sessions': 8,
            'sessions_used': 2,
            'remaining_sessions': 6,
            'sessions_remaining': 6,
            'status': 'active',
            'is_recurring': false,
          },
        ];
      default:
        // New clients or unknown clients start with NO packages
        // Trainer assigns packages based on client request
        return [];
    }
  }

  /// Get available packages from trainer
  Future<List<Map<String, dynamic>>> getAvailablePackages({
    required String trainerId,
  }) async {
    if (_isRealMode) {
      return await _realService.getAvailablePackages(trainerId: trainerId);
    } else {
      return _getDemoAvailablePackages();
    }
  }

  List<Map<String, dynamic>> _getDemoAvailablePackages() {
    return [
      {
        'id': 'demo-pkg-1',
        'name': 'Starter Package',
        'description': 'Perfect for beginners',
        'total_sessions': 8,
        'duration_per_session': 60,
        'price': 299.99,
        'validity_days': 30,
        'is_active': true,
      },
      {
        'id': 'demo-pkg-2',
        'name': 'Pro Package',
        'description': 'For serious athletes',
        'total_sessions': 16,
        'duration_per_session': 60,
        'price': 499.99,
        'validity_days': 60,
        'is_active': true,
      },
      {
        'id': 'demo-pkg-3',
        'name': 'Elite Package',
        'description': 'Maximum results',
        'total_sessions': 24,
        'duration_per_session': 90,
        'price': 899.99,
        'validity_days': 90,
        'is_active': true,
      },
    ];
  }

  /// Purchase a package
  Future<String> purchasePackage({
    required String clientId,
    required String trainerId,
    required String packageId,
    required double pricePaid,
    String paymentMethod = 'cash',
    String paymentStatus = 'paid',
    String? notes,
  }) async {
    if (_isRealMode) {
      return await _realService.purchasePackage(
        clientId: clientId,
        trainerId: trainerId,
        packageId: packageId,
        pricePaid: pricePaid,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        notes: notes,
      );
    } else {
      debugPrint('📱 Demo: Package purchased');
      return 'demo-client-package-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ============================================================================
  // SESSIONS & BOOKING
  // ============================================================================

  /// Book a session
  Future<Map<String, dynamic>> bookSession({
    required String clientId,
    required String trainerId,
    required DateTime scheduledDate,
    required int durationMinutes,
    required String packageId,
    String sessionType = 'in_person',
    String? location,
    String? notes,
  }) async {
    if (_isRealMode) {
      return await _realService.bookSession(
        clientId: clientId,
        trainerId: trainerId,
        scheduledDate: scheduledDate,
        durationMinutes: durationMinutes,
        packageId: packageId,
        sessionType: sessionType,
        location: location,
        notes: notes,
      );
    } else {
      debugPrint('📱 Demo: Session booked');
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
      return {
        'success': true,
        'session_id': 'demo-session-${DateTime.now().millisecondsSinceEpoch}',
        'remaining_sessions': 11,
      };
    }
  }

  /// Get available time slots
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String trainerId,
    required DateTime date,
    int durationMinutes = 60,
  }) async {
    if (_isRealMode) {
      return await _realService.getAvailableSlots(
        trainerId: trainerId,
        date: date,
        durationMinutes: durationMinutes,
      );
    } else {
      return _getDemoTimeSlots(date, durationMinutes);
    }
  }

  List<Map<String, dynamic>> _getDemoTimeSlots(DateTime date, int duration) {
    final slots = <Map<String, dynamic>>[];
    final startHour = 6;
    final endHour = 21;

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
        final isAvailable = slotTime.isAfter(DateTime.now().add(const Duration(hours: 2)));

        slots.add({
          'slot_time': slotTime.toIso8601String(),
          'is_available': isAvailable,
          'conflict_reason': isAvailable ? null : 'Too soon (2h minimum)',
        });
      }
    }

    return slots;
  }

  /// Get sessions for trainer
  Future<List<Map<String, dynamic>>> getTrainerSessions({
    required String trainerId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    if (_isRealMode) {
      return await _realService.getTrainerSessions(
        trainerId: trainerId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
    } else {
      return _getDemoSessions();
    }
  }

  /// Get sessions for client
  Future<List<Map<String, dynamic>>> getClientSessions({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_isRealMode) {
      return await _realService.getClientSessions(
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      return _getDemoSessions();
    }
  }

  List<Map<String, dynamic>> _getDemoSessions() {
    final now = DateTime.now();
    return [
      {
        'id': 'demo-session-1',
        'client_id': 'demo-client-1',
        'client_name': 'John Doe',
        'scheduled_date': now.add(const Duration(hours: 2)).toIso8601String(),
        'duration_minutes': 60,
        'status': 'scheduled',
        'session_type': 'in_person',
        'location': 'Main Gym',
      },
      {
        'id': 'demo-session-2',
        'client_id': 'demo-client-2',
        'client_name': 'Jane Smith',
        'scheduled_date': now.add(const Duration(days: 1)).toIso8601String(),
        'duration_minutes': 60,
        'status': 'scheduled',
        'session_type': 'online',
      },
    ];
  }

  /// Cancel a session
  Future<Map<String, dynamic>> cancelSession({
    required String sessionId,
    required String cancelledBy,
    String? reason,
    bool refundSession = true,
  }) async {
    if (_isRealMode) {
      return await _realService.cancelSession(
        sessionId: sessionId,
        cancelledBy: cancelledBy,
        reason: reason,
        refundSession: refundSession,
      );
    } else {
      debugPrint('📱 Demo: Session cancelled');
      return {
        'success': true,
        'refunded': refundSession,
        'hours_notice': 24.0,
      };
    }
  }

  /// Update session status
  Future<void> updateSessionStatus({
    required String sessionId,
    required String status,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? actualDurationMinutes,
    String? notes,
  }) async {
    if (_isRealMode) {
      await _realService.updateSessionStatus(
        sessionId: sessionId,
        status: status,
        actualStartTime: actualStartTime,
        actualEndTime: actualEndTime,
        actualDurationMinutes: actualDurationMinutes,
        notes: notes,
      );
    } else {
      debugPrint('📱 Demo: Session status updated to $status');
    }
  }

  // ============================================================================
  // EXERCISE LOGGING
  // ============================================================================

  /// Log an exercise
  Future<void> logExercise({
    required String sessionId,
    required String clientId,
    required String exerciseName,
    int? sets,
    int? reps,
    double? weight,
    int? durationSeconds,
    double? distanceMeters,
    String? notes,
  }) async {
    if (_isRealMode) {
      await _realService.logExercise(
        sessionId: sessionId,
        clientId: clientId,
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        weight: weight,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        notes: notes,
      );
    } else {
      debugPrint('📱 Demo: Exercise logged - $exerciseName');
    }
  }

  /// Get session exercises
  Future<List<Map<String, dynamic>>> getSessionExercises({
    required String sessionId,
  }) async {
    if (_isRealMode) {
      return await _realService.getSessionExercises(sessionId: sessionId);
    } else {
      return [
        {
          'exercise_name': 'Bench Press',
          'sets': 3,
          'reps': 10,
          'weight': 80.0,
        },
        {
          'exercise_name': 'Squats',
          'sets': 3,
          'reps': 12,
          'weight': 100.0,
        },
      ];
    }
  }

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (_isRealMode) {
      try {
        final user = await _realService.getUserProfile(userId);
        return user?.toJson();
      } catch (e) {
        debugPrint('Error getting user profile: $e');
        return null;
      }
    } else {
      return {
        'id': userId,
        'email': 'demo@example.com',
        'full_name': 'Demo User',
        'name': 'Demo User',
        'role': 'trainer',
        'phone': '+1234567890',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };
    }
  }

  /// Create a new client
  Future<String> createClient({
    required String email,
    required String fullName,
    required String phone,
    required String trainerId,
    String? notes,
  }) async {
    if (_isRealMode) {
      // In real mode, this would create user account and assign to trainer
      // For now, simplified - you may want to implement invitation system

      String clientId;

      try {
        // Try to insert new user
        debugPrint('💾 Saving client to database: $fullName');
        final response = await _realService.client.from('users').insert({
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': 'client',
          'is_active': true,
        }).select().single();

        clientId = response['id'] as String;
        debugPrint('✅ New client created with ID: $clientId');
      } catch (e) {
        // If user already exists (duplicate email), get their ID
        debugPrint('⚠️ User might already exist, checking: $e');
        final existing = await _realService.client
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (existing != null) {
          clientId = existing['id'] as String;
          debugPrint('📝 Using existing user ID: $clientId');
        } else {
          // If we can't find existing user, rethrow original error
          debugPrint('❌ Failed to create or find client');
          rethrow;
        }
      }

      // Assign to trainer (handles duplicates internally)
      await _realService.assignClientToTrainer(clientId, trainerId);

      return clientId;
    } else {
      debugPrint('📱 Demo: Client created - $fullName');
      return 'demo-client-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ============================================================================
  // BOOKING MANAGEMENT
  // ============================================================================

  /// Get today's scheduled sessions for a trainer
  Future<List<Map<String, dynamic>>> getTodaySchedule(String trainerId) async {
    if (_isRealMode) {
      return await _realService.getTodaySchedule(trainerId);
    } else {
      debugPrint('📱 Demo: Getting today schedule');
      return [];
    }
  }

  /// Get upcoming sessions for a trainer
  Future<List<Map<String, dynamic>>> getUpcomingSessions(
    String trainerId, {
    int limit = 50,
  }) async {
    if (_isRealMode) {
      return await _realService.getUpcomingSessions(trainerId, limit: limit);
    } else {
      debugPrint('📱 Demo: Getting upcoming sessions');
      return [];
    }
  }

  /// Get weekly calendar view for a trainer
  Future<List<Map<String, dynamic>>> getWeeklyCalendar(String trainerId) async {
    if (_isRealMode) {
      return await _realService.getWeeklyCalendar(trainerId);
    } else {
      debugPrint('📱 Demo: Getting weekly calendar');
      return [];
    }
  }

  /// Cancel a session with reason (simple version for booking management)
  Future<void> cancelSessionSimple(String sessionId, String reason) async {
    if (_isRealMode) {
      await _realService.cancelSessionWithReason(sessionId, reason);
    } else {
      debugPrint('📱 Demo: Cancelling session $sessionId');
    }
  }

  // ============================================================================
  // RAW SUPABASE ACCESS (for advanced usage)
  // ============================================================================

  /// Get raw Supabase client (only in real mode)
  dynamic get rawClient => _isRealMode ? _realService.client : null;
}
