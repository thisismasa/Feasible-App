// APPLE SIGN IN SERVICE
// Sign in with Apple implementation for iOS

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_service.dart';

// Note: sign_in_with_apple package needs to be added to pubspec.yaml
// For now, this is a framework ready for activation

class AppleSignInService {
  static const String clientId = 'com.company.app.service';
  static const String redirectUri = 'https://app.company.com/auth/apple/callback';

  /// Check if Sign in with Apple is available on this device
  static Future<bool> isAvailable() async {
    // Note: Uncomment when sign_in_with_apple package is added
    // return await SignInWithApple.isAvailable();
    return false; // For now, return false until package is integrated
  }

  /// Sign in with Apple
  static Future<AppleAuthResult?> signInWithApple() async {
    try {
      // Check if available
      final available = await isAvailable();
      if (!available) {
        throw AppleSignInException('Sign in with Apple is not available');
      }

      // Note: Uncomment when sign_in_with_apple package is added
      // Request credentials
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      //   webAuthenticationOptions: WebAuthenticationOptions(
      //     clientId: clientId,
      //     redirectUri: Uri.parse(redirectUri),
      //   ),
      //   nonce: _generateNonce(),
      // );

      // Process credential
      // final result = await _processAppleCredential(credential);

      // Track sign in
      // await AnalyticsService.track(
      //   userId: result.userId,
      //   event: 'apple_signin',
      //   properties: {
      //     'first_time': result.isNewUser,
      //     'email_shared': credential.email != null,
      //   },
      // );

      print('Apple Sign In initiated');
      return null; // Return null until fully implemented
    } catch (e) {
      // Note: Uncomment when sign_in_with_apple package is added
      // if (e is SignInWithAppleAuthorizationException) {
      //   if (e.code == AuthorizationErrorCode.canceled) {
      //     // User canceled
      //     return null;
      //   }
      // }
      print('Apple Sign In failed: $e');
      throw e;
    }
  }

  /// Process Apple credential with backend
  static Future<AppleAuthResult> _processAppleCredential(dynamic credential) async {
    try {
      // Verify with Supabase backend
      final response = await Supabase.instance.client.functions.invoke(
        'verify-apple-signin',
        body: {
          'identityToken': credential.identityToken,
          'authorizationCode': credential.authorizationCode,
          'userIdentifier': credential.userIdentifier,
          'email': credential.email,
          'givenName': credential.givenName,
          'familyName': credential.familyName,
        },
      );

      final isNewUser = response.data['is_new_user'] ?? false;
      final userId = response.data['user_id'];
      final sessionToken = response.data['session_token'];

      // Store Apple ID for future use
      if (isNewUser) {
        await _storeAppleUserInfo(userId, credential);
      }

      return AppleAuthResult(
        userId: userId,
        sessionToken: sessionToken,
        isNewUser: isNewUser,
        email: credential.email,
        fullName: '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
      );
    } catch (e) {
      print('Failed to process Apple credential: $e');
      rethrow;
    }
  }

  /// Store Apple user information
  static Future<void> _storeAppleUserInfo(String userId, dynamic credential) async {
    try {
      await Supabase.instance.client.from('apple_users').insert({
        'user_id': userId,
        'apple_user_identifier': credential.userIdentifier,
        'email': credential.email,
        'given_name': credential.givenName,
        'family_name': credential.familyName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to store Apple user info: $e');
    }
  }

  /// Generate cryptographically secure nonce
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Get Apple user info from database
  static Future<Map<String, dynamic>?> getAppleUserInfo(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('apple_users')
          .select()
          .eq('user_id', userId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Failed to get Apple user info: $e');
      return null;
    }
  }
}

/// Apple authentication result
class AppleAuthResult {
  final String userId;
  final String sessionToken;
  final bool isNewUser;
  final String? email;
  final String? fullName;

  AppleAuthResult({
    required this.userId,
    required this.sessionToken,
    required this.isNewUser,
    this.email,
    this.fullName,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'session_token': sessionToken,
    'is_new_user': isNewUser,
    'email': email,
    'full_name': fullName,
  };
}

/// Apple Sign In exception
class AppleSignInException implements Exception {
  final String message;

  AppleSignInException(this.message);

  @override
  String toString() => 'AppleSignInException: $message';
}
