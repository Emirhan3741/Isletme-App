import 'package:cloud_firestore/cloud_firestore.dart';

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

enum NotePriority {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
}

extension NotePriorityExtension on NotePriority {
  String get displayName {
    switch (this) {
      case NotePriority.veryLow:
        return 'Very Low';
      case NotePriority.low:
        return 'Low';
      case NotePriority.medium:
        return 'Medium';
      case NotePriority.high:
        return 'High';
      case NotePriority.veryHigh:
        return 'Very High';
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
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      color: map['color'] ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'color': color,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NoteModel{id: $id, title: $title, content: $content, color: $color, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}

// Cleaned for Web Build by Cursor 