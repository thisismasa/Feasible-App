// iOS BIOMETRIC SERVICE
// Enhanced biometric authentication for iOS with Face ID, Touch ID, and Optic ID support

import 'package:flutter/services.dart';

class IOSBiometricService {
  static const platform = MethodChannel('com.app/biometric');

  /// Check available biometric capabilities on iOS device
  static Future<BiometricCapability> checkIOSBiometrics() async {
    try {
      final Map<dynamic, dynamic> capabilities =
          await platform.invokeMethod('checkBiometrics');

      return BiometricCapability(
        hasFaceID: capabilities['faceID'] ?? false,
        hasTouchID: capabilities['touchID'] ?? false,
        hasOpticID: capabilities['opticID'] ?? false, // Vision Pro
        isEnrolled: capabilities['enrolled'] ?? false,
        requiresPasscode: capabilities['passcodeSet'] ?? false,
      );
    } catch (e) {
      print('Biometric check failed: $e');
      return BiometricCapability.none();
    }
  }

  /// Setup keychain integration for enterprise credential sharing
  static Future<void> setupKeychainIntegration({
    String accessGroup = 'com.company.sharedkeychain',
    bool synchronizable = true,
    String accessibility = 'kSecAttrAccessibleWhenUnlockedThisDeviceOnly',
  }) async {
    try {
      await platform.invokeMethod('setupKeychain', {
        'accessGroup': accessGroup,
        'synchronizable': synchronizable,
        'accessibility': accessibility,
      });
    } catch (e) {
      print('Keychain setup failed: $e');
    }
  }

  /// Authenticate with custom biometric policy
  static Future<bool> authenticateWithPolicy({
    required BiometricPolicy policy,
    required String reason,
  }) async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('authenticateWithPolicy', {
        'reason': reason,
        'policy': policy.toMap(),
        'fallbackTitle': 'Use Passcode',
        'cancelTitle': 'Cancel',
      });

      return result['success'] ?? false;
    } catch (e) {
      print('Biometric authentication failed: $e');
      return false;
    }
  }
}

/// Represents biometric capabilities of the iOS device
class BiometricCapability {
  final bool hasFaceID;
  final bool hasTouchID;
  final bool hasOpticID;
  final bool isEnrolled;
  final bool requiresPasscode;

  BiometricCapability({
    required this.hasFaceID,
    required this.hasTouchID,
    required this.hasOpticID,
    required this.isEnrolled,
    required this.requiresPasscode,
  });

  factory BiometricCapability.none() => BiometricCapability(
    hasFaceID: false,
    hasTouchID: false,
    hasOpticID: false,
    isEnrolled: false,
    requiresPasscode: false,
  );

  /// Get human-readable description of available biometric
  String get biometricType {
    if (hasFaceID) return 'Face ID';
    if (hasTouchID) return 'Touch ID';
    if (hasOpticID) return 'Optic ID';
    return 'None';
  }

  /// Check if any biometric authentication is available
  bool get isAvailable => hasFaceID || hasTouchID || hasOpticID;
}

/// Biometric authentication policy configuration
class BiometricPolicy {
  final bool requireBiometricEnrollment;
  final bool allowPasscodeFallback;
  final Duration reauthenticationInterval;

  BiometricPolicy({
    this.requireBiometricEnrollment = true,
    this.allowPasscodeFallback = true,
    this.reauthenticationInterval = const Duration(minutes: 30),
  });

  Map<String, dynamic> toMap() => {
    'requireEnrollment': requireBiometricEnrollment,
    'allowPasscode': allowPasscodeFallback,
    'reauthInterval': reauthenticationInterval.inSeconds,
  };
}
