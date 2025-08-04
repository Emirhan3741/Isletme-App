import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locapo/models/appointment_model.dart';

void main() {
  group('AppointmentModel Tests', () {
    test('should create AppointmentModel with required fields', () {
      // Arrange
      final dateTime = DateTime.now();
      final appointment = AppointmentModel(
        id: 'test_id',
        userId: 'user_id',
        customerId: 'customer_id',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: dateTime,
        time: TimeOfDay.fromDateTime(dateTime),
        status: AppointmentStatus.confirmed,
        createdAt: dateTime,
      );

      // Assert
      expect(appointment.id, 'test_id');
      expect(appointment.userId, 'user_id');
      expect(appointment.customerId, 'customer_id');
      expect(appointment.serviceId, 'service_id');
      expect(appointment.employeeId, 'employee_id');
      expect(appointment.status, AppointmentStatus.confirmed);
    });

    test('should compare appointments correctly', () {
      // Arrange
      final dateTime = DateTime.now();
      final appointment1 = AppointmentModel(
        id: 'test_id_1',
        userId: 'user_id',
        customerId: 'customer_id_1',
        serviceId: 'service_id_1',
        employeeId: 'employee_id_1',
        date: dateTime,
        time: TimeOfDay.fromDateTime(dateTime),
        status: AppointmentStatus.pending,
        createdAt: dateTime,
      );

      final appointment2 = AppointmentModel(
        id: 'test_id_2',
        userId: 'user_id',
        customerId: 'customer_id_2',
        serviceId: 'service_id_2',
        employeeId: 'employee_id_2',
        date: dateTime,
        time: TimeOfDay.fromDateTime(dateTime),
        status: AppointmentStatus.completed,
        createdAt: dateTime,
      );

      // Assert
      expect(appointment1 == appointment2, false);
      expect(appointment1.id == appointment2.id, false);
    });

    test('should create from map correctly', () {
      // Arrange
      final dateTime = DateTime.now();
      final map = {
        'id': 'test_id',
        'userId': 'user_id',
        'customerId': 'customer_id',
        'serviceId': 'service_id',
        'employeeId': 'employee_id',
        'date': Timestamp.fromDate(dateTime),
        'time': {'hour': dateTime.hour, 'minute': dateTime.minute},
        'status': 'confirmed',
        'notes': 'Test notes',
        'createdAt': Timestamp.fromDate(dateTime),
      };

      // Act
      final appointment = AppointmentModel.fromMap(map);

      // Assert
      expect(appointment.id, 'test_id');
      expect(appointment.userId, 'user_id');
      expect(appointment.status, AppointmentStatus.confirmed);
      expect(appointment.notes, 'Test notes');
    });
  });
}
