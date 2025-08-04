import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor hizmeti/ders modeli
class SportsService {
  final String? id;
  final String userId;
  final String serviceName; // Hizmet adı
  final String? description; // Açıklama
  final String
      category; // 'PT', 'grup_dersi', 'yoga', 'pilates', 'kardiyovaskuler'
  final int duration; // Süre (dakika)
  final double price; // Ücret
  final String level; // 'başlangıç', 'orta', 'ileri', 'tüm_seviyeler'
  final int? maxParticipants; // Maksimum katılımcı (grup dersleri için)
  final List<String>? equipmentNeeded; // Gerekli ekipmanlar
  final List<String>? targetMuscles; // Hedef kas grupları
  final double? estimatedCalories; // Tahmini kalori yakımı
  final String? instructorNotes; // Eğitmen notları
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SportsService({
    this.id,
    required this.userId,
    required this.serviceName,
    this.description,
    required this.category,
    this.duration = 60, // Varsayılan 60 dakika
    required this.price,
    this.level = 'tüm_seviyeler',
    this.maxParticipants,
    this.equipmentNeeded,
    this.targetMuscles,
    this.estimatedCalories,
    this.instructorNotes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Firebase'den veri çekme
  factory SportsService.fromMap(Map<String, dynamic> map, String id) {
    return SportsService(
      id: id,
      userId: map['userId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      description: map['description'],
      category: map['category'] ?? '',
      duration: map['duration'] ?? 60,
      price: (map['price'] ?? 0.0).toDouble(),
      level: map['level'] ?? 'tüm_seviyeler',
      maxParticipants: map['maxParticipants'],
      equipmentNeeded: map['equipmentNeeded'] != null
          ? List<String>.from(map['equipmentNeeded'])
          : null,
      targetMuscles: map['targetMuscles'] != null
          ? List<String>.from(map['targetMuscles'])
          : null,
      estimatedCalories: map['estimatedCalories']?.toDouble(),
      instructorNotes: map['instructorNotes'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceName': serviceName,
      'description': description,
      'category': category,
      'duration': duration,
      'price': price,
      'level': level,
      'maxParticipants': maxParticipants,
      'equipmentNeeded': equipmentNeeded,
      'targetMuscles': targetMuscles,
      'estimatedCalories': estimatedCalories,
      'instructorNotes': instructorNotes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Kategori emojisi
  String get categoryEmoji {
    switch (category) {
      case 'PT':
        return '💪';
      case 'grup_dersi':
        return '👥';
      case 'yoga':
        return '🧘';
      case 'pilates':
        return '🤸';
      case 'kardiyovaskuler':
        return '❤️';
      case 'crossfit':
        return '🏋️';
      default:
        return '🏃';
    }
  }

  // Formatlanmış ücret
  String get formattedPrice {
    return '${price.toStringAsFixed(2)} ₺';
  }

  // Formatlanmış süre
  String get formattedDuration {
    if (duration < 60) {
      return '$duration dk';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '$hours sa';
      } else {
        return '$hours sa $minutes dk';
      }
    }
  }
}
