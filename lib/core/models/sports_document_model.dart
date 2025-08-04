import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum DocumentType {
  certificate,
  license,
  contract,
  insurance,
  medical,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get name {
    switch (this) {
      case DocumentType.certificate:
        return 'Sertifika';
      case DocumentType.license:
        return 'İzin/Lisans';
      case DocumentType.contract:
        return 'Sözleşme';
      case DocumentType.insurance:
        return 'Sigorta';
      case DocumentType.medical:
        return 'Tıbbi Belge';
      case DocumentType.other:
        return 'Diğer';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.certificate:
        return Icons.card_membership;
      case DocumentType.license:
        return Icons.verified;
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.insurance:
        return Icons.security;
      case DocumentType.medical:
        return Icons.medical_services;
      case DocumentType.other:
        return Icons.folder;
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.certificate:
        return const Color(0xFF10B981);
      case DocumentType.license:
        return const Color(0xFF3B82F6);
      case DocumentType.contract:
        return const Color(0xFFF59E0B);
      case DocumentType.insurance:
        return const Color(0xFF8B5CF6);
      case DocumentType.medical:
        return const Color(0xFFEF4444);
      case DocumentType.other:
        return const Color(0xFF6B7280);
    }
  }
}

class SportsDocument {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DocumentType type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize; // bytes
  final DateTime? expiryDate;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SportsDocument({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.expiryDate,
    required this.tags,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SportsDocument.fromMap(Map<String, dynamic> map, String documentId) {
    return SportsDocument(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'tags': tags,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SportsDocument copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DocumentType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? expiryDate,
    List<String>? tags,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportsDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      expiryDate: expiryDate ?? this.expiryDate,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Bilinmiyor';

    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get statusText {
    if (isExpired) return 'Süresi Dolmuş';
    if (isExpiringSoon) return 'Yakında Dolacak';
    return 'Geçerli';
  }

  Color get statusColor {
    if (isExpired) return const Color(0xFFEF4444);
    if (isExpiringSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get tagsDisplay => tags.join(', ');
}
