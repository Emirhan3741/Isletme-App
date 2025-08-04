import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers/base_list_controller.dart';
import '../core/constants/app_constants.dart';
import '../models/transaction_model.dart';

class TransactionsController extends BaseListController<TransactionModel> {
  String _selectedTypeFilter = 'tümü';
  String _selectedStatusFilter = 'tümü';
  String? _selectedCustomerId;

  TransactionsController() : super(pageSize: 20);

  // Getters for filters
  String get selectedTypeFilter => _selectedTypeFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  String? get selectedCustomerId => _selectedCustomerId;

  @override
  Query<Map<String, dynamic>> buildQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    return FirebaseFirestore.instance
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true);
  }

  @override
  TransactionModel fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // ID'yi data map'ine ekle
    return TransactionModel.fromMap(data);
  }

  @override
  Query<Map<String, dynamic>> applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    // Apply type filter
    if (filters['type'] != null && filters['type'] != 'tümü') {
      query = query.where('type', isEqualTo: filters['type']);
    }

    // Apply status filter
    if (filters['status'] != null && filters['status'] != 'tümü') {
      query = query.where('status', isEqualTo: filters['status']);
    }

    // Apply customer filter
    if (filters['customerId'] != null) {
      query = query.where('customerId', isEqualTo: filters['customerId']);
    }

    // Apply date range filter
    if (filters['startDate'] != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filters['startDate']));
    }

    if (filters['endDate'] != null) {
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(filters['endDate']));
    }

    // Apply amount range filter
    if (filters['minAmount'] != null) {
      query =
          query.where('amount', isGreaterThanOrEqualTo: filters['minAmount']);
    }

    if (filters['maxAmount'] != null) {
      query = query.where('amount', isLessThanOrEqualTo: filters['maxAmount']);
    }

    return query;
  }

  // Filter by transaction type
  void updateTypeFilter(String type) {
    _selectedTypeFilter = type;
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['type'] = type;
    updateFilters(newFilters);
  }

  // Filter by transaction status
  void updateStatusFilter(String status) {
    _selectedStatusFilter = status;
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['status'] = status;
    updateFilters(newFilters);
  }

  // Filter by customer
  void updateCustomerFilter(String? customerId) {
    _selectedCustomerId = customerId;
    final newFilters = Map<String, dynamic>.from(filters);
    if (customerId != null) {
      newFilters['customerId'] = customerId;
    } else {
      newFilters.remove('customerId');
    }
    updateFilters(newFilters);
  }

  // Filter by date range
  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['startDate'] = startDate;
    newFilters['endDate'] = endDate;
    updateFilters(newFilters);
  }

  // Filter by amount range
  void updateAmountRange(double? minAmount, double? maxAmount) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters['minAmount'] = minAmount;
    newFilters['maxAmount'] = maxAmount;
    updateFilters(newFilters);
  }

  // Local search filtering for better performance
  List<TransactionModel> get filteredItems {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((transaction) {
      final description = transaction.description.toLowerCase();
      final customerName = (transaction.customerName ?? '').toLowerCase();
      final amount = transaction.amount.toString();

      return description.contains(query) ||
          customerName.contains(query) ||
          amount.contains(query);
    }).toList();
  }

  // Calculate summary statistics
  Map<String, dynamic> calculateSummary() {
    double totalIncome = 0;
    double totalExpense = 0;
    double pendingPayments = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final transaction in items) {
      if (transaction.type.toString() == 'gelir') {
        totalIncome += transaction.amount;
        if (transaction.status.toString() == 'tamamlandi') {
          completedCount++;
        }
      } else if (transaction.type.toString() == 'gider') {
        totalExpense += transaction.amount;
      }

      if (transaction.status.toString() == 'beklemede') {
        pendingPayments += transaction.amount;
        pendingCount++;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netIncome': totalIncome - totalExpense,
      'pendingPayments': pendingPayments,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'totalCount': items.length,
    };
  }

  // Add new transaction
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final data = {
        ...transactionData,
        'userId': user.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .add(data);

      await refresh();
    } catch (e) {
      throw Exception('İşlem eklenirken hata: $e');
    }
  }

  // Update transaction
  Future<void> updateTransaction(
      String transactionId, Map<String, dynamic> updates) async {
    try {
      final data = {
        ...updates,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .update(data);

      await refresh();
    } catch (e) {
      throw Exception('İşlem güncellenirken hata: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .delete();

      await refresh();
    } catch (e) {
      throw Exception('İşlem silinirken hata: $e');
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
      String transactionId, String newStatus) async {
    try {
      await updateTransaction(transactionId, {'status': newStatus});
    } catch (e) {
      throw Exception('İşlem durumu güncellenirken hata: $e');
    }
  }
}
