// OFFLINE AUTHENTICATION SERVICE
// Secure offline authentication capability with encrypted credential storage

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineAuthService {
  static const int _maxOfflineDays = 7;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Enable offline authentication mode
  static Future<bool> enableOfflineMode(String userId, String email) async {
    try {
      // Generate offline token
      final offlineToken = await _generateOfflineToken(userId);

      // Store encrypted credentials
      await _secureStorage.write(
        key: 'offline_token',
        value: offlineToken,
      );

      await _secureStorage.write(
        key: 'offline_user_id',
        value: userId,
      );

      await _secureStorage.write(
        key: 'offline_email',
        value: email,
      );

      // Cache essential data
      await _cacheEssentialData(userId);

      // Set expiration
      final expiryDate = DateTime.now().add(Duration(days: _maxOfflineDays));
      await _secureStorage.write(
        key: 'offline_expiry',
        value: expiryDate.toIso8601String(),
      );

      print('Offline mode enabled for $email');
      return true;
    } catch (e) {
      print('Failed to enable offline mode: $e');
      return false;
    }
  }

  /// Authenticate user in offline mode
  static Future<OfflineAuthResult> authenticateOffline({
    required String email,
    required String password,
  }) async {
    try {
      // Check if offline mode is available
      final offlineToken = await _secureStorage.read(key: 'offline_token');
      if (offlineToken == null) {
        return OfflineAuthResult(
          success: false,
          message: 'Offline mode not enabled',
        );
      }

      // Check expiration
      final expiryStr = await _secureStorage.read(key: 'offline_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          await clearOfflineData();
          return OfflineAuthResult(
            success: false,
            message: 'Offline access expired',
          );
        }
      }

      // Verify stored email matches
      final storedEmail = await _secureStorage.read(key: 'offline_email');
      if (storedEmail != email) {
        return OfflineAuthResult(
          success: false,
          message: 'Email mismatch',
        );
      }

      // Verify credentials
      final verified = await _verifyOfflineCredentials(email, password, offlineToken);

      if (verified) {
        final userId = await _secureStorage.read(key: 'offline_user_id');
        final cachedData = await _loadCachedData();

        return OfflineAuthResult(
          success: true,
          userId: userId,
          email: email,
          cachedData: cachedData,
          message: 'Offline authentication successful',
        );
      }

      return OfflineAuthResult(
        success: false,
        message: 'Invalid credentials',
      );
    } catch (e) {
      print('Offline authentication failed: $e');
      return OfflineAuthResult(
        success: false,
        message: 'Authentication error: $e',
      );
    }
  }

  /// Check if offline mode is currently available
  static Future<bool> isOfflineModeAvailable() async {
    final offlineToken = await _secureStorage.read(key: 'offline_token');
    if (offlineToken == null) return false;

    final expiryStr = await _secureStorage.read(key: 'offline_expiry');
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        await clearOfflineData();
        return false;
      }
    }

    return true;
  }

  /// Get offline expiry date
  static Future<DateTime?> getOfflineExpiry() async {
    final expiryStr = await _secureStorage.read(key: 'offline_expiry');
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return null;
  }

  /// Clear all offline data
  static Future<void> clearOfflineData() async {
    await _secureStorage.delete(key: 'offline_token');
    await _secureStorage.delete(key: 'offline_user_id');
    await _secureStorage.delete(key: 'offline_email');
    await _secureStorage.delete(key: 'offline_expiry');
    await _secureStorage.delete(key: 'offline_cache');
    await _secureStorage.deleteAll();
    print('Offline data cleared');
  }

  /// Store password hash for offline verification
  static Future<void> storePasswordHash(String email, String password) async {
    final hash = _hashPassword(password);
    await _secureStorage.write(
      key: 'pwd_hash_$email',
      value: hash,
    );
  }

  /// Generate offline token
  static Future<String> _generateOfflineToken(String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId:offline:$timestamp';

    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);

    return base64.encode(digest.bytes);
  }

  /// Cache essential user data for offline use
  static Future<void> _cacheEssentialData(String userId) async {
    try {
      // Fetch and cache essential user data
      final userResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Cache the data
      final cache = {
        'user': userResponse,
        'cached_at': DateTime.now().toIso8601String(),
      };

      await _secureStorage.write(
        key: 'offline_cache',
        value: jsonEncode(cache),
      );

      print('Essential data cached for offline use');
    } catch (e) {
      print('Failed to cache essential data: $e');
    }
  }

  /// Load cached data
  static Future<Map<String, dynamic>?> _loadCachedData() async {
    try {
      final cacheStr = await _secureStorage.read(key: 'offline_cache');
      if (cacheStr != null) {
        return jsonDecode(cacheStr) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Failed to load cached data: $e');
    }
    return null;
  }

  /// Verify offline credentials
  static Future<bool> _verifyOfflineCredentials(
    String email,
    String password,
    String offlineToken,
  ) async {
    // Verify against stored hash
    final storedHash = await _secureStorage.read(key: 'pwd_hash_$email');
    if (storedHash == null) return false;

    final inputHash = _hashPassword(password);
    return inputHash == storedHash;
  }

  /// Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Offline authentication result
class OfflineAuthResult {
  final bool success;
  final String? userId;
  final String? email;
  final Map<String, dynamic>? cachedData;
  final String message;

  OfflineAuthResult({
    required this.success,
    this.userId,
    this.email,
    this.cachedData,
    required this.message,
  });

  @override
  String toString() => 'OfflineAuthResult(success: $success, message: $message)';
}
