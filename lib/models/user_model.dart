// CodeRabbit analyze fix: Dosya düzenlendi
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rol;
  final DateTime? lastSignIn;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.rol,
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
      rol: map['rol'],
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
      'rol': rol,
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
    String? rol,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rol: rol ?? this.rol,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, photoURL: $photoURL, createdAt: $createdAt, updatedAt: $updatedAt, rol: $rol, lastSignIn: $lastSignIn)';
  }

  String get adSoyad => displayName;
  String get eposta => email;
  String get uid => id;
  DateTime get oluşturulmaTarihi => createdAt;
  bool get isOwner => rol == 'owner';
  bool get isWorker => rol == 'worker';
  // rol için ileride enum tanımı yapılması önerildi.
  // Refactored by CodeRabbit suggestion
} 