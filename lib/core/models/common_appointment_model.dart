import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

// Randevu Durumları
enum AppointmentStatus {
  pending('pending', 'Beklemede'),
  confirmed('confirmed', 'Onaylandı'),
  completed('completed', 'Tamamlandı'),
  cancelled('cancelled', 'İptal Edildi'),
  noShow('no_show', 'Gelmedi');

  const AppointmentStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Ortak Randevu Modeli
class CommonAppointmentModel extends BaseModel
    implements StatusModel, SectorModel {
  final String customerId;
  final String customerName;
  final String? employeeId;
  final String? employeeName;
  final String? serviceId;
  final String serviceName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final double price;
  final AppointmentStatus appointmentStatus;
  final String notes;
  final bool isRecurring;
  final String? recurringType; // daily, weekly, monthly
  final DateTime? recurringEndDate;
  final bool reminderSent;
  final String category;
  @override
  final Map<String, dynamic> sectorSpecificData;

  const CommonAppointmentModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.customerId,
    required this.customerName,
    this.employeeId,
    this.employeeName,
    this.serviceId,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    required this.price,
    this.appointmentStatus = AppointmentStatus.pending,
    this.notes = '',
    this.isRecurring = false,
    this.recurringType,
    this.recurringEndDate,
    this.reminderSent = false,
    required this.category,
    this.sectorSpecificData = const {},
  });

  factory CommonAppointmentModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);
    return CommonAppointmentModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      serviceId: map['serviceId'],
      serviceName: map['serviceName'] ?? '',
      appointmentDate:
          (map['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: map['appointmentTime'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 60,
      price: (map['price'] ?? 0).toDouble(),
      appointmentStatus: AppointmentStatus.values.firstWhere(
        (status) => status.value == (map['appointmentStatus'] ?? 'pending'),
        orElse: () => AppointmentStatus.pending,
      ),
      notes: map['notes'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      recurringType: map['recurringType'],
      recurringEndDate: (map['recurringEndDate'] as Timestamp?)?.toDate(),
      reminderSent: map['reminderSent'] ?? false,
      category: map['category'] ?? '',
      sectorSpecificData:
          Map<String, dynamic>.from(map['sectorSpecificData'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'customerId': customerId,
      'customerName': customerName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'durationMinutes': durationMinutes,
      'price': price,
      'appointmentStatus': appointmentStatus.value,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'recurringEndDate': recurringEndDate != null
          ? Timestamp.fromDate(recurringEndDate!)
          : null,
      'reminderSent': reminderSent,
      'category': category,
      'sectorSpecificData': sectorSpecificData,
    });
    return map;
  }

  // StatusModel implementation
  @override
  String get status => appointmentStatus.value;

  @override
  bool get isActive => appointmentStatus != AppointmentStatus.cancelled;

  // SectorModel implementation
  @override
  String get sector => sectorSpecificData['sector'] ?? '';

  // Utility methods
  DateTime get appointmentDateTime {
    final timeParts = appointmentTime.split(':');
    if (timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      return DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );
    }
    return appointmentDate;
  }

  DateTime get endDateTime =>
      appointmentDateTime.add(Duration(minutes: durationMinutes));

  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
  }

  bool get isPast => appointmentDateTime.isBefore(DateTime.now());

  bool get isUpcoming => appointmentDateTime.isAfter(DateTime.now());

  bool get canBeCancelled =>
      !isPast && appointmentStatus != AppointmentStatus.cancelled;

  bool get needsReminder {
    if (reminderSent) return false;
    final reminderTime = appointmentDateTime.subtract(const Duration(hours: 2));
    return DateTime.now().isAfter(reminderTime) && isUpcoming;
  }

  // Conflict checking
  bool conflictsWith(CommonAppointmentModel other) {
    if (employeeId != null &&
        other.employeeId != null &&
        employeeId != other.employeeId) {
      return false; // Different employees, no conflict
    }

    final thisStart = appointmentDateTime;
    final thisEnd = endDateTime;
    final otherStart = other.appointmentDateTime;
    final otherEnd = other.endDateTime;

    return !(thisEnd.isBefore(otherStart) || thisStart.isAfter(otherEnd));
  }

  CommonAppointmentModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    String? customerName,
    String? employeeId,
    String? employeeName,
    String? serviceId,
    String? serviceName,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? durationMinutes,
    double? price,
    AppointmentStatus? appointmentStatus,
    String? notes,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    bool? reminderSent,
    String? category,
    Map<String, dynamic>? sectorSpecificData,
  }) {
    return CommonAppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      reminderSent: reminderSent ?? this.reminderSent,
      category: category ?? this.category,
      sectorSpecificData: sectorSpecificData ?? this.sectorSpecificData,
    );
  }
}
