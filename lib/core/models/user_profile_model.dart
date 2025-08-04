import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? specialization; // Branş (Doktor, Diş hekimi, Fizyoterapist vs.)
  final String? title; // Unvan (Dr., Prof. Dr. vs.)
  final String? clinicName;
  final String? address;
  final String? about;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.specialization,
    this.title,
    this.clinicName,
    this.address,
    this.about,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      specialization: map['specialization'],
      title: map['title'],
      clinicName: map['clinicName'],
      address: map['address'],
      about: map['about'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'title': title,
      'clinicName': clinicName,
      'address': address,
      'about': about,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? title,
    String? clinicName,
    String? address,
    String? about,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      title: title ?? this.title,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      about: about ?? this.about,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Branş seçenekleri
class SpecializationOptions {
  static const List<String> specializations = [
    'Aile Hekimi',
    'Anestezi ve Reanimasyon',
    'Beyin ve Sinir Cerrahisi',
    'Çocuk Sağlığı ve Hastalıkları',
    'Deri ve Zührevi Hastalıklar',
    'Diş Hekimi',
    'Fizik Tedavi ve Rehabilitasyon',
    'Genel Cerrahi',
    'Göğüs Hastalıkları',
    'Göz Hastalıkları',
    'Jinekolog',
    'Kalp ve Damar Cerrahisi',
    'Kardiyoloji',
    'Kulak Burun Boğaz',
    'Nöroloji',
    'Ortopedi ve Travmatoloji',
    'Plastik Cerrahi',
    'Psikiyatri',
    'Psikolog',
    'Radyoloji',
    'Üroloji',
    'Diğer',
  ];

  static const List<String> titles = [
    'Dr.',
    'Doç. Dr.',
    'Prof. Dr.',
    'Uzm. Dr.',
    'Op. Dr.',
    'Psikolog',
    'Fizyoterapist',
    'Diyetisyen',
    'Diğer',
  ];
}
