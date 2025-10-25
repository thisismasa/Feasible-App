class PackageModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int sessionCount;
  final int validityDays; // How many days the package is valid for
  final bool isActive;
  final DateTime createdAt;
  
  // Recurring package fields
  final bool isRecurring;
  final String? recurringType; // 'weekly' or 'monthly'
  final int? sessionsPerWeek; // For recurring packages
  final int? minimumCommitmentMonths; // Minimum commitment period
  final double? pricePerSession; // Price per individual session

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sessionCount,
    required this.validityDays,
    required this.isActive,
    required this.createdAt,
    this.isRecurring = false,
    this.recurringType,
    this.sessionsPerWeek,
    this.minimumCommitmentMonths,
    this.pricePerSession,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String id) {
    // Support both camelCase (from stub) and snake_case (from Supabase)
    // Also support total_sessions (new) and session_count (old)
    final packageType = map['package_type'] ?? 'pay_as_you_go';
    final isSubscription = packageType == 'subscription';

    // DEBUG: Print all available keys to find the sessions field
    print('🔍 PackageModel.fromMap - Package: ${map['name']}');
    print('   Available keys: ${map.keys.toList()}');
    print('   sessionCount: ${map['sessionCount']}');
    print('   session_count: ${map['session_count']}');
    print('   sessions: ${map['sessions']}');
    print('   total_sessions: ${map['total_sessions']}');

    return PackageModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? map['price_per_month'] ?? 0).toDouble(),
      sessionCount: map['sessionCount'] ?? map['session_count'] ?? map['sessions'] ?? map['total_sessions'] ?? 0,
      validityDays: map['validityDays'] ?? map['validity_days'] ?? 30,
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : (map['created_at'] != null
              ? DateTime.parse(map['created_at'])
              : DateTime.now()),
      isRecurring: isSubscription,
      recurringType: isSubscription ? 'monthly' : null,
      sessionsPerWeek: map['sessionsPerWeek'] ?? map['sessions_per_week'],
      minimumCommitmentMonths: map['minimumCommitmentMonths'] ?? map['minimum_commitment_months'],
      pricePerSession: (map['pricePerSession'] ?? map['price_per_session'])?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'sessionCount': sessionCount,
      'validityDays': validityDays,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'sessionsPerWeek': sessionsPerWeek,
      'minimumCommitmentMonths': minimumCommitmentMonths,
      'pricePerSession': pricePerSession,
    };
  }
}

class ClientPackage {
  final String id;
  final String clientId;
  final String packageId;
  final String packageName;
  final int totalSessions;
  final int sessionsUsed;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double amountPaid;
  final PackageStatus status;
  final String paymentStatus;

  ClientPackage({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.packageName,
    required this.totalSessions,
    required this.sessionsUsed,
    required this.purchaseDate,
    required this.expiryDate,
    required this.amountPaid,
    required this.status,
    this.paymentStatus = 'paid',
  });

  int get remainingSessions => totalSessions - sessionsUsed;
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get hasSessionsRemaining => sessionsUsed < totalSessions;

  factory ClientPackage.fromMap(Map<String, dynamic> map, String id) {
    return ClientPackage(
      id: id,
      clientId: map['clientId'] ?? '',
      packageId: map['packageId'] ?? '',
      packageName: map['packageName'] ?? '',
      totalSessions: map['totalSessions'] ?? 0,
      sessionsUsed: map['sessionsUsed'] ?? 0,
      purchaseDate: DateTime.parse(map['purchaseDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      status: PackageStatus.values.firstWhere(
        (e) => e.toString() == 'PackageStatus.${map['status']}',
        orElse: () => PackageStatus.active,
      ),
      paymentStatus: map['paymentStatus'] ?? 'paid',
    );
  }
  
  factory ClientPackage.fromSupabaseMap(Map<String, dynamic> map) {
    return ClientPackage(
      id: map['id'] ?? '',
      clientId: map['client_id'] ?? '',
      packageId: map['package_id'] ?? '',
      packageName: map['package_name'] ?? 'Unknown Package',
      totalSessions: map['total_sessions'] ?? 0,
      sessionsUsed: map['sessions_used'] ?? 0,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'])
          : DateTime.now(),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : DateTime.now().add(const Duration(days: 30)),
      amountPaid: (map['amount_paid'] ?? 0).toDouble(),
      status: PackageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PackageStatus.active,
      ),
      paymentStatus: map['payment_status'] ?? 'paid',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'packageId': packageId,
      'packageName': packageName,
      'totalSessions': totalSessions,
      'sessionsUsed': sessionsUsed,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'amountPaid': amountPaid,
      'status': status.name,
    };
  }
}

enum PackageStatus {
  active,
  expired,
  completed,
}
