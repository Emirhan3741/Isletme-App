import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

enum NoteCategory {
  general,
  marketing,
  personnel,
  production,
  finance,
  customer,
  supply,
  quality,
  technology,
  law,
  sales,
  project,
}

extension NoteCategoryExtension on NoteCategory {
  String get displayName {
    switch (this) {
      case NoteCategory.general:
        return 'General';
      case NoteCategory.marketing:
        return 'Marketing';
      case NoteCategory.personnel:
        return 'Personnel';
      case NoteCategory.production:
        return 'Production';
      case NoteCategory.finance:
        return 'Finance';
      case NoteCategory.customer:
        return 'Customer';
      case NoteCategory.supply:
        return 'Supply';
      case NoteCategory.quality:
        return 'Quality';
      case NoteCategory.technology:
        return 'Technology';
      case NoteCategory.law:
        return 'Law';
      case NoteCategory.sales:
        return 'Sales';
      case NoteCategory.project:
        return 'Project';
    }
  }
}

enum NoteStatus {
  active,
  completed,
  archived,
  deleted,
  pending,
}

enum NotePriority {
  low,
  medium,
  high,
  urgent,
}

extension NoteStatusExtension on NoteStatus {
  String get text {
    switch (this) {
      case NoteStatus.active:
        return 'Aktif';
      case NoteStatus.completed:
        return 'Tamamlandı';
      case NoteStatus.archived:
        return 'Arşivlendi';
      case NoteStatus.deleted:
        return 'Silindi';
      case NoteStatus.pending:
        return 'Beklemede';
    }
  }

  Color get color {
    switch (this) {
      case NoteStatus.active:
        return Colors.blue;
      case NoteStatus.completed:
        return Colors.green;
      case NoteStatus.archived:
        return Colors.orange;
      case NoteStatus.deleted:
        return Colors.red;
      case NoteStatus.pending:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case NoteStatus.active:
        return Icons.note;
      case NoteStatus.completed:
        return Icons.check_circle;
      case NoteStatus.archived:
        return Icons.archive;
      case NoteStatus.deleted:
        return Icons.delete;
      case NoteStatus.pending:
        return Icons.pending;
    }
  }
}

extension NotePriorityExtension on NotePriority {
  String get text {
    switch (this) {
      case NotePriority.low:
        return 'Düşük';
      case NotePriority.medium:
        return 'Orta';
      case NotePriority.high:
        return 'Yüksek';
      case NotePriority.urgent:
        return 'Acil';
    }
  }

  Color get color {
    switch (this) {
      case NotePriority.low:
        return Colors.green;
      case NotePriority.medium:
        return Colors.blue;
      case NotePriority.high:
        return Colors.orange;
      case NotePriority.urgent:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case NotePriority.low:
        return Icons.arrow_downward;
      case NotePriority.medium:
        return Icons.remove;
      case NotePriority.high:
        return Icons.arrow_upward;
      case NotePriority.urgent:
        return Icons.priority_high;
    }
  }
}

enum NoteColor {
  blue,
  green,
  red,
  orange,
  purple,
  pink,
  yellow,
  gray,
  turquoise,
  lime,
}

extension NoteColorExtension on NoteColor {
  String get displayName {
    switch (this) {
      case NoteColor.blue:
        return 'Blue';
      case NoteColor.green:
        return 'Green';
      case NoteColor.red:
        return 'Red';
      case NoteColor.orange:
        return 'Orange';
      case NoteColor.purple:
        return 'Purple';
      case NoteColor.pink:
        return 'Pink';
      case NoteColor.yellow:
        return 'Yellow';
      case NoteColor.gray:
        return 'Gray';
      case NoteColor.turquoise:
        return 'Turquoise';
      case NoteColor.lime:
        return 'Lime';
    }
  }

  static NoteColor fromString(String value) {
    return NoteColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteColor.blue,
    );
  }
}

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NoteStatus status;
  final NotePriority priority;
  final String category;
  final DateTime? deadline;
  final String color;
  final List<String>? tags;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.priority,
    required this.category,
    this.deadline,
    required this.color,
    this.tags,
  });

  // Backward compatibility getter'ları
  String get encryptedContent => content; // Şifreli içerik için

  // Şifreli içerik çözme
  String getDecryptedContent(String keyStr) {
    if (!kIsWeb) {
      final key = encrypt.Key.fromUtf8(keyStr.padRight(32, '0'));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt64(content, iv: iv);
    }
    return content;
  }

  // Şifreli içerik oluşturma
  static String encryptContent(String content, String keyStr) {
    if (!kIsWeb) {
      final key = encrypt.Key.fromUtf8(keyStr.padRight(32, '0'));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.encrypt(content, iv: iv).base64;
    }
    return content;
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: NoteStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => NoteStatus.active,
      ),
      priority: NotePriority.values.firstWhere(
        (e) => e.name == (map['priority'] as String),
        orElse: () => NotePriority.medium,
      ),
      category: map['category'] as String,
      deadline: map['deadline'] != null
          ? (map['deadline'] as Timestamp).toDate()
          : null,
      color: map['color'] as String,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'color': color,
      'tags': tags,
    };
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteStatus? status,
    NotePriority? priority,
    String? category,
    DateTime? deadline,
    String? color,
    List<String>? tags,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      tags: tags ?? this.tags,
    );
  }

  // Status ve Priority metotları
  String getStatusText() {
    return status.text;
  }

  String getPriorityText() {
    return priority.text;
  }

  Color getStatusColor() {
    return status.color;
  }

  Color getPriorityColor() {
    return priority.color;
  }

  IconData getStatusIcon() {
    return status.icon;
  }

  @override
  String toString() {
    return 'NoteModel{id: $id, title: $title, status: $status, priority: $priority}';
  }
}

// Cleaned for Web Build by Cursor
