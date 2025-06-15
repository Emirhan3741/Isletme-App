import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection referansı
  CollectionReference get _customersCollection => _firestore.collection('customers');

  // Mevcut kullanıcı ID'si
  String? get _currentUserId => _auth.currentUser?.uid;

  // Müşteri ekle
  Future<CustomerModel?> addCustomer({
    required String ad,
    required String soyad,
    required String telefon,
    String? eposta,
    String? not,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final customerData = {
        'ad': ad.trim(),
        'soyad': soyad.trim(),
        'telefon': telefon.replaceAll(RegExp(r'[^\d]'), ''), // Sadece rakamlar
        'eposta': eposta?.trim(),
        'not': not?.trim(),
        'olusturulmaTarihi': Timestamp.now(),
        'ekleyenKullaniciId': _currentUserId!,
      };

      final docRef = await _customersCollection.add(customerData);
      
      // Eklenen müşteriyi geri döndür
      return CustomerModel.fromMap(customerData, docRef.id);
    } catch (e) {
      print('Müşteri ekleme hatası: $e');
      rethrow;
    }
  }

  // Müşteri güncelle
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      if (customer.ekleyenKullaniciId != _currentUserId) {
        throw Exception('Bu müşteriyi güncelleme yetkiniz yok');
      }

      await _customersCollection.doc(customer.id).update(customer.toMap());
    } catch (e) {
      print('Müşteri güncelleme hatası: $e');
      rethrow;
    }
  }

  // Müşteri sil
  Future<void> deleteCustomer(String customerId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Önce müşterinin sahibini kontrol et
      final doc = await _customersCollection.doc(customerId).get();
      if (!doc.exists) {
        throw Exception('Müşteri bulunamadı');
      }

      final customerData = doc.data() as Map<String, dynamic>;
      if (customerData['ekleyenKullaniciId'] != _currentUserId) {
        throw Exception('Bu müşteriyi silme yetkiniz yok');
      }

      await _customersCollection.doc(customerId).delete();
    } catch (e) {
      print('Müşteri silme hatası: $e');
      rethrow;
    }
  }

  // Tek müşteri getir
  Future<CustomerModel?> getCustomer(String customerId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final doc = await _customersCollection.doc(customerId).get();
      
      if (!doc.exists) {
        return null;
      }

      final customerData = doc.data() as Map<String, dynamic>;
      
      // Sadece kendi müşterisini döndür
      if (customerData['ekleyenKullaniciId'] != _currentUserId) {
        throw Exception('Bu müşteriyi görüntüleme yetkiniz yok');
      }

      return CustomerModel.fromSnapshot(doc);
    } catch (e) {
      print('Müşteri getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının tüm müşterilerini getir (Stream)
  Stream<List<CustomerModel>> getCustomersStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _customersCollection
        .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerModel.fromSnapshot(doc);
      }).toList();
    });
  }

  // Kullanıcının tüm müşterilerini getir (Future)
  Future<List<CustomerModel>> getCustomers() async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _customersCollection
          .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
          .orderBy('olusturulmaTarihi', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return CustomerModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Müşterileri getirme hatası: $e');
      rethrow;
    }
  }

  // Müşteri ara
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      if (query.isEmpty) {
        return await getCustomers();
      }

      final allCustomers = await getCustomers();
      final searchQuery = query.toLowerCase();

      return allCustomers.where((customer) {
        return customer.aramaMetni.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Müşteri arama hatası: $e');
      rethrow;
    }
  }

  // Telefon numarasından müşteri ara
  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      final querySnapshot = await _customersCollection
          .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
          .where('telefon', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return CustomerModel.fromSnapshot(querySnapshot.docs.first);
    } catch (e) {
      print('Telefon ile müşteri arama hatası: $e');
      rethrow;
    }
  }

  // Müşteri sayısını getir
  Future<int> getCustomerCount() async {
    try {
      if (_currentUserId == null) {
        return 0;
      }

      final querySnapshot = await _customersCollection
          .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Müşteri sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Son eklenen müşterileri getir
  Future<List<CustomerModel>> getRecentCustomers({int limit = 5}) async {
    try {
      if (_currentUserId == null) {
        return [];
      }

      final querySnapshot = await _customersCollection
          .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
          .orderBy('olusturulmaTarihi', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        return CustomerModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Son müşterileri getirme hatası: $e');
      return [];
    }
  }

  // Müşteri var mı kontrol et (telefon numarasına göre)
  Future<bool> isPhoneExists(String phone, {String? excludeCustomerId}) async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      var query = _customersCollection
          .where('ekleyenKullaniciId', isEqualTo: _currentUserId)
          .where('telefon', isEqualTo: cleanPhone);

      final querySnapshot = await query.get();

      if (excludeCustomerId != null) {
        // Güncelleme sırasında mevcut müşteriyi hariç tut
        return querySnapshot.docs.any((doc) => doc.id != excludeCustomerId);
      }

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Telefon kontrol hatası: $e');
      return false;
    }
  }
} 