import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';

class ServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Hizmet ekleme
  Future<void> addService(ServiceModel service) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    try {
      await _firestore.collection('services').doc(service.id).set({
        ...service.toMap(),
        'userId': _userId,
      });
    } catch (e) {
      throw Exception('Hizmet eklenirken hata oluştu: $e');
    }
  }

  // Hizmet güncelleme
  Future<void> updateService(ServiceModel service) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    try {
      await _firestore.collection('services').doc(service.id).update({
        ...service.toMap(),
        'userId': _userId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Hizmet güncellenirken hata oluştu: $e');
    }
  }

  // Hizmet silme
  Future<void> deleteService(String serviceId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      throw Exception('Hizmet silinirken hata oluştu: $e');
    }
  }

  // Tüm hizmetleri getirme (aktif ve pasif dahil)
  Stream<List<ServiceModel>> getAllServices() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('services')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      // Client-side sorting to avoid index requirement
      services.sort((a, b) => a.name.compareTo(b.name));
      return services;
    });
  }

  // Sadece aktif hizmetleri getirme
  Stream<List<ServiceModel>> getActiveServices() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('services')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap({...doc.data(), 'id': doc.id}))
          .where((service) => service.isActive)
          .toList();
      // Client-side sorting to avoid index requirement
      services.sort((a, b) => a.name.compareTo(b.name));
      return services;
    });
  }

  // Kategoriye göre hizmetleri getirme
  Stream<List<ServiceModel>> getServicesByCategory(
      BeautyServiceCategory category) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('services')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap({...doc.data(), 'id': doc.id}))
          .where((service) => service.category == category && service.isActive)
          .toList();
      // Client-side sorting to avoid index requirement
      services.sort((a, b) => a.name.compareTo(b.name));
      return services;
    });
  }

  // Tek hizmet getirme
  Future<ServiceModel?> getService(String serviceId) async {
    if (_userId == null) return null;

    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists && doc.data()?['userId'] == _userId) {
        return ServiceModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Hizmet getirilirken hata oluştu: $e');
    }
  }

  // Hizmet durumunu değiştirme
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    try {
      await _firestore.collection('services').doc(serviceId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Hizmet durumu değiştirilirken hata oluştu: $e');
    }
  }

  // Varsayılan hizmetleri oluşturma
  Future<void> createDefaultServices() async {
    if (_userId == null) return;

    try {
      final defaultServices = BeautyServiceTemplates.getDefaultServices();

      for (final service in defaultServices) {
        final serviceWithUser = ServiceModel(
          id: '${_userId}_${service.id}',
          name: service.name,
          category: service.category,
          price: service.price,
          durationMinutes: service.durationMinutes,
          description: service.description,
          isActive: service.isActive,
          createdAt: service.createdAt,
          commissionRate: service.commissionRate,
          requiredMaterials: service.requiredMaterials,
          compatibleSpecialties: service.compatibleSpecialties,
          isPopular: service.isPopular,
          preparationTimeMinutes: service.preparationTimeMinutes,
          afterCareInstructions: service.afterCareInstructions,
        );

        await addService(serviceWithUser);
      }
    } catch (e) {
      throw Exception('Varsayılan hizmetler oluşturulurken hata oluştu: $e');
    }
  }

  // Tüm hizmetleri getirme (Future - liste sayfaları için)
  Future<List<ServiceModel>> getAllServicesAsList() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: _userId)
          .get();

      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      services.sort((a, b) => a.name.compareTo(b.name));
      return services;
    } catch (e) {
      throw Exception('Hizmetler yüklenirken hata oluştu: $e');
    }
  }

  // Hizmet istatistikleri
  Future<Map<String, dynamic>> getServiceStats() async {
    if (_userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: _userId)
          .get();

      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      final totalServices = services.length;
      final activeServices = services.where((s) => s.isActive).length;
      final averagePrice = services.isEmpty
          ? 0.0
          : services.map((s) => s.price).reduce((a, b) => a + b) /
              services.length;
      final popularServices = services.where((s) => s.isPopular).length;

      return {
        'total': totalServices,
        'active': activeServices,
        'inactive': totalServices - activeServices,
        'averagePrice': averagePrice,
        'popular': popularServices,
      };
    } catch (e) {
      throw Exception('Hizmet istatistikleri alınırken hata oluştu: $e');
    }
  }
}
