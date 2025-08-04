import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/models/education_expense_model.dart';
import '../core/constants/app_constants.dart';

class EducationExpensesController extends BaseListController<EducationExpense> {
  String _selectedTypeFilter = 'tümü';
  String _selectedStatusFilter = 'tümü';
  String _selectedCategoryFilter = 'tümü';

  String get selectedTypeFilter => _selectedTypeFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    var query = FirebaseFirestore.instance
        .collection(AppConstants.educationExpensesCollection)
        .where('userId', isEqualTo: user.uid);

    return query.orderBy('giderTarihi', descending: true);
  }

  @override
  EducationExpense fromDocument(DocumentSnapshot doc) {
    return EducationExpense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Query<Map<String, dynamic>> applySearchFilter(
    Query<Map<String, dynamic>> query,
    String searchQuery,
  ) {
    // Firebase'de complex search yapmak için client-side filtering yapacağız
    return query;
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Gider türü filtresi
    if (filters['expenseType'] != null) {
      query = query.where('giderTuru', isEqualTo: filters['expenseType']);
    }

    // Durum filtresi
    if (filters['status'] != null) {
      query = query.where('durum', isEqualTo: filters['status']);
    }

    // Kategori filtresi
    if (filters['category'] != null) {
      query = query.where('kategori', isEqualTo: filters['category']);
    }

    // Tarih aralığı filtresi
    if (filters['startDate'] != null) {
      query = query.where('giderTarihi',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filters['startDate']));
    }

    if (filters['endDate'] != null) {
      query = query.where('giderTarihi',
          isLessThanOrEqualTo: Timestamp.fromDate(filters['endDate']));
    }

    return query;
  }

  // Gider türü filtresini güncelle
  void updateTypeFilter(String expenseType) {
    _selectedTypeFilter = expenseType;
    final newFilters = Map<String, dynamic>.from(filters);

    if (expenseType == 'tümü') {
      newFilters.remove('expenseType');
    } else {
      newFilters['expenseType'] = expenseType;
    }

    updateFilters(newFilters);
  }

  // Durum filtresini güncelle
  void updateStatusFilter(String status) {
    _selectedStatusFilter = status;
    final newFilters = Map<String, dynamic>.from(filters);

    if (status == 'tümü') {
      newFilters.remove('status');
    } else {
      newFilters['status'] = status;
    }

    updateFilters(newFilters);
  }

  // Kategori filtresini güncelle
  void updateCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    final newFilters = Map<String, dynamic>.from(filters);

    if (category == 'tümü') {
      newFilters.remove('category');
    } else {
      newFilters['category'] = category;
    }

    updateFilters(newFilters);
  }

  // Tarih aralığı filtresini güncelle
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    final newFilters = Map<String, dynamic>.from(filters);

    if (startDate != null) {
      newFilters['startDate'] = startDate;
    } else {
      newFilters.remove('startDate');
    }

    if (endDate != null) {
      newFilters['endDate'] = endDate;
    } else {
      newFilters.remove('endDate');
    }

    updateFilters(newFilters);
  }

  // Filtreleri temizle
  void clearAllFilters() {
    _selectedTypeFilter = 'tümü';
    _selectedStatusFilter = 'tümü';
    _selectedCategoryFilter = 'tümü';
    clearFilters();
  }

  // Gider ekle
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı oturum açmamış');

    final now = DateTime.now();
    final data = {
      ...expenseData,
      'userId': user.uid,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await FirebaseFirestore.instance
        .collection(AppConstants.educationExpensesCollection)
        .add(data);

    refresh();
  }

  // Gider güncelle
  Future<void> updateExpense(
      String expenseId, Map<String, dynamic> updates) async {
    final data = {
      ...updates,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance
        .collection(AppConstants.educationExpensesCollection)
        .doc(expenseId)
        .update(data);

    refresh();
  }

  // Gider sil
  Future<void> deleteExpense(String expenseId) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.educationExpensesCollection)
        .doc(expenseId)
        .delete();

    refresh();
  }

  // Gideri ödendi olarak işaretle
  Future<void> markAsPaid(
    String expenseId, {
    DateTime? paidDate,
    String? paymentMethod,
    String? receiptNo,
  }) async {
    await updateExpense(expenseId, {
      'durum': ExpenseStatus.paid.value,
      'odemeTarihi': Timestamp.fromDate(paidDate ?? DateTime.now()),
      'odemeYontemi': paymentMethod,
      'makbuzNo': receiptNo,
    });
  }

  // Toplam gider hesapla (mevcut filtrelere göre)
  double getTotalAmount() {
    return getFilteredItems()
        .fold(0.0, (totalAmount, expense) => totalAmount + expense.tutar);
  }

  // KDV dahil toplam gider hesapla
  double getTotalAmountWithTax() {
    return getFilteredItems().fold(
        0.0, (totalAmount, expense) => totalAmount + expense.kdvDahilTutar);
  }

  // Aylık gider hesapla
  double getMonthlyTotal(DateTime month) {
    final monthlyExpenses = items
        .where((expense) =>
            expense.giderTarihi.year == month.year &&
            expense.giderTarihi.month == month.month)
        .toList();

    return monthlyExpenses.fold(
        0.0, (totalAmount, expense) => totalAmount + expense.tutar);
  }

  // Gider türüne göre toplamlar
  Map<EducationExpenseType, double> getTotalsByType() {
    final totals = <EducationExpenseType, double>{};

    for (final type in EducationExpenseType.values) {
      totals[type] = 0.0;
    }

    for (final expense in getFilteredItems()) {
      totals[expense.giderTuru] =
          (totals[expense.giderTuru] ?? 0.0) + expense.tutar;
    }

    return totals;
  }

  // Ödeme durumu istatistikleri
  Map<ExpenseStatus, int> getStatusStats() {
    final stats = <ExpenseStatus, int>{};

    for (final status in ExpenseStatus.values) {
      stats[status] = 0;
    }

    for (final expense in getFilteredItems()) {
      stats[expense.durum] = (stats[expense.durum] ?? 0) + 1;
    }

    return stats;
  }

  // Vadesi geçen giderler
  List<EducationExpense> getOverdueExpenses() {
    return items
        .where((expense) => expense.vadesiGecti && !expense.odendi)
        .toList();
  }

  // Bu hafta vadesi dolan giderler
  List<EducationExpense> getThisWeeksDueExpenses() {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));

    return items
        .where((expense) =>
            expense.vadeseTarihi != null &&
            expense.vadeseTarihi!.isAfter(now) &&
            expense.vadeseTarihi!.isBefore(weekEnd) &&
            !expense.odendi)
        .toList();
  }

  // Client-side arama (Firebase limitation workaround)
  List<EducationExpense> getFilteredItems() {
    var filteredItems = items;

    // Arama filtresi
    if (searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where((expense) =>
              expense.baslik
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              expense.aciklama
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (expense.tedarikci
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                  false) ||
              (expense.fisNo
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filteredItems;
  }

  // Aylık büyüme oranı hesapla
  double getMonthlyGrowthRate() {
    final now = DateTime.now();
    final thisMonth = getMonthlyTotal(now);
    final lastMonth = getMonthlyTotal(DateTime(now.year, now.month - 1));

    if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;

    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  // En çok harcama yapılan kategoriler (top 5)
  List<MapEntry<EducationExpenseType, double>> getTopExpenseTypes() {
    final totals = getTotalsByType();
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }
}
