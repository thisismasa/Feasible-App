class SessionModel {
  final String id;
  final String clientId;
  final String clientName;
  final String trainerId;
  final DateTime scheduledDate;
  final int durationMinutes;
  final SessionStatus status;
  final String? notes;
  final String? clientPackageId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double price;

  SessionModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    required this.scheduledDate,
    required this.durationMinutes,
    required this.status,
    this.notes,
    this.clientPackageId,
    required this.createdAt,
    this.completedAt,
    this.price = 50.0,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      trainerId: map['trainerId'] ?? '',
      scheduledDate: DateTime.parse(map['scheduledDate']),
      durationMinutes: map['durationMinutes'] ?? 60,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${map['status']}',
        orElse: () => SessionStatus.scheduled,
      ),
      notes: map['notes'],
      clientPackageId: map['clientPackageId'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }
  
  factory SessionModel.fromSupabaseMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      clientId: map['client_id'] ?? '',
      clientName: map['client_name'] ?? 'Unknown',
      trainerId: map['trainer_id'] ?? '',
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.parse(map['scheduled_date'])
          : DateTime.now(),
      durationMinutes: map['duration_minutes'] ?? 60,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'scheduled'),
        orElse: () => SessionStatus.scheduled,
      ),
      notes: map['notes'],
      clientPackageId: map['client_package_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'trainerId': trainerId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'notes': notes,
      'clientPackageId': clientPackageId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

enum SessionStatus {
  scheduled,
  completed,
  cancelled,
  noShow,
}
