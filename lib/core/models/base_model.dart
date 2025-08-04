import 'package:cloud_firestore/cloud_firestore.dart';

// Tüm modeller için ortak base sınıf
abstract class BaseModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BaseModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  // Firestore'a kaydetmek için map'e çevir
  Map<String, dynamic> toMap();

  // Firestore'dan okumak için map'ten oluştur
  // Bu method her modelde override edilmeli

  // Ortak alanları map'e ekle
  Map<String, dynamic> baseToMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Ortak alanları map'ten al
  static Map<String, dynamic> getBaseFields(Map<String, dynamic> map) {
    return {
      'id': map['id'] as String? ?? '',
      'userId': map['userId'] as String? ?? '',
      'createdAt': (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      'updatedAt': (map['updatedAt'] as Timestamp?)?.toDate(),
    };
  }

  // Model validasyonu
  bool get isValid => id.isNotEmpty && userId.isNotEmpty;

  // Model yaşı (gün cinsinden)
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  // Son güncelleme tarihi
  DateTime get lastModified => updatedAt ?? createdAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BaseModel(id: $id, userId: $userId, createdAt: $createdAt)';
}

// Durum bazlı modeller için interface
abstract class StatusModel {
  String get status;
  bool get isActive;
}

// Öncelik bazlı modeller için interface
abstract class PriorityModel {
  String get priority;
  int get priorityLevel;
}

// Kategori bazlı modeller için interface
abstract class CategoryModel {
  String get category;
  String get categoryDisplayName;
}

// Sektörel özelleştirme için interface
abstract class SectorModel {
  String get sector;
  Map<String, dynamic> get sectorSpecificData;
}
