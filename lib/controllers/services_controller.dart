import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/constants/app_constants.dart';
import '../models/service_model.dart';

class ServicesController extends BaseListController<ServiceModel> {
  String _selectedCategoryFilter = 'Tümü';
  bool _showActiveOnly = true;

  ServicesController() : super(pageSize: 20);

  // Getters for filters
  String get selectedCategoryFilter => _selectedCategoryFilter;
  bool get showActiveOnly => _showActiveOnly;

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(AppConstants.servicesCollection)
        .where('userId', isEqualTo: user.uid);

    // Apply active filter
    if (_showActiveOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.orderBy('createdAt', descending: true);
  }

  @override
  ServiceModel fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // ID'yi data map'ine ekle
    return ServiceModel.fromMap(data);
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Apply category filter
    if (filters['category'] != null && filters['category'] != 'Tümü') {
      query = query.where('category', isEqualTo: filters['category']);
    }

    // Apply price range filter
    if (filters['minPrice'] != null) {
      query = query.where('price', isGreaterThanOrEqualTo: filters['minPrice']);
    }

    if (filters['maxPrice'] != null) {
      query = query.where('price', isLessThanOrEqualTo: filters['maxPrice']);
    }

    return query;
  }

  // Filter by category
  void updateCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['category'] = category;
    updateFilters(newFilters);
  }

  // Toggle active filter
  void updateActiveFilter(bool showActiveOnly) {
    _showActiveOnly = showActiveOnly;
    loadInitial(); // Rebuild query completely
  }

  // Filter by price range
  void updatePriceRange(double? minPrice, double? maxPrice) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['minPrice'] = minPrice;
    newFilters['maxPrice'] = maxPrice;
    updateFilters(newFilters);
  }

  // Local search filtering
  List<ServiceModel> get filteredItems {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((service) {
      final name = service.name.toLowerCase();
      final description = service.description.toLowerCase();
      final category = service.category.toString().toLowerCase();

      return name.contains(query) ||
          description.contains(query) ||
          category.contains(query);
    }).toList();
  }

  // Calculate summary statistics
  Map<String, dynamic> calculateSummary() {
    double totalRevenue = 0;
    double avgPrice = 0;
    int activeCount = 0;
    Map<String, int> categoryCount = {};

    for (final service in items) {
      if (service.isActive) {
        activeCount++;
        totalRevenue += service.price;
      }

      categoryCount[service.category.toString()] =
          (categoryCount[service.category.toString()] ?? 0) + 1;
    }

    if (activeCount > 0) {
      avgPrice = totalRevenue / activeCount;
    }

    final mostPopularCategory =
        categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'totalServices': items.length,
      'activeServices': activeCount,
      'avgPrice': avgPrice,
      'totalRevenue': totalRevenue,
      'mostPopularCategory': mostPopularCategory,
      'categoryBreakdown': categoryCount,
    };
  }

  // Add new service
  Future<void> addService(Map<String, dynamic> serviceData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final data = {
        ...serviceData,
        'userId': user.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.servicesCollection)
          .add(data);

      await refresh();
    } catch (e) {
      throw Exception('Hizmet eklenirken hata: $e');
    }
  }

  // Update service
  Future<void> updateService(
      String serviceId, Map<String, dynamic> updates) async {
    try {
      final data = {
        ...updates,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.servicesCollection)
          .doc(serviceId)
          .update(data);

      await refresh();
    } catch (e) {
      throw Exception('Hizmet güncellenirken hata: $e');
    }
  }

  // Delete service (soft delete)
  Future<void> deleteService(String serviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.servicesCollection)
          .doc(serviceId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      await refresh();
    } catch (e) {
      throw Exception('Hizmet silinirken hata: $e');
    }
  }

  // Toggle service status
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      await updateService(serviceId, {'isActive': isActive});
    } catch (e) {
      throw Exception('Hizmet durumu güncellenirken hata: $e');
    }
  }
}
