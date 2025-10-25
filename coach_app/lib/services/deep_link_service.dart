// DEEP LINK SERVICE
// Universal link and deep link handling for authentication flows

import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  static StreamSubscription? _linkSubscription;
  static final _linkController = StreamController<DeepLinkAction>.broadcast();

  /// Stream of deep link actions
  static Stream<DeepLinkAction> get linkStream => _linkController.stream;

  /// Initialize deep link handling
  static Future<void> initialize() async {
    // Handle initial link (app opened from link)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        print('Initial link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }

    // Listen for incoming links while app is open
    _linkSubscription = linkStream.listen(
      (link) {
        print('Received deep link: ${link.type}');
        _linkController.add(link);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  /// Handle deep link based on host and path
  static void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      print('Processing deep link - Host: ${uri.host}, Path: ${uri.path}');

      switch (uri.host) {
        case 'login':
          _handleLoginLink(uri);
          break;
        case 'reset-password':
        case 'password-reset':
          _handlePasswordReset(uri);
          break;
        case 'verify-email':
        case 'email-verification':
          _handleEmailVerification(uri);
          break;
        case 'oauth-callback':
          _handleOAuthCallback(uri);
          break;
        case 'invite':
        case 'team-invite':
          _handleTeamInvite(uri);
          break;
        case 'magic-link':
          _handleMagicLink(uri);
          break;
        default:
          print('Unknown deep link host: ${uri.host}');
          _linkController.add(DeepLinkAction(
            type: DeepLinkType.unknown,
            data: {'url': link},
          ));
      }
    } catch (e) {
      print('Error handling deep link: $e');
    }
  }

  /// Handle login deep link
  static void _handleLoginLink(Uri uri) {
    final token = uri.queryParameters['token'];
    final returnTo = uri.queryParameters['return_to'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.login,
      data: {
        'token': token,
        'return_to': returnTo,
      },
    ));
  }

  /// Handle password reset deep link
  static void _handlePasswordReset(Uri uri) {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.passwordReset,
      data: {
        'token': token,
        'email': email,
      },
    ));
  }

  /// Handle email verification deep link
  static void _handleEmailVerification(Uri uri) {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.emailVerification,
      data: {
        'token': token,
        'email': email,
      },
    ));
  }

  /// Handle OAuth callback deep link
  static void _handleOAuthCallback(Uri uri) {
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final provider = uri.queryParameters['provider'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.oauthCallback,
      data: {
        'code': code,
        'state': state,
        'provider': provider,
      },
    ));
  }

  /// Handle team invite deep link
  static void _handleTeamInvite(Uri uri) {
    final inviteCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    final teamId = uri.queryParameters['team_id'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.teamInvite,
      data: {
        'invite_code': inviteCode,
        'team_id': teamId,
      },
    ));
  }

  /// Handle magic link deep link
  static void _handleMagicLink(Uri uri) {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    _linkController.add(DeepLinkAction(
      type: DeepLinkType.magicLink,
      data: {
        'token': token,
        'email': email,
      },
    ));
  }

  /// Process Supabase magic link
  static Future<bool> processMagicLink(String token) async {
    try {
      // Verify the magic link token with Supabase
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.magiclink,
        token: token,
      );

      return response.session != null;
    } catch (e) {
      print('Magic link verification failed: $e');
      return false;
    }
  }

  /// Process password reset token
  static Future<bool> processPasswordResetToken(String token, String newPassword) async {
    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response.user != null;
    } catch (e) {
      print('Password reset failed: $e');
      return false;
    }
  }

  /// Clean up resources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkController.close();
  }
}

/// Deep link action types
enum DeepLinkType {
  login,
  passwordReset,
  emailVerification,
  oauthCallback,
  teamInvite,
  magicLink,
  unknown,
}

/// Deep link action data
class DeepLinkAction {
  final DeepLinkType type;
  final Map<String, dynamic> data;

  DeepLinkAction({
    required this.type,
    required this.data,
  });

  @override
  String toString() => 'DeepLinkAction(type: $type, data: $data)';
}
