import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/supabase_service.dart';
import '../services/real_supabase_service.dart';
import '../services/google_calendar_service.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'biometric_auth_screen.dart';
import 'trainer_dashboard_enhanced.dart';

/// Ultra-Modern Enhanced Login Screen with Advanced Animations
/// Features: Particle system, glassmorphism, micro-interactions, fluid animations
class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _particleController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _glowController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonBounceAnimation;
  late Animation<double> _successAnimation;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // States
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSignUp = false;
  bool _showSuccess = false;
  UserRole _selectedRole = UserRole.trainer;

  // Focus Nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  // Particle System
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeParticles();
    _startAnimations();
  }

  void _setupAnimations() {
    // Particle system animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Form entrance animations with stagger
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.elasticOut,
    ));

    // Button bounce animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _buttonBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 4 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.0005,
          speedY: (random.nextDouble() - 0.5) * 0.0005,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _glowController.dispose();
    _successController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Particle Background
          _ParticleBackground(
            particles: _particles,
            animation: _particleController,
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Animated Logo with Glow
                      _buildAnimatedLogoWithGlow(),

                      const SizedBox(height: 40),

                      // Glassmorphic Form Container
                      FadeTransition(
                        opacity: _formFadeAnimation,
                        child: SlideTransition(
                          position: _formSlideAnimation,
                          child: _buildEnhancedGlassContainer(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Enhanced Social Login
                      _buildEnhancedSocialLogin(),

                      const SizedBox(height: 24),

                      // Toggle Link
                      _buildToggleLink(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay with Animation
          if (_isLoading) _buildEnhancedLoadingOverlay(),

          // Success Overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogoWithGlow() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF6B73FF), const Color(0xFF9D50FF), _glowAnimation.value)!,
                      const Color(0xFF000DFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B73FF).withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 30 + (_glowAnimation.value * 20),
                      spreadRadius: 5 + (_glowAnimation.value * 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner glow
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 55,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedGlassContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Toggle
                _buildSmoothToggle(),

                const SizedBox(height: 24),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9D50FF)],
                  ).createShader(bounds),
                  child: Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isSignUp
                    ? 'Join as a Trainer or find your Coach'
                    : 'Sign in to your training dashboard',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 30),

                // Role Selection (for signup)
                if (_isSignUp) ...[
                  _buildEnhancedRoleSelection(),
                  const SizedBox(height: 20),
                ],

                // Full Name (for signup)
                if (_isSignUp) ...[
                  _buildEnhancedTextField(
                    controller: _fullNameController,
                    focusNode: _fullNameFocus,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                _buildEnhancedTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  validator: _emailValidator,
                ),

                const SizedBox(height: 16),

                // Phone (for signup)
                if (_isSignUp) ...[
                  _buildEnhancedTextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    validator: (value) => (value?.isEmpty ?? true) && _isSignUp ? 'Please enter your phone' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Field
                _buildEnhancedPasswordField(),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                if (!_isSignUp) _buildRememberForgot(),

                const SizedBox(height: 30),

                // Sign In Button with Advanced Animation
                _buildEnhancedActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: isFocused ? 1.0 : 0.0),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08 + (animValue * 0.05)),
                    Colors.white.withOpacity(0.04 + (animValue * 0.03)),
                  ],
                ),
                border: Border.all(
                  color: Color.lerp(
                    Colors.white.withOpacity(0.2),
                    const Color(0xFF6B73FF),
                    animValue,
                  )!,
                  width: 1.5 + (animValue * 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B73FF).withOpacity(animValue * 0.2),
                    blurRadius: 15 * animValue,
                    spreadRadius: 2 * animValue,
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(
                  color: Colors.black, // BLACK TEXT for visibility on white background!
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  floatingLabelStyle: TextStyle(
                    color: isFocused
                        ? const Color(0xFF6B73FF)
                        : Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  labelStyle: TextStyle(
                    color: isFocused
                        ? const Color(0xFF6B73FF)
                        : Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: 'Enter your $label',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 15,
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      icon,
                      color: isFocused
                          ? const Color(0xFF6B73FF)
                          : const Color(0xFFB0B8FF),
                      size: 22,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                validator: validator,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedPasswordField() {
    return AnimatedBuilder(
      animation: _passwordFocus,
      builder: (context, child) {
        final isFocused = _passwordFocus.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: isFocused ? 1.0 : 0.0),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08 + (animValue * 0.05)),
                        Colors.white.withOpacity(0.04 + (animValue * 0.03)),
                      ],
                    ),
                    border: Border.all(
                      color: Color.lerp(
                        Colors.white.withOpacity(0.2),
                        const Color(0xFF6B73FF),
                        animValue,
                      )!,
                      width: 1.5 + (animValue * 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B73FF).withOpacity(animValue * 0.2),
                        blurRadius: 15 * animValue,
                        spreadRadius: 2 * animValue,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Colors.black, // BLACK TEXT for visibility on white background!
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      floatingLabelStyle: TextStyle(
                        color: isFocused
                            ? const Color(0xFF6B73FF)
                            : Colors.grey.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      labelStyle: TextStyle(
                        color: isFocused
                            ? const Color(0xFF6B73FF)
                            : Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isFocused
                            ? const Color(0xFF6B73FF)
                            : const Color(0xFFB0B8FF),
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return RotationTransition(
                              turns: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey(_obscurePassword),
                            color: const Color(0xFFB0B8FF),
                            size: 22,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: _passwordValidator,
                  ),
                );
              },
            ),

            // Password Strength Indicator
            if (_isSignUp && _passwordController.text.isNotEmpty)
              _buildPasswordStrengthIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _calculatePasswordStrength(_passwordController.text);
    final strengthData = _getPasswordStrengthData(strength);

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Strength Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * strengthData['percentage'],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: strengthData['colors'],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: strengthData['colors'][0].withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Strength Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                Icon(
                  _getStrengthIcon(strength),
                  size: 14,
                  color: strengthData['colors'][0],
                  key: ValueKey(strength),
                ),
                const SizedBox(width: 6),
                Text(
                  strengthData['text'],
                  key: ValueKey(strengthData['text']),
                  style: TextStyle(
                    fontSize: 13,
                    color: strengthData['colors'][0],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Requirements hint
          if (_isSignUp && strength < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Password must contain: uppercase, lowercase, number, and 8+ characters',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStrengthIcon(int strength) {
    switch (strength) {
      case 1: return Icons.warning_rounded;
      case 2: return Icons.check_circle_outline;
      case 3: return Icons.verified_rounded;
      default: return Icons.error_outline;
    }
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 2) return 1;
    if (strength <= 4) return 2;
    return 3;
  }

  Map<String, dynamic> _getPasswordStrengthData(int strength) {
    switch (strength) {
      case 1:
        return {
          'text': 'Weak password',
          'percentage': 0.33,
          'colors': [const Color(0xFFFF4757), const Color(0xFFFF6348)],
        };
      case 2:
        return {
          'text': 'Good password',
          'percentage': 0.66,
          'colors': [const Color(0xFFFFA502), const Color(0xFFFFD93D)],
        };
      case 3:
        return {
          'text': 'Strong password',
          'percentage': 1.0,
          'colors': [const Color(0xFF26DE81), const Color(0xFF20BDFF)],
        };
      default:
        return {
          'text': '',
          'percentage': 0.0,
          'colors': [Colors.grey, Colors.grey],
        };
    }
  }

  Widget _buildSmoothToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: _isSignUp ? MediaQuery.of(context).size.width * 0.42 : 0,
            right: _isSignUp ? 0 : MediaQuery.of(context).size.width * 0.42,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B73FF), Color(0xFF000DFF)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B73FF).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isSignUp = false);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: !_isSignUp ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isSignUp = true);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: _isSignUp ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.trainer,
                title: 'Personal Trainer',
                subtitle: 'Manage clients & sessions',
                icon: Icons.fitness_center,
                isSelected: _selectedRole == UserRole.trainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.client,
                title: 'Client',
                subtitle: 'Book sessions & track progress',
                icon: Icons.person_outline,
                isSelected: _selectedRole == UserRole.client,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
              ? [const Color(0xFF6B73FF).withOpacity(0.3), const Color(0xFF000DFF).withOpacity(0.2)]
              : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? const Color(0xFF6B73FF)
              : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6B73FF) : Colors.white60,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() => _rememberMe = value ?? false);
                },
                activeColor: const Color(0xFF6B73FF),
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Remember me',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _showForgotPasswordDialog,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFF6B73FF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedActionButton() {
    return AnimatedBuilder(
      animation: _buttonBounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonBounceAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _buttonController.forward();
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) {
              _buttonController.reverse();
              _handleSignIn();
            },
            onTapCancel: () => _buttonController.reverse(),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B73FF), Color(0xFF000DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B73FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Sign In to Dashboard',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSocialLogin() {
    return FadeTransition(
      opacity: _formFadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  label: 'Google',
                  icon: Icons.g_mobiledata_rounded,
                  gradient: [const Color(0xFFDB4437), const Color(0xFFC23321)],
                  onTap: _handleGoogleSignIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  label: 'Demo Login',
                  icon: Icons.play_circle_outline,
                  gradient: [const Color(0xFF6B73FF), const Color(0xFF000DFF)],
                  onTap: _handleDemoLogin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  label: 'Biometric',
                  icon: Icons.fingerprint,
                  gradient: [const Color(0xFF26DE81), const Color(0xFF20BDFF)],
                  onTap: _handleBiometricLogin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  label: 'Face ID',
                  icon: Icons.face_outlined,
                  gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                  onTap: _handleBiometricLogin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleLink() {
    return FadeTransition(
      opacity: _formFadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isSignUp ? "Already have an account? " : "Don't have an account? ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSignUp = !_isSignUp;
                _emailController.clear();
                _passwordController.clear();
                _fullNameController.clear();
                _phoneController.clear();
              });
            },
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6B73FF), Color(0xFF9D50FF)],
              ).createShader(bounds),
              child: Text(
                _isSignUp ? 'Sign In' : 'Sign Up',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
                        strokeWidth: 5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isSignUp ? 'Creating your account...' : 'Signing you in...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: ScaleTransition(
          scale: _successAnimation,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF26DE81), Color(0xFF20BDFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF26DE81).withOpacity(0.5),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 100,
            ),
          ),
        ),
      ),
    );
  }

  // Validators
  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // Handlers
  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (SupabaseConfig.isDemoMode) {
          // Demo mode - works without backend
          final demoResult = await RealSupabaseService.instance.demoLogin(
            email: _emailController.text.trim(),
            role: _selectedRole,
            fullName: _fullNameController.text.trim().isNotEmpty
                ? _fullNameController.text.trim()
                : null,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📱 Demo ${_isSignUp ? 'Registration' : 'Login'}: ${_selectedRole.name.capitalize()} Account'
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            setState(() {
              _isLoading = false;
              _showSuccess = true;
            });

            _successController.forward();

            await Future.delayed(const Duration(milliseconds: 1500));

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TrainerDashboardEnhanced(
                  trainerId: demoResult['user']['id'],
                ),
              ),
            );
          }
        } else {
          // Real authentication with Supabase
          if (_isSignUp) {
            await RealSupabaseService.instance.signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              phone: _phoneController.text.trim(),
              role: _selectedRole,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Account created! Please check your email to verify.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // Switch to login mode
              setState(() {
                _isSignUp = false;
                _isLoading = false;
              });
            }
          } else {
            await RealSupabaseService.instance.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );

            if (mounted) {
              setState(() {
                _isLoading = false;
                _showSuccess = true;
              });

              _successController.forward();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Welcome back!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                ),
              );

              // Navigate to dashboard
              await Future.delayed(const Duration(milliseconds: 1500));
              final user = RealSupabaseService.instance.currentUser;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TrainerDashboardEnhanced(
                    trainerId: user?.id ?? 'demo-user',
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${_isSignUp ? 'Registration' : 'Sign in'} failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      // Use GoogleCalendarService for direct Google Sign-In
      // This avoids the Supabase OAuth redirect and gives us calendar access
      final success = await GoogleCalendarService.instance.promptGoogleSignIn();

      if (!success) {
        throw Exception('Google sign-in was cancelled');
      }

      // Get the signed-in user's email
      final userEmail = GoogleCalendarService.instance.userEmail;

      debugPrint('✅ Google Sign-In successful: $userEmail');
      debugPrint('🎯 Navigating to trainer dashboard...');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        _successController.forward();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Successfully signed in with Google!\n$userEmail'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate directly to trainer dashboard
        // No redirect to callback URL, straight to the app!
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TrainerDashboardEnhanced(
              trainerId: userEmail ?? 'google-trainer',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Google sign-in failed: ${e.toString()}\n\nTry again or use Email/Password login.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleBiometricLogin() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BiometricAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleDemoLogin() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      _successController.forward();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Demo Mode: Logged in as Trainer'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TrainerDashboardEnhanced(
            trainerId: 'demo-trainer-id',
          ),
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Password reset feature coming soon!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF6B73FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Particle Background Widget
class _ParticleBackground extends StatelessWidget {
  final List<Particle> particles;
  final Animation<double> animation;

  const _ParticleBackground({
    required this.particles,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(particles, animation.value),
          child: Container(),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F0E2E),
          Color(0xFF1A1447),
          Color(0xFF0F3460),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw particles
    for (var particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );

      // Draw connections between nearby particles
      for (var otherParticle in particles) {
        if (particle != otherParticle) {
          final distance = math.sqrt(
            math.pow((particle.x - otherParticle.x) * size.width, 2) +
            math.pow((particle.y - otherParticle.y) * size.height, 2),
          );

          if (distance < 100) {
            final linePaint = Paint()
              ..color = Colors.white.withOpacity((1 - distance / 100) * 0.1)
              ..strokeWidth = 0.5;

            canvas.drawLine(
              Offset(particle.x * size.width, particle.y * size.height),
              Offset(otherParticle.x * size.width, otherParticle.y * size.height),
              linePaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle Class
class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  void update(Size size) {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1) speedX *= -1;
    if (y < 0 || y > 1) speedY *= -1;
  }
}

