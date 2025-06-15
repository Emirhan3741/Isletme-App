import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _transactionsCollection = 'transactions';
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

  // Yeni işlem ekle
  Future<String?> addTransaction(TransactionModel transaction) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Transaction verilerini hazırla
      final transactionData = transaction.copyWith(
        ekleyenKullaniciId: currentUser!.uid,
        olusturulmaTarihi: Timestamp.now(),
      ).toMap();

      // Firestore'a ekle
      final docRef = await _firestore
          .collection(_transactionsCollection)
          .add(transactionData);

      return docRef.id;
    } catch (e) {
      print('İşlem ekleme hatası: $e');
      throw Exception('İşlem eklenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // İşlem güncelle
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // İşlemin sahibini kontrol et
      final existingTransaction = await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .get();

      if (!existingTransaction.exists) {
        throw Exception('İşlem bulunamadı');
      }

      final existingData = existingTransaction.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi işlemlerini güncelleyebilir
      if (!userIsOwner && existingData['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu işlemi güncelleme yetkiniz yok');
      }

      // Güncelleme verilerini hazırla (ekleyenKullaniciId ve olusturulmaTarihi korunur)
      final updateData = transaction.toMap();
      updateData.remove('ekleyenKullaniciId');
      updateData.remove('olusturulmaTarihi');

      await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .update(updateData);

    } catch (e) {
      print('İşlem güncelleme hatası: $e');
      throw Exception('İşlem güncellenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // İşlem sil
  Future<void> deleteTransaction(String transactionId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // İşlemin sahibini kontrol et
      final transactionDoc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('İşlem bulunamadı');
      }

      final transactionData = transactionDoc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi işlemlerini silebilir
      if (!userIsOwner && transactionData['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu işlemi silme yetkiniz yok');
      }

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .delete();

    } catch (e) {
      print('İşlem silme hatası: $e');
      throw Exception('İşlem silinirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Tüm işlemleri getir (kullanıcı yetkisine göre filtrelenir)
  Stream<List<TransactionModel>> getTransactions() {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_transactionsCollection)
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<TransactionModel> transactions = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm işlemleri, normal kullanıcı sadece kendi işlemlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final transaction = TransactionModel.fromMap(data, doc.id);
                transactions.add(transaction);
              } catch (e) {
                print('İşlem parsing hatası: $e');
              }
            }
          }
          
          return transactions;
        });
  }

  // Müşteriye göre işlemleri getir
  Stream<List<TransactionModel>> getTransactionsByCustomer(String customerId) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_transactionsCollection)
        .where('musteriId', isEqualTo: customerId)
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<TransactionModel> transactions = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm işlemleri, normal kullanıcı sadece kendi işlemlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final transaction = TransactionModel.fromMap(data, doc.id);
                transactions.add(transaction);
              } catch (e) {
                print('İşlem parsing hatası: $e');
              }
            }
          }
          
          return transactions;
        });
  }

  // Randevuya göre işlemleri getir
  Stream<List<TransactionModel>> getTransactionsByAppointment(String randevuId) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_transactionsCollection)
        .where('randevuId', isEqualTo: randevuId)
        .orderBy('tarih', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<TransactionModel> transactions = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm işlemleri, normal kullanıcı sadece kendi işlemlerini görebilir
            if (userIsOwner || data['ekleyenKullaniciId'] == currentUser!.uid) {
              try {
                final transaction = TransactionModel.fromMap(data, doc.id);
                transactions.add(transaction);
              } catch (e) {
                print('İşlem parsing hatası: $e');
              }
            }
          }
          
          return transactions;
        });
  }

  // Tek işlem getir
  Future<TransactionModel?> getTransaction(String transactionId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Owner tüm işlemleri, normal kullanıcı sadece kendi işlemlerini görebilir
      if (!userIsOwner && data['ekleyenKullaniciId'] != currentUser!.uid) {
        throw Exception('Bu işlemi görüntüleme yetkiniz yok');
      }

      return TransactionModel.fromMap(data, doc.id);
    } catch (e) {
      print('İşlem getirme hatası: $e');
      throw Exception('İşlem getirilirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Finansal özet getir (toplam borç, toplam ödeme)
  Future<Map<String, double>> getFinancialSummary() async {
    if (currentUser == null) {
      return {'toplamBorc': 0.0, 'toplamOdeme': 0.0};
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_transactionsCollection);

      if (!userIsOwner) {
        query = query.where('ekleyenKullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      double toplamBorc = 0.0;
      double toplamOdeme = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tutar = (data['tutar'] ?? 0.0).toDouble();
        final odemeDurumu = data['odemeDurumu'] ?? '';

        if (odemeDurumu == OdemeDurumu.borc) {
          toplamBorc += tutar;
        } else if (odemeDurumu == OdemeDurumu.odendi) {
          toplamOdeme += tutar;
        }
      }

      return {
        'toplamBorc': toplamBorc,
        'toplamOdeme': toplamOdeme,
      };
    } catch (e) {
      print('Finansal özet hatası: $e');
      return {'toplamBorc': 0.0, 'toplamOdeme': 0.0};
    }
  }
} 