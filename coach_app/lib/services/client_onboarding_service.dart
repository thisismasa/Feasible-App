import 'dart:math';
import '../models/package_model.dart';
import 'supabase_service.dart';

/// Client Onboarding Service - Transaction-Safe Client Creation
/// Features: Security, validation, agreements, payments, audit trail
class ClientOnboardingService {
  static final ClientOnboardingService _instance = ClientOnboardingService._internal();
  factory ClientOnboardingService() => instance;
  static ClientOnboardingService get instance => _instance;
  ClientOnboardingService._internal();

  /// Create new client with full transaction safety
  Future<OnboardingResult> createClient(OnboardingRequest request) async {
    // Pre-validation
    final validation = await _preValidate(request);
    if (!validation.isValid) {
      return OnboardingResult.error(validation.reason);
    }
    
    String? userId;
    String? packageId;
    final temporaryPassword = _generateSecurePassword();
    
    try {
      // Step 1: Create user account
      userId = await _createUserAccount(request, temporaryPassword);
      
      // Step 2: Store health information
      await _storeHealthInformation(userId, request);
      
      // Step 3: Store preferences
      await _storePreferences(userId, request);
      
      // Step 4: Process payment
      final paymentResult = await _processPayment(request);
      if (!paymentResult.success) {
        throw PaymentException(paymentResult.message);
      }
      
      // Step 5: Assign package
      packageId = await _assignPackage(userId, request, paymentResult.transactionId);
      
      // Step 6: Store agreements
      await _storeAgreements(userId, request);
      
      // Step 7: Send welcome email
      await _sendWelcomeEmail(
        email: request.email,
        fullName: request.fullName,
        temporaryPassword: temporaryPassword,
        packageName: request.selectedPackageId,
      );
      
      // Step 8: Log creation
      await _logClientCreation(userId, request);
      
      return OnboardingResult.success(
        'Client created successfully',
        clientId: userId,
        packageId: packageId,
        temporaryPassword: temporaryPassword,
      );
      
    } catch (e) {
      // Rollback on failure
      await _rollbackClientCreation(userId, packageId);
      return OnboardingResult.error('Failed to create client: ${e.toString()}');
    }
  }

  /// Pre-validation before attempting creation
  Future<ValidationResult> _preValidate(OnboardingRequest request) async {
    // Check email uniqueness
    final emailExists = await _checkEmailExists(request.email);
    if (emailExists) {
      return ValidationResult(false, 'Email already registered');
    }
    
    // Check phone uniqueness
    final phoneExists = await _checkPhoneExists(request.phone);
    if (phoneExists) {
      return ValidationResult(false, 'Phone number already registered');
    }
    
    // Validate age
    final age = DateTime.now().year - request.birthDate.year;
    if (age < 16) {
      return ValidationResult(false, 'Must be at least 16 years old');
    }
    
    // Validate medical clearance if required
    if (request.requiresMedicalClearance && request.medicalClearanceDocUrl == null) {
      return ValidationResult(false, 'Medical clearance document required');
    }
    
    // Validate parental consent if minor
    if (age < 18 && !request.hasParentalConsent) {
      return ValidationResult(false, 'Parental consent required for minors');
    }
    
    // Validate all agreements signed
    if (!request.agreedToTerms || !request.signedLiabilityWaiver) {
      return ValidationResult(false, 'All agreements must be signed');
    }
    
    return ValidationResult(true, 'Valid');
  }

  /// Create user account with secure password
  Future<String> _createUserAccount(OnboardingRequest request, String password) async {
    final response = await SupabaseService.instance.client.auth.signUp(
      email: request.email,
      password: password,
      data: {
        'full_name': request.fullName,
        'role': 'client',
        'phone': request.phone,
        'birth_date': request.birthDate.toIso8601String(),
        'gender': request.gender,
        'emergency_contact': request.emergencyContact,
        'emergency_phone': request.emergencyPhone,
        'profile_photo_url': request.profilePhotoUrl,
        'requires_password_reset': true,
        'temp_password_expires': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      },
    );
    
    if (response.user == null) {
      throw Exception('Failed to create user account');
    }
    
    return response.user!.id;
  }

  /// Store health and medical information
  Future<void> _storeHealthInformation(String userId, OnboardingRequest request) async {
    await SupabaseService.instance.client.from('client_health_info').insert({
      'client_id': userId,
      'health_conditions': request.healthConditions,
      'medications': request.medications,
      'injuries': request.injuries,
      'fitness_level': request.fitnessLevel,
      'requires_medical_clearance': request.requiresMedicalClearance,
      'medical_clearance_doc_url': request.medicalClearanceDocUrl,
      'clearance_verified': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Store client preferences
  Future<void> _storePreferences(String userId, OnboardingRequest request) async {
    await SupabaseService.instance.client.from('client_preferences').insert({
      'client_id': userId,
      'preferred_days': request.preferredDays,
      'preferred_times': request.preferredTimes,
      'preferred_location': request.preferredLocation,
      'session_type_preference': request.sessionTypePreference,
      'communication_method': request.communicationMethod,
      'marketing_opt_in': request.marketingOptIn,
      'referral_source': request.referralSource,
      'goals': request.goals,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Process payment based on method
  Future<PaymentResult> _processPayment(OnboardingRequest request) async {
    switch (request.paymentMethod) {
      case 'Card':
        return await _processCardPayment(request);
      case 'Cash':
        return await _processCashPayment(request);
      case 'Transfer':
        return await _processBankTransfer(request);
      case 'Invoice':
        return await _createInvoice(request);
      default:
        return PaymentResult(false, 'Unknown payment method', null);
    }
  }

  Future<PaymentResult> _processCardPayment(OnboardingRequest request) async {
    // In production, integrate with Stripe/Square
    // For now, simulate successful payment
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(true, 'Payment successful', transactionId);
  }

  Future<PaymentResult> _processCashPayment(OnboardingRequest request) async {
    final receiptNumber = _generateReceiptNumber();
    
    await SupabaseService.instance.client.from('cash_payments').insert({
      'receipt_number': receiptNumber,
      'amount': request.getAmount(),
      'client_id': request.email, // Will update with actual ID later
      'collected_by': SupabaseService.instance.currentUser?.id,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return PaymentResult(true, 'Cash payment recorded', receiptNumber);
  }

  Future<PaymentResult> _processBankTransfer(OnboardingRequest request) async {
    final invoiceNumber = _generateInvoiceNumber();
    
    await SupabaseService.instance.client.from('pending_transfers').insert({
      'invoice_number': invoiceNumber,
      'amount': request.getAmount(),
      'client_email': request.email,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    return PaymentResult(true, 'Transfer initiated', invoiceNumber);
  }

  Future<PaymentResult> _createInvoice(OnboardingRequest request) async {
    final invoiceNumber = _generateInvoiceNumber();
    
    await SupabaseService.instance.client.from('invoices').insert({
      'invoice_number': invoiceNumber,
      'client_email': request.email,
      'amount': request.getAmount(),
      'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    return PaymentResult(true, 'Invoice created', invoiceNumber);
  }

  /// Assign package to client
  Future<String> _assignPackage(
    String userId,
    OnboardingRequest request,
    String? paymentTransactionId,
  ) async {
    // IMPORTANT: Always assign a package, even if none selected
    String? packageId = request.selectedPackageId;
    String packageName = 'No Package';
    int totalSessions = 0;
    double amountPaid = 0;

    // If no package selected, create/find default "No Package"
    if (packageId == null || packageId.isEmpty) {
      // Find or create "No Package"
      final noPackageQuery = await SupabaseService.instance.client
          .from('packages')
          .select()
          .eq('name', 'No Package')
          .limit(1);

      if (noPackageQuery.isEmpty) {
        // Create "No Package" if it doesn't exist
        final newPackage = await SupabaseService.instance.client
            .from('packages')
            .insert({
              'name': 'No Package',
              'description': 'Default package - Please assign a real package',
              'session_count': 0,
              'price': 0,
              'validity_days': 30,
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        packageId = newPackage['id'];
      } else {
        packageId = noPackageQuery.first['id'];
      }

      packageName = 'No Package';
      totalSessions = 0;
      amountPaid = 0;
    } else {
      // Get package details
      final packageData = await SupabaseService.instance.client
          .from('packages')
          .select()
          .eq('id', packageId)
          .single();

      packageName = packageData['name'] ?? 'Package';
      totalSessions = packageData['session_count'] ?? 10;
      amountPaid = request.getAmount();
    }

    final response = await SupabaseService.instance.client
        .from('client_packages')
        .insert({
          'client_id': userId,
          'package_id': packageId,
          'package_name': packageName,
          'purchase_date': request.packageStartDate.toIso8601String(),
          'expiry_date': request.packageStartDate
              .add(Duration(days: 90)) // Assuming 90 days validity
              .toIso8601String(),
          'total_sessions': totalSessions,
          'remaining_sessions': totalSessions,
          'used_sessions': 0,
          'sessions_scheduled': 0,
          'status': 'active',
          'payment_method': request.paymentMethod ?? 'none',
          'payment_status': packageId != null && amountPaid > 0 ? 'paid' : 'pending',
          'amount_paid': amountPaid,
          'price_paid': amountPaid,
          'is_active': true,
          'is_subscription': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return response['id'];
  }

  /// Store signed agreements
  Future<void> _storeAgreements(String userId, OnboardingRequest request) async {
    final agreements = [
      if (request.agreedToTerms) 'terms_of_service',
      if (request.signedLiabilityWaiver) 'liability_waiver',
      if (request.signedPhotoRelease) 'photo_release',
      if (request.signedCancellationPolicy) 'cancellation_policy',
      if (request.hasParentalConsent) 'parental_consent',
    ];
    
    for (final agreement in agreements) {
      await SupabaseService.instance.client.from('client_agreements').insert({
        'client_id': userId,
        'agreement_type': agreement,
        'signed_at': DateTime.now().toIso8601String(),
        'ip_address': await _getIpAddress(),
        'version': '1.0',
      });
    }
  }

  /// Send welcome email with temporary password
  Future<void> _sendWelcomeEmail({
    required String email,
    required String fullName,
    required String temporaryPassword,
    required String packageName,
  }) async {
    // In production, integrate with email service (SendGrid, AWS SES, etc.)
    // For now, just log
    print('Welcome email sent to $email with temp password: $temporaryPassword');
    
    // Store in email queue
    await SupabaseService.instance.client.from('email_queue').insert({
      'to_email': email,
      'subject': 'Welcome to PT Coach!',
      'body': '''
Hi $fullName,

Welcome to PT Coach! Your account has been created.

Login Credentials:
Email: $email
Temporary Password: $temporaryPassword

Please login and change your password immediately.
The temporary password expires in 24 hours.

Your Package: $packageName

Let's start your fitness journey!

Best regards,
PT Coach Team
''',
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Log client creation for audit trail
  Future<void> _logClientCreation(String userId, OnboardingRequest request) async {
    await SupabaseService.instance.client.from('audit_log').insert({
      'action': 'client_created',
      'performed_by': SupabaseService.instance.currentUser?.id,
      'target_user_id': userId,
      'metadata': {
        'package_id': request.selectedPackageId,
        'payment_method': request.paymentMethod,
        'referral_source': request.referralSource,
        'has_medical_clearance': request.requiresMedicalClearance,
      },
      'ip_address': await _getIpAddress(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Rollback on failure
  Future<void> _rollbackClientCreation(String? userId, String? packageId) async {
    if (userId != null) {
      try {
        // Delete user and all related data
        await SupabaseService.instance.client.from('users').delete().eq('id', userId);
        await SupabaseService.instance.client.from('client_health_info').delete().eq('client_id', userId);
        await SupabaseService.instance.client.from('client_preferences').delete().eq('client_id', userId);
        await SupabaseService.instance.client.from('client_agreements').delete().eq('client_id', userId);
        
        if (packageId != null) {
          await SupabaseService.instance.client.from('client_packages').delete().eq('id', packageId);
        }
        
        print('Rollback completed for user: $userId');
      } catch (e) {
        print('Rollback error: $e');
      }
    }
  }

  // Helper Methods
  Future<bool> _checkEmailExists(String email) async {
    final response = await SupabaseService.instance.client
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return response != null;
  }

  Future<bool> _checkPhoneExists(String phone) async {
    final response = await SupabaseService.instance.client
        .from('users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    return response != null;
  }

  String _generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateReceiptNumber() {
    return 'RCP-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Future<String> _getIpAddress() async {
    // In production, get actual IP address
    return '127.0.0.1';
  }
}

/// Onboarding Request Model
class OnboardingRequest {
  // Basic Info
  final String fullName;
  final String email;
  final String phone;
  final DateTime birthDate;
  final String? gender;
  final String emergencyContact;
  final String emergencyPhone;
  final String? profilePhotoUrl;
  
  // Health & Fitness
  final List<String> healthConditions;
  final List<String> medications;
  final List<String> injuries;
  final List<String> goals;
  final String fitnessLevel;
  final bool requiresMedicalClearance;
  final String? medicalClearanceDocUrl;
  
  // Preferences
  final List<String> preferredDays;
  final List<String> preferredTimes;
  final String? preferredLocation;
  final String sessionTypePreference;
  final String communicationMethod;
  final bool marketingOptIn;
  final String? referralSource;
  
  // Package & Payment
  final String selectedPackageId;
  final String paymentMethod;
  final DateTime packageStartDate;
  final bool useProrating;
  
  // Agreements
  final bool agreedToTerms;
  final bool signedLiabilityWaiver;
  final bool signedPhotoRelease;
  final bool signedCancellationPolicy;
  final bool hasParentalConsent;

  OnboardingRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.birthDate,
    this.gender,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.profilePhotoUrl,
    required this.healthConditions,
    required this.medications,
    required this.injuries,
    required this.goals,
    required this.fitnessLevel,
    required this.requiresMedicalClearance,
    this.medicalClearanceDocUrl,
    required this.preferredDays,
    required this.preferredTimes,
    this.preferredLocation,
    required this.sessionTypePreference,
    required this.communicationMethod,
    required this.marketingOptIn,
    this.referralSource,
    required this.selectedPackageId,
    required this.paymentMethod,
    required this.packageStartDate,
    required this.useProrating,
    required this.agreedToTerms,
    required this.signedLiabilityWaiver,
    required this.signedPhotoRelease,
    required this.signedCancellationPolicy,
    required this.hasParentalConsent,
  });

  double getAmount() {
    // Calculate based on package and proration
    return 199.99; // Placeholder
  }
}

/// Onboarding Result
class OnboardingResult {
  final bool success;
  final String message;
  final String? clientId;
  final String? packageId;
  final String? temporaryPassword;

  OnboardingResult._({
    required this.success,
    required this.message,
    this.clientId,
    this.packageId,
    this.temporaryPassword,
  });

  factory OnboardingResult.success(
    String message, {
    String? clientId,
    String? packageId,
    String? temporaryPassword,
  }) {
    return OnboardingResult._(
      success: true,
      message: message,
      clientId: clientId,
      packageId: packageId,
      temporaryPassword: temporaryPassword,
    );
  }

  factory OnboardingResult.error(String message) {
    return OnboardingResult._(success: false, message: message);
  }
}

class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult(this.success, this.message, this.transactionId);
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  
  @override
  String toString() => message;
}

