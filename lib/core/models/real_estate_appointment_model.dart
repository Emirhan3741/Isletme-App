import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AppointmentStatus {
  planned, // Planlandı
  completed, // Tamamlandı
  cancelled, // İptal Edildi
  rescheduled // Ertelendi
}

enum AppointmentType {
  viewing, // Mülk Gösterimi
  meeting, // Müşteri Toplantısı
  consultation, // Danışmanlık
  valuation // Değerleme
}

class RealEstateAppointment {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String propertyName;
  final String propertyAddress;
  final String propertyId;
  final DateTime appointmentDate;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? expectedPrice;
  final String? customerBudget;

  const RealEstateAppointment({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.propertyName,
    required this.propertyAddress,
    required this.propertyId,
    required this.appointmentDate,
    required this.type,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.expectedPrice,
    this.customerBudget,
  });

  factory RealEstateAppointment.fromMap(Map<String, dynamic> map) {
    return RealEstateAppointment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      propertyName: map['propertyName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      propertyId: map['propertyId'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      type: AppointmentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AppointmentType.viewing,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AppointmentStatus.planned,
      ),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      expectedPrice: map['expectedPrice']?.toDouble(),
      customerBudget: map['customerBudget'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
      'propertyId': propertyId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'expectedPrice': expectedPrice,
      'customerBudget': customerBudget,
    };
  }

  RealEstateAppointment copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? propertyName,
    String? propertyAddress,
    String? propertyId,
    DateTime? appointmentDate,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? expectedPrice,
    String? customerBudget,
  }) {
    return RealEstateAppointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyId: propertyId ?? this.propertyId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      customerBudget: customerBudget ?? this.customerBudget,
    );
  }

  // Yardımcı metodlar
  String get typeDisplayName {
    switch (type) {
      case AppointmentType.viewing:
        return 'Mülk Gösterimi';
      case AppointmentType.meeting:
        return 'Müşteri Toplantısı';
      case AppointmentType.consultation:
        return 'Danışmanlık';
      case AppointmentType.valuation:
        return 'Değerleme';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AppointmentStatus.planned:
        return 'Planlandı';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.rescheduled:
        return 'Ertelendi';
    }
  }

  Color get statusColor {
    switch (status) {
      case AppointmentStatus.planned:
        return const Color(0xFF3B82F6); // Mavi
      case AppointmentStatus.completed:
        return const Color(0xFF10B981); // Yeşil
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444); // Kırmızı
      case AppointmentStatus.rescheduled:
        return const Color(0xFFF59E0B); // Sarı
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AppointmentStatus.planned:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.rescheduled:
        return Icons.update;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AppointmentType.viewing:
        return Icons.visibility;
      case AppointmentType.meeting:
        return Icons.meeting_room;
      case AppointmentType.consultation:
        return Icons.support_agent;
      case AppointmentType.valuation:
        return Icons.assessment;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.day == now.day &&
        appointmentDate.month == now.month &&
        appointmentDate.year == now.year;
  }

  bool get isPast {
    return appointmentDate.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    return appointmentDate.isAfter(DateTime.now());
  }

  String get formattedDate {
    final months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return '${appointmentDate.day} ${months[appointmentDate.month]} ${appointmentDate.year}';
  }

  String get formattedTime {
    return '${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }
}
