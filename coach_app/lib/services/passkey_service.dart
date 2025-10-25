// PASSKEY SERVICE
// WebAuthn/Passkey implementation for iOS 16+ passwordless authentication

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_service.dart';
import 'analytics_service.dart';

class PasskeyService {
  // Note: The 'passkeys' package needs to be added to pubspec.yaml
  // For now, this is a framework that can be activated when ready

  static const String rpId = 'app.company.com';
  static const String rpName = 'PT Fitness Pro';

  /// Register a new passkey for the user
  static Future<PasskeyCredential?> registerPasskey({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      // Generate registration options
      final challenge = _generateChallenge();

      // Note: Uncomment when passkeys package is added
      // final credential = await Passkeys().register(
      //   RegisterOptions(
      //     rpId: rpId,
      //     rpName: rpName,
      //     userId: base64Encode(utf8.encode(userId)),
      //     userName: email,
      //     userDisplayName: displayName,
      //     challenge: challenge,
      //     authenticatorSelection: AuthenticatorSelection(
      //       authenticatorAttachment: 'platform',
      //       requireResidentKey: true,
      //       residentKey: 'required',
      //       userVerification: 'required',
      //     ),
      //     attestation: 'direct',
      //     pubKeyCredParams: [
      //       PubKeyCredParam(alg: -7, type: 'public-key'), // ES256
      //       PubKeyCredParam(alg: -257, type: 'public-key'), // RS256
      //     ],
      //   ),
      // );

      // For now, return null until passkeys package is integrated
      print('Passkey registration initiated for $email');

      // Track adoption
      await AnalyticsService.track(
        userId: userId,
        event: 'passkey_registration_attempted',
        properties: {
          'platform': 'ios',
          'email': email,
        },
      );

      return null;
    } catch (e) {
      print('Passkey registration failed: $e');
      return null;
    }
  }

  /// Authenticate using an existing passkey
  static Future<bool> authenticateWithPasskey(String email) async {
    try {
      // Generate authentication options
      final challenge = _generateChallenge();

      // Note: Uncomment when passkeys package is added
      // final assertion = await Passkeys().authenticate(
      //   AuthenticateOptions(
      //     rpId: rpId,
      //     challenge: challenge,
      //     userVerification: 'required',
      //     allowCredentials: await _getUserCredentials(email),
      //   ),
      // );

      // Verify with server
      // final verified = await _verifyAssertion(assertion);

      // if (verified) {
      //   await _logPasskeyAuthentication(email);
      // }

      print('Passkey authentication attempted for $email');

      // For now, return false until fully implemented
      return false;
    } catch (e) {
      print('Passkey authentication failed: $e');
      return false;
    }
  }

  /// Generate a cryptographically secure challenge
  static String _generateChallenge() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Store passkey credential in database
  static Future<void> _storePasskeyCredential(
    String userId,
    PasskeyCredential credential,
  ) async {
    try {
      await Supabase.instance.client.from('passkey_credentials').insert({
        'user_id': userId,
        'credential_id': credential.id,
        'public_key': credential.publicKey,
        'authenticator_type': credential.authenticatorType,
        'created_at': DateTime.now().toIso8601String(),
        'last_used': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to store passkey credential: $e');
    }
  }

  /// Get user's stored passkey credentials
  static Future<List<Map<String, dynamic>>> _getUserCredentials(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('passkey_credentials')
          .select('credential_id')
          .eq('user_email', email);

      return (response as List).map((r) => {
        'id': r['credential_id'],
        'type': 'public-key',
      }).toList();
    } catch (e) {
      print('Failed to get user credentials: $e');
      return [];
    }
  }

  /// Verify passkey assertion with backend
  static Future<bool> _verifyAssertion(dynamic assertion) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-passkey',
        body: {
          'credentialId': assertion.credentialId,
          'signature': assertion.signature,
          'authenticatorData': assertion.authenticatorData,
          'clientDataJSON': assertion.clientDataJSON,
        },
      );

      return response.data['verified'] ?? false;
    } catch (e) {
      print('Failed to verify assertion: $e');
      return false;
    }
  }

  /// Log passkey authentication event
  static Future<void> _logPasskeyAuthentication(String email) async {
    try {
      await AuditService.logEvent(
        userId: email,
        type: AuditEventType.passkeyAuth,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': 'ios',
        },
      );
    } catch (e) {
      print('Failed to log passkey authentication: $e');
    }
  }

  /// Check if passkeys are supported on this device
  static Future<bool> isPasskeySupported() async {
    // iOS 16+ supports passkeys
    // This would need platform channel to check iOS version
    return false; // Return false until implementation is complete
  }
}

/// Passkey credential data
class PasskeyCredential {
  final String id;
  final String publicKey;
  final String authenticatorType;

  PasskeyCredential({
    required this.id,
    required this.publicKey,
    required this.authenticatorType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'public_key': publicKey,
    'authenticator_type': authenticatorType,
  };
}
