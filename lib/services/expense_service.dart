import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';

class ExpenseService {
  final CollectionReference _expensesCollection =
      FirebaseFirestore.instance.collection('expenses');

  Stream<List<ExpenseModel>> getExpensesStream() {
    return _expensesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final snapshot =
        await _expensesCollection.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ExpenseModel.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesCollection.add(expense.toMap());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final snapshot = await _expensesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Giderler yüklenirken hata oluştu: $e');
    }
  }

  // Ek Stream metodları
  Stream<List<ExpenseModel>> getExpensesByCategoryStream(String category) {
    return _expensesCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Stream<List<ExpenseModel>> getExpensesByDateRangeStream(
      DateTime startDate, DateTime endDate) {
    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Stream<ExpenseModel?> getExpenseStream(String expenseId) {
    return _expensesCollection.doc(expenseId).snapshots().map((doc) =>
        doc.exists
            ? ExpenseModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            : null);
  }

  Stream<List<ExpenseModel>> getUnpaidExpensesStream() {
    return _expensesCollection
        .where('isPaid', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }
}
// Cleaned for Web Build by Cursor
