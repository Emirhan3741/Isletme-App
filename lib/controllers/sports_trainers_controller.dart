import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/models/sports_trainer_model.dart';

class SportsTrainersController extends BaseListController<SportsTrainer> {
  String _selectedSpecialityFilter = 'tümü';
  String _selectedStatusFilter = 'tümü';

  String get selectedSpecialityFilter => _selectedSpecialityFilter;
  String get selectedStatusFilter => _selectedStatusFilter;

  String get collectionName => 'sports_trainers';

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
    }

    return query.orderBy('fullName');
  }

  @override
  SportsTrainer fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return SportsTrainer.fromMap(doc.data(), doc.id);
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Uzmanlık filtresi
    if (filters['speciality'] != null && filters['speciality'] != 'tümü') {
      query = query.where('speciality', isEqualTo: filters['speciality']);
    }

    return query;
  }

  // Client-side filtering for complex searches
  List<SportsTrainer> getFilteredItems() {
    return items.where((trainer) {
      // Arama filtresi
      final matchesSearch = searchQuery.isEmpty ||
          trainer.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          trainer.speciality.toLowerCase().contains(searchQuery.toLowerCase());

      // Uzmanlık filtresi
      final matchesSpeciality = _selectedSpecialityFilter == 'tümü' ||
          trainer.speciality
              .toLowerCase()
              .contains(_selectedSpecialityFilter.toLowerCase());

      return matchesSearch && matchesSpeciality;
    }).toList();
  }

  void updateSpecialityFilter(String filter) {
    _selectedSpecialityFilter = filter;
    refresh();
  }

  void updateStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    refresh();
  }

  @override
  void clearFilters() {
    _selectedSpecialityFilter = 'tümü';
    _selectedStatusFilter = 'tümü';
    refresh();
  }

  Future<void> addTrainer(Map<String, dynamic> trainerData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    final now = DateTime.now();
    final data = {
      ...trainerData,
      'userId': user.uid,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await FirebaseFirestore.instance.collection(collectionName).add(data);
    refresh();
  }

  Future<void> updateTrainer(
      String trainerId, Map<String, dynamic> updates) async {
    final data = {
      ...updates,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(trainerId)
        .update(data);
    refresh();
  }

  Future<void> deleteTrainer(String trainerId) async {
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(trainerId)
        .delete();
    refresh();
  }

  Future<void> toggleTrainerStatus(SportsTrainer trainer) async {
    await updateTrainer(trainer.id!, {
      'isActive': !trainer.isActive,
    });
  }
}
