import 'package:cloud_firestore/cloud_firestore.dart';

// Kullanıcı rolleri enum
enum UserRole {
  owner,
  worker;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'İşletme Sahibi';
      case UserRole.worker:
        return 'Çalışan';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'worker':
        return UserRole.worker;
      default:
        return UserRole.worker;
    }
  }
}

class UserModel {
  final String id;
  final String adSoyad;
  final String eposta;
  final UserRole rol;
  final Timestamp oluşturulmaTarihi;
  final String? photoURL;
  final DateTime lastSignIn;

  UserModel({
    required this.id,
    required this.adSoyad,
    required this.eposta,
    required this.rol,
    required this.oluşturulmaTarihi,
    this.photoURL,
    required this.lastSignIn,
  });

  // Firebase Auth User'dan UserModel oluştur
  factory UserModel.fromFirebaseUser(user, {
    String? adSoyad,
    UserRole? rol,
    Timestamp? oluşturulmaTarihi,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: user.uid,
      adSoyad: adSoyad ?? user.displayName ?? 'Kullanıcı',
      eposta: user.email ?? '',
      rol: rol ?? UserRole.worker,
      photoURL: user.photoURL,
      oluşturulmaTarihi: oluşturulmaTarihi ?? Timestamp.now(),
      lastSignIn: lastSignIn ?? DateTime.now(),
    );
  }

  // Firestore'dan UserModel oluştur
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      adSoyad: map['adSoyad'] ?? '',
      eposta: map['eposta'] ?? '',
      rol: UserRole.fromString(map['rol'] ?? 'worker'),
      photoURL: map['photoURL'],
      oluşturulmaTarihi: map['oluşturulmaTarihi'] ?? Timestamp.now(),
      lastSignIn: DateTime.parse(map['lastSignIn'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Firestore için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adSoyad': adSoyad,
      'eposta': eposta,
      'rol': rol.name,
      'photoURL': photoURL,
      'oluşturulmaTarihi': oluşturulmaTarihi,
      'lastSignIn': lastSignIn.toIso8601String(),
    };
  }

  // Kullanıcı bilgilerini güncelle
  UserModel copyWith({
    String? id,
    String? adSoyad,
    String? eposta,
    UserRole? rol,
    String? photoURL,
    Timestamp? oluşturulmaTarihi,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      eposta: eposta ?? this.eposta,
      rol: rol ?? this.rol,
      photoURL: photoURL ?? this.photoURL,
      oluşturulmaTarihi: oluşturulmaTarihi ?? this.oluşturulmaTarihi,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  // Yetki kontrolü metodları
  bool get isOwner => rol == UserRole.owner;
  bool get isWorker => rol == UserRole.worker;

  @override
  String toString() {
    return 'UserModel(id: $id, adSoyad: $adSoyad, eposta: $eposta, rol: ${rol.displayName})';
  }
} 