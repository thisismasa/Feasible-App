class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;
  final Map<String, dynamic>? metadata;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.metadata,
    this.isOnline = false,
    this.lastSeen,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.client,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      photoUrl: map['photo_url'],
      metadata: map['metadata'],
      isOnline: map['is_online'] ?? false,
      lastSeen: map['last_seen'] != null ? DateTime.parse(map['last_seen']) : null,
    );
  }
  
  factory UserModel.fromSupabaseMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'] ?? '',
      name: map['full_name'] ?? map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.client,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      photoUrl: map['photo_url'],
      metadata: map['metadata'],
      isOnline: map['is_online'] ?? false,
      lastSeen: map['last_seen'] != null ? DateTime.parse(map['last_seen']) : null,
      isActive: map['is_active'] ?? true,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.client,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      photoUrl: json['photo_url'],
      metadata: json['metadata'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'photo_url': photoUrl,
      'metadata': metadata,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'name': name,
      'phone': phone,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
      'metadata': metadata,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

enum UserRole {
  client,
  trainer,
}
