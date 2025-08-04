import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor salonu not/görev modeli
class SportsNote {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final String
      category; // 'görev', 'hatırlatma', 'genel', 'üye_notu', 'antrenman_notu'
  final String priority; // 'düşük', 'orta', 'yüksek', 'acil'
  final DateTime? dueDate; // Bitiş tarihi
  final String status; // 'bekliyor', 'devam_ediyor', 'tamamlandı', 'iptal'
  final String? assignedTo; // Atanan kişi (eğitmen ID)
  final String? relatedMemberId; // İlgili üye ID
  final String? relatedSessionId; // İlgili seans ID
  final List<String>? tags; // Etiketler
  final String? notes; // Ek notlar
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final bool isActive;

  SportsNote({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.priority = 'orta',
    this.dueDate,
    this.status = 'bekliyor',
    this.assignedTo,
    this.relatedMemberId,
    this.relatedSessionId,
    this.tags,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.isActive = true,
  });

  // Firebase'den veri çekme
  factory SportsNote.fromMap(Map<String, dynamic> map, String id) {
    return SportsNote(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'genel',
      priority: map['priority'] ?? 'orta',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      status: map['status'] ?? 'bekliyor',
      assignedTo: map['assignedTo'],
      relatedMemberId: map['relatedMemberId'],
      relatedSessionId: map['relatedSessionId'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'assignedTo': assignedTo,
      'relatedMemberId': relatedMemberId,
      'relatedSessionId': relatedSessionId,
      'tags': tags,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isActive': isActive,
    };
  }

  // Kategori emojisi
  String get categoryEmoji {
    switch (category) {
      case 'görev':
        return '✅';
      case 'hatırlatma':
        return '⏰';
      case 'genel':
        return '📝';
      case 'üye_notu':
        return '👤';
      case 'antrenman_notu':
        return '💪';
      default:
        return '📝';
    }
  }

  // Öncelik emojisi
  String get priorityEmoji {
    switch (priority) {
      case 'düşük':
        return '🟢';
      case 'orta':
        return '🟡';
      case 'yüksek':
        return '🟠';
      case 'acil':
        return '🔴';
      default:
        return '🟡';
    }
  }

  // Durum emojisi
  String get statusEmoji {
    switch (status) {
      case 'bekliyor':
        return '⏳';
      case 'devam_ediyor':
        return '🔄';
      case 'tamamlandı':
        return '✅';
      case 'iptal':
        return '❌';
      default:
        return '⏳';
    }
  }

  // Gecikmiş mi?
  bool get isOverdue {
    if (dueDate == null || status == 'tamamlandı' || status == 'iptal') {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  // Yakında bitiyor mu?
  bool get isDueSoon {
    if (dueDate == null || status == 'tamamlandı' || status == 'iptal') {
      return false;
    }
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff <= 1 && diff >= 0;
  }

  // Etiketler string formatı
  String get tagsString {
    if (tags == null || tags!.isEmpty) return '';
    return tags!.join(', ');
  }
}
