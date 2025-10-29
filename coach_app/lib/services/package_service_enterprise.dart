// ENTERPRISE PACKAGE SERVICE
// Advanced package management with business logic, validation, and booking integration

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model_enterprise.dart';
import '../services/supabase_service.dart';
import '../services/booking_service.dart';
import '../services/analytics_service.dart';

/// Enterprise Package Management Service
class PackageServiceEnterprise {
  static final PackageServiceEnterprise _instance = PackageServiceEnterprise._internal();
  factory PackageServiceEnterprise() => _instance;
  PackageServiceEnterprise._internal();

  final _supabase = Supabase.instance.client;

  // ============================================================================
  // PACKAGE MANAGEMENT
  // ============================================================================

  /// Get all active packages for a trainer
  Future<List<PackageEnterprise>> getTrainerPackages(String trainerId) async {
    try {
      final response = await _supabase
          .from('packages')
          .select()
          .eq('trainer_id', trainerId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((data) => PackageEnterprise.fromMap(data, data['id']))
          .toList();
    } catch (e) {
      print('Error fetching packages: $e');
      return [];
    }
  }

  /// Get featured packages
  Future<List<PackageEnterprise>> getFeaturedPackages(String trainerId) async {
    try {
      final response = await _supabase
          .from('packages')
          .select()
          .eq('trainer_id', trainerId)
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .limit(3);

      return (response as List)
          .map((data) => PackageEnterprise.fromMap(data, data['id']))
          .toList();
    } catch (e) {
      print('Error fetching featured packages: $e');
      return [];
    }
  }

  /// Get package by ID
  Future<PackageEnterprise?> getPackageById(String packageId) async {
    try {
      final response = await _supabase
          .from('packages')
          .select()
          .eq('id', packageId)
          .single();

      return PackageEnterprise.fromMap(response, response['id']);
    } catch (e) {
      print('Error fetching package: $e');
      return null;
    }
  }

  /// Create new package
  Future<String?> createPackage(PackageEnterprise package, String trainerId) async {
    try {
      final data = package.toMap();
      data['trainer_id'] = trainerId;

      final response = await _supabase
          .from('packages')
          .insert(data)
          .select()
          .single();

      // Track in analytics
      await AnalyticsService.track(
        userId: trainerId,
        event: 'package_created',
        properties: {
          'package_id': response['id'],
          'tier': package.tier.name,
          'price': package.basePrice,
        },
      );

      return response['id'];
    } catch (e) {
      print('Error creating package: $e');
      return null;
    }
  }

  /// Update existing package
  Future<bool> updatePackage(String packageId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('packages')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', packageId);

      return true;
    } catch (e) {
      print('Error updating package: $e');
      return false;
    }
  }

  /// Delete package
  Future<bool> deletePackage(String packageId) async {
    try {
      // Check if package has active clients
      final clients = await getPackageClients(packageId);
      if (clients.isNotEmpty) {
        throw Exception('Cannot delete package with active clients');
      }

      await _supabase
          .from('packages')
          .delete()
          .eq('id', packageId);

      return true;
    } catch (e) {
      print('Error deleting package: $e');
      return false;
    }
  }

  // ============================================================================
  // CLIENT PACKAGE MANAGEMENT
  // ============================================================================

  /// Get client's purchased packages
  Future<List<ClientPackageEnterprise>> getClientPackages(String clientId) async {
    try {
      final response = await _supabase
          .from('client_packages')
          .select('*, packages(*)')
          .eq('client_id', clientId)
          .order('purchase_date', ascending: false);

      final List<ClientPackageEnterprise> packages = [];
      for (final data in response as List) {
        final package = PackageEnterprise.fromMap(
          data['packages'],
          data['packages']['id'],
        );
        packages.add(
          ClientPackageEnterprise.fromMap(data, data['id'], package),
        );
      }

      return packages;
    } catch (e) {
      print('Error fetching client packages: $e');
      return [];
    }
  }

  /// Get client's active package
  Future<ClientPackageEnterprise?> getClientActivePackage(String clientId) async {
    final packages = await getClientPackages(clientId);

    return packages.firstWhere(
      (p) => p.status == PackageStatus.active && p.hasSessionsAvailable,
      orElse: () => packages.first,
    );
  }

  /// Get clients for a package
  Future<List<ClientPackageEnterprise>> getPackageClients(String packageId) async {
    try {
      final response = await _supabase
          .from('client_packages')
          .select('*, packages(*)')
          .eq('package_id', packageId);

      final List<ClientPackageEnterprise> clients = [];
      for (final data in response as List) {
        final package = PackageEnterprise.fromMap(
          data['packages'],
          data['packages']['id'],
        );
        clients.add(
          ClientPackageEnterprise.fromMap(data, data['id'], package),
        );
      }

      return clients;
    } catch (e) {
      print('Error fetching package clients: $e');
      return [];
    }
  }

  // ============================================================================
  // PURCHASE & PAYMENT
  // ============================================================================

  /// Purchase package
  Future<PurchaseResult> purchasePackage({
    required String clientId,
    required String clientName,
    required String trainerId,
    required String packageId,
    required String paymentMethod,
    required String transactionId,
    String? promoCode,
  }) async {
    try {
      // Get package details
      final package = await getPackageById(packageId);
      if (package == null) {
        return PurchaseResult.error('Package not found');
      }

      // Validate package availability
      final validation = await validatePackagePurchase(clientId, packageId);
      if (!validation.isValid) {
        return PurchaseResult.error(validation.message);
      }

      // Apply promo code if provided
      double finalPrice = package.effectivePrice;
      if (promoCode != null) {
        final discount = await _applyPromoCode(promoCode, packageId);
        if (discount > 0) {
          finalPrice = finalPrice * (1 - discount);
        }
      }

      // Calculate expiry date
      final purchaseDate = DateTime.now();
      final expiryDate = package.calculateExpiryDate(purchaseDate);

      // Create client package record
      final clientPackageData = {
        'client_id': clientId,
        'client_name': clientName,
        'trainer_id': trainerId,
        'package_id': packageId,
        'purchase_date': purchaseDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'amount_paid': finalPrice,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'status': PackageStatus.active.name,
        'total_sessions': package.sessionCount,
        'sessions_used': 0,
        'sessions_scheduled': 0,
        'sessions_cancelled': 0,
        'sessions_no_show': 0,
        'is_subscription': package.isRecurring,
        'auto_renew_enabled': package.autoRenew,
        'utilization_rate': 0.0,
        'average_session_interval': 0.0,
      };

      final response = await _supabase
          .from('client_packages')
          .insert(clientPackageData)
          .select()
          .single();

      // Track purchase in analytics
      await AnalyticsService.track(
        userId: clientId,
        event: 'package_purchased',
        properties: {
          'package_id': packageId,
          'package_name': package.name,
          'amount': finalPrice,
          'tier': package.tier.name,
          'sessions': package.sessionCount,
        },
      );

      // Send purchase confirmation notification
      await _sendPurchaseConfirmation(
        clientId: clientId,
        trainerId: trainerId,
        package: package,
        clientPackageId: response['id'],
      );

      return PurchaseResult.success(
        'Package purchased successfully!',
        clientPackageId: response['id'],
      );
    } catch (e) {
      print('Error purchasing package: $e');
      return PurchaseResult.error('Purchase failed: ${e.toString()}');
    }
  }

  /// Validate package purchase
  Future<PackagePurchaseValidation> validatePackagePurchase(
    String clientId,
    String packageId,
  ) async {
    try {
      // Check if package exists and is active
      final package = await getPackageById(packageId);
      if (package == null) {
        return PackagePurchaseValidation(
          isValid: false,
          message: 'Package not found',
        );
      }

      if (!package.isActive) {
        return PackagePurchaseValidation(
          isValid: false,
          message: 'Package is not available for purchase',
        );
      }

      // Check if package requires approval
      if (package.requiresApproval) {
        return PackagePurchaseValidation(
          isValid: false,
          message: 'This package requires trainer approval',
          requiresApproval: true,
        );
      }

      // Check if client already has active package
      final activePackage = await getClientActivePackage(clientId);
      if (activePackage != null && activePackage.hasSessionsAvailable) {
        return PackagePurchaseValidation(
          isValid: false,
          message: 'You already have an active package',
          hasActivePackage: true,
        );
      }

      // Check max clients per month
      if (package.maxClientsPerMonth != null) {
        final clientsThisMonth = await _getMonthlyPurchaseCount(packageId);
        if (clientsThisMonth >= package.maxClientsPerMonth!) {
          return PackagePurchaseValidation(
            isValid: false,
            message: 'Package has reached maximum clients for this month',
          );
        }
      }

      return PackagePurchaseValidation(
        isValid: true,
        message: 'Valid',
      );
    } catch (e) {
      print('Error validating purchase: $e');
      return PackagePurchaseValidation(
        isValid: false,
        message: 'Validation error',
      );
    }
  }

  /// Apply promo code
  Future<double> _applyPromoCode(String promoCode, String packageId) async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .select()
          .eq('code', promoCode)
          .eq('package_id', packageId)
          .eq('is_active', true)
          .single();

      final expiry = DateTime.parse(response['expiry_date']);
      if (DateTime.now().isAfter(expiry)) {
        return 0.0; // Expired
      }

      return (response['discount_percentage'] ?? 0.0).toDouble();
    } catch (e) {
      print('Invalid promo code: $e');
      return 0.0;
    }
  }

  /// Get monthly purchase count for package
  Future<int> _getMonthlyPurchaseCount(String packageId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    try {
      final response = await _supabase
          .from('client_packages')
          .select('id')
          .eq('package_id', packageId)
          .gte('purchase_date', startOfMonth.toIso8601String());

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT & BOOKING INTEGRATION
  // ============================================================================

  /// Use session from package (called after booking confirmed)
  Future<bool> useSession(String clientPackageId) async {
    try {
      // Get current package
      final response = await _supabase
          .from('client_packages')
          .select()
          .eq('id', clientPackageId)
          .single();

      final sessionsUsed = response['sessions_used'] ?? 0;
      final totalSessions = response['total_sessions'] ?? 0;

      if (sessionsUsed >= totalSessions) {
        throw Exception('No sessions remaining');
      }

      // Increment sessions used
      await _supabase
          .from('client_packages')
          .update({
            'sessions_used': sessionsUsed + 1,
            'last_session_date': DateTime.now().toIso8601String(),
          })
          .eq('id', clientPackageId);

      // Check if package is now completed
      if (sessionsUsed + 1 >= totalSessions) {
        await _markPackageCompleted(clientPackageId);
      }

      return true;
    } catch (e) {
      print('Error using session: $e');
      return false;
    }
  }

  /// Return session to package (called if session cancelled)
  Future<bool> returnSession(String clientPackageId) async {
    try {
      final response = await _supabase
          .from('client_packages')
          .select()
          .eq('id', clientPackageId)
          .single();

      final sessionsUsed = response['sessions_used'] ?? 0;
      if (sessionsUsed <= 0) return false;

      await _supabase
          .from('client_packages')
          .update({
            'sessions_used': sessionsUsed - 1,
            'sessions_cancelled': (response['sessions_cancelled'] ?? 0) + 1,
          })
          .eq('id', clientPackageId);

      return true;
    } catch (e) {
      print('Error returning session: $e');
      return false;
    }
  }

  /// Validate booking with package
  Future<PackageBookingValidation> validateBookingWithPackage({
    required String clientPackageId,
    required int sessionsToBook,
  }) async {
    try {
      final response = await _supabase
          .from('client_packages')
          .select('*, packages(*)')
          .eq('id', clientPackageId)
          .single();

      final package = PackageEnterprise.fromMap(
        response['packages'],
        response['packages']['id'],
      );
      final clientPackage = ClientPackageEnterprise.fromMap(
        response,
        response['id'],
        package,
      );

      // Check if package can be used for booking
      if (!clientPackage.canBookSession()) {
        return PackageBookingValidation(
          isValid: false,
          message: 'Package cannot be used for booking',
        );
      }

      // Check if enough sessions remaining
      if (clientPackage.remainingSessions < sessionsToBook) {
        return PackageBookingValidation(
          isValid: false,
          message: 'Not enough sessions remaining (${clientPackage.remainingSessions} available)',
          suggestUpgrade: true,
        );
      }

      // Check if booking is before expiry
      final latestBookingDate = DateTime.now().add(Duration(days: 30));
      if (latestBookingDate.isAfter(clientPackage.expiryDate)) {
        return PackageBookingValidation(
          isValid: false,
          message: 'Package will expire before session date',
          suggestExtension: true,
        );
      }

      return PackageBookingValidation(
        isValid: true,
        message: 'Valid',
      );
    } catch (e) {
      print('Error validating booking: $e');
      return PackageBookingValidation(
        isValid: false,
        message: 'Validation error',
      );
    }
  }

  // ============================================================================
  // PACKAGE LIFECYCLE MANAGEMENT
  // ============================================================================

  /// Freeze package
  Future<bool> freezePackage(String clientPackageId, int freezeDays) async {
    try {
      final now = DateTime.now();
      final freezeEnd = now.add(Duration(days: freezeDays));

      await _supabase
          .from('client_packages')
          .update({
            'status': PackageStatus.frozen.name,
            'has_freeze': true,
            'freeze_start_date': now.toIso8601String(),
            'freeze_end_date': freezeEnd.toIso8601String(),
            'freeze_days_remaining': freezeDays,
          })
          .eq('id', clientPackageId);

      // Extend expiry date
      final response = await _supabase
          .from('client_packages')
          .select('expiry_date')
          .eq('id', clientPackageId)
          .single();

      final currentExpiry = DateTime.parse(response['expiry_date']);
      final newExpiry = currentExpiry.add(Duration(days: freezeDays));

      await _supabase
          .from('client_packages')
          .update({'expiry_date': newExpiry.toIso8601String()})
          .eq('id', clientPackageId);

      return true;
    } catch (e) {
      print('Error freezing package: $e');
      return false;
    }
  }

  /// Unfreeze package
  Future<bool> unfreezePackage(String clientPackageId) async {
    try {
      await _supabase
          .from('client_packages')
          .update({
            'status': PackageStatus.active.name,
            'has_freeze': false,
            'freeze_start_date': null,
            'freeze_end_date': null,
            'freeze_days_remaining': null,
          })
          .eq('id', clientPackageId);

      return true;
    } catch (e) {
      print('Error unfreezing package: $e');
      return false;
    }
  }

  /// Mark package as completed
  Future<void> _markPackageCompleted(String clientPackageId) async {
    await _supabase
        .from('client_packages')
        .update({'status': PackageStatus.completed.name})
        .eq('id', clientPackageId);

    // Track completion
    final response = await _supabase
        .from('client_packages')
        .select('client_id, package_id')
        .eq('id', clientPackageId)
        .single();

    await AnalyticsService.track(
      userId: response['client_id'],
      event: 'package_completed',
      properties: {
        'package_id': response['package_id'],
      },
    );
  }

  /// Check and update expired packages
  Future<void> updateExpiredPackages() async {
    try {
      final now = DateTime.now();

      await _supabase
          .from('client_packages')
          .update({'status': PackageStatus.expired.name})
          .eq('status', PackageStatus.active.name)
          .lt('expiry_date', now.toIso8601String());
    } catch (e) {
      print('Error updating expired packages: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & REPORTING
  // ============================================================================

  /// Get package performance stats
  Future<PackagePerformanceStats> getPackagePerformance(String packageId) async {
    try {
      final clients = await getPackageClients(packageId);

      if (clients.isEmpty) {
        return PackagePerformanceStats(
          totalClients: 0,
          activeClients: 0,
          totalRevenue: 0,
          averageUtilization: 0,
          completionRate: 0,
        );
      }

      final active = clients.where((c) => c.status == PackageStatus.active).length;
      final completed = clients.where((c) => c.status == PackageStatus.completed).length;
      final totalRevenue = clients.fold<double>(0, (sum, c) => sum + c.amountPaid);
      final avgUtilization = clients.fold<double>(0, (sum, c) => sum + c.utilizationRate) / clients.length;
      final completionRate = clients.isEmpty ? 0.0 : completed / clients.length;

      return PackagePerformanceStats(
        totalClients: clients.length,
        activeClients: active,
        totalRevenue: totalRevenue,
        averageUtilization: avgUtilization,
        completionRate: completionRate,
      );
    } catch (e) {
      print('Error getting package performance: $e');
      return PackagePerformanceStats(
        totalClients: 0,
        activeClients: 0,
        totalRevenue: 0,
        averageUtilization: 0,
        completionRate: 0,
      );
    }
  }

  /// Get trainer's package summary
  Future<PackageSummary> getTrainerPackageSummary(String trainerId) async {
    try {
      final response = await _supabase
          .from('client_packages')
          .select('*, packages(*)')
          .eq('trainer_id', trainerId);

      final packages = response as List;

      final active = packages.where((p) => p['status'] == PackageStatus.active.name).length;
      final totalRevenue = packages.fold<double>(0, (sum, p) => sum + (p['amount_paid'] ?? 0).toDouble());
      final totalSessions = packages.fold<int>(0, (sum, p) => sum + (p['sessions_used'] ?? 0));

      return PackageSummary(
        totalPackagesSold: packages.length,
        activePackages: active,
        totalRevenue: totalRevenue,
        totalSessionsDelivered: totalSessions,
      );
    } catch (e) {
      print('Error getting trainer summary: $e');
      return PackageSummary(
        totalPackagesSold: 0,
        activePackages: 0,
        totalRevenue: 0,
        totalSessionsDelivered: 0,
      );
    }
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Send purchase confirmation
  Future<void> _sendPurchaseConfirmation({
    required String clientId,
    required String trainerId,
    required PackageEnterprise package,
    required String clientPackageId,
  }) async {
    try {
      // Notify client
      await _supabase.from('notifications').insert({
        'user_id': clientId,
        'type': 'package_purchased',
        'title': 'Package Purchased',
        'message': 'You have successfully purchased ${package.name}',
        'data': {'client_package_id': clientPackageId},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Notify trainer
      await _supabase.from('notifications').insert({
        'user_id': trainerId,
        'type': 'package_sold',
        'title': 'Package Sold',
        'message': 'A client has purchased ${package.name}',
        'data': {'client_package_id': clientPackageId},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending purchase confirmation: $e');
    }
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class PurchaseResult {
  final bool success;
  final String message;
  final String? clientPackageId;

  PurchaseResult._({
    required this.success,
    required this.message,
    this.clientPackageId,
  });

  factory PurchaseResult.success(String message, {String? clientPackageId}) {
    return PurchaseResult._(
      success: true,
      message: message,
      clientPackageId: clientPackageId,
    );
  }

  factory PurchaseResult.error(String message) {
    return PurchaseResult._(
      success: false,
      message: message,
    );
  }
}

class PackagePurchaseValidation {
  final bool isValid;
  final String message;
  final bool requiresApproval;
  final bool hasActivePackage;

  PackagePurchaseValidation({
    required this.isValid,
    required this.message,
    this.requiresApproval = false,
    this.hasActivePackage = false,
  });
}

class PackageBookingValidation {
  final bool isValid;
  final String message;
  final bool suggestUpgrade;
  final bool suggestExtension;

  PackageBookingValidation({
    required this.isValid,
    required this.message,
    this.suggestUpgrade = false,
    this.suggestExtension = false,
  });
}

class PackagePerformanceStats {
  final int totalClients;
  final int activeClients;
  final double totalRevenue;
  final double averageUtilization;
  final double completionRate;

  PackagePerformanceStats({
    required this.totalClients,
    required this.activeClients,
    required this.totalRevenue,
    required this.averageUtilization,
    required this.completionRate,
  });
}

class PackageSummary {
  final int totalPackagesSold;
  final int activePackages;
  final double totalRevenue;
  final int totalSessionsDelivered;

  PackageSummary({
    required this.totalPackagesSold,
    required this.activePackages,
    required this.totalRevenue,
    required this.totalSessionsDelivered,
  });
}
