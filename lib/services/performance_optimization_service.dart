import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

/// Performance optimization service for Firestore operations
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache configuration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _longCacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 1000;

  /// Enable Firestore offline persistence
  static Future<void> enableOfflinePersistence() async {
    try {
      final settings = Settings(persistenceEnabled: true);
      FirebaseFirestore.instance.settings = settings;
      if (kDebugMode) print('Firestore offline persistence enabled');
    } catch (e) {
      if (kDebugMode) print('Failed to enable offline persistence: $e');
    }
  }

  /// Configure Firestore settings for optimal performance
  static Future<void> configureFirestoreSettings() async {
    try {
      final settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes:
            Settings.CACHE_SIZE_UNLIMITED, // Use unlimited cache for web
      );
      FirebaseFirestore.instance.settings = settings;
      if (kDebugMode) print('Firestore settings configured');
    } catch (e) {
      if (kDebugMode) print('Failed to configure Firestore settings: $e');
    }
  }

  /// Get cached data or fetch from Firestore
  Future<T?> getCachedData<T>({
    required String cacheKey,
    required Future<T?> Function() fetchFunction,
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    // Check if data exists in cache and is still valid
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < cacheDuration) {
        return _cache[cacheKey] as T?;
      }
    }

    // Fetch fresh data
    try {
      final data = await fetchFunction();
      if (data != null) {
        _setCacheData(cacheKey, data);
      }
      return data;
    } catch (e) {
      // Return cached data if available, even if expired
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as T?;
      }
      rethrow;
    }
  }

  /// Set data in cache
  void _setCacheData(String key, dynamic data) {
    // Prevent cache from growing too large
    if (_cache.length >= _maxCacheSize) {
      _clearOldestCacheEntries();
    }

    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Clear oldest cache entries when cache is full
  void _clearOldestCacheEntries() {
    final entries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 25% of entries
    final entriesToRemove = (entries.length * 0.25).round();
    for (int i = 0; i < entriesToRemove; i++) {
      final key = entries[i].key;
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear specific cache entry
  void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get optimized customers list with caching
  Future<List<Map<String, dynamic>>> getOptimizedCustomers({
    String? status,
    String? customerType,
    int limit = 50,
  }) async {
    final cacheKey = 'customers_${status}_${customerType}_$limit';

    return await getCachedData<List<Map<String, dynamic>>>(
          cacheKey: cacheKey,
          fetchFunction: () => _firestoreService.getCustomers(
            status: status,
            customerType: customerType,
            limit: limit,
          ),
          cacheDuration: _defaultCacheDuration,
        ) ??
        [];
  }

  /// Get optimized services list with caching
  Future<List<Map<String, dynamic>>> getOptimizedServices({
    bool? isActive,
    String? category,
    String? sector,
  }) async {
    final cacheKey = 'services_${isActive}_${category}_$sector';

    return await getCachedData<List<Map<String, dynamic>>>(
          cacheKey: cacheKey,
          fetchFunction: () => _firestoreService.getServices(
            isActive: isActive,
            category: category,
            sector: sector,
          ),
          cacheDuration: _longCacheDuration, // Services change less frequently
        ) ??
        [];
  }

  /// Get optimized staff list with caching
  Future<List<Map<String, dynamic>>> getOptimizedStaff({
    bool? isActive,
    String? department,
    String? role,
  }) async {
    final cacheKey = 'staff_${isActive}_${department}_$role';

    return await getCachedData<List<Map<String, dynamic>>>(
          cacheKey: cacheKey,
          fetchFunction: () => _firestoreService.getStaff(
            isActive: isActive,
            department: department,
            role: role,
          ),
          cacheDuration: _longCacheDuration, // Staff changes less frequently
        ) ??
        [];
  }

  /// Batch create multiple documents for better performance
  Future<List<String>> batchCreateDocuments({
    required String collection,
    required List<Map<String, dynamic>> documentsData,
  }) async {
    if (documentsData.isEmpty) return [];

    final batch = FirebaseFirestore.instance.batch();
    final documentIds = <String>[];

    for (final docData in documentsData) {
      final docRef = FirebaseFirestore.instance.collection(collection).doc();
      final dataWithMetadata = {
        ...docData,
        'id': docRef.id,
        'userId': _firestoreService.currentUserId,
        'ownerId': _firestoreService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(docRef, dataWithMetadata);
      documentIds.add(docRef.id);
    }

    await batch.commit();

    // Clear relevant cache entries
    _clearCacheForCollection(collection);

    return documentIds;
  }

  /// Batch update multiple documents
  Future<void> batchUpdateDocuments({
    required String collection,
    required Map<String, Map<String, dynamic>>
        updates, // documentId -> updateData
  }) async {
    if (updates.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final entry in updates.entries) {
      final docRef =
          FirebaseFirestore.instance.collection(collection).doc(entry.key);
      final updateData = {
        ...entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(docRef, updateData);
    }

    await batch.commit();

    // Clear relevant cache entries
    _clearCacheForCollection(collection);
    for (final docId in updates.keys) {
      clearCacheEntry('${collection}_$docId');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDeleteDocuments({
    required String collection,
    required List<String> documentIds,
  }) async {
    if (documentIds.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final docId in documentIds) {
      final docRef =
          FirebaseFirestore.instance.collection(collection).doc(docId);
      batch.delete(docRef);
    }

    await batch.commit();

    // Clear relevant cache entries
    _clearCacheForCollection(collection);
    for (final docId in documentIds) {
      clearCacheEntry('${collection}_$docId');
    }
  }

  /// Clear cache entries for a specific collection
  void _clearCacheForCollection(String collection) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(collection)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Get appointment statistics with optimized queries
  Future<Map<String, dynamic>> getAppointmentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey =
        'appointment_stats_${startDate?.millisecondsSinceEpoch}_${endDate?.millisecondsSinceEpoch}';

    return await getCachedData<Map<String, dynamic>>(
          cacheKey: cacheKey,
          fetchFunction: () =>
              _calculateAppointmentStatistics(startDate, endDate),
          cacheDuration:
              const Duration(minutes: 15), // Stats can be cached longer
        ) ??
        {};
  }

  /// Calculate appointment statistics
  Future<Map<String, dynamic>> _calculateAppointmentStatistics(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) return {};

      Query query = FirebaseFirestore.instance
          .collection(FirestoreService.appointmentsCollection)
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('startDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('startDateTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final appointments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Calculate statistics
      final totalAppointments = appointments.length;
      final completedAppointments =
          appointments.where((apt) => apt['status'] == 'completed').length;
      final cancelledAppointments =
          appointments.where((apt) => apt['status'] == 'cancelled').length;
      final totalRevenue = appointments
          .where((apt) => apt['status'] == 'completed')
          .fold<double>(0.0,
              (sum, apt) => sum + ((apt['price'] as num?)?.toDouble() ?? 0.0));

      final statusCounts = <String, int>{};
      final priorityCounts = <String, int>{};
      final servicePopularity = <String, int>{};

      for (final appointment in appointments) {
        final status = appointment['status'] as String? ?? 'unknown';
        final priority = appointment['priority'] as String? ?? 'normal';
        final serviceId = appointment['serviceId'] as String? ?? '';

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;

        if (serviceId.isNotEmpty) {
          servicePopularity[serviceId] =
              (servicePopularity[serviceId] ?? 0) + 1;
        }
      }

      return {
        'totalAppointments': totalAppointments,
        'completedAppointments': completedAppointments,
        'cancelledAppointments': cancelledAppointments,
        'completionRate': totalAppointments > 0
            ? (completedAppointments / totalAppointments)
            : 0.0,
        'cancellationRate': totalAppointments > 0
            ? (cancelledAppointments / totalAppointments)
            : 0.0,
        'totalRevenue': totalRevenue,
        'averageRevenuePerAppointment': completedAppointments > 0
            ? (totalRevenue / completedAppointments)
            : 0.0,
        'statusCounts': statusCounts,
        'priorityCounts': priorityCounts,
        'servicePopularity': servicePopularity,
        'calculatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('Error calculating appointment statistics: $e');
      return {};
    }
  }

  /// Preload frequently accessed data
  Future<void> preloadFrequentData() async {
    try {
      // Preload in parallel for better performance
      await Future.wait([
        getOptimizedCustomers(limit: 100),
        getOptimizedServices(isActive: true),
        getOptimizedStaff(isActive: true),
      ]);

      if (kDebugMode) print('Frequent data preloaded successfully');
    } catch (e) {
      if (kDebugMode) print('Error preloading frequent data: $e');
    }
  }

  /// Create composite indexes for better query performance
  /// Note: This is just documentation - actual indexes need to be created in Firebase Console
  static Map<String, List<Map<String, dynamic>>> getRecommendedIndexes() {
    return {
      'appointments': [
        {
          'fields': ['userId', 'startDateTime'],
          'description': 'User appointments ordered by date'
        },
        {
          'fields': ['userId', 'status', 'startDateTime'],
          'description':
              'User appointments filtered by status and ordered by date'
        },
        {
          'fields': ['userId', 'customerId', 'startDateTime'],
          'description': 'Customer appointments ordered by date'
        },
        {
          'fields': ['userId', 'staffId', 'startDateTime'],
          'description': 'Staff appointments ordered by date'
        },
        {
          'fields': ['userId', 'sector', 'startDateTime'],
          'description': 'Sector-specific appointments ordered by date'
        },
      ],
      'customers': [
        {
          'fields': ['userId', 'status', 'firstName'],
          'description': 'Active customers ordered by name'
        },
        {
          'fields': ['userId', 'customerType', 'lastName'],
          'description': 'Customers by type ordered by lastname'
        },
        {
          'fields': ['userId', 'sector', 'createdAt'],
          'description': 'Sector customers ordered by creation date'
        },
      ],
      'services': [
        {
          'fields': ['userId', 'isActive', 'category'],
          'description': 'Active services by category'
        },
        {
          'fields': ['userId', 'sector', 'price'],
          'description': 'Sector services ordered by price'
        },
      ],
      'staff': [
        {
          'fields': ['userId', 'isActive', 'department'],
          'description': 'Active staff by department'
        },
        {
          'fields': ['userId', 'role', 'firstName'],
          'description': 'Staff by role ordered by name'
        },
      ],
      'documents': [
        {
          'fields': [
            'userId',
            'relatedEntityType',
            'relatedEntityId',
            'uploadedAt'
          ],
          'description': 'Entity documents ordered by upload date'
        },
        {
          'fields': ['userId', 'type', 'uploadedAt'],
          'description': 'Documents by type ordered by upload date'
        },
        {
          'fields': ['userId', 'category', 'uploadedAt'],
          'description': 'Documents by category ordered by upload date'
        },
      ],
    };
  }

  /// Get cache statistics for monitoring
  Map<String, dynamic> getCacheStatistics() {
    final now = DateTime.now();
    final expiredEntries = _cacheTimestamps.values
        .where((timestamp) => now.difference(timestamp) > _defaultCacheDuration)
        .length;

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredEntries,
      'validEntries': _cache.length - expiredEntries,
      'cacheHitRate': _getCacheHitRate(),
      'memorySizeEstimate': _estimateMemoryUsage(),
    };
  }

  /// Estimate cache memory usage (rough calculation)
  String _estimateMemoryUsage() {
    final totalBytes = _cache.values.fold<int>(
      0,
      (sum, value) => sum + value.toString().length * 2, // Rough estimation
    );

    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Calculate cache hit rate (would need to track hits/misses)
  double _getCacheHitRate() {
    // This is a placeholder - would need to implement proper tracking
    return 0.85; // Assume 85% hit rate
  }

  /// Monitor and log performance metrics
  void logPerformanceMetrics() {
    if (kDebugMode) {
      final stats = getCacheStatistics();
      print('=== Performance Metrics ===');
      print('Cache entries: ${stats['totalEntries']}');
      print('Valid entries: ${stats['validEntries']}');
      print('Memory usage: ${stats['memorySizeEstimate']}');
      print('Hit rate: ${(stats['cacheHitRate'] * 100).toStringAsFixed(1)}%');
      print('==========================');
    }
  }
}
