import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model.dart';
import '../models/user_model.dart';

/// Payment Service for handling all payment-related database operations
/// Integrates with payment_transactions, client_packages, and subscription_contracts tables
class PaymentService {
  static PaymentService? _instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  PaymentService._();

  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  /// Record a payment transaction and update client package
  /// Returns the transaction ID if successful
  Future<String?> recordPayment({
    required String clientId,
    required String trainerId,
    required PackageModel package,
    required String paymentMethod,
    required double amount,
    String? contractId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user');
        return null;
      }

      // Step 1: Create payment transaction record
      final transactionData = {
        'client_id': clientId,
        'trainer_id': trainerId,
        'package_id': package.id,
        'contract_id': contractId,
        'payment_method': paymentMethod,
        'transaction_type': package.isRecurring ? 'subscription_payment' : 'package_purchase',
        'amount': amount,
        'currency': 'THB',
        'payment_status': _getInitialPaymentStatus(paymentMethod),
        'transaction_date': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      };

      final transactionResult = await _supabase
          .from('payment_transactions')
          .insert(transactionData)
          .select();

      // Handle single or multiple results (in case of triggers)
      final List<dynamic> resultList = transactionResult is List
          ? transactionResult
          : [transactionResult];

      if (resultList.isEmpty) {
        debugPrint('❌ No transaction created');
        return null;
      }

      final transaction = resultList.first as Map<String, dynamic>;
      final transactionId = transaction['id'] as String;
      debugPrint('✅ Payment transaction created: $transactionId');

      if (resultList.length > 1) {
        debugPrint('⚠️  Warning: Multiple rows returned from INSERT (${resultList.length} rows)');
        debugPrint('   This may indicate a database trigger is duplicating records');
      }

      // Step 2: Create or update client_packages record
      await _assignPackageToClient(
        clientId: clientId,
        trainerId: trainerId,
        package: package,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        contractId: contractId,
      );

      return transactionId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error recording payment: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get initial payment status based on payment method
  String _getInitialPaymentStatus(String paymentMethod) {
    switch (paymentMethod) {
      case 'promptpay':
        return 'paid'; // Trust user confirmation, verify later
      case 'bank_transfer':
        return 'paid'; // Trust user confirmation, verify later
      case 'credit_card':
        return 'completed'; // Instant if successful
      case 'manual':
        return 'paid'; // Trust user, trainer can verify later
      default:
        return 'paid';
    }
  }

  /// Assign package to client after payment
  Future<void> _assignPackageToClient({
    required String clientId,
    required String trainerId,
    required PackageModel package,
    required String paymentMethod,
    required String transactionId,
    String? contractId,
  }) async {
    try {
      // ALWAYS CREATE A NEW PACKAGE - Each payment creates a separate package
      // This is correct behavior: if client buys same package twice, they get 2 separate packages
      debugPrint('📦 Creating new client package...');
      debugPrint('   Package ID: ${package.id}');
      debugPrint('   Package Name: ${package.name}');
      debugPrint('   Session Count: ${package.sessionCount}');
      debugPrint('   Price: ${package.price}');

      if (package.sessionCount == 0) {
        debugPrint('⚠️⚠️⚠️  WARNING: Package has ZERO sessions! This will create an empty package!');
      }

      // Create new client_packages record
      final packageData = {
        'client_id': clientId,
        'trainer_id': trainerId,
        'package_id': package.id,
        'package_name': package.name,
        'used_sessions': 0, // ✅ FIXED: Use 'used_sessions' (real column), not 'sessions_used' (generated alias)
        'sessions_scheduled': 0,
        'total_sessions': package.sessionCount,
        'remaining_sessions': package.sessionCount, // ✅ FIXED: Must set explicitly! Default is 0, not auto-calculated
        'price_paid': package.price,
        'amount_paid': package.price, // Add amount_paid field
        'payment_method': paymentMethod,
        'payment_status': _getInitialPaymentStatus(paymentMethod),
        'purchase_date': DateTime.now().toIso8601String(),
        'expiry_date': DateTime.now()
            .add(Duration(days: package.validityDays))
            .toIso8601String(),
        'status': 'active', // Add status field
        'is_subscription': package.isRecurring,
        'subscription_contract_id': contractId,
        'sessions_per_week': package.sessionsPerWeek,
        'auto_billing_enabled': paymentMethod == 'credit_card',
      };

      final insertResult = await _supabase
          .from('client_packages')
          .insert(packageData)
          .select()
          .limit(1);

      if (insertResult.isNotEmpty) {
        debugPrint('✅ Package assigned to client');
        debugPrint('   Package ID: ${insertResult.first['id']}');
      } else {
        debugPrint('⚠️  Package insert returned no data');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error assigning package: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Record PromptPay payment
  Future<String?> recordPromptPayPayment({
    required String clientId,
    required String trainerId,
    required PackageModel package,
  }) async {
    return await recordPayment(
      clientId: clientId,
      trainerId: trainerId,
      package: package,
      paymentMethod: 'promptpay',
      amount: package.price,
      metadata: {
        'promptpay_id': '1095535268',
        'confirmation_type': 'user_confirmed',
        'confirmation_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Record Bank Transfer payment
  Future<String?> recordBankTransferPayment({
    required String clientId,
    required String trainerId,
    required PackageModel package,
  }) async {
    return await recordPayment(
      clientId: clientId,
      trainerId: trainerId,
      package: package,
      paymentMethod: 'bank_transfer',
      amount: package.price,
      metadata: {
        'bank_name': 'Kasikorn Bank',
        'account_number': '271-2-25514-8',
        'account_name': 'Masa Thomard / เมษา โต๊ะหมาด',
        'confirmation_type': 'user_confirmed',
        'confirmation_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Record Manual/Cash payment
  Future<String?> recordManualPayment({
    required String clientId,
    required String trainerId,
    required PackageModel package,
  }) async {
    return await recordPayment(
      clientId: clientId,
      trainerId: trainerId,
      package: package,
      paymentMethod: 'manual',
      amount: package.price,
      metadata: {
        'payment_type': 'cash_in_person',
        'confirmation_type': 'pending_trainer',
        'confirmation_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Record Credit Card payment
  Future<String?> recordCreditCardPayment({
    required String clientId,
    required String trainerId,
    required PackageModel package,
    required String cardToken,
    String? transactionId,
  }) async {
    return await recordPayment(
      clientId: clientId,
      trainerId: trainerId,
      package: package,
      paymentMethod: 'credit_card',
      amount: package.price,
      metadata: {
        'card_token': cardToken,
        'gateway_transaction_id': transactionId,
        'confirmation_type': 'gateway_confirmed',
        'confirmation_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get payment transactions for a client
  Future<List<Map<String, dynamic>>> getClientPayments(String clientId) async {
    try {
      final result = await _supabase
          .from('payment_transactions')
          .select()
          .eq('client_id', clientId)
          .order('transaction_date', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching client payments: $e');
      return [];
    }
  }

  /// Get payment transaction by ID
  Future<Map<String, dynamic>?> getPaymentById(String transactionId) async {
    try {
      final result = await _supabase
          .from('payment_transactions')
          .select()
          .eq('id', transactionId)
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('❌ Error fetching payment: $e');
      return null;
    }
  }

  /// Update payment status (for trainer verification)
  Future<bool> updatePaymentStatus({
    required String transactionId,
    required String newStatus,
    String? verifiedBy,
  }) async {
    try {
      await _supabase.from('payment_transactions').update({
        'payment_status': newStatus,
        'verified_by': verifiedBy,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);

      // If payment is verified, update client_packages status
      if (newStatus == 'completed' || newStatus == 'verified') {
        final transaction = await getPaymentById(transactionId);
        if (transaction != null) {
          await _supabase.from('client_packages').update({
            'payment_status': 'paid',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('client_id', transaction['client_id']).eq(
              'payment_method', transaction['payment_method']);
        }
      }

      debugPrint('✅ Payment status updated: $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      return false;
    }
  }

  /// Get pending payments for trainer to verify
  Future<List<Map<String, dynamic>>> getPendingPayments(
      String trainerId) async {
    try {
      final result = await _supabase
          .from('payment_transactions')
          .select('''
            *,
            client:users!payment_transactions_client_id_fkey(id, full_name, email),
            package:packages!payment_transactions_package_id_fkey(name, session_count)
          ''')
          .eq('trainer_id', trainerId)
          .inFilter('payment_status', ['pending_verification', 'pending'])
          .order('transaction_date', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching pending payments: $e');
      return [];
    }
  }

  /// Get client's active packages
  Future<List<Map<String, dynamic>>> getClientActivePackages(
      String clientId) async {
    try {
      final result = await _supabase
          .from('client_packages')
          .select()
          .eq('client_id', clientId)
          .gt('sessions_remaining', 0)
          .order('purchase_date', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching client packages: $e');
      return [];
    }
  }

  /// Check if client has active package
  Future<bool> hasActivePackage(String clientId, String packageId) async {
    try {
      final result = await _supabase
          .from('client_packages')
          .select()
          .eq('client_id', clientId)
          .eq('package_id', packageId)
          .gt('sessions_remaining', 0)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking active package: $e');
      return false;
    }
  }
}
