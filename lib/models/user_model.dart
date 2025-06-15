// CodeRabbit analyze fix: Dosya düzenlendi

enum UserRole { owner, worker, unknown }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Yönetici';
      case UserRole.worker:
        return 'Çalışan';
      default:
        return 'Bilinmiyor';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'worker':
        return UserRole.worker;
      default:
        return UserRole.unknown;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserRole role;
  final DateTime? lastSignIn;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.role = UserRole.unknown,
    this.lastSignIn,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      role: UserRoleExtension.fromString(map['rol']),
      lastSignIn: map['lastSignIn'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastSignIn']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'rol': role.name,
      'lastSignIn': lastSignIn?.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserRole? role,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, photoURL: $photoURL, createdAt: $createdAt, updatedAt: $updatedAt, role: $role, lastSignIn: $lastSignIn)';
  }

  String get adSoyad => displayName;
  String get eposta => email;
  String get uid => id;
  DateTime get oluşturulmaTarihi => createdAt;
  bool get isOwner => role == UserRole.owner;
  bool get isWorker => role == UserRole.worker;
  // Refactored by Cursor
} 