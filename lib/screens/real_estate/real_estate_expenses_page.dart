import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/feedback_utils.dart';

class RealEstateExpensesPage extends StatefulWidget {
  const RealEstateExpensesPage({super.key});

  @override
  State<RealEstateExpensesPage> createState() => _RealEstateExpensesPageState();
}

class _RealEstateExpensesPageState extends State<RealEstateExpensesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'tümü';
  String _selectedStatus = 'tümü';
  bool _isLoading = false;
  List<RealEstateExpense> _expenses = [];

  final List<String> _categoryOptions = [
    'tümü',
    'reklam',
    'komisyon',
    'ulaşım',
    'ofis',
    'pazarlama',
    'teknoloji',
    'diğer'
  ];
  final List<String> _statusOptions = ['tümü', 'ödendi', 'beklemede', 'iptal'];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<RealEstateExpense> get _filteredExpenses {
    return _expenses.where((expense) {
      final matchesSearch = _searchQuery.isEmpty ||
          expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'tümü' || expense.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'tümü' || expense.status == _selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  Future<void> _loadExpenses() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.realEstateExpensesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('expenseDate', descending: true)
          .get();

      setState(() {
        _expenses = snapshot.docs
            .map((doc) => RealEstateExpense.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Giderler yüklenirken hata: $e');
    }
  }

  Future<void> _saveExpense(RealEstateExpense expense) async {
    try {
      setState(() => _isLoading = true);

      if (expense.id.isEmpty) {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstateExpensesCollection)
            .add(expense.toMap());
        FeedbackUtils.showSuccess(context, 'Gider başarıyla eklendi');
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstateExpensesCollection)
            .doc(expense.id)
            .update(expense.toMap());
        FeedbackUtils.showSuccess(context, 'Gider başarıyla güncellendi');
      }

      _loadExpenses();
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Gider kaydedilirken hata: $e');
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.realEstateExpensesCollection)
          .doc(expenseId)
          .delete();

      FeedbackUtils.showSuccess(context, 'Gider başarıyla silindi');
      _loadExpenses();
    } catch (e) {
      FeedbackUtils.showError(context, 'Gider silinirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildSummaryCards(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red))
                : _filteredExpenses.isEmpty
                    ? _buildEmptyState()
                    : _buildExpensesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.money_off, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gider Yönetimi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'İş giderlerinizi takip edin ve yönetin',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddExpenseDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Gider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Gider başlığı, açıklama ile ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildCategoryFilter(),
          const SizedBox(width: 12),
          _buildStatusFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getCategoryLabel(_selectedCategory)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => _categoryOptions.map((category) {
        return PopupMenuItem(
          value: category,
          child: Text(_getCategoryLabel(category)),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getStatusLabel(_selectedStatus)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => _statusOptions.map((status) {
        return PopupMenuItem(
          value: status,
          child: Text(_getStatusLabel(status)),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildSummaryCards() {
    final totalExpenses = _expenses.fold<double>(
        0, (totalAmount, expense) => totalAmount + expense.amount);
    final paidExpenses = _expenses
        .where((e) => e.status == 'ödendi')
        .fold<double>(
            0, (totalAmount, expense) => totalAmount + expense.amount);
    final pendingExpenses = _expenses
        .where((e) => e.status == 'beklemede')
        .fold<double>(
            0, (totalAmount, expense) => totalAmount + expense.amount);

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Toplam Gider',
              '₺${NumberFormat('#,##0.00', 'tr_TR').format(totalExpenses)}',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ödenen',
              '₺${NumberFormat('#,##0.00', 'tr_TR').format(paidExpenses)}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Bekleyen',
              '₺${NumberFormat('#,##0.00', 'tr_TR').format(pendingExpenses)}',
              Icons.pending,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.money_off,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz gider yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk giderinizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExpenseDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Gideri Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) {
        return _buildExpenseCard(_filteredExpenses[index]);
      },
    );
  }

  Widget _buildExpenseCard(RealEstateExpense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _getCategoryColor(expense.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: _getCategoryColor(expense.category),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(expense.amount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(expense.category)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCategoryLabel(expense.category),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getCategoryColor(expense.category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(expense.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(expense.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(expense.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(expense.expenseDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditExpenseDialog(expense);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(expense);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      const SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditExpenseDialog(
        onSaved: _saveExpense,
      ),
    );
  }

  void _showEditExpenseDialog(RealEstateExpense expense) {
    showDialog(
      context: context,
      builder: (context) => _AddEditExpenseDialog(
        expense: expense,
        onSaved: _saveExpense,
      ),
    );
  }

  void _showDeleteConfirmation(RealEstateExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: Text(
            '${expense.title} giderini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(expense.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tümü':
        return 'Tüm Kategoriler';
      case 'reklam':
        return 'Reklam';
      case 'komisyon':
        return 'Komisyon';
      case 'ulaşım':
        return 'Ulaşım';
      case 'ofis':
        return 'Ofis';
      case 'pazarlama':
        return 'Pazarlama';
      case 'teknoloji':
        return 'Teknoloji';
      case 'diğer':
        return 'Diğer';
      default:
        return category;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'tümü':
        return 'Tüm Durumlar';
      case 'ödendi':
        return 'Ödendi';
      case 'beklemede':
        return 'Beklemede';
      case 'iptal':
        return 'İptal';
      default:
        return status;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'reklam':
        return Colors.purple;
      case 'komisyon':
        return Colors.orange;
      case 'ulaşım':
        return Colors.blue;
      case 'ofis':
        return Colors.green;
      case 'pazarlama':
        return Colors.pink;
      case 'teknoloji':
        return Colors.indigo;
      case 'diğer':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ödendi':
        return Colors.green;
      case 'beklemede':
        return Colors.orange;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'reklam':
        return Icons.campaign;
      case 'komisyon':
        return Icons.monetization_on;
      case 'ulaşım':
        return Icons.directions_car;
      case 'ofis':
        return Icons.business;
      case 'pazarlama':
        return Icons.trending_up;
      case 'teknoloji':
        return Icons.computer;
      case 'diğer':
        return Icons.category;
      default:
        return Icons.category;
    }
  }
}

class RealEstateExpense {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final String category;
  final String status;
  final DateTime expenseDate;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RealEstateExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.status,
    required this.expenseDate,
    this.receiptUrl,
    required this.createdAt,
    this.updatedAt,
  });

  static RealEstateExpense fromMap(Map<String, dynamic> map, String id) {
    return RealEstateExpense(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'diğer',
      status: map['status'] ?? 'beklemede',
      expenseDate:
          (map['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptUrl: map['receiptUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'status': status,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class _AddEditExpenseDialog extends StatefulWidget {
  final RealEstateExpense? expense;
  final Function(RealEstateExpense) onSaved;

  const _AddEditExpenseDialog({
    this.expense,
    required this.onSaved,
  });

  @override
  State<_AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends State<_AddEditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'diğer';
  String _selectedStatus = 'beklemede';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      _selectedCategory = widget.expense!.category;
      _selectedStatus = widget.expense!.status;
      _selectedDate = widget.expense!.expenseDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Yeni Gider' : 'Gideri Düzenle'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Gider Başlığı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Gider başlığı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Açıklama gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_lira),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tutar gerekli';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir tutar giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'reklam', child: Text('Reklam')),
                          DropdownMenuItem(
                              value: 'komisyon', child: Text('Komisyon')),
                          DropdownMenuItem(
                              value: 'ulaşım', child: Text('Ulaşım')),
                          DropdownMenuItem(value: 'ofis', child: Text('Ofis')),
                          DropdownMenuItem(
                              value: 'pazarlama', child: Text('Pazarlama')),
                          DropdownMenuItem(
                              value: 'teknoloji', child: Text('Teknoloji')),
                          DropdownMenuItem(
                              value: 'diğer', child: Text('Diğer')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'beklemede', child: Text('Beklemede')),
                          DropdownMenuItem(
                              value: 'ödendi', child: Text('Ödendi')),
                          DropdownMenuItem(
                              value: 'iptal', child: Text('İptal')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Gider Tarihi',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = RealEstateExpense(
        id: widget.expense?.id ?? '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        status: _selectedStatus,
        expenseDate: _selectedDate,
        receiptUrl: widget.expense?.receiptUrl,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: widget.expense != null ? DateTime.now() : null,
      );

      widget.onSaved(expense);
      Navigator.pop(context);
    }
  }
}
