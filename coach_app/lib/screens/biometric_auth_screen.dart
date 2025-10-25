import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
// import 'package:local_auth/local_auth.dart'; // Uncomment when adding real biometric

/// Biometric Authentication Screen for PT Coach App
/// Features: Fingerprint/Face ID, Ripple animations, Haptic feedback, Multiple auth options
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({Key? key}) : super(key: key);

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation1;
  late Animation<double> _rippleAnimation2;
  late Animation<double> _rippleAnimation3;
  
  bool _isAuthenticating = false;
  bool _authSuccess = false;
  bool _authFailed = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Main button scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Ripple animations (3 waves)
    _rippleAnimation1 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _rippleAnimation2 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _rippleAnimation3 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
    
    // Start entrance animation
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const Spacer(),
                
                // Title
                FadeTransition(
                  opacity: _scaleAnimation,
                  child: Column(
                    children: [
                      Text(
                        _authSuccess 
                            ? 'Authentication Successful!' 
                            : _authFailed
                                ? 'Authentication Failed'
                                : 'Quick Sign In',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _authSuccess
                            ? 'Welcome back!'
                            : _authFailed
                                ? 'Please try again or use password'
                                : 'Use biometric authentication',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Fingerprint Scanner with Ripple Effect
                _buildFingerprintScanner(),
                
                const SizedBox(height: 60),
                
                // Alternative Auth Options
                _buildAlternativeAuthOptions(),
                
                const Spacer(),
                
                // Fallback to Password
                _buildPasswordFallback(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFingerprintScanner() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple Ring 1
          _buildRippleRing(_rippleAnimation1, 1.0),
          
          // Ripple Ring 2
          _buildRippleRing(_rippleAnimation2, 1.2),
          
          // Ripple Ring 3
          _buildRippleRing(_rippleAnimation3, 1.4),
          
          // Main Fingerprint Button
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _authenticate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _authSuccess
                        ? [const Color(0xFF26DE81), const Color(0xFF0BE881)]
                        : _authFailed
                            ? [const Color(0xFFFF4757), const Color(0xFFFF6348)]
                            : [const Color(0xFF6B73FF), const Color(0xFF000DFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _authSuccess
                          ? const Color(0xFF26DE81).withOpacity(0.6)
                          : _authFailed
                              ? const Color(0xFFFF4757).withOpacity(0.6)
                              : const Color(0xFF6B73FF).withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: _isAuthenticating
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        _authSuccess
                            ? Icons.check_circle_outline
                            : _authFailed
                                ? Icons.error_outline
                                : Icons.fingerprint,
                        size: 70,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRippleRing(Animation<double> animation, double sizeMultiplier) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (animation.value * 0.4 * sizeMultiplier),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6B73FF).withOpacity(
                  (0.8 - animation.value) * 0.5,
                ),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAlternativeAuthOptions() {
    return FadeTransition(
      opacity: _scaleAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAlternativeAuth(
            icon: Icons.face_outlined,
            label: 'Face ID',
            delay: 200,
            onTap: _authenticateWithFaceID,
          ),
          const SizedBox(width: 50),
          _buildAlternativeAuth(
            icon: Icons.pin_outlined,
            label: 'PIN',
            delay: 400,
            onTap: _authenticateWithPIN,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlternativeAuth({
    required IconData icon,
    required String label,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white70, size: 35),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPasswordFallback() {
    return TextButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF6B73FF)),
      label: const Text(
        'Use Password Instead',
        style: TextStyle(
          color: Color(0xFF6B73FF),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================
  
  void _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
      _authSuccess = false;
    });
    
    // Start continuous ripple animation
    _animationController.repeat();
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    try {
      // Simulate biometric authentication (replace with real API)
      await Future.delayed(const Duration(seconds: 2));
      
      // For demo: randomly succeed or fail
      final success = math.Random().nextBool();
      
      if (success) {
        // Success!
        setState(() {
          _isAuthenticating = false;
          _authSuccess = true;
        });
        
        _animationController.stop();
        _animationController.forward(from: 0);
        
        // Success haptic
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        HapticFeedback.lightImpact();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Authentication successful!'),
              backgroundColor: Color(0xFF26DE81),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate to dashboard
          await Future.delayed(const Duration(seconds: 1));
          Navigator.of(context).pushReplacementNamed(
            '/dashboard',
            arguments: 'biometric-user-id',
          );
        }
      } else {
        // Failed
        setState(() {
          _isAuthenticating = false;
          _authFailed = true;
        });
        
        _animationController.stop();
        _animationController.forward(from: 0);
        
        // Error haptic (vibrate pattern)
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
        
        // Shake animation
        _shakeButton();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Authentication failed. Please try again.'),
              backgroundColor: Color(0xFFFF4757),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        
        // Reset after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _authFailed = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authFailed = true;
      });
      
      _animationController.stop();
      _animationController.forward(from: 0);
    }
  }
  
  void _authenticateWithFaceID() async {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Face ID available on supported devices'),
        backgroundColor: Color(0xFF6B73FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // In production, implement actual Face ID here
    // final localAuth = LocalAuthentication();
    // final authenticated = await localAuth.authenticate(...);
  }
  
  void _authenticateWithPIN() {
    HapticFeedback.lightImpact();
    
    // Show PIN entry dialog
    showDialog(
      context: context,
      builder: (context) => _PINEntryDialog(),
    );
  }
  
  void _shakeButton() {
    // Implement shake animation for error feedback
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        HapticFeedback.selectionClick();
      });
    }
  }
}

/// PIN Entry Dialog
class _PINEntryDialog extends StatefulWidget {
  @override
  State<_PINEntryDialog> createState() => _PINEntryDialogState();
}

class _PINEntryDialogState extends State<_PINEntryDialog>
    with SingleTickerProviderStateMixin {
  final List<String> _pinDigits = [];
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter PIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your 4-digit PIN code',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                
                // PIN Dots Display
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = math.sin(_shakeAnimation.value * math.pi * 4) * 10;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _pinDigits.length
                                    ? const Color(0xFF6B73FF)
                                    : Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: index < _pinDigits.length
                                      ? const Color(0xFF6B73FF)
                                      : Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Number Pad
                _buildNumberPad(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow([1, 2, 3]),
        const SizedBox(height: 12),
        _buildNumberRow([4, 5, 6]),
        const SizedBox(height: 12),
        _buildNumberRow([7, 8, 9]),
        const SizedBox(height: 12),
        _buildNumberRow([null, 0, -1]), // -1 represents delete
      ],
    );
  }
  
  Widget _buildNumberRow(List<int?> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number == null) {
          return const SizedBox(width: 70, height: 70);
        }
        
        return _buildNumberButton(number);
      }).toList(),
    );
  }
  
  Widget _buildNumberButton(int number) {
    final isDelete = number == -1;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isDelete) {
            if (_pinDigits.isNotEmpty) {
              setState(() {
                _pinDigits.removeLast();
              });
            }
          } else {
            if (_pinDigits.length < 4) {
              setState(() {
                _pinDigits.add(number.toString());
              });
              
              // Auto-verify when 4 digits entered
              if (_pinDigits.length == 4) {
                _verifyPIN();
              }
            }
          }
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 24)
                : Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  void _verifyPIN() async {
    // Simulate PIN verification
    await Future.delayed(const Duration(milliseconds: 500));
    
    final pin = _pinDigits.join();
    
    // Demo: accept "1234" or any 4 digits for demo
    final correct = pin == "1234" || _pinDigits.length == 4;
    
    if (correct) {
      // Success
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushReplacementNamed(
          '/dashboard',
          arguments: 'pin-user-id',
        );
      }
    } else {
      // Wrong PIN - shake and clear
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _pinDigits.clear();
      });
    }
  }
}

/// Password Fallback Widget
class _buildPasswordFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

