import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';
import '../models/package_model.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Book a new session
  Future<String> bookSession({
    required String clientId,
    required String clientName,
    required String trainerId,
    required DateTime scheduledDate,
    required int durationMinutes,
    String? clientPackageId,
    String? notes,
  }) async {
    try {
      // Check if client has an active package with remaining sessions
      if (clientPackageId != null) {
        DocumentSnapshot packageDoc = await _firestore
            .collection('client_packages')
            .doc(clientPackageId)
            .get();

        if (packageDoc.exists) {
          ClientPackage clientPackage = ClientPackage.fromMap(
              packageDoc.data() as Map<String, dynamic>, packageDoc.id);

          if (!clientPackage.hasSessionsRemaining) {
            throw Exception('No sessions remaining in package');
          }

          if (clientPackage.isExpired) {
            throw Exception('Package has expired');
          }
        }
      }

      SessionModel session = SessionModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        trainerId: trainerId,
        scheduledDate: scheduledDate,
        durationMinutes: durationMinutes,
        status: SessionStatus.scheduled,
        notes: notes,
        clientPackageId: clientPackageId,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef =
          await _firestore.collection('sessions').add(session.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to book session: ${e.toString()}');
    }
  }

  // Get sessions for a client
  Stream<List<SessionModel>> getClientSessions(String clientId) {
    return _firestore
        .collection('sessions')
        .where('clientId', isEqualTo: clientId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get sessions for a trainer
  Stream<List<SessionModel>> getTrainerSessions(String trainerId) {
    return _firestore
        .collection('sessions')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get sessions by date range
  Stream<List<SessionModel>> getSessionsByDateRange(
    String trainerId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('sessions')
        .where('trainerId', isEqualTo: trainerId)
        .where('scheduledDate', isGreaterThanOrEqualTo: startDate)
        .where('scheduledDate', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Complete a session
  Future<void> completeSession(String sessionId, {String? notes}) async {
    try {
      DocumentSnapshot sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      SessionModel session = SessionModel.fromMap(
          sessionDoc.data() as Map<String, dynamic>, sessionDoc.id);

      // Update session status
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': SessionStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      });

      // If session is part of a package, increment sessions used
      if (session.clientPackageId != null) {
        DocumentSnapshot packageDoc = await _firestore
            .collection('client_packages')
            .doc(session.clientPackageId)
            .get();

        if (packageDoc.exists) {
          ClientPackage clientPackage = ClientPackage.fromMap(
              packageDoc.data() as Map<String, dynamic>, packageDoc.id);

          int newSessionsUsed = clientPackage.sessionsUsed + 1;
          PackageStatus newStatus = clientPackage.status;

          // If all sessions used, mark package as completed
          if (newSessionsUsed >= clientPackage.totalSessions) {
            newStatus = PackageStatus.completed;
          }

          await _firestore
              .collection('client_packages')
              .doc(session.clientPackageId)
              .update({
            'sessionsUsed': newSessionsUsed,
            'status': newStatus.name,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to complete session: ${e.toString()}');
    }
  }

  // Cancel a session
  Future<void> cancelSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': SessionStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel session: ${e.toString()}');
    }
  }

  // Mark session as no-show
  Future<void> markNoShow(String sessionId) async {
    try {
      DocumentSnapshot sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      SessionModel session = SessionModel.fromMap(
          sessionDoc.data() as Map<String, dynamic>, sessionDoc.id);

      await _firestore.collection('sessions').doc(sessionId).update({
        'status': SessionStatus.noShow.name,
      });

      // Still increment sessions used for no-shows (policy decision)
      if (session.clientPackageId != null) {
        DocumentSnapshot packageDoc = await _firestore
            .collection('client_packages')
            .doc(session.clientPackageId)
            .get();

        if (packageDoc.exists) {
          ClientPackage clientPackage = ClientPackage.fromMap(
              packageDoc.data() as Map<String, dynamic>, packageDoc.id);

          int newSessionsUsed = clientPackage.sessionsUsed + 1;
          await _firestore
              .collection('client_packages')
              .doc(session.clientPackageId)
              .update({
            'sessionsUsed': newSessionsUsed,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to mark no-show: ${e.toString()}');
    }
  }

  // Get total sessions conducted for a client
  Future<int> getClientTotalSessions(String clientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: SessionStatus.completed.name)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get total sessions: ${e.toString()}');
    }
  }
}
