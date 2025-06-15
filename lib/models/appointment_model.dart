import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String customerId;
  final String employeeId;
  final DateTime date;
  final String time;
  final String operationName;
  final String? note;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.employeeId,
    required this.date,
    required this.time,
    required this.operationName,
    this.note,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap(data, doc.id);
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return AppointmentModel(
      id: documentId ?? map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      time: map['time'] ?? '',
      operationName: map['operationName'] ?? '',
      note: map['note'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'employeeId': employeeId,
      'date': date,
      'time': time,
      'operationName': operationName,
      'note': note,
      'createdAt': createdAt,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? employeeId,
    DateTime? date,
    String? time,
    String? operationName,
    String? note,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      time: time ?? this.time,
      operationName: operationName ?? this.operationName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel{id: $id, customerId: $customerId, operationName: $operationName, date: $date, time: $time}';
  }
} 