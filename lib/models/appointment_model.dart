import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AppointmentStatus {
  pending,
  planned,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get text {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Bekliyor';
      case AppointmentStatus.planned:
        return 'Planlandı';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.inProgress:
        return 'Devam Ediyor';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.noShow:
        return 'Gelmedi';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.planned:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.green.shade700;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.planned:
        return Icons.event;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.timelapse;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }
}

class AppointmentModel {
  final String id;
  final String userId;
  final String? customerId;
  final String? customerName;
  final String? employeeId;
  final String? employeeName;
  final String? serviceId;

  final int? duration; // dakika cinsinden
  final DateTime date;
  final TimeOfDay time;
  final AppointmentStatus status;
  final String? notes;
  final double? price;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    this.customerId,
    this.customerName,
    this.employeeId,
    this.employeeName,
    this.serviceId,
    this.duration,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    this.price,
    required this.createdAt,
    this.updatedAt,
  });

  // Backward compatibility getters
  String? get serviceName => serviceId;
  String? get serviceTitle => serviceId;
  DateTime get dateTime =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
  String? get note => notes;
  bool get isPaid => price != null && price! > 0;

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    // Tarih dönüştürme helper
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.parse(dateValue);
      return DateTime.now();
    }

    // Saat dönüştürme helper
    TimeOfDay parseTime(dynamic timeValue) {
      if (timeValue == null) return TimeOfDay.now();
      if (timeValue is Timestamp) {
        final date = timeValue.toDate();
        return TimeOfDay(hour: date.hour, minute: date.minute);
      }
      if (timeValue is String) {
        final parts = timeValue.split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return TimeOfDay.now();
    }

    return AppointmentModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
      employeeId: map['employeeId'] as String?,
      employeeName: map['employeeName'] as String?,
      serviceId: map['serviceId'] as String?,
      date: parseDate(map['date']),
      time: parseTime(map['time']),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => AppointmentStatus.pending,
      ),
      notes: map['notes'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerId': customerId,
      'customerName': customerName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'serviceId': serviceId,
      'date': Timestamp.fromDate(date),
      'time': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day, time.hour, time.minute)),
      'status': status.name,
      'notes': notes,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? customerName,
    String? employeeId,
    String? employeeName,
    String? serviceId,
    DateTime? date,
    TimeOfDay? time,
    AppointmentStatus? status,
    String? notes,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel{id: $id, customerId: $customerId, status: $status, date: $date}';
  }

  String getStatusText() {
    return status.text;
  }

  Color getStatusColor() {
    return status.color;
  }

  IconData getStatusIcon() {
    return status.icon;
  }
}
