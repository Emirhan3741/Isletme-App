import 'package:flutter/material.dart';
import '../../controllers/transactions_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../utils/auth_guard.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../utils/feedback_utils.dart';
import 'add_edit_transaction_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late final TransactionsController _controller;
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();

  List<CustomerModel> _customers = [];
  bool _isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _controller = TransactionsController();
    _searchController.addListener(_onSearchChanged);
    _loadCustomers();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.updateSearch(_searchController.text);
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() => _isLoadingCustomers = false);
      if (mounted) {
        FeedbackUtils.showError(context, 'Müşteriler yüklenirken hata: $e');
      }
    }
  }

  void _showAddTransactionDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTransactionPage(),
      ),
    );
    if (result == true) {
      _controller.refresh();
    }
  }

  void _editTransaction(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionPage(transaction: transaction),
      ),
    );
    if (result == true) {
      _controller.refresh();
    }
  }

  Widget _buildSearchAndCustomerSelector() {
    return Column(
      children: [
        // Arama çubuğu
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'İşlem başlığı, açıklama ara...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    // Search is now handled by controller through _searchController listener
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: Icon(Icons.clear, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),

        // Müşteri seçici
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF1A73E8)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) => DropdownButton<String?>(
                      value: _controller.selectedCustomerId,
                      hint: const Text('Müşteri Seç'),
                      isExpanded: true,
                      onChanged: (value) =>
                          _controller.updateCustomerFilter(value),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm İşlemler'),
                        ),
                        ..._customers.map((customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(customer.name),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final summary = _controller.calculateSummary();

        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: "Toplam Gelir",
                  amount: summary['totalIncome']!,
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: "Toplam Gider",
                  amount: summary['totalExpense']!,
                  icon: Icons.trending_down,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: "Net Gelir",
                  amount: summary['netIncome']!,
                  icon: Icons.account_balance_wallet,
                  color: summary['netIncome']! >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  highlight: summary['netIncome']! < 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'İşlem Geçmişi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Ödeme Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showAddPaymentModal(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('İşlem Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showAddTransactionModal(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      TransactionModel transaction, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editTransaction(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: transaction
                            .getCategoryColor()
                            .withValues(alpha: 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTransactionIcon(transaction),
                        color: transaction.getCategoryColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transaction.getCategoryText(localizations),
                            style: TextStyle(
                              color: transaction.getCategoryColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd MMM', 'tr_TR')
                              .format(transaction.createdAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${transaction.type == TransactionType.expense ? '-' : '+'}${transaction.amount.toStringAsFixed(0)}₺',
                          style: TextStyle(
                            color: transaction.type == TransactionType.expense
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
    }
  }

  Future<void> _showAddTransactionModal() async {
    await showDialog(
      context: context,
      builder: (context) => _AddTransactionModal(
        customers: _customers,
        onSaved: () {
          _controller.refresh();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showAddPaymentModal() async {
    final selectedCustomerId = _controller.selectedCustomerId;
    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödeme eklemek için bir müşteri seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _AddPaymentModal(
        customerId: selectedCustomerId,
        customerName:
            _customers.firstWhere((c) => c.id == selectedCustomerId).name,
        onSaved: () {
          _controller.refresh();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return PermissionGuard(
      hasPermission: (auth) => auth.canManageFinances,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        appBar: AppBar(
          title: const Text(
            'İşlem & Ödeme Takibi',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Column(
          children: [
            _buildSearchAndCustomerSelector(),
            const SizedBox(height: 8),
            _buildSummaryCards(),
            _buildTransactionHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: PaginatedListView<TransactionModel>(
                controller: _controller,
                emptyTitle: 'Henüz İşlem Yok',
                emptySubtitle: 'Başlamak için yeni bir işlem ekleyin',
                emptyIcon: Icons.receipt_long,
                emptyActionLabel: 'İlk İşlemi Ekle',
                onEmptyAction: () => _showAddTransactionDialog(),
                color: AppConstants.primaryColor,
                itemSpacing: 8,
                itemBuilder: (context, transaction, index) {
                  return _buildTransactionCard(transaction, localizations);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 25) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            highlight ? Border.all(color: color.withValues(alpha: 76)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0', 'tr_TR').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionModal extends StatefulWidget {
  final List<CustomerModel> customers;
  final VoidCallback onSaved;

  const _AddTransactionModal({
    required this.customers,
    required this.onSaved,
  });

  @override
  State<_AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<_AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.income;
  TransactionCategory _selectedCategory = TransactionCategory.other;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: _selectedType,
        category: _selectedCategory.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        createdAt: DateTime.now(),
        fileUrls: [],
      );

      await TransactionService().addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Yeni İşlem Ekle',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'İşlem Başlığı *',
                    hintText: 'İşlem açıklaması girin',
                    prefixIcon: const Icon(Icons.title),
                    filled: true,
                    fillColor: const Color(0xFFF5F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İşlem başlığı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Tutar (₺) *',
                    hintText: 'Tutarı girin',
                    prefixIcon: const Icon(Icons.money),
                    filled: true,
                    fillColor: const Color(0xFFF5F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tutar gerekli';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Geçersiz tutar';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'İşlem Tipi',
                    prefixIcon: const Icon(Icons.category),
                    filled: true,
                    fillColor: const Color(0xFFF5F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(TransactionModel(
                              id: '',
                              userId: '',
                              type: type,
                              category: 'other',
                              title: '',
                              description: '',
                              amount: 0,
                              createdAt: DateTime.now(),
                              fileUrls: [])
                          .getTypeText(AppLocalizations.of(context)!)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'İsteğe bağlı açıklama',
                    prefixIcon: const Icon(Icons.note),
                    filled: true,
                    fillColor: const Color(0xFFF5F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

class _AddPaymentModal extends StatefulWidget {
  final String customerId;
  final String customerName;
  final VoidCallback onSaved;

  const _AddPaymentModal({
    required this.customerId,
    required this.customerName,
    required this.onSaved,
  });

  @override
  State<_AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends State<_AddPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: TransactionType.income,
        category: TransactionCategory.appointment.name,
        title: 'Ödeme - ${widget.customerName}',
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        createdAt: DateTime.now(),
        fileUrls: [],
      );

      await TransactionService().addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Ödeme Ekle - ${widget.customerName} 💳',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Ödeme Tutarı (₺) *',
                hintText: 'Ödenen tutarı girin',
                prefixIcon: const Icon(Icons.payment),
                filled: true,
                fillColor: const Color(0xFFF5F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ödeme tutarı gerekli';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Geçersiz tutar';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                hintText: 'İsteğe bağlı ödeme açıklaması',
                prefixIcon: const Icon(Icons.note),
                filled: true,
                fillColor: const Color(0xFFF5F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Ödemeyi Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
