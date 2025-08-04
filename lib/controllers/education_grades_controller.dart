import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/models/education_grade_model.dart';
import '../core/constants/app_constants.dart';

class EducationGradesController extends BaseListController<EducationGrade> {
  String _selectedStudentFilter = 'tümü';
  String _selectedCourseFilter = 'tümü';
  String _selectedGradeTypeFilter = 'tümü';

  String get selectedStudentFilter => _selectedStudentFilter;
  String get selectedCourseFilter => _selectedCourseFilter;
  String get selectedGradeTypeFilter => _selectedGradeTypeFilter;

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    var query = FirebaseFirestore.instance
        .collection(AppConstants.educationGradesCollection)
        .where('userId', isEqualTo: user.uid)
        .where('aktif', isEqualTo: true);

    return query.orderBy('notTarihi', descending: true);
  }

  @override
  EducationGrade fromDocument(DocumentSnapshot doc) {
    return EducationGrade.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Query<Map<String, dynamic>> applySearchFilter(
    Query<Map<String, dynamic>> query,
    String searchQuery,
  ) {
    // Firebase'de complex search yapmak için client-side filtering yapacağız
    // TODO: Algolia veya başka arama servisi entegrasyonu yapılabilir
    return query;
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Öğrenci filtresi
    if (filters['studentId'] != null) {
      query = query.where('ogrenciId', isEqualTo: filters['studentId']);
    }

    // Ders filtresi
    if (filters['courseId'] != null) {
      query = query.where('dersId', isEqualTo: filters['courseId']);
    }

    // Not türü filtresi
    if (filters['gradeType'] != null) {
      query = query.where('notTuru', isEqualTo: filters['gradeType']);
    }

    return query;
  }

  // Öğrenci filtresini güncelle
  void updateStudentFilter(String studentId) {
    _selectedStudentFilter = studentId;
    final newFilters = Map<String, dynamic>.from(filters);

    if (studentId == 'tümü') {
      newFilters.remove('studentId');
    } else {
      newFilters['studentId'] = studentId;
    }

    updateFilters(newFilters);
  }

  // Ders filtresini güncelle
  void updateCourseFilter(String courseId) {
    _selectedCourseFilter = courseId;
    final newFilters = Map<String, dynamic>.from(filters);

    if (courseId == 'tümü') {
      newFilters.remove('courseId');
    } else {
      newFilters['courseId'] = courseId;
    }

    updateFilters(newFilters);
  }

  // Not türü filtresini güncelle
  void updateGradeTypeFilter(String gradeType) {
    _selectedGradeTypeFilter = gradeType;
    final newFilters = Map<String, dynamic>.from(filters);

    if (gradeType == 'tümü') {
      newFilters.remove('gradeType');
    } else {
      newFilters['gradeType'] = gradeType;
    }

    updateFilters(newFilters);
  }

  // Filtreleri temizle
  void clearAllFilters() {
    _selectedStudentFilter = 'tümü';
    _selectedCourseFilter = 'tümü';
    _selectedGradeTypeFilter = 'tümü';
    clearFilters();
  }

  // Not ekle
  Future<void> addGrade(Map<String, dynamic> gradeData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    final now = DateTime.now();
    final data = {
      ...gradeData,
      'userId': user.uid,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await FirebaseFirestore.instance
        .collection(AppConstants.educationGradesCollection)
        .add(data);

    refresh();
  }

  // Not güncelle
  Future<void> updateGrade(String gradeId, Map<String, dynamic> updates) async {
    final data = {
      ...updates,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance
        .collection(AppConstants.educationGradesCollection)
        .doc(gradeId)
        .update(data);

    refresh();
  }

  // Not sil (aktif = false yap)
  Future<void> deleteGrade(String gradeId, String? cancelReason) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.educationGradesCollection)
        .doc(gradeId)
        .update({
      'aktif': false,
      'iptalNedeni': cancelReason ?? 'Silinmiş',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    refresh();
  }

  // Öğrenci ortalamasını hesapla
  double calculateStudentAverage(String studentId, String courseId) {
    final studentGrades = items.where((grade) =>
        grade.ogrenciId == studentId &&
        grade.dersId == courseId &&
        grade.aktif);

    if (studentGrades.isEmpty) return 0.0;

    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;

    for (final grade in studentGrades) {
      final weight = grade.agirlik ?? 1.0;
      totalWeightedScore += grade.yuzde * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;
  }

  // Sınıf ortalamasını hesapla
  double calculateClassAverage(String courseId) {
    final courseGrades =
        items.where((grade) => grade.dersId == courseId && grade.aktif);

    if (courseGrades.isEmpty) return 0.0;

    final studentAverages = <String, List<double>>{};

    // Her öğrenci için ortalama hesapla
    for (final grade in courseGrades) {
      if (!studentAverages.containsKey(grade.ogrenciId)) {
        studentAverages[grade.ogrenciId] = [];
      }
      studentAverages[grade.ogrenciId]!.add(grade.yuzde);
    }

    // Sınıf ortalamasını hesapla
    double totalAverage = 0.0;
    for (final averages in studentAverages.values) {
      totalAverage += averages.reduce((a, b) => a + b) / averages.length;
    }

    return studentAverages.isNotEmpty
        ? totalAverage / studentAverages.length
        : 0.0;
  }

  // Başarı istatistikleri
  Map<String, int> getSuccessStats(String courseId) {
    final courseGrades = items
        .where((grade) => grade.dersId == courseId && grade.aktif)
        .toList();

    final stats = {
      'excellent': 0, // 85+
      'good': 0, // 70-84
      'average': 0, // 60-69
      'poor': 0, // 50-59
      'failed': 0, // <50
    };

    for (final grade in courseGrades) {
      if (grade.yuzde >= 85) {
        stats['excellent'] = stats['excellent']! + 1;
      } else if (grade.yuzde >= 70) {
        stats['good'] = stats['good']! + 1;
      } else if (grade.yuzde >= 60) {
        stats['average'] = stats['average']! + 1;
      } else if (grade.yuzde >= 50) {
        stats['poor'] = stats['poor']! + 1;
      } else {
        stats['failed'] = stats['failed']! + 1;
      }
    }

    return stats;
  }

  // Client-side arama (Firebase limitation workaround)
  List<EducationGrade> getFilteredItems() {
    var filteredItems = items;

    // Arama filtresi
    if (searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where((grade) =>
              grade.baslik.toLowerCase().contains(searchQuery.toLowerCase()) ||
              grade.aciklama
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (grade.ogretmenNotu
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filteredItems;
  }
}
