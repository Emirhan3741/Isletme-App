import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

class BeautyCustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Get the salon ID for the current user
  /// For now, using userId as salonId until proper salon structure is implemented
  String? get _salonId => _userId;

  /// Get salon customers
  Stream<List<CustomerModel>> getSalonCustomers() {
    if (_salonId == null) return Stream.value([]);

    return _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get salon customers as Future (for compatibility)
  Future<List<CustomerModel>> getCustomers() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Add customer
  Future<void> addCustomer(CustomerModel customer) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');

    final customerData = customer.toMap();
    customerData['userId'] = _userId;
    customerData['salonId'] = _salonId;
    customerData['createdAt'] = FieldValue.serverTimestamp();
    customerData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('customers')
        .doc(customer.id)
        .set(customerData);
  }

  /// Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');
    if (customer.id.isEmpty) throw Exception('Müşteri ID boş olamaz');

    final customerData = customer.toMap();
    customerData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('customers')
        .doc(customer.id)
        .update(customerData);
  }

  /// Delete customer with validation
  Future<void> deleteCustomer(String customerId) async {
    // Validation checks
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null || _salonId!.isEmpty) {
      throw Exception('Salon ID bulunamadı veya geçersiz');
    }
    if (customerId.isEmpty) {
      throw Exception('Müşteri ID boş olamaz');
    }

    try {
      // Check if customer exists first
      final docSnapshot = await _firestore
          .collection('salons')
          .doc(_salonId)
          .collection('customers')
          .doc(customerId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Silinmek istenen müşteri bulunamadı');
      }

      // Delete the customer
      await _firestore
          .collection('salons')
          .doc(_salonId)
          .collection('customers')
          .doc(customerId)
          .delete();
    } catch (e) {
      throw Exception('Müşteri silme hatası: $e');
    }
  }

  /// Get single customer
  Future<CustomerModel?> getCustomer(String customerId) async {
    if (_salonId == null || customerId.isEmpty) return null;

    final doc = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('customers')
        .doc(customerId)
        .get();

    if (doc.exists) {
      return CustomerModel.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  /// Initialize salon document if it doesn't exist
  Future<void> initializeSalon() async {
    if (_userId == null || _salonId == null) return;

    final salonDoc = await _firestore.collection('salons').doc(_salonId).get();

    if (!salonDoc.exists) {
      await _firestore.collection('salons').doc(_salonId).set({
        'ownerId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
        'salonType': 'beauty',
        'isActive': true,
      });
    }
  }
}
