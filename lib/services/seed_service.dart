import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedInitialData() async {
  final firestore = FirebaseFirestore.instance;

  // 1. User
  final userRef = firestore.collection('users').doc('demoUser');
  await userRef.set({
    'id': 'demoUser',
    'name': 'Demo User',
    'email': 'demo@demo.com',
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
  });

  // 2. Customer
  final customerRef = firestore.collection('customers').doc('demoCustomer');
  await customerRef.set({
    'id': 'demoCustomer',
    'name': 'John Doe',
    'email': 'john@example.com',
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
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
    'createdAt': DateTime.now(),
  });

  // 4. Transaction
  final transactionRef = firestore.collection('transactions').doc('demoTransaction');
  await transactionRef.set({
    'id': 'demoTransaction',
    'amount': 100.0,
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
  });

  // 5. Expense
  final expenseRef = firestore.collection('expenses').doc('demoExpense');
  await expenseRef.set({
    'id': 'demoExpense',
    'amount': 50.0,
    'category': 'other',
    'createdAt': DateTime.now(),
  });

  // 6. Note
  final noteRef = firestore.collection('notes').doc('demoNote');
  await noteRef.set({
    'id': 'demoNote',
    'title': 'Welcome',
    'content': 'Welcome to the system!',
    'color': 0,
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
  });
} 