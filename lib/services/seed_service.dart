import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/appointment_model.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';
import '../models/note_model.dart';

Future<void> seedInitialData() async {
  final firestore = FirebaseFirestore.instance;

  // 1. User
  final userRef = firestore.collection('users').doc('demoUser');
  await userRef.set({
    'id': 'demoUser',
    'email': 'demo@demo.com',
    'displayName': 'Demo User',
    'photoURL': null,
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
    'role': 'owner',
    'lastSignIn': DateTime.now().toIso8601String(),
  });

  // 2. Customer
  final customerRef = firestore.collection('customers').doc('demoCustomer');
  await customerRef.set({
    'id': 'demoCustomer',
    'firstName': 'John',
    'lastName': 'Doe',
    'phone': '5551234567',
    'email': 'john@example.com',
    'note': 'VIP müşteri',
    'createdAt': DateTime.now(),
    'createdByUserId': 'demoUser',
  });

  // 3. Appointment
  final appointmentRef = firestore.collection('appointments').doc('demoAppointment');
  await appointmentRef.set({
    'id': 'demoAppointment',
    'customerId': 'demoCustomer',
    'employeeId': 'demoUser',
    'date': DateTime.now(),
    'time': '10:00',
    'operationName': 'Consultation',
    'note': 'İlk randevu',
    'createdAt': DateTime.now(),
  });

  // 4. Transaction
  final transactionRef = firestore.collection('transactions').doc('demoTransaction');
  await transactionRef.set({
    'id': 'demoTransaction',
    'customerId': 'demoCustomer',
    'appointmentId': 'demoAppointment',
    'operationName': 'Consultation',
    'amount': 100.0,
    'paymentStatus': 'paid',
    'paymentType': 'cash',
    'note': 'Nakit ödeme',
    'date': DateTime.now(),
    'createdAt': DateTime.now(),
    'createdByUserId': 'demoUser',
  });

  // 5. Expense
  final expenseRef = firestore.collection('expenses').doc('demoExpense');
  await expenseRef.set({
    'id': 'demoExpense',
    'amount': 50.0,
    'category': 'Office',
    'description': 'Kırtasiye',
    'date': DateTime.now(),
    'invoiceNo': 'INV-001',
    'supplier': 'Ofis Market',
    'paymentMethod': 'cash',
    'userId': 'demoUser',
    'createdAt': DateTime.now(),
  });

  // 6. Note
  final noteRef = firestore.collection('notes').doc('demoNote');
  await noteRef.set({
    'id': 'demoNote',
    'title': 'Hoş geldiniz',
    'content': 'Sisteme hoş geldiniz!',
    'category': 'Genel',
    'completed': false,
    'priority': 1,
    'color': '#2196F3',
    'createdAt': DateTime.now(),
    'userId': 'demoUser',
  });
} 