import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enterprise Supabase Service for Client Management
/// Supports full CRUD operations for enterprise client system with:
/// - Extended client profiles
/// - Medical conditions
/// - Emergency contacts
/// - Body measurements
/// - Allergies and injuries
/// - Risk assessments
class SupabaseService {
  static SupabaseService? _instance;
  SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  // Configuration flags
  bool get isConfigured => _client != null;
  bool get isInitialized => _client != null && _client!.auth.currentUser != null;

  // Access to Supabase client
  SupabaseClient get client {
    if (_client == null) {
      debugPrint('⚠️ Supabase client not initialized, returning demo stub');
      return _SupabaseClientStub() as SupabaseClient;
    }
    return _client!;
  }

  /// Initialize Supabase service (assumes Supabase.initialize() was already called)
  /// Call this in main.dart after Supabase.initialize()
  Future<void> initialize({
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) async {
    try {
      // Check if Supabase is already initialized
      _client = Supabase.instance.client;
      debugPrint('✅ Supabase service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to get Supabase client: $e');
      debugPrint('📱 Running in demo mode');
    }
  }

  // =====================================================
  // AUTH METHODS
  // =====================================================

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    if (_client == null) {
      debugPrint('📱 Demo: Sign in with $email');
      return _createDemoAuthResponse();
    }

    return await _client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    if (_client == null) {
      debugPrint('📱 Demo: Sign up with $email');
      return _createDemoAuthResponse();
    }

    final response = await _client!.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'phone': phone,
        'role': role,
      },
    );

    // Create user profile in users table
    if (response.user != null) {
      await _client!.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': name,
        'phone': phone,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  Future<bool> signInWithGoogle() async {
    if (_client == null) {
      debugPrint('📱 Demo: Google sign in');
      return false;
    }

    final result = await _client!.auth.signInWithOAuth(OAuthProvider.google);
    return result;
  }

  Future<void> signOut() async {
    if (_client == null) {
      debugPrint('📱 Demo: Sign out');
      return;
    }

    await _client!.auth.signOut();
  }

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return Stream.value(AuthState(AuthChangeEvent.signedOut, null));
    }
    return _client!.auth.onAuthStateChange;
  }

  // =====================================================
  // CLIENT CRUD OPERATIONS
  // =====================================================

  /// Create a new enterprise client with full profile
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> clientData) async {
    if (_client == null) {
      debugPrint('📱 Demo: Creating client ${clientData['full_name']}');
      return {'id': 'demo-client-${DateTime.now().millisecondsSinceEpoch}', ...clientData};
    }

    // Insert main client record
    final response = await _client!.from('users').insert({
      ...clientData,
      'role': 'client',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    debugPrint('✅ Client created: ${response['id']}');
    return response;
  }

  /// Update existing client
  Future<Map<String, dynamic>> updateClient(String clientId, Map<String, dynamic> updates) async {
    if (_client == null) {
      debugPrint('📱 Demo: Updating client $clientId');
      return {'id': clientId, ...updates};
    }

    final response = await _client!
        .from('users')
        .update(updates)
        .eq('id', clientId)
        .select()
        .single();

    debugPrint('✅ Client updated: $clientId');
    return response;
  }

  /// Get client by ID with all related data
  Future<Map<String, dynamic>?> getClientById(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get client $clientId');
      return _getDemoClient(clientId);
    }

    final client = await _client!
        .from('users')
        .select()
        .eq('id', clientId)
        .eq('role', 'client')
        .maybeSingle();

    if (client == null) return null;

    // Fetch related data
    final medicalConditions = await getMedicalConditions(clientId);
    final emergencyContacts = await getEmergencyContacts(clientId);
    final bodyMeasurements = await getBodyMeasurements(clientId, limit: 1);
    final allergies = await getAllergies(clientId);
    final injuries = await getInjuries(clientId);

    return {
      ...client,
      'medical_conditions': medicalConditions,
      'emergency_contacts': emergencyContacts,
      'latest_measurements': bodyMeasurements.isNotEmpty ? bodyMeasurements.first : null,
      'allergies': allergies,
      'injuries': injuries,
    };
  }

  /// Get all clients for a trainer
  Future<List<Map<String, dynamic>>> getAllClients({String? trainerId}) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get all clients');
      return _getDemoClients();
    }

    final response = await _client!
        .from('users')
        .select()
        .eq('role', 'client')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Delete client (soft delete by setting is_active = false)
  Future<void> deleteClient(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Delete client $clientId');
      return;
    }

    await _client!
        .from('users')
        .update({'is_active': false})
        .eq('id', clientId);

    debugPrint('✅ Client soft deleted: $clientId');
  }

  // =====================================================
  // MEDICAL CONDITIONS
  // =====================================================

  Future<List<Map<String, dynamic>>> getMedicalConditions(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get medical conditions for $clientId');
      return [];
    }

    final response = await _client!
        .from('medical_conditions')
        .select()
        .eq('client_id', clientId)
        .eq('is_current', true)
        .order('severity', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addMedicalCondition(String clientId, Map<String, dynamic> condition) async {
    if (_client == null) {
      debugPrint('📱 Demo: Add medical condition for $clientId');
      return condition;
    }

    final response = await _client!
        .from('medical_conditions')
        .insert({
          'client_id': clientId,
          ...condition,
        })
        .select()
        .single();

    return response;
  }

  // =====================================================
  // EMERGENCY CONTACTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get emergency contacts for $clientId');
      return [];
    }

    final response = await _client!
        .from('emergency_contacts')
        .select()
        .eq('client_id', clientId)
        .order('is_primary', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addEmergencyContact(String clientId, Map<String, dynamic> contact) async {
    if (_client == null) {
      debugPrint('📱 Demo: Add emergency contact for $clientId');
      return contact;
    }

    final response = await _client!
        .from('emergency_contacts')
        .insert({
          'client_id': clientId,
          ...contact,
        })
        .select()
        .single();

    return response;
  }

  // =====================================================
  // BODY MEASUREMENTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getBodyMeasurements(String clientId, {int? limit}) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get body measurements for $clientId');
      return [];
    }

    var query = _client!
        .from('body_measurements')
        .select()
        .eq('client_id', clientId)
        .order('measured_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addBodyMeasurement(String clientId, Map<String, dynamic> measurement) async {
    if (_client == null) {
      debugPrint('📱 Demo: Add body measurement for $clientId');
      return measurement;
    }

    // Calculate BMI if weight and height are provided
    if (measurement['weight_kg'] != null && measurement['height_cm'] != null) {
      final weight = measurement['weight_kg'] as num;
      final heightM = (measurement['height_cm'] as num) / 100;
      measurement['bmi'] = weight / (heightM * heightM);
    }

    final response = await _client!
        .from('body_measurements')
        .insert({
          'client_id': clientId,
          'measured_date': DateTime.now().toIso8601String(),
          ...measurement,
        })
        .select()
        .single();

    // Update current measurements in users table
    await _client!.from('users').update({
      'current_weight_kg': measurement['weight_kg'],
      'current_height_cm': measurement['height_cm'],
      'current_body_fat_percentage': measurement['body_fat_percentage'],
      'current_muscle_mass_kg': measurement['muscle_mass_kg'],
    }).eq('id', clientId);

    return response;
  }

  // =====================================================
  // ALLERGIES
  // =====================================================

  Future<List<Map<String, dynamic>>> getAllergies(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get allergies for $clientId');
      return [];
    }

    final response = await _client!
        .from('client_allergies')
        .select()
        .eq('client_id', clientId)
        .order('severity', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addAllergy(String clientId, Map<String, dynamic> allergy) async {
    if (_client == null) {
      debugPrint('📱 Demo: Add allergy for $clientId');
      return allergy;
    }

    final response = await _client!
        .from('client_allergies')
        .insert({
          'client_id': clientId,
          ...allergy,
        })
        .select()
        .single();

    return response;
  }

  // =====================================================
  // INJURIES
  // =====================================================

  Future<List<Map<String, dynamic>>> getInjuries(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get injuries for $clientId');
      return [];
    }

    final response = await _client!
        .from('client_injuries')
        .select()
        .eq('client_id', clientId)
        .order('is_current', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addInjury(String clientId, Map<String, dynamic> injury) async {
    if (_client == null) {
      debugPrint('📱 Demo: Add injury for $clientId');
      return injury;
    }

    final response = await _client!
        .from('client_injuries')
        .insert({
          'client_id': clientId,
          ...injury,
        })
        .select()
        .single();

    return response;
  }

  // =====================================================
  // RISK ASSESSMENTS
  // =====================================================

  Future<Map<String, dynamic>> createRiskAssessment(String clientId, Map<String, dynamic> assessment) async {
    if (_client == null) {
      debugPrint('📱 Demo: Create risk assessment for $clientId');
      return assessment;
    }

    final response = await _client!
        .from('risk_assessments')
        .insert({
          'client_id': clientId,
          'assessed_date': DateTime.now().toIso8601String(),
          ...assessment,
        })
        .select()
        .single();

    // Update client's current risk level
    await _client!.from('users').update({
      'risk_level': assessment['risk_level'],
      'risk_score': assessment['risk_score'],
    }).eq('id', clientId);

    return response;
  }

  Future<List<Map<String, dynamic>>> getRiskAssessmentHistory(String clientId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get risk assessment history for $clientId');
      return [];
    }

    final response = await _client!
        .from('risk_assessments')
        .select()
        .eq('client_id', clientId)
        .order('assessed_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // =====================================================
  // NOTIFICATIONS
  // =====================================================

  Future<void> createNotification({
    required String userId,
    required String title,
    String? message,
    String? body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final content = message ?? body ?? '';

    if (_client == null) {
      debugPrint('📱 Demo: Notification created - $title: $content');
      return;
    }

    await _client!.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': content,
      'type': type,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });
  }

  // =====================================================
  // USER PROFILE
  // =====================================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (_client == null) {
      debugPrint('📱 Demo: Get user profile');
      return {'id': userId, 'name': 'Demo User', 'role': 'trainer'};
    }

    return await _client!
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // =====================================================
  // DEMO/STUB HELPERS
  // =====================================================

  AuthResponse _createDemoAuthResponse() {
    // Return a mock auth response for demo mode
    return AuthResponse(
      user: User(
        id: 'demo-user-123',
        appMetadata: {},
        userMetadata: {'name': 'Demo User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
      session: null,
    );
  }

  Map<String, dynamic> _getDemoClient(String clientId) {
    return {
      'id': clientId,
      'email': 'demo.client@example.com',
      'full_name': 'Demo Client',
      'phone': '555-0100',
      'role': 'client',
      'birth_date': '1990-01-01',
      'gender': 'Other',
      'client_status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': true,
    };
  }

  List<Map<String, dynamic>> _getDemoClients() {
    return [
      {
        'id': 'demo-client-1',
        'email': 'john.doe@example.com',
        'full_name': 'John Doe',
        'phone': '555-0101',
        'role': 'client',
        'birth_date': '1990-05-15',
        'gender': 'Male',
        'client_status': 'active',
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
      },
      {
        'id': 'demo-client-2',
        'email': 'sarah.smith@example.com',
        'full_name': 'Sarah Smith',
        'phone': '555-0102',
        'role': 'client',
        'birth_date': '1988-08-22',
        'gender': 'Female',
        'client_status': 'active',
        'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        'is_active': true,
      },
    ];
  }
}

// =====================================================
// STUB IMPLEMENTATION FOR DEMO MODE
// =====================================================

class _SupabaseClientStub {
  _QueryBuilderStub from(String table) => _QueryBuilderStub(table);
  _AuthStub get auth => _AuthStub();
}

class _QueryBuilderStub {
  final String table;
  _QueryBuilderStub(this.table);

  _QueryBuilderStub select([String columns = '*']) {
    debugPrint('📱 Demo: SELECT from $table');
    return this;
  }

  _QueryBuilderStub insert(Map<String, dynamic> data) {
    debugPrint('📱 Demo: INSERT into $table');
    return this;
  }

  _QueryBuilderStub update(Map<String, dynamic> data) {
    debugPrint('📱 Demo: UPDATE $table');
    return this;
  }

  _QueryBuilderStub delete() {
    debugPrint('📱 Demo: DELETE from $table');
    return this;
  }

  _QueryBuilderStub eq(String column, dynamic value) {
    debugPrint('📱 Demo: WHERE $column = $value');
    return this;
  }

  _QueryBuilderStub order(String column, {bool ascending = true}) {
    debugPrint('📱 Demo: ORDER BY $column');
    return this;
  }

  _QueryBuilderStub limit(int count) {
    debugPrint('📱 Demo: LIMIT $count');
    return this;
  }

  Future<Map<String, dynamic>?> maybeSingle() async {
    debugPrint('📱 Demo: maybeSingle() on $table');
    return null;
  }

  Future<Map<String, dynamic>> single() async {
    debugPrint('📱 Demo: single() on $table');
    return {};
  }

  Future<List<dynamic>> then<T>(
    FutureOr<T> Function(List<dynamic>) onValue, {
    Function? onError,
  }) async {
    debugPrint('📱 Demo: Query on $table');
    return [];
  }
}

class _AuthStub {
  User? get currentUser => null;
  Stream<AuthState> get onAuthStateChange => Stream.value(AuthState(AuthChangeEvent.signedOut, null));

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('📱 Demo: Auth signUp');
    return AuthResponse(user: null, session: null);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('📱 Demo: Auth signIn');
    return AuthResponse(user: null, session: null);
  }

  Future<void> signOut() async {
    debugPrint('📱 Demo: Auth signOut');
  }
}
