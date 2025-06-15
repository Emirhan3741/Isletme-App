import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _expensesCollection => _firestore.collection('expenses');

  // Gider ekle
  Future<void> addExpense(ExpenseModel expense) async {
    final data = expense.toMap();
    data['id'] = expense.id;
    await _expensesCollection.doc(expense.id).set(data);
  }

  // Gider güncelle
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  // Gider sil
  Future<void> deleteExpense(String expenseId) async {
    await _expensesCollection.doc(expenseId).delete();
  }

  // Tüm giderleri getir
  Future<List<ExpenseModel>> getExpenses() async {
    final querySnapshot = await _expensesCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}
// Cleaned for Web Build by Cursor 