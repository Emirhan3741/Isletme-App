import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locapo/models/customer_model.dart';

void main() {
  group('CustomerModel Tests', () {
    test('should create CustomerModel with required fields', () {
      // Arrange
      final customer = CustomerModel(
        id: 'test_id',
        userId: 'user_id',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(customer.id, 'test_id');
      expect(customer.name, 'John Doe');
      expect(customer.email, 'john@example.com');
      expect(customer.phone, '+1234567890');
    });

    test('should validate email correctly', () {
      // Valid emails
      expect(CustomerModel.isValidEmail('test@example.com'), true);
      expect(CustomerModel.isValidEmail('user.name@domain.co.uk'), true);

      // Invalid emails
      expect(CustomerModel.isValidEmail('invalid-email'), false);
      expect(CustomerModel.isValidEmail('test@'), false);
      expect(CustomerModel.isValidEmail('@example.com'), false);
    });

    test('should validate phone correctly', () {
      // Valid phones
      expect(CustomerModel.isValidPhone('+1234567890'), true);
      expect(CustomerModel.isValidPhone('05321234567'), true);
      expect(CustomerModel.isValidPhone('+905321234567'), true);

      // Invalid phones
      expect(CustomerModel.isValidPhone('123'), false);
      expect(CustomerModel.isValidPhone('abc'), false);
      expect(CustomerModel.isValidPhone(''), false);
    });

    test('should convert to map correctly', () {
      // Arrange
      final dateTime = DateTime.now();
      final customer = CustomerModel(
        id: 'test_id',
        userId: 'user_id',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        createdAt: dateTime,
      );

      // Act
      final map = customer.toMap();

      // Assert
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['phone'], '+1234567890');
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
