import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locapo/models/appointment_model.dart';

// Basit test sınıfı - Firebase bağımlılığı olmadan
class TestAppointmentService {
  bool hasTimeConflict(AppointmentModel newAppointment, List<AppointmentModel> existingAppointments) {
    final newStart = newAppointment.dateTime;
    final newEnd = getAppointmentEndTime(newAppointment);

    for (final existing in existingAppointments) {
      if (existing.id == newAppointment.id) continue;
      
      final existingStart = existing.dateTime;
      final existingEnd = getAppointmentEndTime(existing);

      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  DateTime getAppointmentEndTime(AppointmentModel appointment) {
    final duration = appointment.duration ?? 60;
    return appointment.dateTime.add(Duration(minutes: duration));
  }
}

void main() {
  group('AppointmentService Tests', () {
    late TestAppointmentService appointmentService;

    setUp(() {
      appointmentService = TestAppointmentService();
    });

    test('should validate appointment conflicts correctly', () {
      // Arrange
      final existingAppointment = AppointmentModel(
        id: 'existing_id',
        userId: 'user_id',
        customerId: 'customer_id',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: DateTime(2024, 1, 15),
        time: const TimeOfDay(hour: 10, minute: 0), // 10:00
        status: AppointmentStatus.confirmed,
        createdAt: DateTime.now(),
        duration: 60, // 1 hour
      );

      final newAppointment = AppointmentModel(
        id: 'new_id',
        userId: 'user_id',
        customerId: 'another_customer',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: DateTime(2024, 1, 15),
        time: const TimeOfDay(hour: 10, minute: 30), // 10:30 - conflicts!
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        duration: 60,
      );

      // Act
      final hasConflict = appointmentService.hasTimeConflict(
        newAppointment,
        [existingAppointment],
      );

      // Assert
      expect(hasConflict, true);
    });

    test('should not find conflict when appointments do not overlap', () {
      // Arrange
      final existingAppointment = AppointmentModel(
        id: 'existing_id',
        userId: 'user_id',
        customerId: 'customer_id',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: DateTime(2024, 1, 15),
        time: const TimeOfDay(hour: 10, minute: 0), // 10:00-11:00
        status: AppointmentStatus.confirmed,
        createdAt: DateTime.now(),
        duration: 60,
      );

      final newAppointment = AppointmentModel(
        id: 'new_id',
        userId: 'user_id',
        customerId: 'another_customer',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: DateTime(2024, 1, 15),
        time: const TimeOfDay(hour: 11, minute: 30), // 11:30-12:30 - no conflict
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        duration: 60,
      );

      // Act
      final hasConflict = appointmentService.hasTimeConflict(
        newAppointment,
        [existingAppointment],
      );

      // Assert
      expect(hasConflict, false);
    });

    test('should calculate appointment end time correctly', () {
      // Arrange
      final appointment = AppointmentModel(
        id: 'test_id',
        userId: 'user_id',
        customerId: 'customer_id',
        serviceId: 'service_id',
        employeeId: 'employee_id',
        date: DateTime(2024, 1, 15),
        time: const TimeOfDay(hour: 10, minute: 0),
        status: AppointmentStatus.confirmed,
        createdAt: DateTime.now(),
        duration: 90, // 1.5 hours
      );

      // Act
      final endTime = appointmentService.getAppointmentEndTime(appointment);

      // Assert
      expect(endTime, DateTime(2024, 1, 15, 11, 30));
    });
  });
}
