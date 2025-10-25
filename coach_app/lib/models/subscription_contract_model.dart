import 'package:flutter/foundation.dart';

/// Subscription contract with e-signature and auto-billing
class SubscriptionContract {
  final String id;
  final String clientId;
  final String trainerId;
  final String packageId;

  // Contract details
  final int sessionsPerWeek;
  final int? customSessionsPerWeek; // If > 3
  final double pricePerMonth;
  final int totalCommitmentMonths;

  // Dates
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? signedDate;

  // E-signature
  final String? clientSignatureUrl;
  final String? clientSignatureData;
  final String? clientIpAddress;
  final String? contractPdfUrl;

  // Status
  final String status; // pending, active, cancelled, completed, suspended
  final DateTime? cancellationDate;
  final String? cancellationReason;

  // Payment
  final String? paymentMethod;
  final bool autoDeductEnabled;
  final DateTime? nextBillingDate;
  final DateTime? lastBillingDate;

  // Metadata
  final String termsVersion;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionContract({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    required this.sessionsPerWeek,
    this.customSessionsPerWeek,
    required this.pricePerMonth,
    required this.totalCommitmentMonths,
    required this.startDate,
    required this.endDate,
    this.signedDate,
    this.clientSignatureUrl,
    this.clientSignatureData,
    this.clientIpAddress,
    this.contractPdfUrl,
    this.status = 'pending',
    this.cancellationDate,
    this.cancellationReason,
    this.paymentMethod,
    this.autoDeductEnabled = true,
    this.nextBillingDate,
    this.lastBillingDate,
    this.termsVersion = '1.0',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isSuspended => status == 'suspended';

  bool get requiresSignature => clientSignatureData == null || signedDate == null;
  bool get isPaymentDue => nextBillingDate != null &&
      nextBillingDate!.isBefore(DateTime.now());

  int get monthsRemaining {
    if (endDate.isBefore(DateTime.now())) return 0;
    return ((endDate.difference(DateTime.now()).inDays) / 30).ceil();
  }

  int get effectiveSessionsPerWeek => customSessionsPerWeek ?? sessionsPerWeek;

  String get displayStatus {
    if (isPaymentDue) return 'Payment Due';
    if (monthsRemaining <= 1 && isActive) return 'Expiring Soon';
    return status[0].toUpperCase() + status.substring(1);
  }

  factory SubscriptionContract.fromJson(Map<String, dynamic> json) {
    return SubscriptionContract(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      packageId: json['package_id'] as String,
      sessionsPerWeek: json['sessions_per_week'] as int,
      customSessionsPerWeek: json['custom_sessions_per_week'] as int?,
      pricePerMonth: (json['price_per_month'] as num).toDouble(),
      totalCommitmentMonths: json['total_commitment_months'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      signedDate: json['signed_date'] != null
          ? DateTime.parse(json['signed_date'] as String)
          : null,
      clientSignatureUrl: json['client_signature_url'] as String?,
      clientSignatureData: json['client_signature_data'] as String?,
      clientIpAddress: json['client_ip_address'] as String?,
      contractPdfUrl: json['contract_pdf_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      cancellationDate: json['cancellation_date'] != null
          ? DateTime.parse(json['cancellation_date'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      paymentMethod: json['payment_method'] as String?,
      autoDeductEnabled: json['auto_deduct_enabled'] as bool? ?? true,
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.parse(json['next_billing_date'] as String)
          : null,
      lastBillingDate: json['last_billing_date'] != null
          ? DateTime.parse(json['last_billing_date'] as String)
          : null,
      termsVersion: json['terms_version'] as String? ?? '1.0',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'package_id': packageId,
      'sessions_per_week': sessionsPerWeek,
      'custom_sessions_per_week': customSessionsPerWeek,
      'price_per_month': pricePerMonth,
      'total_commitment_months': totalCommitmentMonths,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'signed_date': signedDate?.toIso8601String(),
      'client_signature_url': clientSignatureUrl,
      'client_signature_data': clientSignatureData,
      'client_ip_address': clientIpAddress,
      'contract_pdf_url': contractPdfUrl,
      'status': status,
      'cancellation_date': cancellationDate?.toIso8601String().split('T')[0],
      'cancellation_reason': cancellationReason,
      'payment_method': paymentMethod,
      'auto_deduct_enabled': autoDeductEnabled,
      'next_billing_date': nextBillingDate?.toIso8601String().split('T')[0],
      'last_billing_date': lastBillingDate?.toIso8601String().split('T')[0],
      'terms_version': termsVersion,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubscriptionContract copyWith({
    String? id,
    String? clientId,
    String? trainerId,
    String? packageId,
    int? sessionsPerWeek,
    int? customSessionsPerWeek,
    double? pricePerMonth,
    int? totalCommitmentMonths,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? signedDate,
    String? clientSignatureUrl,
    String? clientSignatureData,
    String? clientIpAddress,
    String? contractPdfUrl,
    String? status,
    DateTime? cancellationDate,
    String? cancellationReason,
    String? paymentMethod,
    bool? autoDeductEnabled,
    DateTime? nextBillingDate,
    DateTime? lastBillingDate,
    String? termsVersion,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionContract(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      trainerId: trainerId ?? this.trainerId,
      packageId: packageId ?? this.packageId,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      customSessionsPerWeek: customSessionsPerWeek ?? this.customSessionsPerWeek,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      totalCommitmentMonths: totalCommitmentMonths ?? this.totalCommitmentMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      signedDate: signedDate ?? this.signedDate,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
      clientSignatureData: clientSignatureData ?? this.clientSignatureData,
      clientIpAddress: clientIpAddress ?? this.clientIpAddress,
      contractPdfUrl: contractPdfUrl ?? this.contractPdfUrl,
      status: status ?? this.status,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      autoDeductEnabled: autoDeductEnabled ?? this.autoDeductEnabled,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      lastBillingDate: lastBillingDate ?? this.lastBillingDate,
      termsVersion: termsVersion ?? this.termsVersion,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Payment transaction for packages and subscriptions
class PaymentTransaction {
  final String id;
  final String? contractId;
  final String? clientPackageId;
  final String clientId;
  final String trainerId;

  // Transaction details
  final String transactionType; // subscription_payment, package_purchase, refund
  final double amount;
  final String currency;

  // Payment
  final String? paymentMethod;
  final String paymentStatus; // pending, completed, failed, refunded
  final String? paymentGateway;
  final String? gatewayTransactionId;

  // Dates
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;
  final DateTime transactionDate;
  final DateTime? processedDate;

  // Metadata
  final String? description;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    this.contractId,
    this.clientPackageId,
    required this.clientId,
    required this.trainerId,
    required this.transactionType,
    required this.amount,
    this.currency = 'THB',
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentGateway,
    this.gatewayTransactionId,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    required this.transactionDate,
    this.processedDate,
    this.description,
    this.errorMessage,
    this.metadata,
    required this.createdAt,
  });

  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => paymentStatus == 'completed';
  bool get isFailed => paymentStatus == 'failed';
  bool get isRefunded => paymentStatus == 'refunded';

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      contractId: json['contract_id'] as String?,
      clientPackageId: json['client_package_id'] as String?,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      transactionType: json['transaction_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'THB',
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentGateway: json['payment_gateway'] as String?,
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      billingPeriodStart: json['billing_period_start'] != null
          ? DateTime.parse(json['billing_period_start'] as String)
          : null,
      billingPeriodEnd: json['billing_period_end'] != null
          ? DateTime.parse(json['billing_period_end'] as String)
          : null,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      processedDate: json['processed_date'] != null
          ? DateTime.parse(json['processed_date'] as String)
          : null,
      description: json['description'] as String?,
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'client_package_id': clientPackageId,
      'client_id': clientId,
      'trainer_id': trainerId,
      'transaction_type': transactionType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_gateway': paymentGateway,
      'gateway_transaction_id': gatewayTransactionId,
      'billing_period_start': billingPeriodStart?.toIso8601String().split('T')[0],
      'billing_period_end': billingPeriodEnd?.toIso8601String().split('T')[0],
      'transaction_date': transactionDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'description': description,
      'error_message': errorMessage,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
