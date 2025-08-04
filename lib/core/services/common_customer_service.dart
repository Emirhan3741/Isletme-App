import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/common_customer_model.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';

class CommonCustomerService extends BaseService<CommonCustomerModel> {
  @override
  String get collectionName => AppConstants.customersCollection;

  @override
  CommonCustomerModel fromMap(Map<String, dynamic> map) {
    return CommonCustomerModel.fromMap(map);
  }

  // Müşteriye özel metodlar

  // Telefon numarasına göre arama
  Future<CommonCustomerModel?> getByPhone(String phone) async {
    if (currentUserId == null) return null;

    final snapshot =
        await userCollection.where('phone', isEqualTo: phone).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return fromMap(data);
  }

  // Email'e göre arama
  Future<CommonCustomerModel?> getByEmail(String email) async {
    if (currentUserId == null) return null;

    final snapshot =
        await userCollection.where('email', isEqualTo: email).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return fromMap(data);
  }

  // İsme göre arama
  Stream<List<CommonCustomerModel>> searchByName(String name) {
    return search(field: 'name', searchTerm: name.toLowerCase());
  }

  // VIP müşteriler
  Stream<List<CommonCustomerModel>> getVipCustomers({int? limit}) {
    return filter(
      whereConditions: {},
      orderBy: 'totalSpent',
      descending: true,
      limit: limit,
    );
  }

  // Müşteri değerine göre filtreleme
  Stream<List<CommonCustomerModel>> getByCustomerValue(String value,
      {int? limit}) {
    double minSpent = 0;
    switch (value) {
      case 'VIP':
        minSpent = 5000;
        break;
      case 'Premium':
        minSpent = 2000;
        break;
      case 'Regular':
        minSpent = 500;
        break;
      case 'New':
        minSpent = 0;
        break;
    }

    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection
        .where('isActive', isEqualTo: true)
        .where('totalSpent', isGreaterThanOrEqualTo: minSpent);

    if (value != 'New') {
      double maxSpent = double.infinity;
      switch (value) {
        case 'Regular':
          maxSpent = 1999.99;
          break;
        case 'Premium':
          maxSpent = 4999.99;
          break;
      }
      if (maxSpent != double.infinity) {
        query = query.where('totalSpent', isLessThan: maxSpent);
      }
    }

    query = query.orderBy('totalSpent', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Doğum günü yaklaşan müşteriler
  Stream<List<CommonCustomerModel>> getUpcomingBirthdays({int daysAhead = 30}) {
    if (currentUserId == null) return Stream.value([]);

    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    return userCollection
        .where('isActive', isEqualTo: true)
        .where('birthDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('birthDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('birthDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Son ziyaret tarihine göre müşteriler
  Stream<List<CommonCustomerModel>> getByLastVisit({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return getByDateRange(
      dateField: 'lastVisit',
      startDate: startDate,
      endDate: endDate,
      orderBy: 'lastVisit',
      descending: true,
      limit: limit,
    );
  }

  // Uzun süredir gelmeyen müşteriler
  Stream<List<CommonCustomerModel>> getInactiveCustomers(
      {int daysSinceLastVisit = 90}) {
    if (currentUserId == null) return Stream.value([]);

    final cutoffDate =
        DateTime.now().subtract(Duration(days: daysSinceLastVisit));

    return userCollection
        .where('isActive', isEqualTo: true)
        .where('lastVisit', isLessThan: Timestamp.fromDate(cutoffDate))
        .orderBy('lastVisit')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Hiç ziyaret etmemiş müşteriler
  Stream<List<CommonCustomerModel>> getNeverVisitedCustomers() {
    if (currentUserId == null) return Stream.value([]);

    return userCollection
        .where('isActive', isEqualTo: true)
        .where('visitCount', isEqualTo: 0)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Tag'e göre müşteriler
  Stream<List<CommonCustomerModel>> getByTag(String tag) {
    if (currentUserId == null) return Stream.value([]);

    return userCollection
        .where('isActive', isEqualTo: true)
        .where('tags', arrayContains: tag)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Cinsiyete göre müşteriler
  Stream<List<CommonCustomerModel>> getByGender(String gender) {
    return filter(
      whereConditions: {'gender': gender},
      orderBy: 'name',
    );
  }

  // Müşteri istatistikleri
  Future<Map<String, dynamic>> getCustomerStats() async {
    if (currentUserId == null) return {};

    final snapshot =
        await userCollection.where('isActive', isEqualTo: true).get();

    final customers = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return fromMap(data);
    }).toList();

    int totalCustomers = customers.length;
    int maleCustomers = customers.where((c) => c.gender == 'male').length;
    int femaleCustomers = customers.where((c) => c.gender == 'female').length;
    int vipCustomers = customers.where((c) => c.customerValue == 'VIP').length;
    int premiumCustomers =
        customers.where((c) => c.customerValue == 'Premium').length;
    double totalRevenue =
        customers.fold(0.0, (totalAmount, c) => totalAmount + c.totalSpent);
    double averageSpent =
        totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0;

    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    int newCustomersThisMonth =
        customers.where((c) => c.createdAt.isAfter(lastMonth)).length;

    return {
      'totalCustomers': totalCustomers,
      'maleCustomers': maleCustomers,
      'femaleCustomers': femaleCustomers,
      'vipCustomers': vipCustomers,
      'premiumCustomers': premiumCustomers,
      'totalRevenue': totalRevenue,
      'averageSpent': averageSpent,
      'newCustomersThisMonth': newCustomersThisMonth,
    };
  }

  // Müşteri ziyaret güncelleme
  Future<void> updateCustomerVisit(
      String customerId, double spentAmount) async {
    final customer = await getById(customerId);
    if (customer == null) return;

    final updatedCustomer = customer.copyWith(
      totalSpent: customer.totalSpent + spentAmount,
      visitCount: customer.visitCount + 1,
      lastVisit: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await update(updatedCustomer);
  }

  // Sektörel özelleştirme alanları güncelleme
  Future<void> updateSectorSpecificData(
      String customerId, Map<String, dynamic> sectorData) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(customerId).update({
      'sectorSpecificData': sectorData,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Tag ekleme/çıkarma
  Future<void> addTag(String customerId, String tag) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(customerId).update({
      'tags': FieldValue.arrayUnion([tag]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeTag(String customerId, String tag) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(customerId).update({
      'tags': FieldValue.arrayRemove([tag]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Müşteri duplicate kontrolü
  Future<bool> isDuplicateCustomer({
    required String name,
    required String phone,
    String? excludeId,
  }) async {
    if (currentUserId == null) return false;

    Query query = userCollection
        .where('isActive', isEqualTo: true)
        .where('phone', isEqualTo: phone);

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final customer = fromMap({...data, 'id': doc.id});

      // Aynı telefon ve benzer isim
      if (customer.phone == phone &&
          customer.name.toLowerCase().trim() == name.toLowerCase().trim() &&
          (excludeId == null || customer.id != excludeId)) {
        return true;
      }
    }

    return false;
  }
}
