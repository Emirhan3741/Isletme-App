import 'package:cloud_firestore/cloud_firestore.dart';

/// Günlük işlem öğesi modeli (randevu, duruşma, görev vs.)
class DailyScheduleItem {
  final String id;
  final String title;
  final String panel;
  final String? customerName;
  final DateTime startTime;
  final String? description;
  final bool documentAttached;
  final bool notified;
  final String status; // active, completed, canceled
  final String itemType; // appointment, hearing, meeting, task, note, event
  final String? customerId;
  final String userId;

  DailyScheduleItem({
    required this.id,
    required this.title,
    required this.panel,
    this.customerName,
    required this.startTime,
    this.description,
    this.documentAttached = false,
    this.notified = false,
    this.status = 'active',
    required this.itemType,
    this.customerId,
    required this.userId,
  });

  /// Firestore dokümanından DailyScheduleItem oluştur
  factory DailyScheduleItem.fromFirestore(DocumentSnapshot doc, String itemType) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DailyScheduleItem(
      id: doc.id,
      title: data['title'] ?? '',
      panel: data['panel'] ?? '',
      customerName: data['customerName'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      description: data['description'],
      documentAttached: data['documentAttached'] ?? false,
      notified: data['notified'] ?? false,
      status: data['status'] ?? 'active',
      itemType: itemType,
      customerId: data['customerId'],
      userId: data['userId'] ?? '',
    );
  }

  /// Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'panel': panel,
      'customerName': customerName,
      'startTime': Timestamp.fromDate(startTime),
      'description': description,
      'documentAttached': documentAttached,
      'notified': notified,
      'status': status,
      'customerId': customerId,
      'userId': userId,
    };
  }

  /// Kalan süreyi hesapla
  String get remainingTime {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (difference.isNegative) {
      return 'Geçti';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk kaldı';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat kaldı';
    } else {
      return '${difference.inDays} gün kaldı';
    }
  }

  /// Panel türüne göre emoji döndür
  String get panelEmoji {
    switch (panel) {
      case 'lawyer':
        return '⚖️';
      case 'beauty':
        return '💄';
      case 'veterinary':
        return '🐕';
      case 'education':
        return '🎓';
      case 'sports':
        return '🏃';
      case 'consulting':
        return '💼';
      case 'real_estate':
        return '🏠';
      default:
        return '📅';
    }
  }

  /// İşlem türüne göre emoji döndür
  String get typeEmoji {
    switch (itemType) {
      case 'appointment':
        return '📅';
      case 'hearing':
        return '🧑‍⚖️';
      case 'meeting':
        return '💼';
      case 'task':
        return '✅';
      case 'note':
        return '📝';
      case 'event':
        return '🎉';
      default:
        return '📌';
    }
  }

  /// İşlem türüne göre Türkçe isim döndür
  String get typeDisplayName {
    switch (itemType) {
      case 'appointment':
        return 'Randevu';
      case 'hearing':
        return 'Duruşma';
      case 'meeting':
        return 'Görüşme';
      case 'task':
        return 'Görev';
      case 'note':
        return 'Not';
      case 'event':
        return 'Etkinlik';
      default:
        return 'İşlem';
    }
  }

  /// copyWith metodu
  DailyScheduleItem copyWith({
    String? id,
    String? title,
    String? panel,
    String? customerName,
    DateTime? startTime,
    String? description,
    bool? documentAttached,
    bool? notified,
    String? status,
    String? itemType,
    String? customerId,
    String? userId,
  }) {
    return DailyScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      panel: panel ?? this.panel,
      customerName: customerName ?? this.customerName,
      startTime: startTime ?? this.startTime,
      description: description ?? this.description,
      documentAttached: documentAttached ?? this.documentAttached,
      notified: notified ?? this.notified,
      status: status ?? this.status,
      itemType: itemType ?? this.itemType,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
    );
  }
}