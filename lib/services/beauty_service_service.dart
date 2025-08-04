import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeautyServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get _salonId => _userId;

  /// Get salon services stream
  Stream<List<Map<String, dynamic>>> getSalonServices() {
    if (_salonId == null) return Stream.value([]);

    return _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Get salon services as Future
  Future<List<Map<String, dynamic>>> getServices() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Add service
  Future<void> addService(Map<String, dynamic> serviceData) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');

    serviceData['userId'] = _userId;
    serviceData['salonId'] = _salonId;
    serviceData['createdAt'] = FieldValue.serverTimestamp();
    serviceData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .add(serviceData);
  }

  /// Update service
  Future<void> updateService(
      String serviceId, Map<String, dynamic> serviceData) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');
    if (serviceId.isEmpty) throw Exception('Hizmet ID boş olamaz');

    serviceData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .doc(serviceId)
        .update(serviceData);
  }

  /// Delete service with validation
  Future<void> deleteService(String serviceId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null || _salonId!.isEmpty) {
      throw Exception('Salon ID bulunamadı veya geçersiz');
    }
    if (serviceId.isEmpty) {
      throw Exception('Hizmet ID boş olamaz');
    }

    try {
      await _firestore
          .collection('salons')
          .doc(_salonId)
          .collection('services')
          .doc(serviceId)
          .delete();
    } catch (e) {
      throw Exception('Hizmet silme hatası: $e');
    }
  }

  /// Get single service
  Future<Map<String, dynamic>?> getService(String serviceId) async {
    if (_salonId == null || serviceId.isEmpty) return null;

    final doc = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .doc(serviceId)
        .get();

    if (doc.exists) {
      return {...doc.data()!, 'id': doc.id};
    }
    return null;
  }

  /// Get active services for dropdowns
  Future<List<Map<String, dynamic>>> getActiveServices() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get services by category
  Future<List<Map<String, dynamic>>> getServicesByCategory(
      String category) async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Get service categories
  Future<List<String>> getServiceCategories() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    final categories = <String>{};
    for (final doc in snapshot.docs) {
      final category = doc.data()['category'] as String? ?? '';
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    return categories.toList()..sort();
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
