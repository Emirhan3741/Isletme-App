import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _customersCollection =>
      _firestore.collection('customers');

  // Salon başlatma işlemi (beauty modülü için)
  Future<void> initializeSalon() async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    
    try {
      // Salon başlatma işlemi - demo veri ekleme veya varsayılan ayarlar
      await _firestore
          .collection('salon_settings')
          .doc(_userId)
          .set({
        'isInitialized': true,
        'salonName': 'Güzellik Salonu',
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'workingHours': {
            'start': '09:00',
            'end': '18:00',
          },
          'workingDays': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
          'appointmentDuration': 60, // dakika
        }
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Salon başlatılamadı: $e');
    }
  }

  // Kullanıcının müşterilerini getirme
  Stream<List<CustomerModel>> getUserCustomers() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('customers')
        .where('userId', isEqualTo: _userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .toList());
  }

  // Müşteri ekleme
  Future<void> addCustomer(CustomerModel customer) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore
        .collection('customers')
        .doc(customer.id)
        .set(customer.toMap());
  }

  // Müşteri güncelleme
  Future<void> updateCustomer(CustomerModel customer) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore
        .collection('customers')
        .doc(customer.id)
        .update(customer.toMap());
  }

  // Müşteri silme
  Future<void> deleteCustomer(String customerId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('customers').doc(customerId).delete();
  }

  // Tek müşteri getirme
  Future<CustomerModel?> getCustomer(String customerId) async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (doc.exists) {
      return CustomerModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Tek müşteri getirme (alias)
  Future<CustomerModel?> getCustomerById(String customerId) async {
    return getCustomer(customerId);
  }

  // Müşteri arama (isim veya telefon)
  Stream<List<CustomerModel>> searchCustomers(String query) {
    if (_userId == null || query.isEmpty) return getUserCustomers();

    return _firestore
        .collection('customers')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                customer.phone.contains(query))
            .toList());
  }

  // Sadakat seviyesine göre müşteriler
  Stream<List<CustomerModel>> getCustomersByLoyalty(String loyaltyLevel) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('customers')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .where((customer) => customer.loyaltyLevel == loyaltyLevel)
            .toList());
  }

  // Doğum günü olan müşteriler (bu ay)
  Stream<List<CustomerModel>> getBirthdayCustomersThisMonth() {
    if (_userId == null) return Stream.value([]);

    final now = DateTime.now();
    return _firestore
        .collection('customers')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .where((customer) =>
                customer.birthDate != null &&
                customer.birthDate!.month == now.month)
            .toList());
  }

  // Müşteri ziyaret bilgilerini güncelleme
  Future<void> updateCustomerVisit(
      String customerId, double spentAmount) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    final customer = await getCustomer(customerId);
    if (customer != null) {
      final updatedCustomer = customer.copyWith(
        lastVisit: DateTime.now(),
        totalVisits: customer.totalVisits + 1,
        totalSpent: customer.totalSpent + spentAmount,
      );
      await updateCustomer(updatedCustomer);
    }
  }

  // Tüm müşterileri getir
  Future<List<CustomerModel>> getCustomers() async {
    final querySnapshot =
        await _customersCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<CustomerModel>> getCustomersByUserId(String userId) {
    return FirebaseFirestore.instance
        .collection('customers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _customersCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Müşteriler yüklenirken hata oluştu: $e');
    }
  }

  Future<List<CustomerModel>> getCustomersForUser(
      {required String userId, required String role}) async {
    QuerySnapshot snapshot;
    if (role == 'admin') {
      snapshot = await _customersCollection.get();
    } else {
      snapshot = await _customersCollection
          .where('createdBy', isEqualTo: userId)
          .get();
    }
    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream metodları
  Stream<List<CustomerModel>> getCustomersStream() {
    if (_userId == null) return Stream.value([]);

    return _customersCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Stream<CustomerModel?> getCustomerStream(String customerId) {
    return _customersCollection.doc(customerId).snapshots().map((doc) =>
        doc.exists
            ? CustomerModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            : null);
  }

  Stream<List<CustomerModel>> searchCustomersStream(String query) {
    if (_userId == null) return Stream.value([]);

    return _customersCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                customer.phone.toLowerCase().contains(query.toLowerCase()) ||
                customer.email.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }
}
// Cleaned for Web Build by Cursor
