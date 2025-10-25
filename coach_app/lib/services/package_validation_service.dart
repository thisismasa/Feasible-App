import '../models/package_model.dart';
import '../services/supabase_service.dart';

class PackageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final PackageValidationError? errorType;
  final ClientPackage? package;

  PackageValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
    this.package,
  });

  factory PackageValidationResult.success(ClientPackage package) {
    return PackageValidationResult(
      isValid: true,
      package: package,
    );
  }

  factory PackageValidationResult.failure(
    String message,
    PackageValidationError errorType,
  ) {
    return PackageValidationResult(
      isValid: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

enum PackageValidationError {
  noPackage,
  expired,
  noSessionsLeft,
  notPaid,
  inactive,
}

class PackageValidationService {
  static Future<PackageValidationResult> validatePackageForBooking(
    String clientId, {
    int sessionsNeeded = 1,
    DateTime? sessionDate,
  }) async {
    try {
      // Get active package for client
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('client_id', clientId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) {
        return PackageValidationResult.failure(
          'Client does not have an active package',
          PackageValidationError.noPackage,
        );
      }

      final package = ClientPackage.fromSupabaseMap(response);

      // Validate payment status
      if (package.paymentStatus != 'paid') {
        return PackageValidationResult.failure(
          'Package payment is ${package.paymentStatus}. Please complete payment.',
          PackageValidationError.notPaid,
        );
      }

      // Validate expiry date
      final checkDate = sessionDate ?? DateTime.now();
      if (package.expiryDate.isBefore(checkDate)) {
        return PackageValidationResult.failure(
          'Package expired on ${package.expiryDate.toString().split(' ')[0]}',
          PackageValidationError.expired,
        );
      }

      // Validate remaining sessions
      if (package.remainingSessions < sessionsNeeded) {
        return PackageValidationResult.failure(
          'Not enough sessions. ${package.remainingSessions} remaining, $sessionsNeeded needed.',
          PackageValidationError.noSessionsLeft,
        );
      }

      return PackageValidationResult.success(package);
    } catch (e) {
      return PackageValidationResult.failure(
        'Error validating package: ${e.toString()}',
        PackageValidationError.noPackage,
      );
    }
  }

  static Future<ClientPackage?> getActivePackage(String clientId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('client_id', clientId)
          .eq('status', 'active')
          .gte('remaining_sessions', 1)
          .maybeSingle();

      if (response != null) {
        return ClientPackage.fromSupabaseMap(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<ClientPackage>> getAllClientPackages(
    String clientId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      if (response is List) {
        return (response as List)
            .map((data) => ClientPackage.fromSupabaseMap(data))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deductSession(String packageId) async {
    try {
      // Get current package
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('id', packageId)
          .single();

      final package = ClientPackage.fromSupabaseMap(response);

      // Update sessions used
      await SupabaseService.instance.client
          .from('client_packages')
          .update({
            'sessions_used': package.sessionsUsed + 1,
          })
          .eq('id', packageId);

      // If no sessions remaining, mark as completed
      if (package.remainingSessions <= 1) {
        await SupabaseService.instance.client
            .from('client_packages')
            .update({'status': 'completed'})
            .eq('id', packageId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> refundSession(String packageId) async {
    try {
      // Get current package
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('id', packageId)
          .single();

      final package = ClientPackage.fromSupabaseMap(response);

      if (package.sessionsUsed > 0) {
        // Update sessions used
        await SupabaseService.instance.client
            .from('client_packages')
            .update({
              'sessions_used': package.sessionsUsed - 1,
              'status': 'active', // Reactivate if was completed
            })
            .eq('id', packageId);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> validatePackageBeforeSessionStart(
    String packageId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('id', packageId)
          .single();

      final package = ClientPackage.fromSupabaseMap(response);

      // Check if package is still valid
      if (package.status != 'active') {
        throw Exception('Package is not active');
      }

      if (package.paymentStatus != 'paid') {
        throw Exception('Package payment is pending');
      }

      if (package.expiryDate.isBefore(DateTime.now())) {
        throw Exception('Package has expired');
      }

      if (package.remainingSessions <= 0) {
        throw Exception('No sessions remaining');
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static String getPackageStatusMessage(ClientPackage package) {
    if (package.status != 'active') {
      return 'Package is ${package.status}';
    }

    if (package.expiryDate.isBefore(DateTime.now())) {
      return 'Package expired';
    }

    if (package.remainingSessions <= 0) {
      return 'No sessions remaining';
    }

    final daysUntilExpiry = package.expiryDate.difference(DateTime.now()).inDays;

    if (daysUntilExpiry <= 7) {
      return 'Expires in $daysUntilExpiry days';
    }

    if (package.remainingSessions <= 3) {
      return '${package.remainingSessions} sessions left';
    }

    return 'Active package';
  }
}
