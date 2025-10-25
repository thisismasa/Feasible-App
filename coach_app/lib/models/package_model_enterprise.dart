// ENTERPRISE PACKAGE MODEL
// Advanced package management with business logic, pricing tiers, and auto-renewal

import 'package:flutter/material.dart';

/// Enterprise-level package with advanced features
class PackageEnterprise {
  final String id;
  final String name;
  final String description;
  final PackageTier tier;
  final PackageType type;
  final PricingModel pricingModel;

  // Core attributes
  final int sessionCount;
  final int validityDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Pricing
  final double basePrice;
  final double? discountedPrice;
  final double? taxRate;
  final String currency;

  // Recurring options
  final bool isRecurring;
  final RecurringPeriod? recurringPeriod;
  final int? sessionsPerWeek;
  final int? minimumCommitmentMonths;
  final bool autoRenew;
  final DateTime? nextRenewalDate;

  // Features & Benefits
  final List<String> features;
  final Map<String, dynamic> benefits;
  final bool includeNutritionPlan;
  final bool includeProgressTracking;
  final bool priorityBooking;
  final int? rescheduleLimit;
  final int? cancellationNoticeDays;

  // Business logic
  final int? maxClientsPerMonth;
  final bool requiresApproval;
  final String? targetAudience;
  final List<String>? prerequisites;

  // Promotional
  final bool isFeatured;
  final int? displayOrder;
  final String? promoCode;
  final DateTime? promoExpiryDate;
  final double? earlyBirdDiscount;

  // Meta
  final Map<String, dynamic>? metadata;
  final String? termsAndConditions;
  final String? cancellationPolicy;

  PackageEnterprise({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.type,
    required this.pricingModel,
    required this.sessionCount,
    required this.validityDays,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.basePrice,
    this.discountedPrice,
    this.taxRate,
    this.currency = 'USD',
    this.isRecurring = false,
    this.recurringPeriod,
    this.sessionsPerWeek,
    this.minimumCommitmentMonths,
    this.autoRenew = false,
    this.nextRenewalDate,
    this.features = const [],
    this.benefits = const {},
    this.includeNutritionPlan = false,
    this.includeProgressTracking = false,
    this.priorityBooking = false,
    this.rescheduleLimit,
    this.cancellationNoticeDays,
    this.maxClientsPerMonth,
    this.requiresApproval = false,
    this.targetAudience,
    this.prerequisites,
    this.isFeatured = false,
    this.displayOrder,
    this.promoCode,
    this.promoExpiryDate,
    this.earlyBirdDiscount,
    this.metadata,
    this.termsAndConditions,
    this.cancellationPolicy,
  });

  // Business Logic Methods

  /// Get effective price with discounts
  double get effectivePrice {
    if (discountedPrice != null) return discountedPrice!;
    if (earlyBirdDiscount != null && _isEarlyBirdValid()) {
      return basePrice * (1 - earlyBirdDiscount!);
    }
    return basePrice;
  }

  /// Get price per session
  double get pricePerSession => effectivePrice / sessionCount;

  /// Get total price including tax
  double get totalPrice {
    if (taxRate == null) return effectivePrice;
    return effectivePrice * (1 + taxRate!);
  }

  /// Calculate savings from discount
  double? get savings {
    if (discountedPrice != null) {
      return basePrice - discountedPrice!;
    }
    if (earlyBirdDiscount != null && _isEarlyBirdValid()) {
      return basePrice * earlyBirdDiscount!;
    }
    return null;
  }

  /// Get discount percentage
  double? get discountPercentage {
    if (savings == null) return null;
    return (savings! / basePrice) * 100;
  }

  /// Check if early bird discount is still valid
  bool _isEarlyBirdValid() {
    if (promoExpiryDate == null) return false;
    return DateTime.now().isBefore(promoExpiryDate!);
  }

  /// Check if package is available for purchase
  bool get isAvailableForPurchase {
    if (!isActive) return false;
    if (maxClientsPerMonth != null) {
      // Would check current month's purchases
      return true; // Placeholder
    }
    return true;
  }

  /// Get color scheme based on tier
  Color get tierColor {
    switch (tier) {
      case PackageTier.basic:
        return Colors.blue;
      case PackageTier.standard:
        return Colors.purple;
      case PackageTier.premium:
        return Colors.amber;
      case PackageTier.elite:
        return Colors.black;
    }
  }

  /// Get icon based on tier
  IconData get tierIcon {
    switch (tier) {
      case PackageTier.basic:
        return Icons.star_border;
      case PackageTier.standard:
        return Icons.star_half;
      case PackageTier.premium:
        return Icons.star;
      case PackageTier.elite:
        return Icons.stars;
    }
  }

  /// Check if package is suitable for client
  bool isSuitableFor({
    required String clientLevel,
    required List<String> clientGoals,
  }) {
    if (targetAudience != null && targetAudience != clientLevel) {
      return false;
    }
    if (prerequisites != null && prerequisites!.isNotEmpty) {
      // Check if client meets prerequisites
      return true; // Placeholder
    }
    return true;
  }

  /// Calculate expiry date from purchase date
  DateTime calculateExpiryDate(DateTime purchaseDate) {
    return purchaseDate.add(Duration(days: validityDays));
  }

  /// Factory methods
  factory PackageEnterprise.fromMap(Map<String, dynamic> map, String id) {
    return PackageEnterprise(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      tier: PackageTier.values.firstWhere(
        (e) => e.name == (map['tier'] ?? 'basic'),
        orElse: () => PackageTier.basic,
      ),
      type: PackageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'session_pack'),
        orElse: () => PackageType.sessionPack,
      ),
      pricingModel: PricingModel.values.firstWhere(
        (e) => e.name == (map['pricing_model'] ?? 'one_time'),
        orElse: () => PricingModel.oneTime,
      ),
      sessionCount: map['session_count'] ?? 0,
      validityDays: map['validity_days'] ?? 30,
      isActive: map['is_active'] ?? true,
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']),
      basePrice: (map['base_price'] ?? 0).toDouble(),
      discountedPrice: map['discounted_price']?.toDouble(),
      taxRate: map['tax_rate']?.toDouble(),
      currency: map['currency'] ?? 'USD',
      isRecurring: map['is_recurring'] ?? false,
      recurringPeriod: map['recurring_period'] != null
          ? RecurringPeriod.values.firstWhere(
              (e) => e.name == map['recurring_period'],
              orElse: () => RecurringPeriod.monthly,
            )
          : null,
      sessionsPerWeek: map['sessions_per_week'],
      minimumCommitmentMonths: map['minimum_commitment_months'],
      autoRenew: map['auto_renew'] ?? false,
      nextRenewalDate: _parseDateTime(map['next_renewal_date']),
      features: _parseList(map['features']),
      benefits: map['benefits'] ?? {},
      includeNutritionPlan: map['include_nutrition_plan'] ?? false,
      includeProgressTracking: map['include_progress_tracking'] ?? false,
      priorityBooking: map['priority_booking'] ?? false,
      rescheduleLimit: map['reschedule_limit'],
      cancellationNoticeDays: map['cancellation_notice_days'],
      maxClientsPerMonth: map['max_clients_per_month'],
      requiresApproval: map['requires_approval'] ?? false,
      targetAudience: map['target_audience'],
      prerequisites: _parseList(map['prerequisites']),
      isFeatured: map['is_featured'] ?? false,
      displayOrder: map['display_order'],
      promoCode: map['promo_code'],
      promoExpiryDate: _parseDateTime(map['promo_expiry_date']),
      earlyBirdDiscount: map['early_bird_discount']?.toDouble(),
      metadata: map['metadata'],
      termsAndConditions: map['terms_and_conditions'],
      cancellationPolicy: map['cancellation_policy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tier': tier.name,
      'type': type.name,
      'pricing_model': pricingModel.name,
      'session_count': sessionCount,
      'validity_days': validityDays,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'base_price': basePrice,
      'discounted_price': discountedPrice,
      'tax_rate': taxRate,
      'currency': currency,
      'is_recurring': isRecurring,
      'recurring_period': recurringPeriod?.name,
      'sessions_per_week': sessionsPerWeek,
      'minimum_commitment_months': minimumCommitmentMonths,
      'auto_renew': autoRenew,
      'next_renewal_date': nextRenewalDate?.toIso8601String(),
      'features': features,
      'benefits': benefits,
      'include_nutrition_plan': includeNutritionPlan,
      'include_progress_tracking': includeProgressTracking,
      'priority_booking': priorityBooking,
      'reschedule_limit': rescheduleLimit,
      'cancellation_notice_days': cancellationNoticeDays,
      'max_clients_per_month': maxClientsPerMonth,
      'requires_approval': requiresApproval,
      'target_audience': targetAudience,
      'prerequisites': prerequisites,
      'is_featured': isFeatured,
      'display_order': displayOrder,
      'promo_code': promoCode,
      'promo_expiry_date': promoExpiryDate?.toIso8601String(),
      'early_bird_discount': earlyBirdDiscount,
      'metadata': metadata,
      'terms_and_conditions': termsAndConditions,
      'cancellation_policy': cancellationPolicy,
    };
  }

  // Helper methods
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

/// Client's purchased package with usage tracking
class ClientPackageEnterprise {
  final String id;
  final String clientId;
  final String clientName;
  final String trainerId;
  final String packageId;
  final PackageEnterprise package;

  // Purchase details
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double amountPaid;
  final String paymentMethod;
  final String? transactionId;
  final PackageStatus status;

  // Usage tracking
  final int totalSessions;
  final int sessionsUsed;
  final int sessionsScheduled;
  final int sessionsCancelled;
  final int sessionsNoShow;
  final DateTime? lastSessionDate;
  final DateTime? nextSessionDate;

  // Recurring subscription
  final bool isSubscription;
  final DateTime? nextBillingDate;
  final bool autoRenewEnabled;
  final String? subscriptionId;
  final SubscriptionStatus? subscriptionStatus;

  // Modifications
  final List<PackageModification> modifications;
  final bool hasFreeze;
  final DateTime? freezeStartDate;
  final DateTime? freezeEndDate;
  final int? freezeDaysRemaining;

  // Analytics
  final double utilizationRate;
  final double averageSessionInterval;
  final Map<String, dynamic>? usageStats;

  ClientPackageEnterprise({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    required this.packageId,
    required this.package,
    required this.purchaseDate,
    required this.expiryDate,
    required this.amountPaid,
    required this.paymentMethod,
    this.transactionId,
    required this.status,
    required this.totalSessions,
    required this.sessionsUsed,
    this.sessionsScheduled = 0,
    this.sessionsCancelled = 0,
    this.sessionsNoShow = 0,
    this.lastSessionDate,
    this.nextSessionDate,
    this.isSubscription = false,
    this.nextBillingDate,
    this.autoRenewEnabled = false,
    this.subscriptionId,
    this.subscriptionStatus,
    this.modifications = const [],
    this.hasFreeze = false,
    this.freezeStartDate,
    this.freezeEndDate,
    this.freezeDaysRemaining,
    required this.utilizationRate,
    this.averageSessionInterval = 0,
    this.usageStats,
  });

  // Business Logic

  /// Remaining sessions available
  int get remainingSessions => totalSessions - sessionsUsed - sessionsScheduled;

  /// Check if package is expired
  bool get isExpired {
    if (hasFreeze) return false; // Frozen packages don't expire
    return DateTime.now().isAfter(expiryDate);
  }

  /// Check if has available sessions
  bool get hasSessionsAvailable => remainingSessions > 0 && !isExpired;

  /// Check if package is nearing expiry (< 7 days)
  bool get isNearingExpiry {
    if (isExpired) return false;
    return expiryDate.difference(DateTime.now()).inDays < 7;
  }

  /// Check if package usage is low (< 30% used with < 30% time remaining)
  bool get hasLowUsage {
    final timeElapsed = DateTime.now().difference(purchaseDate).inDays;
    final totalDays = expiryDate.difference(purchaseDate).inDays;
    final timeProgress = timeElapsed / totalDays;
    final sessionProgress = sessionsUsed / totalSessions;

    return timeProgress > 0.7 && sessionProgress < 0.3;
  }

  /// Check if eligible for renewal
  bool get isEligibleForRenewal {
    if (isSubscription && autoRenewEnabled) return false; // Auto-renews
    return remainingSessions <= 2 || isNearingExpiry;
  }

  /// Get health score (0-100)
  int get healthScore {
    if (totalSessions == 0) return 0;

    int score = 50; // Base score

    // Usage rate (0-30 points)
    final usageRate = sessionsUsed / totalSessions;
    score += (usageRate * 30).round();

    // Consistency (0-20 points)
    if (averageSessionInterval > 0 && averageSessionInterval < 7) {
      score += 20; // Good consistency
    } else if (averageSessionInterval < 14) {
      score += 10; // Acceptable consistency
    }

    // No-show rate (-20 points)
    if (sessionsUsed > 0) {
      final noShowRate = sessionsNoShow / sessionsUsed;
      score -= (noShowRate * 20).round();
    }

    // Cancellation rate (-10 points)
    if (sessionsUsed > 0) {
      final cancelRate = sessionsCancelled / sessionsUsed;
      score -= (cancelRate * 10).round();
    }

    return score.clamp(0, 100);
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case PackageStatus.active:
        return Colors.green;
      case PackageStatus.expired:
        return Colors.red;
      case PackageStatus.completed:
        return Colors.grey;
      case PackageStatus.frozen:
        return Colors.blue;
      case PackageStatus.cancelled:
        return Colors.orange;
    }
  }

  /// Get usage progress (0-1)
  double get usageProgress {
    if (totalSessions == 0) return 0;
    return (sessionsUsed / totalSessions).clamp(0.0, 1.0);
  }

  /// Get time progress (0-1)
  double get timeProgress {
    final totalDays = expiryDate.difference(purchaseDate).inDays;
    if (totalDays == 0) return 1.0;
    final elapsed = DateTime.now().difference(purchaseDate).inDays;
    return (elapsed / totalDays).clamp(0.0, 1.0);
  }

  /// Can book new session
  bool canBookSession() {
    if (!hasSessionsAvailable) return false;
    if (status == PackageStatus.frozen) return false;
    if (status == PackageStatus.cancelled) return false;
    return true;
  }

  /// Can cancel/reschedule session
  bool canModifySession(DateTime sessionDate) {
    if (package.cancellationNoticeDays == null) return true;

    final hoursUntilSession = sessionDate.difference(DateTime.now()).inHours;
    final requiredHours = package.cancellationNoticeDays! * 24;

    return hoursUntilSession >= requiredHours;
  }

  /// Factory method
  factory ClientPackageEnterprise.fromMap(
    Map<String, dynamic> map,
    String id,
    PackageEnterprise package,
  ) {
    return ClientPackageEnterprise(
      id: id,
      clientId: map['client_id'] ?? '',
      clientName: map['client_name'] ?? '',
      trainerId: map['trainer_id'] ?? '',
      packageId: map['package_id'] ?? '',
      package: package,
      purchaseDate: _parseDateTime(map['purchase_date']) ?? DateTime.now(),
      expiryDate: _parseDateTime(map['expiry_date']) ?? DateTime.now(),
      amountPaid: (map['amount_paid'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'unknown',
      transactionId: map['transaction_id'],
      status: PackageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PackageStatus.active,
      ),
      totalSessions: map['total_sessions'] ?? 0,
      sessionsUsed: map['sessions_used'] ?? 0,
      sessionsScheduled: map['sessions_scheduled'] ?? 0,
      sessionsCancelled: map['sessions_cancelled'] ?? 0,
      sessionsNoShow: map['sessions_no_show'] ?? 0,
      lastSessionDate: _parseDateTime(map['last_session_date']),
      nextSessionDate: _parseDateTime(map['next_session_date']),
      isSubscription: map['is_subscription'] ?? false,
      nextBillingDate: _parseDateTime(map['next_billing_date']),
      autoRenewEnabled: map['auto_renew_enabled'] ?? false,
      subscriptionId: map['subscription_id'],
      subscriptionStatus: map['subscription_status'] != null
          ? SubscriptionStatus.values.firstWhere(
              (e) => e.name == map['subscription_status'],
              orElse: () => SubscriptionStatus.active,
            )
          : null,
      modifications: [],
      hasFreeze: map['has_freeze'] ?? false,
      freezeStartDate: _parseDateTime(map['freeze_start_date']),
      freezeEndDate: _parseDateTime(map['freeze_end_date']),
      freezeDaysRemaining: map['freeze_days_remaining'],
      utilizationRate: (map['utilization_rate'] ?? 0).toDouble(),
      averageSessionInterval: (map['average_session_interval'] ?? 0).toDouble(),
      usageStats: map['usage_stats'],
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'client_name': clientName,
      'trainer_id': trainerId,
      'package_id': packageId,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': status.name,
      'total_sessions': totalSessions,
      'sessions_used': sessionsUsed,
      'sessions_scheduled': sessionsScheduled,
      'sessions_cancelled': sessionsCancelled,
      'sessions_no_show': sessionsNoShow,
      'last_session_date': lastSessionDate?.toIso8601String(),
      'next_session_date': nextSessionDate?.toIso8601String(),
      'is_subscription': isSubscription,
      'next_billing_date': nextBillingDate?.toIso8601String(),
      'auto_renew_enabled': autoRenewEnabled,
      'subscription_id': subscriptionId,
      'subscription_status': subscriptionStatus?.name,
      'has_freeze': hasFreeze,
      'freeze_start_date': freezeStartDate?.toIso8601String(),
      'freeze_end_date': freezeEndDate?.toIso8601String(),
      'freeze_days_remaining': freezeDaysRemaining,
      'utilization_rate': utilizationRate,
      'average_session_interval': averageSessionInterval,
      'usage_stats': usageStats,
    };
  }
}

/// Package modification history
class PackageModification {
  final String id;
  final DateTime modifiedDate;
  final ModificationType type;
  final String description;
  final Map<String, dynamic>? details;
  final String? modifiedBy;

  PackageModification({
    required this.id,
    required this.modifiedDate,
    required this.type,
    required this.description,
    this.details,
    this.modifiedBy,
  });
}

/// Enums
enum PackageTier {
  basic,
  standard,
  premium,
  elite,
}

enum PackageType {
  sessionPack,     // Fixed number of sessions
  subscription,    // Recurring monthly/weekly
  unlimited,       // Unlimited sessions in period
  classPass,       // Access to group classes
  hybrid,          // Mix of personal + group
}

enum PricingModel {
  oneTime,         // Single payment
  recurring,       // Subscription model
  payPerSession,   // Pay as you go
  tiered,          // Pricing changes with usage
}

enum RecurringPeriod {
  weekly,
  biweekly,
  monthly,
  quarterly,
  annually,
}

enum PackageStatus {
  active,
  expired,
  completed,
  frozen,
  cancelled,
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled,
  pastDue,
  trialing,
}

enum ModificationType {
  sessionsAdded,
  sessionsFrozen,
  sessionsExtended,
  priceAdjusted,
  upgraded,
  downgraded,
}
