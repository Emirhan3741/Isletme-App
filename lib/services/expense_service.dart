import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import 'notification_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collections
  static const String _expensesCollection = 'expenses';
  static const String _usersCollection = 'users';

  // Mevcut kullanıcı bilgilerini al
  User? get currentUser => _auth.currentUser;

  // Kullanıcının rolünü kontrol et
  Future<bool> isOwner() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'owner';
      }
      return false;
    } catch (e) {
      print('Rol kontrolü hatası: $e');
      return false;
    }
  }

  // Yeni gider ekle
  Future<String?> addExpense(ExpenseModel expense) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Expense verilerini hazırla
      final expenseData = expense.copyWith(
        ekleyenKullaniciId: currentUser!.uid,
        olusturulmaTarihi: Timestamp.now(),
      ).toMap();

      // Firestore'a ekle
      final docRef = await _firestore
          .collection(_expensesCollection)
          .add(expenseData);

      // Hatırlatıcı ayarla
      final newExpense = expense.copyWith(id: docRef.id);
      await _notificationService.scheduleExpenseReminder(newExpense);

      return docRef.id;
    } catch (e) {
      print('Gider ekleme hatası: $e');
      throw Exception('Gider eklenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Gider güncelle
  Future<void> updateExpense(ExpenseModel expense) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Giderin sahibini kontrol et
      final existingExpense = await _firestore
          .collection(_expensesCollection)
          .doc(expense.id)
          .get();

      if (!existingExpense.exists) {
        throw Exception('Gider bulunamadı');
      }

      final existingData = existingExpense.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi giderlerini güncelleyebilir
      if (!userIsOwner && existingData['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu gideri güncelleme yetkiniz yok');
      }

      // Güncelleme verilerini hazırla (ekleyenKullaniciId ve olusturulmaTarihi korunur)
      final updateData = expense.toMap();
      updateData.remove('ekleyenKullaniciId');
      updateData.remove('olusturulmaTarihi');

      await _firestore
          .collection(_expensesCollection)
          .doc(expense.id)
          .update(updateData);

      // Hatırlatıcıyı güncelle
      await _notificationService.cancelExpenseReminder(expense.id);
      await _notificationService.scheduleExpenseReminder(expense);

    } catch (e) {
      print('Gider güncelleme hatası: $e');
      throw Exception('Gider güncellenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Gider sil
  Future<void> deleteExpense(String expenseId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Giderin sahibini kontrol et
      final expenseDoc = await _firestore
          .collection(_expensesCollection)
          .doc(expenseId)
          .get();

      if (!expenseDoc.exists) {
        throw Exception('Gider bulunamadı');
      }

      final expenseData = expenseDoc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi giderlerini silebilir
      if (!userIsOwner && expenseData['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu gideri silme yetkiniz yok');
      }

      await _firestore
          .collection(_expensesCollection)
          .doc(expenseId)
          .delete();

      // Hatırlatıcıyı iptal et
      await _notificationService.cancelExpenseReminder(expenseId);

    } catch (e) {
      print('Gider silme hatası: $e');
      throw Exception('Gider silinirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Tüm giderleri getir (kullanıcı yetkisine göre filtrelenir)
  Stream<List<ExpenseModel>> getExpenses() {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_expensesCollection)
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<ExpenseModel> expenses = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm giderleri, normal kullanıcı sadece kendi giderlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final expense = ExpenseModel.fromMap(data, doc.id);
                expenses.add(expense);
              } catch (e) {
                print('Gider parsing hatası: $e');
              }
            }
          }
          
          return expenses;
        });
  }

  // Kategoriye göre giderleri getir
  Stream<List<ExpenseModel>> getExpensesByCategory(String category) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_expensesCollection)
        .where('kategori', isEqualTo: category)
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<ExpenseModel> expenses = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm giderleri, normal kullanıcı sadece kendi giderlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final expense = ExpenseModel.fromMap(data, doc.id);
                expenses.add(expense);
              } catch (e) {
                print('Gider parsing hatası: $e');
              }
            }
          }
          
          return expenses;
        });
  }

  // Tarih aralığına göre giderleri getir
  Stream<List<ExpenseModel>> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_expensesCollection)
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<ExpenseModel> expenses = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm giderleri, normal kullanıcı sadece kendi giderlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final expense = ExpenseModel.fromMap(data, doc.id);
                expenses.add(expense);
              } catch (e) {
                print('Gider parsing hatası: $e');
              }
            }
          }
          
          return expenses;
        });
  }

  // Tek gider getir
  Future<ExpenseModel?> getExpense(String expenseId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      final doc = await _firestore
          .collection(_expensesCollection)
          .doc(expenseId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Owner tüm giderleri, normal kullanıcı sadece kendi giderlerini görebilir
      if (!userIsOwner && data['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu gideri görüntüleme yetkiniz yok');
      }

      return ExpenseModel.fromMap(data, doc.id);
    } catch (e) {
      print('Gider getirme hatası: $e');
      throw Exception('Gider getirilirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Toplam gider hesapla
  Future<double> getTotalExpenses() async {
    if (currentUser == null) {
      return 0.0;
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_expensesCollection);

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        total += tutar;
      }

      return total;
    } catch (e) {
      print('Toplam gider hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Kategori bazlı gider özeti
  Future<Map<String, double>> getCategoryExpenseSummary() async {
    if (currentUser == null) {
      return {};
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_expensesCollection);

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      final Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final kategori = data['kategori'] ?? '';
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        
        categoryTotals[kategori] = (categoryTotals[kategori] ?? 0.0) + tutar;
      }

      return categoryTotals;
    } catch (e) {
      print('Kategori özeti hatası: $e');
      return {};
    }
  }

  // Aylık gider hesapla
  Future<double> getMonthlyExpenses([DateTime? date]) async {
    if (currentUser == null) {
      return 0.0;
    }

    try {
      final targetDate = date ?? DateTime.now();
      final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);

      final bool userIsOwner = await isOwner();
      Query query = _firestore
          .collection(_expensesCollection)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        total += tutar;
      }

      return total;
    } catch (e) {
      print('Aylık gider hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Bugünkü giderleri getir
  Future<double> getTodayExpenses() async {
    if (currentUser == null) {
      return 0.0;
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final bool userIsOwner = await isOwner();
      Query query = _firestore
          .collection(_expensesCollection)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        total += tutar;
      }

      return total;
    } catch (e) {
      print('Bugünkü gider hesaplama hatası: $e');
      return 0.0;
    }
  }
} 