import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _transactionsCollection => _firestore.collection('transactions');

  // İşlem ekle
  Future<void> addTransaction(TransactionModel transaction) async {
    final data = transaction.toMap();
    await _transactionsCollection.add(data);
  }

  // İşlem güncelle
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
  }

  // İşlem sil
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsCollection.doc(transactionId).delete();
  }

  // Tüm işlemleri getir
  Future<List<TransactionModel>> getTransactions() async {
    final querySnapshot = await _transactionsCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}
// Cleaned for Web Build by Cursor 