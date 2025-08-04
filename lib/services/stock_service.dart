import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stock_model.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Stok ekleme
  Future<void> addStock(StockModel stock) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('stocks').doc(stock.id).set(stock.toMap());
  }

  // Stok güncelleme
  Future<void> updateStock(StockModel stock) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    final updatedStock = StockModel(
      id: stock.id,
      productName: stock.productName,
      brand: stock.brand,
      category: stock.category,
      quantity: stock.quantity,
      minQuantity: stock.minQuantity,
      unitPrice: stock.unitPrice,
      expiryDate: stock.expiryDate,
      description: stock.description,
      userId: stock.userId,
      createdAt: stock.createdAt,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('stocks')
        .doc(stock.id)
        .update(updatedStock.toMap());
  }

  // Stok silme
  Future<void> deleteStock(String stockId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('stocks').doc(stockId).delete();
  }

  // Kullanıcının stoklarını getirme
  Stream<List<StockModel>> getUserStocks() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('stocks')
        .where('userId', isEqualTo: _userId)
        .orderBy('productName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockModel.fromMap(doc.data()))
            .toList());
  }

  // Kategoriye göre stokları getirme
  Stream<List<StockModel>> getStocksByCategory(String category) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('stocks')
        .where('userId', isEqualTo: _userId)
        .where('category', isEqualTo: category)
        .orderBy('productName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockModel.fromMap(doc.data()))
            .toList());
  }

  // Düşük stokları getirme
  Stream<List<StockModel>> getLowStocks() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('stocks')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockModel.fromMap(doc.data()))
            .where((stock) => stock.isLowStock)
            .toList());
  }

  // Düşük stokları getirme (Future version)
  Future<List<StockModel>> getLowStockItems() async {
    if (_userId == null) return [];

    final snapshot = await _firestore
        .collection('stocks')
        .where('userId', isEqualTo: _userId)
        .get();

    return snapshot.docs
        .map((doc) => StockModel.fromMap(doc.data()))
        .where((stock) => stock.isLowStock)
        .toList();
  }

  // Süresi yaklaşan ürünleri getirme
  Stream<List<StockModel>> getExpiringSoonStocks() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('stocks')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockModel.fromMap(doc.data()))
            .where((stock) => stock.isExpiringSoon)
            .toList());
  }

  // Tek stok getirme
  Future<StockModel?> getStock(String stockId) async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('stocks').doc(stockId).get();
    if (doc.exists) {
      return StockModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Stok miktarını güncelleme (kullanım sonrası)
  Future<void> updateStockQuantity(String stockId, int newQuantity) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('stocks').doc(stockId).update({
      'quantity': newQuantity,
      'updatedAt': DateTime.now(),
    });
  }

  // Stok kullanımı (miktar azaltma)
  Future<void> useStock(String stockId, int usedQuantity) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    final stock = await getStock(stockId);
    if (stock != null) {
      final newQuantity = stock.quantity - usedQuantity;
      if (newQuantity >= 0) {
        await updateStockQuantity(stockId, newQuantity);
      } else {
        throw Exception('Yetersiz stok miktarı');
      }
    }
  }
}
