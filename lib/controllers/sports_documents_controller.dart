import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/models/sports_document_model.dart';

class SportsDocumentsController extends BaseListController<SportsDocument> {
  DocumentType? _selectedTypeFilter;
  String _selectedStatusFilter = 'tümü';

  DocumentType? get selectedTypeFilter => _selectedTypeFilter;
  String get selectedStatusFilter => _selectedStatusFilter;

  String get collectionName => 'sports_documents';

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    var query = FirebaseFirestore.instance
        .collection(collectionName)
        .where('userId', isEqualTo: user.uid);

    // Durum filtresi
    if (_selectedStatusFilter == 'aktif') {
      query = query.where('isActive', isEqualTo: true);
    } else if (_selectedStatusFilter == 'pasif') {
      query = query.where('isActive', isEqualTo: false);
    } else if (_selectedStatusFilter == 'süresi_dolmuş') {
      query = query.where('expiryDate', isLessThan: Timestamp.now());
    }

    return query.orderBy('createdAt', descending: true);
  }

  @override
  SportsDocument fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return SportsDocument.fromMap(doc.data(), doc.id);
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Tür filtresi
    if (filters['documentType'] != null) {
      query = query.where('type', isEqualTo: filters['documentType']);
    }

    return query;
  }

  // Client-side filtering for complex searches
  List<SportsDocument> getFilteredItems() {
    return items.where((document) {
      // Arama filtresi
      final matchesSearch = searchQuery.isEmpty ||
          document.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          document.description
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          document.tagsDisplay
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      // Tür filtresi
      final matchesType =
          _selectedTypeFilter == null || document.type == _selectedTypeFilter;

      // Özel durum filtreleri
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'yakında_dolacak') {
        matchesStatus = document.isExpiringSoon;
      } else if (_selectedStatusFilter == 'süresi_dolmuş') {
        matchesStatus = document.isExpired;
      }

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void updateTypeFilter(DocumentType? filter) {
    _selectedTypeFilter = filter;
    refresh();
  }

  void updateStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    refresh();
  }

  @override
  void clearFilters() {
    _selectedTypeFilter = null;
    _selectedStatusFilter = 'tümü';
    refresh();
  }

  Future<void> addDocument(Map<String, dynamic> documentData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    final now = DateTime.now();
    final data = {
      ...documentData,
      'userId': user.uid,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await FirebaseFirestore.instance.collection(collectionName).add(data);
    refresh();
  }

  Future<void> updateDocument(
      String documentId, Map<String, dynamic> updates) async {
    final data = {
      ...updates,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(documentId)
        .update(data);
    refresh();
  }

  Future<void> deleteDocument(String documentId) async {
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(documentId)
        .delete();
    refresh();
  }

  Future<void> toggleDocumentStatus(SportsDocument document) async {
    await updateDocument(document.id!, {
      'isActive': !document.isActive,
    });
  }

  // Süresi yaklaşan belgeleri getir
  List<SportsDocument> getExpiringSoonDocuments() {
    return items.where((doc) => doc.isExpiringSoon).toList();
  }

  // Süresi dolmuş belgeleri getir
  List<SportsDocument> getExpiredDocuments() {
    return items.where((doc) => doc.isExpired).toList();
  }
}
