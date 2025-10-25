/// Payment Configuration for Coach App
/// Supports 4 payment methods: PromptPay, Credit Card, Bank Transfer, Manual

class PaymentConfig {
  // Payment method types
  static const String promptPay = 'promptpay';
  static const String creditCard = 'credit_card';
  static const String bankTransfer = 'bank_transfer';
  static const String manual = 'manual';

  // PromptPay Configuration
  static const String promptPayId = '0123456789'; // TODO: Replace with your PromptPay ID/Phone Number
  static const String promptPayName = 'Your Training Business Name'; // TODO: Replace with your business name

  // Bank Transfer Configuration
  static const String bankName = 'Bangkok Bank'; // TODO: Replace with your bank
  static const String bankAccountNumber = '123-4-56789-0'; // TODO: Replace with your account number
  static const String bankAccountName = 'Your Training Business'; // TODO: Replace with account name
  static const String bankBranch = 'Main Branch'; // TODO: Replace with branch name

  // Payment Gateway Configuration (Omise for Thailand)
  // Omise is preferred for Thai businesses over Stripe
  static const String omisePublicKey = 'pkey_test_xxxxxxxxxxxxx'; // TODO: Replace with your Omise public key
  static const bool useProductionKeys = false; // Set to true for production

  // Subscription Billing Rules
  static const int minimumCommitmentMonths = 3;
  static const bool autoRenewAfterCommitment = true;
  static const int billingCycleDays = 30; // Monthly billing

  // Payment deadline configuration
  static const int paymentDueDays = 7; // Days before subscription expires to charge
  static const int paymentReminderDays = 3; // Days before due date to send reminder

  // Supported payment methods for package types
  static List<String> getPaymentMethodsForPackageType(String packageType) {
    if (packageType == 'subscription') {
      // Subscriptions support all methods, but credit card enables auto-billing
      return [promptPay, creditCard, bankTransfer, manual];
    } else {
      // Pay-as-you-go supports all methods except auto-billing
      return [promptPay, creditCard, bankTransfer, manual];
    }
  }

  // Check if payment method supports auto-billing
  static bool supportsAutoBilling(String paymentMethod) {
    return paymentMethod == creditCard;
  }

  // Get payment method display name
  static String getPaymentMethodName(String method) {
    switch (method) {
      case promptPay:
        return 'PromptPay QR Code';
      case creditCard:
        return 'Credit Card (Auto-billing)';
      case bankTransfer:
        return 'Bank Transfer';
      case manual:
        return 'Manual Payment';
      default:
        return 'Unknown';
    }
  }

  // Get payment method icon
  static String getPaymentMethodIcon(String method) {
    switch (method) {
      case promptPay:
        return '📱'; // QR code icon
      case creditCard:
        return '💳'; // Credit card icon
      case bankTransfer:
        return '🏦'; // Bank icon
      case manual:
        return '💵'; // Cash icon
      default:
        return '💰';
    }
  }

  // Calculate next billing date
  static DateTime getNextBillingDate(DateTime startDate, int monthsElapsed) {
    return DateTime(
      startDate.year,
      startDate.month + monthsElapsed + 1,
      startDate.day,
    );
  }

  // Check if subscription is within commitment period
  static bool isWithinCommitmentPeriod(DateTime startDate, DateTime currentDate) {
    final commitmentEndDate = DateTime(
      startDate.year,
      startDate.month + minimumCommitmentMonths,
      startDate.day,
    );
    return currentDate.isBefore(commitmentEndDate);
  }

  // Calculate early cancellation penalty (if needed)
  static double calculateCancellationPenalty(
    DateTime startDate,
    DateTime cancellationDate,
    double monthlyPrice,
  ) {
    if (isWithinCommitmentPeriod(startDate, cancellationDate)) {
      // Calculate remaining months in commitment
      final commitmentEndDate = DateTime(
        startDate.year,
        startDate.month + minimumCommitmentMonths,
        startDate.day,
      );
      final monthsRemaining = commitmentEndDate.difference(cancellationDate).inDays / 30;

      // Could charge remaining months or a fixed penalty
      // For now, return 0 (no cancellation during commitment period)
      return 0.0; // Client must complete commitment
    }
    return 0.0; // No penalty after commitment period
  }
}

/// Payment method model
class PaymentMethodModel {
  final String id;
  final String name;
  final String icon;
  final bool supportsAutoBilling;
  final String description;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.supportsAutoBilling,
    required this.description,
  });

  static List<PaymentMethodModel> getAllMethods() {
    return [
      PaymentMethodModel(
        id: PaymentConfig.promptPay,
        name: 'PromptPay',
        icon: '📱',
        supportsAutoBilling: false,
        description: 'Scan QR code to pay instantly',
      ),
      PaymentMethodModel(
        id: PaymentConfig.creditCard,
        name: 'Credit Card',
        icon: '💳',
        supportsAutoBilling: true,
        description: 'Auto-billing for subscriptions',
      ),
      PaymentMethodModel(
        id: PaymentConfig.bankTransfer,
        name: 'Bank Transfer',
        icon: '🏦',
        supportsAutoBilling: false,
        description: 'Transfer to bank account',
      ),
      PaymentMethodModel(
        id: PaymentConfig.manual,
        name: 'Cash/Manual',
        icon: '💵',
        supportsAutoBilling: false,
        description: 'Pay in person',
      ),
    ];
  }
}
