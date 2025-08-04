// Remove unused imports:
// dart:io

// Remove unused fields:
// final FirebaseStorage _storage;
// final CollectionReference _transactionsCollection;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/appointment_model.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Kullanıcının işlemlerini getirme
  Stream<List<TransactionModel>> getUserTransactions() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map(
              (doc) => TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
          .toList();
      // Client-side sorting to avoid index requirement
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  // İşlem ekleme
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    try {
      await _firestore.collection('transactions').doc(transaction.id).set({
        ...transaction.toMap(),
        'userId': _userId,
      });
    } catch (e) {
      throw Exception('İşlem eklenirken hata oluştu: $e');
    }
  }

  // İşlem güncelleme
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  // İşlem silme
  Future<void> deleteTransaction(String transactionId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('transactions').doc(transactionId).delete();
  }

  // Tek işlem getirme
  Future<TransactionModel?> getTransaction(String transactionId) async {
    if (_userId == null) return null;

    final doc =
        await _firestore.collection('transactions').doc(transactionId).get();
    if (doc.exists) {
      return TransactionModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Gelir işlemlerini getirme
  Stream<List<TransactionModel>> getIncomeTransactions() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map(
              (doc) => TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
          .where((transaction) => transaction.type == TransactionType.income)
          .toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  // Gider işlemlerini getirme
  Stream<List<TransactionModel>> getExpenseTransactions() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map(
              (doc) => TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  // Belirli tarih aralığındaki işlemleri getirme
  Stream<List<TransactionModel>> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  // Aylık gelir hesaplama
  Stream<double> getMonthlyIncome(int year, int month) {
    if (_userId == null) return Stream.value(0.0);

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: TransactionType.income.name)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .where('createdAt', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .fold(0.0, (sum, transaction) => sum + transaction.amount));
  }

  // Aylık gider hesaplama
  Stream<double> getMonthlyExpense(int year, int month) {
    if (_userId == null) return Stream.value(0.0);

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .where('createdAt', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .fold(0.0, (sum, transaction) => sum + transaction.amount));
  }

  // Kategoriye göre işlemleri getirme
  Stream<List<TransactionModel>> getTransactionsByCategory(
      TransactionCategory category) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  // Randevudan işlem oluşturma
  Future<void> createTransactionFromAppointment({
    required String appointmentId,
    required String customerName,
    required String serviceName,
    required double amount,
  }) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId!,
      type: TransactionType.income,
      category: 'appointment',
      title: '$customerName - $serviceName',
      description: 'Randevu geliri (ID: $appointmentId)',
      amount: amount,
      createdAt: DateTime.now(),
      fileUrls: [],
    );

    await addTransaction(transaction);
  }

  Future<Map<String, double>> getFinancialSummary() async {
    if (_userId == null) return {'toplamBorc': 0.0, 'toplamOdeme': 0.0};

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _userId)
          .get();

      double totalDebt = 0.0;
      double totalPayment = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final type = data['type'] as String? ?? '';

        if (type == 'debt') {
          totalDebt += amount;
        } else if (type == 'income') {
          totalPayment += amount;
        }
      }

      return {
        'toplamBorc': totalDebt,
        'toplamOdeme': totalPayment,
      };
    } catch (e) {
      return {'toplamBorc': 0.0, 'toplamOdeme': 0.0};
    }
  }

  Future<void> addFromAppointment(AppointmentModel appointment) async {
    try {
      final transaction = TransactionModel.fromAppointment(appointment);
      await addTransaction(transaction);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
              (doc) => TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('İşlemler yüklenirken hata oluştu: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions({String? userId}) async {
    try {
      Query query = _firestore.collection('transactions');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final querySnapshot = await query.get();

      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return TransactionModel.fromMap(data);
      }).toList();

      // Client-side sorting
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (e) {
      throw Exception('İşlemler yüklenirken hata oluştu: $e');
    }
  }

  // Ek Stream metodları
  Stream<List<TransactionModel>> getTransactionsStream({String? userId}) {
    final targetUserId = userId ?? _userId;
    if (targetUserId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByTypeStream(
      TransactionType type) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByDateRangeStream(
      DateTime startDate, DateTime endDate) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                TransactionModel.fromMap({...?doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<TransactionModel?> getTransactionStream(String transactionId) {
    return _firestore
        .collection('transactions')
        .doc(transactionId)
        .snapshots()
        .map((doc) => doc.exists
            ? TransactionModel.fromMap({...?doc.data(), 'id': doc.id})
            : null);
  }
}
// Cleaned for Web Build by Cursor
