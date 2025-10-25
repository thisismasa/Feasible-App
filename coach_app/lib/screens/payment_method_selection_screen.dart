import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import '../models/package_model.dart';
import '../models/user_model.dart';
import 'promptpay_payment_screen.dart';
import 'credit_card_payment_screen.dart';
import 'bank_transfer_screen.dart';
import '../services/payment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final PackageModel package;
  final UserModel client;
  final bool isSubscription;

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.package,
    required this.client,
    this.isSubscription = false,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedMethod;
  bool _isProcessing = false;

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption(
      id: 'promptpay',
      name: 'PromptPay',
      subtitle: 'Instant payment via QR code',
      icon: Icons.qr_code_scanner,
      gradient: [Color(0xFF4A90E2), Color(0xFF357ABD)],
      badge: 'Instant',
      recommended: true,
    ),
    PaymentMethodOption(
      id: 'credit_card',
      name: 'Credit Card',
      subtitle: 'Visa, Mastercard, AMEX',
      icon: Icons.credit_card,
      gradient: [Color(0xFF6B46C1), Color(0xFF553C9A)],
      badge: 'Auto-billing',
      autoBillingOnly: true,
    ),
    PaymentMethodOption(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      subtitle: 'Kasikorn Bank',
      icon: Icons.account_balance,
      gradient: [Color(0xFF48BB78), Color(0xFF38A169)],
      badge: 'Manual',
    ),
    PaymentMethodOption(
      id: 'manual',
      name: 'Cash / In Person',
      subtitle: 'Pay directly to trainer',
      icon: Icons.payments,
      gradient: [Color(0xFFED8936), Color(0xFFDD6B20)],
      badge: 'In Person',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildPackageCard(),
                      const SizedBox(height: 32),
                      _buildPaymentMethodsTitle(),
                      const SizedBox(height: 16),
                      ..._buildPaymentMethodCards(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue.shade700, Colors.purple.shade600],
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select how you want to pay for ${widget.client.name}\'s package',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.package.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.package.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPackageDetail(
                    Icons.fitness_center,
                    '${widget.package.sessionCount} Sessions',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildPackageDetail(
                    Icons.calendar_today,
                    '${widget.package.validityDays} Days',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '฿${widget.package.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsTitle() {
    return Row(
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_paymentMethods.length} options',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentMethodCards() {
    return List.generate(_paymentMethods.length, (index) {
      final method = _paymentMethods[index];
      final delay = Duration(milliseconds: 100 * index);

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 500 + (index * 100)),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPaymentMethodCard(method),
        ),
      );
    });
  }

  Widget _buildPaymentMethodCard(PaymentMethodOption method) {
    final isSelected = _selectedMethod == method.id;
    final isSubscription = widget.isSubscription;

    // Show auto-billing badge for subscriptions
    final showAutoBillingBadge = isSubscription && method.autoBillingOnly;

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      transitionDuration: const Duration(milliseconds: 500),
      closedColor: Colors.transparent,
      openColor: Colors.white,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: () {
            // Haptic feedback for better UX
            HapticFeedback.lightImpact();
            setState(() {
              _selectedMethod = method.id;
            });
            // Show success feedback
            _showMethodSelectedFeedback(method.name);
          },
          onLongPress: () {
            // Haptic feedback for long press
            HapticFeedback.mediumImpact();
            _showPaymentMethodDetails(method);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: method.gradient,
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? method.gradient[0].withOpacity(0.4)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 20 : 10,
                  offset: Offset(0, isSelected ? 10 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : method.gradient[0].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    method.icon,
                    color: isSelected ? Colors.white : method.gradient[0],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (method.recommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⭐ Best',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (showAutoBillingBadge) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔄 Required for auto-billing',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: method.gradient[0],
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
      openBuilder: (context, _) => _getPaymentScreen(method.id),
    );
  }

  Widget _getPaymentScreen(String methodId) {
    switch (methodId) {
      case 'promptpay':
        return PromptPayPaymentScreen(
          package: widget.package,
          client: widget.client,
        );
      case 'credit_card':
        return CreditCardPaymentScreen(
          package: widget.package,
          client: widget.client,
          isSubscription: widget.isSubscription,
        );
      case 'bank_transfer':
        return BankTransferScreen(
          package: widget.package,
          client: widget.client,
        );
      default:
        return Container(); // Manual payment handled by trainer
    }
  }

  Widget _buildBottomBar() {
    final canProceed = _selectedMethod != null && !_isProcessing;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            onPressed: canProceed ? _proceedToPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canProceed ? 8 : 0,
              shadowColor: Colors.blue.shade300,
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: canProceed ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward,
                        color: canProceed ? Colors.white : Colors.grey.shade500,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _proceedToPayment() async {
    if (_selectedMethod == null || _isProcessing) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isProcessing = true;
    });

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    // Handle manual payment (trainer marks as paid)
    if (_selectedMethod == 'manual') {
      setState(() {
        _isProcessing = false;
      });
      _showManualPaymentDialog();
      return;
    }

    // Navigate to specific payment screen
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedMethod,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _getPaymentScreen(_selectedMethod!),
      ),
    );

    setState(() {
      _isProcessing = false;
    });

    // Handle payment result
    if (result != null && mounted) {
      _handlePaymentResult(result);
    }
  }

  void _handlePaymentResult(dynamic result) {
    if (result is String) {
      if (result == 'promptpay_completed' ||
          result == 'bank_transfer_completed' ||
          result == 'credit_card_completed') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Payment recorded successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Return to previous screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, result);
          }
        });
      }
    }
  }

  void _showMethodSelectedFeedback(String methodName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('$methodName selected'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _showPaymentMethodDetails(PaymentMethodOption method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Method icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: method.gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    method.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        method.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Details based on payment method
            _buildMethodSpecificDetails(method),

            const SizedBox(height: 24),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: method.gradient[0],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSpecificDetails(PaymentMethodOption method) {
    String details = '';
    List<String> features = [];

    switch (method.id) {
      case 'promptpay':
        details = 'Instant payment using QR code. Scan with any Thai banking app.';
        features = [
          'Instant confirmation',
          'No fees',
          'Secure and verified',
          'All Thai banks supported',
        ];
        break;
      case 'credit_card':
        details = 'Pay with Visa, Mastercard, or AMEX. Required for subscription auto-billing.';
        features = [
          'Auto-billing for subscriptions',
          'Secure card storage',
          'International cards accepted',
          'Instant confirmation',
        ];
        break;
      case 'bank_transfer':
        details = 'Transfer directly to Kasikorn Bank account. Manual verification required.';
        features = [
          'No transaction fees',
          'Upload receipt for faster processing',
          'Verification within 24 hours',
          'Available 24/7',
        ];
        break;
      case 'manual':
        details = 'Pay directly to your trainer in person with cash.';
        features = [
          'Flexible payment',
          'No online transaction',
          'Pay at session',
          'Trainer confirmation required',
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          details,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Features:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: method.gradient[0],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showManualPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.payments, color: Colors.orange),
            SizedBox(width: 12),
            Text('Manual Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The client will pay you directly in person.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can mark this as paid later in the app',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Record manual payment to database
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                final transactionId = await PaymentService.instance.recordManualPayment(
                  clientId: widget.client.id,
                  trainerId: user.id,
                  package: widget.package,
                );

                if (transactionId != null) {
                  debugPrint('✅ Manual payment recorded: $transactionId');
                } else {
                  debugPrint('⚠️ Failed to record manual payment');
                }
              }

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context, 'manual');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodOption {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String badge;
  final bool recommended;
  final bool autoBillingOnly;

  PaymentMethodOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.badge,
    this.recommended = false,
    this.autoBillingOnly = false,
  });
}
