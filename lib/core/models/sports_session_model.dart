import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor seansı/randevu modeli
class SportsSession {
  final String? id;
  final String userId; // Salon/stüdyo sahibinin ID'si
  final String? memberId; // Üye ID'si
  final String? memberName; // Üye adı (hızlı erişim için)
  final String? trainerId; // Eğitmen ID'si
  final String? trainerName; // Eğitmen adı
  final String sessionType; // 'PT', 'grup_dersi', 'yoga', 'pilates', 'crossfit'
  final String serviceName; // Hizmet adı
  final DateTime sessionDate; // Seans tarihi
  final String sessionTime; // Seans saati (örn: "09:00")
  final int duration; // Dakika cinsinden süre
  final double price; // Ücret
  final String status; // 'bekliyor', 'onaylandı', 'tamamlandı', 'iptal'
  final String? notes; // Seans notları
  final String? paymentStatus; // 'ödenmedi', 'ödendi', 'kısmi'
  final bool isRecurring; // Tekrarlayan seans mı?
  final String? recurringType; // 'haftalık', 'aylık'
  final Map<String, dynamic>? recurringSettings; // Tekrar ayarları
  final String? location; // Konum/salon
  final int? maxParticipants; // Maksimum katılımcı (grup dersleri için)
  final List<String>? participantIds; // Katılımcı ID'leri
  final String? equipment; // Gerekli ekipman
  final String? level; // Seviye (başlangıç, orta, ileri)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  SportsSession({
    this.id,
    required this.userId,
    this.memberId,
    this.memberName,
    this.trainerId,
    this.trainerName,
    required this.sessionType,
    required this.serviceName,
    required this.sessionDate,
    required this.sessionTime,
    required this.duration,
    required this.price,
    this.status = 'bekliyor',
    this.notes,
    this.paymentStatus = 'ödenmedi',
    this.isRecurring = false,
    this.recurringType,
    this.recurringSettings,
    this.location,
    this.maxParticipants,
    this.participantIds,
    this.equipment,
    this.level,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Firebase'den veri çekme
  factory SportsSession.fromMap(Map<String, dynamic> map, String id) {
    return SportsSession(
      id: id,
      userId: map['userId'] ?? '',
      memberId: map['memberId'],
      memberName: map['memberName'],
      trainerId: map['trainerId'],
      trainerName: map['trainerName'],
      sessionType: map['sessionType'] ?? '',
      serviceName: map['serviceName'] ?? '',
      sessionDate: (map['sessionDate'] as Timestamp).toDate(),
      sessionTime: map['sessionTime'] ?? '',
      duration: map['duration'] ?? 60,
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'bekliyor',
      notes: map['notes'],
      paymentStatus: map['paymentStatus'] ?? 'ödenmedi',
      isRecurring: map['isRecurring'] ?? false,
      recurringType: map['recurringType'],
      recurringSettings: map['recurringSettings'],
      location: map['location'],
      maxParticipants: map['maxParticipants'],
      participantIds: map['participantIds'] != null
          ? List<String>.from(map['participantIds'])
          : null,
      equipment: map['equipment'],
      level: map['level'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'memberId': memberId,
      'memberName': memberName,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'sessionType': sessionType,
      'serviceName': serviceName,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'sessionTime': sessionTime,
      'duration': duration,
      'price': price,
      'status': status,
      'notes': notes,
      'paymentStatus': paymentStatus,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'recurringSettings': recurringSettings,
      'location': location,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'equipment': equipment,
      'level': level,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  // Copy with method
  SportsSession copyWith({
    String? id,
    String? userId,
    String? memberId,
    String? memberName,
    String? trainerId,
    String? trainerName,
    String? sessionType,
    String? serviceName,
    DateTime? sessionDate,
    String? sessionTime,
    int? duration,
    double? price,
    String? status,
    String? notes,
    String? paymentStatus,
    bool? isRecurring,
    String? recurringType,
    Map<String, dynamic>? recurringSettings,
    String? location,
    int? maxParticipants,
    List<String>? participantIds,
    String? equipment,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SportsSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      sessionType: sessionType ?? this.sessionType,
      serviceName: serviceName ?? this.serviceName,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringSettings: recurringSettings ?? this.recurringSettings,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantIds: participantIds ?? this.participantIds,
      equipment: equipment ?? this.equipment,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Seans bitiş zamanı
  DateTime get sessionEndTime {
    final parts = sessionTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final startDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      hour,
      minute,
    );

    return startDateTime.add(Duration(minutes: duration));
  }

  // Seans durumu emoji
  String get statusEmoji {
    switch (status) {
      case 'bekliyor':
        return '⏳';
      case 'onaylandı':
        return '✅';
      case 'tamamlandı':
        return '🎯';
      case 'iptal':
        return '❌';
      default:
        return '⏳';
    }
  }

  // Ödeme durumu emoji
  String get paymentStatusEmoji {
    switch (paymentStatus) {
      case 'ödendi':
        return '💳';
      case 'kısmi':
        return '⚠️';
      case 'ödenmedi':
        return '💰';
      default:
        return '💰';
    }
  }

  // Türkçe getter'lar (UI uyumluluğu için)
  String get seansTipi => sessionType;
  DateTime get seansTarihi => sessionDate;
  int get sure => duration;
  String? get notlar => notes;

  // Formatlanmış tutar
  String get formatliTutar {
    return '${price.toStringAsFixed(2)} ₺';
  }
}
