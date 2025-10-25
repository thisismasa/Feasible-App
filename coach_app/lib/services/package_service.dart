import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class PackageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new package (trainer only)
  Future<String> createPackage(PackageModel package) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('packages').add(package.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create package: ${e.toString()}');
    }
  }

  // Get all active packages
  Stream<List<PackageModel>> getActivePackages() {
    return _firestore
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .orderBy('price', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PackageModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all packages (for trainer dashboard)
  Stream<List<PackageModel>> getAllPackages() {
    return _firestore
        .collection('packages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PackageModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Update package
  Future<void> updatePackage(String packageId, PackageModel package) async {
    try {
      await _firestore
          .collection('packages')
          .doc(packageId)
          .update(package.toMap());
    } catch (e) {
      throw Exception('Failed to update package: ${e.toString()}');
    }
  }

  // Deactivate package (soft delete)
  Future<void> deactivatePackage(String packageId) async {
    try {
      await _firestore.collection('packages').doc(packageId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate package: ${e.toString()}');
    }
  }

  // Purchase package
  Future<String> purchasePackage({
    required String clientId,
    required String packageId,
    required String paymentIntentId,
  }) async {
    try {
      // Get package details
      DocumentSnapshot packageDoc =
          await _firestore.collection('packages').doc(packageId).get();

      if (!packageDoc.exists) {
        throw Exception('Package not found');
      }

      PackageModel package = PackageModel.fromMap(
          packageDoc.data() as Map<String, dynamic>, packageDoc.id);

      // Create client package
      DateTime purchaseDate = DateTime.now();
      DateTime expiryDate =
          purchaseDate.add(Duration(days: package.validityDays));

      ClientPackage clientPackage = ClientPackage(
        id: '',
        clientId: clientId,
        packageId: packageId,
        packageName: package.name,
        totalSessions: package.sessionCount,
        sessionsUsed: 0,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        amountPaid: package.price,
        status: PackageStatus.active,
      );

      DocumentReference docRef = await _firestore
          .collection('client_packages')
          .add(clientPackage.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to purchase package: ${e.toString()}');
    }
  }

  // Get client's packages
  Stream<List<ClientPackage>> getClientPackages(String clientId) {
    return _firestore
        .collection('client_packages')
        .where('clientId', isEqualTo: clientId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientPackage.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get client's active packages (with remaining sessions)
  Stream<List<ClientPackage>> getClientActivePackages(String clientId) {
    return _firestore
        .collection('client_packages')
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: PackageStatus.active.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientPackage.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .where((pkg) => pkg.hasSessionsRemaining && !pkg.isExpired)
            .toList());
  }

  // Get all client packages for trainer dashboard
  Stream<List<ClientPackage>> getAllClientPackages(String trainerId) {
    return _firestore
        .collection('client_packages')
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientPackage.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Check and update expired packages
  Future<void> updateExpiredPackages() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('client_packages')
          .where('status', isEqualTo: PackageStatus.active.name)
          .get();

      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        ClientPackage package = ClientPackage.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);

        if (package.isExpired) {
          await _firestore.collection('client_packages').doc(doc.id).update({
            'status': PackageStatus.expired.name,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update expired packages: ${e.toString()}');
    }
  }
}
