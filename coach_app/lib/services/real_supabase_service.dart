import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import 'google_calendar_service.dart';

/// Real Supabase Service for Multi-User Authentication
/// Supports: Registration, Login, Profile Management, Real-time Data
class RealSupabaseService {
  static RealSupabaseService? _instance;
  late final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;
  
  // Timeout configuration
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _authTimeout = Duration(seconds: 15);
  
  // Initialization tracking
  bool _isInitialized = false;
  
  RealSupabaseService._();
  
  static RealSupabaseService get instance {
    _instance ??= RealSupabaseService._();
    return _instance!;
  }
  
  SupabaseClient get client => _supabase;
  bool get isInitialized => _isInitialized;
  
  /// Check if Supabase is properly configured
  bool get isConfigured => SupabaseConfig.isRealConfig;
  bool get isDemoMode => SupabaseConfig.isDemoMode;
  
  /// Initialize Supabase with real configuration
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✓ Supabase already initialized');
      return;
    }
    
    try {
      debugPrint('⏳ Initializing Supabase...');
      
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(
        _defaultTimeout,
        onTimeout: () {
          throw TimeoutException('Supabase initialization timeout');
        },
      );
      
      _supabase = Supabase.instance.client;
      
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      _isInitialized = true;
      debugPrint('✓ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // Don't rethrow - app can work in demo mode
    }
  }
  
  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================
  
  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// Sign up new user with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    if (isDemoMode) {
      throw Exception('Demo Mode: Use demo login instead');
    }
    
    _validateEmail(email);
    _validatePassword(password);
    _validateNonEmpty(fullName, 'Full name');
    
    try {
      debugPrint('⏳ Creating user account: $email');
      
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': role.name,
          'created_at': DateTime.now().toIso8601String(),
        },
      ).timeout(_authTimeout);
      
      if (response.user != null) {
        // Create user profile in public.users table
        await _createUserProfile(
          userId: response.user!.id,
          email: email.trim(),
          fullName: fullName.trim(),
          phone: phone.trim(),
          role: role,
        );
        
        debugPrint('✓ User registered successfully: $email');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      rethrow;
    }
  }
  
  /// Sign in existing user with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (isDemoMode) {
      throw Exception('Demo Mode: Use demo login instead');
    }
    
    _validateEmail(email);
    _validatePassword(password);
    
    try {
      debugPrint('⏳ Signing in user: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ).timeout(_authTimeout);
      
      if (response.user != null) {
        debugPrint('✓ User signed in successfully: $email');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    if (isDemoMode) {
      throw Exception('Demo Mode: Google sign in not available');
    }
    
    try {
      debugPrint('⏳ Starting Google sign in...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in cancelled by user');
      }
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      if (response.user != null) {
        // Check if user profile exists, create if not
        final userExists = await _checkUserExists(response.user!.id);
        
        if (!userExists) {
          await _createUserProfile(
            userId: response.user!.id,
            email: response.user!.email ?? googleUser.email,
            fullName: googleUser.displayName ?? 'User',
            phone: '',
            role: UserRole.client, // Default role for Google sign in
            photoUrl: googleUser.photoUrl,
          );
        }
        
        debugPrint('✓ Google sign in successful: ${response.user!.email}');
      }
      
      return response;
    } catch (e) {
      debugPrint('❌ Google sign in failed: $e');
      rethrow;
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      debugPrint('⏳ Signing out user...');
      
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      debugPrint('✓ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }
  
  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================
  
  /// Create user profile in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required UserRole role,
    String? photoUrl,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role.name,
        'photo_url': photoUrl,
        'is_active': true,
        'is_online': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✓ User profile created: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create user profile: $e');
      rethrow;
    }
  }
  
  /// Check if user profile exists
  Future<bool> _checkUserExists(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking user existence: $e');
      return false;
    }
  }
  
  /// Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromSupabaseMap(response);
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);
      
      debugPrint('✓ User profile updated: $userId');
    } catch (e) {
      debugPrint('❌ Failed to update user profile: $e');
      rethrow;
    }
  }
  
  /// Get all trainers (for client to choose from)
  Future<List<UserModel>> getTrainers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'trainer')
          .eq('is_active', true);
      
      if (response is List) {
        return (response as List)
            .map((data) => UserModel.fromSupabaseMap(data))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting trainers: $e');
      return [];
    }
  }
  
  /// Get all clients for a trainer
  Future<List<UserModel>> getClientsForTrainer(String trainerId) async {
    try {
      debugPrint('📊 Getting clients for trainer: $trainerId');

      // Try to get clients via trainer_clients relationship
      // Use explicit foreign key name to avoid ambiguity
      final response = await _supabase
          .from('trainer_clients')
          .select('client_id, users!trainer_clients_client_id_fkey(*)')
          .eq('trainer_id', trainerId);

      if (response is List && (response as List).isNotEmpty) {
        debugPrint('✅ Found ${(response as List).length} clients via trainer_clients');
        return (response as List)
            .map((data) => UserModel.fromSupabaseMap(data['users']))
            .toList();
      }

      // Fallback: If no trainer_clients found, get ALL clients from users table
      debugPrint('⚠️ No clients found via trainer_clients, falling back to users table');
      final clientsResponse = await _supabase
          .from('users')
          .select('*')
          .eq('role', 'client')
          .order('full_name');

      if (clientsResponse is List) {
        debugPrint('✅ Found ${(clientsResponse as List).length} clients from users table');
        return (clientsResponse as List)
            .map((data) => UserModel.fromSupabaseMap(data))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting clients: $e');

      // Last resort fallback: try to get clients directly from users table
      try {
        debugPrint('🔄 Attempting fallback query...');
        final clientsResponse = await _supabase
            .from('users')
            .select('*')
            .eq('role', 'client')
            .order('full_name');

        if (clientsResponse is List) {
          debugPrint('✅ Fallback successful: Found ${(clientsResponse as List).length} clients');
          return (clientsResponse as List)
              .map((data) => UserModel.fromSupabaseMap(data))
              .toList();
        }
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
      }

      return [];
    }
  }
  
  /// Assign client to trainer
  Future<void> assignClientToTrainer(String clientId, String trainerId) async {
    try {
      // Check if assignment already exists
      final existing = await _supabase
          .from('trainer_clients')
          .select('id')
          .eq('client_id', clientId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('📝 Client already assigned to trainer - skipping duplicate');
        return; // Assignment already exists, no error
      }

      // Create new assignment
      await _supabase.from('trainer_clients').insert({
        'client_id': clientId,
        'trainer_id': trainerId,
        'assigned_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      debugPrint('✓ Client assigned to trainer');
    } catch (e) {
      debugPrint('❌ Failed to assign client: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BOOKING & SESSION MANAGEMENT
  // ============================================================================

  /// Book a session using RPC function for transaction safety
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
    try {
      debugPrint('⏳ Booking session for client: $clientId');

      final response = await _supabase.rpc('book_session_with_validation', params: {
        'p_client_id': clientId,
        'p_trainer_id': trainerId,
        'p_scheduled_start': scheduledDate.toIso8601String(),
        'p_duration_minutes': durationMinutes,
        'p_package_id': packageId,
        'p_session_type': sessionType,
        'p_location': location,
        'p_notes': notes,
      }).timeout(_defaultTimeout);

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✅ Session booked successfully: ${result['session_id']}');

        // GOOGLE CALENDAR SYNC - Universal (works on web & mobile)
        try {
          debugPrint('📅 Attempting Google Calendar sync...');

          // Get client info for calendar event
          final clientResponse = await _supabase
            .from('users')
            .select('full_name, email')
            .eq('id', clientId)
            .maybeSingle()
            .timeout(_defaultTimeout);

          if (clientResponse != null) {
            final clientName = clientResponse['full_name'] ?? 'Client';
            final clientEmail = clientResponse['email'];

            // Create Google Calendar event (works on both web and mobile)
            final eventId = await GoogleCalendarService.instance.createEvent(
              summary: 'PT Session - $clientName',
              startTime: scheduledDate,
              endTime: scheduledDate.add(Duration(minutes: durationMinutes)),
              clientName: clientName,
              clientEmail: clientEmail,
              location: location,
              description: notes ?? 'Personal training session',
            );

            // Store event ID in database if successful
            if (eventId != null && result['session_id'] != null) {
              await _supabase
                .from('sessions')
                .update({'google_calendar_event_id': eventId})
                .eq('id', result['session_id'])
                .timeout(_defaultTimeout);

              debugPrint('✅ Synced to Google Calendar: $eventId');
              debugPrint('   Session will appear in trainer\'s Google Calendar');
              result['google_calendar_event_id'] = eventId;
              result['calendar_synced'] = true;
            } else {
              debugPrint('⚠️ Calendar event created but ID not returned');
              result['calendar_synced'] = false;
            }
          } else {
            debugPrint('⚠️ Client info not found for calendar sync');
            result['calendar_synced'] = false;
          }
        } on CalendarQuotaExceededException catch (e) {
          debugPrint('⚠️ Google Calendar API quota exceeded: ${e.message}');
          result['calendar_synced'] = false;
          result['calendar_error'] = 'API quota exceeded. Try again in 1 hour.';
          result['calendar_error_type'] = 'quota';
          // Don't fail the booking if calendar sync fails
        } on CalendarAuthException catch (e) {
          debugPrint('⚠️ Google Calendar authentication failed: ${e.message}');
          result['calendar_synced'] = false;
          result['calendar_error'] = 'Google Calendar authentication expired. Please sign in again.';
          result['calendar_error_type'] = 'auth';
          // Don't fail the booking if calendar sync fails
        } on CalendarPermissionException catch (e) {
          debugPrint('⚠️ Google Calendar permission denied: ${e.message}');
          result['calendar_synced'] = false;
          result['calendar_error'] = 'No permission to access Google Calendar. Please grant access.';
          result['calendar_error_type'] = 'permission';
          // Don't fail the booking if calendar sync fails
        } on CalendarException catch (e) {
          debugPrint('⚠️ Google Calendar error: ${e.message}');
          result['calendar_synced'] = false;
          result['calendar_error'] = e.message;
          result['calendar_error_type'] = 'calendar';
          // Don't fail the booking if calendar sync fails
        } catch (e) {
          final errorMsg = e.toString().split('\n').first;
          debugPrint('⚠️ Google Calendar sync failed (non-critical): $errorMsg');

          // Provide helpful error messages
          if (errorMsg.contains('ClientID not set') || errorMsg.contains('OAuth')) {
            debugPrint('💡 To enable Google Calendar on web:');
            debugPrint('   1. Get OAuth Client ID from Google Cloud Console');
            debugPrint('   2. Add to web/index.html: <meta name="google-signin-client_id" content="YOUR_CLIENT_ID"/>');
          } else if (errorMsg.contains('not initialized')) {
            debugPrint('💡 Google Calendar not initialized - user may need to sign in to Google');
          }

          result['calendar_synced'] = false;
          result['calendar_error'] = errorMsg;
          result['calendar_error_type'] = 'unknown';
          // Don't fail the booking if calendar sync fails
        }
      } else {
        // ✅ FIXED: Database returns 'errors' (plural array), not 'error' (singular)
        final errors = result['errors'] as List?;
        final errorMessage = errors != null && errors.isNotEmpty ? errors.join(', ') : 'Unknown error';
        debugPrint('❌ Booking failed: $errorMessage');

        // Add formatted error message for UI
        result['error'] = errorMessage;
        result['message'] = errorMessage;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error booking session: $e');
      rethrow;
    }
  }

  /// Get available time slots for a trainer on a specific date
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String trainerId,
    required DateTime date,
    int durationMinutes = 60,
  }) async {
    try {
      final response = await _supabase.rpc('get_available_slots', params: {
        'p_trainer_id': trainerId,
        'p_date': date.toIso8601String().split('T')[0], // Date only
        'p_duration': durationMinutes,
      }).timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting available slots: $e');
      return [];
    }
  }

  /// Cancel a session with optional refund
  Future<Map<String, dynamic>> cancelSession({
    required String sessionId,
    required String cancelledBy,
    String? reason,
    bool refundSession = true,
  }) async {
    try {
      debugPrint('⏳ Cancelling session: $sessionId');

      final response = await _supabase.rpc('cancel_session_with_refund', params: {
        'p_session_id': sessionId,
        'p_cancelled_by': cancelledBy,
        'p_reason': reason,
        'p_refund_session': refundSession,
      }).timeout(_defaultTimeout);

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        debugPrint('✓ Session cancelled successfully');

        // Delete from Google Calendar (non-critical operation)
        try {
          // Get the Google Calendar event ID from the session
          final sessionResponse = await _supabase
            .from('sessions')
            .select('google_calendar_event_id')
            .eq('id', sessionId)
            .maybeSingle()
            .timeout(_defaultTimeout);

          if (sessionResponse != null && sessionResponse['google_calendar_event_id'] != null) {
            final eventId = sessionResponse['google_calendar_event_id'] as String;
            debugPrint('🗑️ Deleting Google Calendar event: $eventId');

            final deleted = await GoogleCalendarService.instance.deleteEvent(eventId);

            if (deleted) {
              debugPrint('✅ Google Calendar event deleted');
            } else {
              debugPrint('⚠️ Failed to delete Google Calendar event');
            }
          } else {
            debugPrint('ℹ️ No Google Calendar event ID found for this session');
          }
        } catch (e) {
          debugPrint('⚠️ Google Calendar deletion failed (non-critical): $e');
          // Don't fail the cancellation if calendar deletion fails
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error cancelling session: $e');
      rethrow;
    }
  }

  /// Get sessions for a trainer
  Future<List<Map<String, dynamic>>> getTrainerSessions({
    required String trainerId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('sessions')
          .select('*, users!client_id(*), client_packages(*)')
          .eq('trainer_id', trainerId);

      if (startDate != null) {
        query = query.gte('scheduled_start', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('scheduled_start', endDate.toIso8601String());
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('scheduled_start')
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting sessions: $e');
      return [];
    }
  }

  /// Get sessions for a client
  Future<List<Map<String, dynamic>>> getClientSessions({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('sessions')
          .select('*, users!trainer_id(*)')
          .eq('client_id', clientId);

      if (startDate != null) {
        query = query.gte('scheduled_start', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('scheduled_start', endDate.toIso8601String());
      }

      final response = await query
          .order('scheduled_start')
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting client sessions: $e');
      return [];
    }
  }

  /// Update session status (start, complete, etc.)
  Future<void> updateSessionStatus({
    required String sessionId,
    required String status,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? actualDurationMinutes,
    String? notes,
  }) async {
    try {
      // ✅ VALIDATION: Block completing sessions that are not scheduled for TODAY
      if (status == 'completed') {
        // Fetch the session to check its scheduled date
        final sessionData = await _supabase
            .from('sessions')
            .select('scheduled_start')
            .eq('id', sessionId)
            .single()
            .timeout(_defaultTimeout);

        if (sessionData != null && sessionData['scheduled_start'] != null) {
          final scheduledStart = DateTime.parse(sessionData['scheduled_start']);
          final scheduledDate = DateUtils.dateOnly(scheduledStart);
          final today = DateUtils.dateOnly(DateTime.now());

          // Only allow completing sessions scheduled for TODAY
          if (!scheduledDate.isAtSameMomentAs(today)) {
            final dateStr = DateFormat('MMM dd, yyyy').format(scheduledDate);
            throw Exception(
              'Cannot complete session in advance. This session is scheduled for $dateStr. You can only complete sessions on the same day they are scheduled.'
            );
          }
        }
      }

      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (actualStartTime != null) {
        updates['actual_start_time'] = actualStartTime.toIso8601String();
      }

      if (actualEndTime != null) {
        updates['actual_end_time'] = actualEndTime.toIso8601String();
      }

      if (actualDurationMinutes != null) {
        updates['actual_duration_minutes'] = actualDurationMinutes;
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _supabase
          .from('sessions')
          .update(updates)
          .eq('id', sessionId)
          .timeout(_defaultTimeout);

      debugPrint('✓ Session status updated: $status');
    } catch (e) {
      debugPrint('❌ Error updating session status: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PACKAGE MANAGEMENT
  // ============================================================================

  /// Get active packages for a client
  Future<List<Map<String, dynamic>>> getClientPackages({
    required String clientId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('client_packages')
          .select('*, packages(*)')
          .eq('client_id', clientId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting client packages: $e');
      return [];
    }
  }

  /// Get available packages from a trainer
  Future<List<Map<String, dynamic>>> getAvailablePackages({
    required String trainerId,
  }) async {
    try {
      final response = await _supabase
          .from('packages')
          .select()
          .eq('trainer_id', trainerId)
          .eq('is_active', true)
          .order('price')
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting packages: $e');
      return [];
    }
  }

  /// Purchase a package for a client
  Future<String> purchasePackage({
    required String clientId,
    required String trainerId,
    required String packageId,
    required double pricePaid,
    String paymentMethod = 'cash',
    String paymentStatus = 'paid',
    String? notes,
  }) async {
    try {
      // Get package details
      final packageData = await _supabase
          .from('packages')
          .select()
          .eq('id', packageId)
          .single()
          .timeout(_defaultTimeout);

      // Calculate expiry date
      final expiryDate = DateTime.now().add(
        Duration(days: packageData['validity_days'] as int),
      );

      // Create client package
      final response = await _supabase
          .from('client_packages')
          .insert({
            'client_id': clientId,
            'trainer_id': trainerId,
            'package_id': packageId,
            'package_name': packageData['name'],
            'total_sessions': packageData['total_sessions'],
            'sessions_used': 0,
            'duration_per_session': packageData['duration_per_session'],
            'price_paid': pricePaid,
            'payment_method': paymentMethod,
            'payment_status': paymentStatus,
            'purchase_date': DateTime.now().toIso8601String(),
            'expiry_date': expiryDate.toIso8601String(),
            'status': 'active',
            'notes': notes,
          })
          .select()
          .single()
          .timeout(_defaultTimeout);

      final clientPackageId = response['id'] as String;
      debugPrint('✓ Package purchased: $clientPackageId');

      return clientPackageId;
    } catch (e) {
      debugPrint('❌ Error purchasing package: $e');
      rethrow;
    }
  }

  // ============================================================================
  // EXERCISE LOGGING
  // ============================================================================

  /// Log an exercise during a session
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
    try {
      await _supabase.from('exercise_logs').insert({
        'session_id': sessionId,
        'client_id': clientId,
        'exercise_name': exerciseName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'notes': notes,
        'logged_at': DateTime.now().toIso8601String(),
      }).timeout(_defaultTimeout);

      debugPrint('✓ Exercise logged: $exerciseName');
    } catch (e) {
      debugPrint('❌ Error logging exercise: $e');
      rethrow;
    }
  }

  /// Get exercise logs for a session
  Future<List<Map<String, dynamic>>> getSessionExercises({
    required String sessionId,
  }) async {
    try {
      final response = await _supabase
          .from('exercise_logs')
          .select()
          .eq('session_id', sessionId)
          .order('logged_at')
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting exercises: $e');
      return [];
    }
  }

  // ============================================================================
  // DEMO MODE METHODS
  // ============================================================================
  
  /// Demo login - bypasses authentication
  Future<Map<String, dynamic>> demoLogin({
    required String email,
    required UserRole role,
    String? fullName,
  }) async {
    debugPrint('📱 Demo Login: $email as ${role.name}');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    return {
      'user': {
        'id': 'demo-${role.name}-${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'full_name': fullName ?? '${role.name.capitalize()} User',
        'phone': '+1234567890',
        'role': role.name,
        'photo_url': null,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      'session': {
        'access_token': 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'demo-refresh-token',
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      }
    };
  }
  
  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================
  
  void _validateEmail(String email) {
    if (email.trim().isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
  }
  
  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
  }
  
  void _validateNonEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
  }

  // ============================================================================
  // BOOKING MANAGEMENT
  // ============================================================================

  /// Get today's scheduled sessions for a trainer
  Future<List<Map<String, dynamic>>> getTodaySchedule(String trainerId) async {
    try {
      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            client:users!sessions_client_id_fkey(
              id,
              full_name,
              email
            ),
            package:client_packages(
              id,
              package_name,
              remaining_sessions
            )
          ''')
          .eq('trainer_id', trainerId)
          .inFilter('status', ['scheduled', 'confirmed']) // ✅ EXCLUDE completed sessions
          .gte('scheduled_start', startOfDay.toIso8601String())
          .lt('scheduled_start', endOfDay.toIso8601String())
          .order('scheduled_start')
          .timeout(_defaultTimeout);

      // Transform nested objects to flat structure
      final sessions = List<Map<String, dynamic>>.from(response as List);
      return sessions.map((session) {
        final client = session['client'];
        final package = session['package'];

        return {
          ...session,
          'client_name': client != null ? client['full_name'] ?? 'Unknown' : 'Unknown',
          'client_email': client != null ? client['email'] : null,
          'package_name': package != null ? package['package_name'] ?? 'Package' : 'Package',
          'remaining_sessions': package != null ? package['remaining_sessions'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting today schedule: $e');
      rethrow;
    }
  }

  /// Get upcoming sessions for a trainer
  Future<List<Map<String, dynamic>>> getUpcomingSessions(
    String trainerId, {
    int limit = 50,
  }) async {
    try {
      final now = DateTime.now();

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            client:users!sessions_client_id_fkey(
              id,
              full_name,
              email
            ),
            package:client_packages(
              id,
              package_name,
              remaining_sessions
            )
          ''')
          .eq('trainer_id', trainerId)
          .inFilter('status', ['scheduled', 'confirmed']) // ✅ EXCLUDE completed sessions
          .gte('scheduled_start', now.toIso8601String())
          .order('scheduled_start')
          .limit(limit)
          .timeout(_defaultTimeout);

      // Transform nested objects to flat structure
      final sessions = List<Map<String, dynamic>>.from(response as List);
      return sessions.map((session) {
        final client = session['client'];
        final package = session['package'];

        return {
          ...session,
          'client_name': client != null ? client['full_name'] ?? 'Unknown' : 'Unknown',
          'client_email': client != null ? client['email'] : null,
          'package_name': package != null ? package['package_name'] ?? 'Package' : 'Package',
          'remaining_sessions': package != null ? package['remaining_sessions'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting upcoming sessions: $e');
      rethrow;
    }
  }

  /// Get weekly calendar view for a trainer
  Future<List<Map<String, dynamic>>> getWeeklyCalendar(String trainerId) async {
    try {
      // Get current week's date range (next 7 days)
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            client:users!sessions_client_id_fkey(
              id,
              full_name,
              email
            ),
            package:client_packages(
              id,
              package_name,
              remaining_sessions
            )
          ''')
          .eq('trainer_id', trainerId)
          .inFilter('status', ['scheduled', 'confirmed']) // ✅ EXCLUDE completed sessions
          .gte('scheduled_start', startOfWeek.toIso8601String())
          .lt('scheduled_start', endOfWeek.toIso8601String())
          .order('scheduled_start')
          .timeout(_defaultTimeout);

      // Transform nested objects to flat structure
      final sessions = List<Map<String, dynamic>>.from(response as List);
      return sessions.map((session) {
        final client = session['client'];
        final package = session['package'];

        return {
          ...session,
          'client_name': client != null ? client['full_name'] ?? 'Unknown' : 'Unknown',
          'client_email': client != null ? client['email'] : null,
          'package_name': package != null ? package['package_name'] ?? 'Package' : 'Package',
          'remaining_sessions': package != null ? package['remaining_sessions'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting weekly calendar: $e');
      rethrow;
    }
  }

  /// Get completed sessions for a trainer within date range
  Future<List<Map<String, dynamic>>> getCompletedSessions(
    String trainerId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            client:users!sessions_client_id_fkey(
              id,
              full_name,
              email
            ),
            package:client_packages(
              id,
              package_name,
              remaining_sessions
            )
          ''')
          .eq('trainer_id', trainerId)
          // ✅ FIX: Show ALL past sessions regardless of status
          // Removed .eq('status', 'completed') to show scheduled, confirmed, completed, and cancelled sessions
          .gte('scheduled_start', startDate.toIso8601String())
          .lte('scheduled_start', endDate.toIso8601String())
          .order('scheduled_start', ascending: false)
          .timeout(_defaultTimeout);

      // Transform nested objects to flat structure
      final sessions = List<Map<String, dynamic>>.from(response as List);
      return sessions.map((session) {
        final client = session['client'];
        final package = session['package'];

        return {
          ...session,
          'client_name': client != null ? client['full_name'] ?? 'Unknown' : 'Unknown',
          'client_email': client != null ? client['email'] : null,
          'package_name': package != null ? package['package_name'] ?? 'Package' : 'Package',
          'remaining_sessions': package != null ? package['remaining_sessions'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting completed sessions: $e');
      rethrow;
    }
  }

  /// Cancel a session with reason and optional no-show charge
  Future<void> cancelSessionWithReason(
    String sessionId,
    String reason,
    {bool chargeNoShow = false}
  ) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('🔴 Cancelling session with DIRECT TABLE operations...');
      debugPrint('   Session ID: $sessionId');
      debugPrint('   Reason: $reason');
      debugPrint('   Charge No Show: $chargeNoShow');

      // STEP 1: Get session details
      final sessionData = await _supabase
          .from('sessions')
          .select('id, client_id, trainer_id, status, package_id')
          .eq('id', sessionId)
          .single()
          .timeout(_defaultTimeout);

      // Check if session can be cancelled
      final status = sessionData['status'] as String;
      if (status != 'scheduled' && status != 'confirmed') {
        throw Exception('Session cannot be cancelled (status: $status)');
      }

      debugPrint('✅ Session found: ${sessionData['status']}');

      // STEP 2: Update session directly (no RPC, no triggers!)
      await _supabase
          .from('sessions')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_by': userId,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .timeout(_defaultTimeout);

      debugPrint('✅ Session cancelled');

      // STEP 3: Refund package if needed (direct table operation)
      if (sessionData['package_id'] != null && !chargeNoShow) {
        // Get current package data
        final packageData = await _supabase
            .from('client_packages')
            .select('used_sessions, remaining_sessions')
            .eq('id', sessionData['package_id'])
            .single()
            .timeout(_defaultTimeout);

        final currentUsed = packageData['used_sessions'] as int;
        final currentRemaining = packageData['remaining_sessions'] as int;

        // Refund: decrease used, increase remaining
        await _supabase
            .from('client_packages')
            .update({
              'used_sessions': currentUsed > 0 ? currentUsed - 1 : 0,
              'remaining_sessions': currentRemaining + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', sessionData['package_id'])
            .timeout(_defaultTimeout);

        debugPrint('✅ Package refunded (direct table update)');
      } else if (chargeNoShow) {
        debugPrint('❌ NO SHOW - No refund');
      }

      debugPrint('✅✅✅ Session cancelled successfully (direct operations)');
    } catch (e) {
      debugPrint('❌ Error cancelling session: $e');
      rethrow;
    }
  }
}

/// Extension to capitalize string
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// Timeout exception
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
