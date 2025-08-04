import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/constants/app_constants.dart';
import '../core/models/sports_session_model.dart';

class SportsSessionsController extends BaseListController<SportsSession> {
  String _selectedStatusFilter = 'tümü';
  String _selectedTypeFilter = 'tümü';

  SportsSessionsController() : super(pageSize: 15);

  // Getters for filters
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedTypeFilter => _selectedTypeFilter;

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    return FirebaseFirestore.instance
        .collection(AppConstants.sportsSessionsCollection)
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('seansTarihi', descending: true);
  }

  @override
  SportsSession fromDocument(DocumentSnapshot doc) {
    return SportsSession.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  @override
  Query<Map<String, dynamic>> applySearchFilter(
    Query<Map<String, dynamic>> query,
    String searchQuery,
  ) {
    // Firestore doesn't support full-text search, so we'll filter in memory
    // For better search, consider using Algolia or similar
    return query;
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters['status'] != null && filters['status'] != 'tümü') {
      query = query.where('durum', isEqualTo: filters['status']);
    }

    // Apply type filter
    if (filters['type'] != null && filters['type'] != 'tümü') {
      query = query.where('seansTipi', isEqualTo: filters['type']);
    }

    // Apply date range filter
    if (filters['startDate'] != null) {
      query = query.where('seansTarihi',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filters['startDate']));
    }

    if (filters['endDate'] != null) {
      query = query.where('seansTarihi',
          isLessThanOrEqualTo: Timestamp.fromDate(filters['endDate']));
    }

    return query;
  }

  // Filter by session status
  void updateStatusFilter(String status) {
    _selectedStatusFilter = status;
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['status'] = status;
    updateFilters(newFilters);
  }

  // Filter by session type
  void updateTypeFilter(String type) {
    _selectedTypeFilter = type;
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['type'] = type;
    updateFilters(newFilters);
  }

  // Filter by date range
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['startDate'] = startDate;
    newFilters['endDate'] = endDate;
    updateFilters(newFilters);
  }

  // Local search filtering (since Firestore doesn't support full-text search)
  List<SportsSession> get filteredItems {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((session) {
      final sessionType = session.sessionType.toLowerCase();
      final title = session.serviceName.toLowerCase();
      final notes = (session.notes ?? '').toLowerCase();

      return sessionType.contains(query) ||
          title.contains(query) ||
          notes.contains(query);
    }).toList();
  }

  // Add new session
  Future<void> addSession(Map<String, dynamic> sessionData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final data = {
        ...sessionData,
        'userId': user.uid,
        'olusturmaTarihi': Timestamp.now(),
        'guncellenmeTarihi': Timestamp.now(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.sportsSessionsCollection)
          .add(data);

      // Refresh the list to show the new session
      await refresh();
    } catch (e) {
      throw Exception('Seans eklenirken hata: $e');
    }
  }

  // Update session
  Future<void> updateSession(
      String sessionId, Map<String, dynamic> updates) async {
    try {
      final data = {
        ...updates,
        'guncellenmeTarihi': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.sportsSessionsCollection)
          .doc(sessionId)
          .update(data);

      // Refresh the list to show the updated session
      await refresh();
    } catch (e) {
      throw Exception('Seans güncellenirken hata: $e');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.sportsSessionsCollection)
          .doc(sessionId)
          .update({
        'isActive': false,
        'guncellenmeTarihi': Timestamp.now(),
      });

      // Refresh the list to remove the deleted session
      await refresh();
    } catch (e) {
      throw Exception('Seans silinirken hata: $e');
    }
  }
}
