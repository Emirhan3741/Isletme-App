import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/expense_model.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/modern_forms.dart';

class BeautyExpensePage extends StatefulWidget {
  const BeautyExpensePage({super.key});

  @override
  State<BeautyExpensePage> createState() => _BeautyExpensePageState();
}

class _BeautyExpensePageState extends State<BeautyExpensePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryKey = 'all';
  String _selectedFilterKey = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;

  final List<String> _categoryKeys = [
    'all',
    'rent',
    'salary',
    'material',
    'marketing',
    'bills',
    'maintenance',
    'other',
  ];

  final List<String> _filterKeys = [
    'all',
    'oneTime',
    'recurring',
    'thisMonth',
    'last30Days',
    'lastMonth',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTranslatedCategory(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'all':
        return localizations.all;
      case 'rent':
        return localizations.categoryRent;
      case 'salary':
        return localizations.categorySalary;
      case 'material':
        return localizations.categoryMaterial;
      case 'marketing':
        return localizations.categoryMarketing;
      case 'bills':
        return localizations.categoryBills;
      case 'maintenance':
        return localizations.categoryMaintenance;
      case 'other':
        return localizations.categoryOther;
      default:
        return localizations.categoryOther;
    }
  }

  String _getTranslatedFilter(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'all':
        return localizations.all;
      case 'oneTime':
        return 'Tek Seferlik';
      case 'recurring':
        return 'Tekrarlayan';
      case 'thisMonth':
        return 'Bu Ay';
      case 'last30Days':
        return 'Son 30 Gün';
      case 'lastMonth':
        return 'Geçen Ay';
      default:
        return localizations.all;
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Query query = FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid);
      final querySnapshot = await query.get();

      final expenses = querySnapshot.docs
          .map((doc) => ExpenseModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();

      expenses.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gider yükleme hatası', isError: true);
      }
    }
  }

  List<ExpenseModel> get _filteredExpenses {
    return _expenses.where((expense) {
      final matchesSearch = _searchQuery.isEmpty ||
          expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          _getTranslatedCategory(context, expense.category.toLowerCase())
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryKey == 'all' ||
          expense.category.toLowerCase() == _selectedCategoryKey;

      bool matchesFilter = true;
      switch (_selectedFilterKey) {
        case 'oneTime':
          matchesFilter = !expense.isRecurring;
          break;
        case 'recurring':
          matchesFilter = expense.isRecurring;
          break;
        case 'thisMonth':
          final now = DateTime.now();
          matchesFilter =
              expense.date.year == now.year && expense.date.month == now.month;
          break;
        case 'last30Days':
          final thirtyDaysAgo =
              DateTime.now().subtract(const Duration(days: 30));
          matchesFilter = expense.date.isAfter(thirtyDaysAgo);
          break;
        case 'lastMonth':
          final now = DateTime.now();
          final lastMonth = DateTime(now.year, now.month - 1);
          matchesFilter = expense.date.year == lastMonth.year &&
              expense.date.month == lastMonth.month;
          break;
      }

      if (_startDate != null && _endDate != null) {
        final expenseDate =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
        final start =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        matchesFilter = matchesFilter &&
            (expenseDate.isAtSameMomentAs(start) ||
                expenseDate.isAfter(start)) &&
            (expenseDate.isAtSameMomentAs(end) || expenseDate.isBefore(end));
      }

      return matchesSearch && matchesCategory && matchesFilter;
    }).toList();
  }

  double get _totalExpenses => _filteredExpenses.fold(
      0.0, (totalAmount, expense) => totalAmount + expense.amount);
  double get _recurringExpenses => _filteredExpenses
      .where((e) => e.isRecurring)
      .fold(0.0, (totalAmount, e) => totalAmount + e.amount);
  int get _expenseCount => _filteredExpenses.length;

  Color _getCategoryColor(String key) {
    switch (key) {
      case 'rent':
        return Colors.purple;
      case 'salary':
        return Colors.blue;
      case 'material':
        return Colors.orange;
      case 'marketing':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'maintenance':
        return Colors.teal;
      default:
        return AppConstants.primaryColor;
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: 'Tarih Aralığı Seç',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const currencySymbol = '₺';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.expenses,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _showDateRangePicker,
            tooltip: 'Tarih Filtresi',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showExpenseAnalytics,
            tooltip: 'Analitik',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                CommonInput(
                  controller: _searchController,
                  hintText: 'Gider ara...',
                  prefixIcon: const Icon(Icons.search_outlined),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildFilterChips(
                    _filterKeys,
                    _selectedFilterKey,
                    (key) => setState(() => _selectedFilterKey = key),
                    (key) => _getTranslatedFilter(context, key)),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildFilterChips(
                    _categoryKeys,
                    _selectedCategoryKey,
                    (key) => setState(() => _selectedCategoryKey = key),
                    (key) => _getTranslatedCategory(context, key),
                    isCategory: true),
                const SizedBox(height: AppConstants.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Toplam Gider',
                        value:
                            "$currencySymbol${_totalExpenses.toStringAsFixed(0)}",
                        icon: Icons.money_off_outlined,
                        color: AppConstants.errorColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: 'Tekrarlayan Gider',
                        value:
                            "$currencySymbol${_recurringExpenses.toStringAsFixed(0)}",
                        icon: Icons.repeat_outlined,
                        color: AppConstants.warningColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: 'Gider Sayısı',
                        value: _expenseCount.toString(),
                        icon: Icons.receipt_outlined,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off_outlined,
                                size: 64, color: AppConstants.textSecondary),
                            const SizedBox(height: AppConstants.paddingMedium),
                            const Text(
                              'Gider bulunamadı',
                              style: TextStyle(
                                  color: AppConstants.textSecondary,
                                  fontSize: 16),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _selectedCategoryKey != 'all' ||
                                _selectedFilterKey != 'all' ||
                                _startDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategoryKey = 'all';
                                    _selectedFilterKey = 'all';
                                    _startDate = null;
                                    _endDate = null;
                                    _searchController.clear();
                                  });
                                },
                                child: const Text('Filtreleri Temizle'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return _ExpenseCard(
                              expense: expense,
                              getCategoryColor: _getCategoryColor,
                              getTranslatedCategory: (key) =>
                                  _getTranslatedCategory(context, key),
                              onTap: () => _showExpenseDetails(expense),
                              onEdit: () => _editExpense(expense),
                              onDelete: () => _deleteExpense(expense.id!),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewExpense,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Gider Ekle',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<String> keys, String selectedKey,
      ValueChanged<String> onSelected, String Function(String) translator,
      {bool isCategory = false}) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final isSelected = selectedKey == key;
          final color =
              isCategory ? _getCategoryColor(key) : AppConstants.primaryColor;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(translator(key)),
              selected: isSelected,
              onSelected: (_) => onSelected(key),
              backgroundColor: Colors.transparent,
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : AppConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? color : AppConstants.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExpenseAnalytics() {
    const currencySymbol = '₺';
    final categoryTotals = <String, double>{};
    final monthlyTotals = <String, double>{};

    for (final expense in _expenses) {
      final categoryName =
          _getTranslatedCategory(context, expense.category.toLowerCase());
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + expense.amount;

      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + expense.amount;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gider Analizi'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategoriye Göre Giderler',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...categoryTotals.entries.map((e) => _detailRow(
                    e.key, "$currencySymbol${e.value.toStringAsFixed(0)}")),
                const SizedBox(height: 16),
                const Text('Aylık Giderler',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...monthlyTotals.entries.take(6).map((e) => _detailRow(
                    e.key, "$currencySymbol${e.value.toStringAsFixed(0)}")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close)),
        ],
      ),
    );
  }

  void _showExpenseDetails(ExpenseModel expense) {
    const currencySymbol = '₺';
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
                'Kategori',
                _getTranslatedCategory(
                    context, expense.category.toLowerCase())),
            _detailRow(
                'Tutar', "$currencySymbol${expense.amount.toStringAsFixed(2)}"),
            _detailRow(
                'Tarih', DateFormat.yMd(languageCode).format(expense.date)),
            _detailRow('Tekrarlayan', expense.isRecurring ? 'Evet' : 'Hayır'),
            if (expense.description.isNotEmpty)
              _detailRow('Açıklama', expense.description),
            _detailRow('Oluşturulma',
                DateFormat.yMd(languageCode).format(expense.createdAt)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editExpense(expense);
            },
            child: Text(AppLocalizations.of(context)!.edit),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text("$label:",
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addNewExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BeautyExpenseForm(
        onSaved: () {
          Navigator.pop(context);
          _loadExpenses();
        },
      ),
    );
  }

  void _editExpense(ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BeautyExpenseForm(
        expenseId: expense.id,
        onSaved: () {
          Navigator.pop(context);
          _loadExpenses();
        },
      ),
    );
  }

  void _deleteExpense(String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: const Text('Bu gideri silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(expenseId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor),
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String expenseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
      _showSnackBar('Gider başarıyla silindi');
      _loadExpenses();
    } catch (e) {
      _showSnackBar('Gider silinirken hata oluştu', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(String) getCategoryColor;
  final String Function(String) getTranslatedCategory;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.getCategoryColor,
    required this.getTranslatedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currencySymbol = localizations.currencySymbol;
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    return CommonCard(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: getCategoryColor(expense.category.toLowerCase()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Text(
                        getTranslatedCategory(expense.category.toLowerCase()),
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$currencySymbol${expense.amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (expense.isRecurring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.repeat_outlined,
                              size: 12,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              localizations.filterRecurring,
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppConstants.textSecondary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(localizations.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 16, color: AppConstants.errorColor),
                          const SizedBox(width: 8),
                          Text(localizations.delete,
                              style: const TextStyle(
                                  color: AppConstants.errorColor)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                expense.description,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label:
                      "${localizations.date}: ${DateFormat.yMd(languageCode).format(expense.date)}",
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                _InfoChip(
                  icon: expense.isRecurring
                      ? Icons.repeat_outlined
                      : Icons.check_circle_outline,
                  label: expense.isRecurring
                      ? localizations.filterRecurring
                      : localizations.filterOneTime,
                  color: expense.isRecurring
                      ? AppConstants.primaryColor
                      : AppConstants.successColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
