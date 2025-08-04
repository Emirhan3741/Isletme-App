import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/education_expense_model.dart';
import '../../controllers/education_expenses_controller.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/widgets/common_widgets.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class EducationExpensesPage extends StatefulWidget {
  const EducationExpensesPage({super.key});

  @override
  State<EducationExpensesPage> createState() => _EducationExpensesPageState();
}

class _EducationExpensesPageState extends State<EducationExpensesPage> {
  late final EducationExpensesController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = EducationExpensesController();
    _searchController.addListener(_onSearchChanged);
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

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        onExpenseAdded: () => _controller.refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilterBar(),
          _buildStatsBar(),
          Expanded(
            child: PaginatedListView<EducationExpense>(
              controller: _controller,
              emptyTitle: 'Henüz gider yok',
              emptySubtitle: 'İlk giderinizi ekleyerek başlayın',
              emptyIcon: Icons.account_balance_wallet,
              emptyActionLabel: 'İlk Gideri Ekle',
              onEmptyAction: _showAddExpenseDialog,
              color: const Color(0xFF10B981),
              itemSpacing: 12,
              itemBuilder: (context, expense, index) {
                return _buildExpenseCard(expense);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giderler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Eğitim kurumu giderlerinizi takip edin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Gider başlığı, açıklama, tedarikci ara...',
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
              ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Gider Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        if (_controller.items.isEmpty) return const SizedBox.shrink();

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
                child: _buildStatCard(
                  'Toplam Gider',
                  '₺${_controller.getTotalAmount().toStringAsFixed(2)}',
                  Icons.trending_up,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'KDV Dahil',
                  '₺${_controller.getTotalAmountWithTax().toStringAsFixed(2)}',
                  Icons.receipt,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Bu Ay',
                  '₺${_controller.getMonthlyTotal(DateTime.now()).toStringAsFixed(2)}',
                  Icons.calendar_month,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Vadesi Geçen',
                  '${_controller.getOverdueExpenses().length}',
                  Icons.warning,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Gider Türü',
                _controller.selectedTypeFilter,
                [
                  'tümü',
                  ...EducationExpenseType.values.map((type) => type.value),
                ],
                (value) => _controller.updateTypeFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Durum',
                _controller.selectedStatusFilter,
                [
                  'tümü',
                  ...ExpenseStatus.values.map((status) => status.value),
                ],
                (value) => _controller.updateStatusFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Kategori',
                _controller.selectedCategoryFilter,
                ['tümü', 'sabit', 'değişken', 'yatırım'],
                (value) => _controller.updateCategoryFilter(value),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _controller.clearAllFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                tooltip: 'Filtreleri Temizle',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: ${_getDisplayName(currentValue)}'),
        backgroundColor: currentValue != 'tümü'
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.grey[100],
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(_getDisplayName(option)),
        );
      }).toList(),
      onSelected: onChanged,
    );
  }

  String _getDisplayName(String value) {
    switch (value) {
      case 'tümü':
        return 'Tümü';
      case 'rent':
        return 'Kira';
      case 'utilities':
        return 'Faturalar';
      case 'supplies':
        return 'Malzemeler';
      case 'books':
        return 'Kitaplar';
      case 'equipment':
        return 'Ekipman';
      case 'salary':
        return 'Maaş';
      case 'marketing':
        return 'Pazarlama';
      case 'maintenance':
        return 'Bakım';
      case 'insurance':
        return 'Sigorta';
      case 'license':
        return 'Lisans';
      case 'training':
        return 'Eğitim';
      case 'transport':
        return 'Ulaşım';
      case 'stationery':
        return 'Kırtasiye';
      case 'software':
        return 'Yazılım';
      case 'other':
        return 'Diğer';
      case 'paid':
        return 'Ödendi';
      case 'pending':
        return 'Beklemede';
      case 'overdue':
        return 'Gecikmiş';
      case 'cancelled':
        return 'İptal Edildi';
      case 'partially_paid':
        return 'Kısmi Ödendi';
      case 'sabit':
        return 'Sabit';
      case 'değişken':
        return 'Değişken';
      case 'yatırım':
        return 'Yatırım';
      default:
        return value.substring(0, 1).toUpperCase() + value.substring(1);
    }
  }

  Widget _buildExpenseCard(EducationExpense expense) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: expense.vadesiGecti
            ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: expense.giderTuru.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  expense.giderTuru.icon,
                  color: expense.giderTuru.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.baslik,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      expense.giderTuru.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.formatliTutar,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: expense.durumRengi.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      expense.durum.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: expense.durumRengi,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expense.aciklama.isNotEmpty) ...[
            Text(
              expense.aciklama,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Tedarikci ve kategori bilgileri
          if (expense.tedarikci != null || expense.kategori != null) ...[
            Row(
              children: [
                if (expense.tedarikci != null) ...[
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    expense.tedarikci!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (expense.kategori != null) const SizedBox(width: 16),
                ],
                if (expense.kategori != null) ...[
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    expense.kategori!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Vade uyarısı
          if (expense.vadesiGecti) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Ödeme vadesi geçmiş!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Tarih ve işlemler
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(expense.giderTarihi),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (expense.vadeseTarihi != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Vade: ${DateFormat('dd/MM/yyyy').format(expense.vadeseTarihi!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: expense.vadesiGecti ? Colors.red : Colors.grey[600],
                    fontWeight: expense.vadesiGecti ? FontWeight.w600 : null,
                  ),
                ),
              ],
              const Spacer(),
              // Ödendi işaretle butonu
              if (!expense.odendi)
                IconButton(
                  onPressed: () => _markAsPaid(expense),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  tooltip: 'Ödendi İşaretle',
                  color: Colors.green,
                ),
              // TODO: Düzenle butonu
              IconButton(
                onPressed: () => _showEditExpenseDialog(expense),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Düzenle',
              ),
              // Sil butonu
              IconButton(
                onPressed: () => _showDeleteConfirmation(expense),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ödendi olarak işaretle
  void _markAsPaid(EducationExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödendi İşaretle'),
        content: Text(
            '${expense.baslik} giderini ödendi olarak işaretlemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.markAsPaid(expense.id!);
                if (mounted) {
                  FeedbackUtils.showSuccess(
                      context, 'Gider ödendi olarak işaretlendi');
                }
              } catch (e) {
                if (mounted) {
                  FeedbackUtils.showError(context, 'Hata: $e');
                }
              }
            },
            child: const Text('Ödendi İşaretle'),
          ),
        ],
      ),
    );
  }

  // TODO: Gider düzenleme dialog'u
  void _showEditExpenseDialog(EducationExpense expense) {
    FeedbackUtils.showInfo(
        context, 'Gider düzenleme özelliği yakında eklenecek');
  }

  // Gider silme onayı
  void _showDeleteConfirmation(EducationExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: Text(
            '${expense.baslik} giderini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteExpense(expense.id!);
                if (mounted) {
                  FeedbackUtils.showSuccess(context, 'Gider başarıyla silindi');
                }
              } catch (e) {
                if (mounted) {
                  FeedbackUtils.showError(context, 'Gider silinirken hata: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final VoidCallback onExpenseAdded;

  const _AddExpenseDialog({required this.onExpenseAdded});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _supplierController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _taxRateController = TextEditingController();

  EducationExpenseType _selectedType = EducationExpenseType.other;
  ExpenseStatus _selectedStatus = ExpenseStatus.pending;
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  bool _isLoading = false;

  // Custom değerler için yeni state alanları
  String? _customCategory;
  String? _customPaymentMethod;

  final List<String> _categories = ['sabit', 'değişken', 'yatırım'];
  final List<String> _paymentMethods = ['nakit', 'kart', 'havale', 'çek'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _supplierController.dispose();
    _receiptNoController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      double? taxAmount;
      if (_taxRateController.text.isNotEmpty) {
        final taxRate = double.parse(_taxRateController.text);
        final amount = double.parse(_amountController.text);
        taxAmount = (amount * taxRate) / 100;
      }

      // Custom değerleri işle
      String? finalCategory = _selectedCategory;
      if (_selectedCategory == 'custom' &&
          _customCategory != null &&
          _customCategory!.trim().isNotEmpty) {
        finalCategory = _customCategory!.trim();
      }

      String? finalPaymentMethod = _selectedPaymentMethod;
      if (_selectedPaymentMethod == 'custom' &&
          _customPaymentMethod != null &&
          _customPaymentMethod!.trim().isNotEmpty) {
        finalPaymentMethod = _customPaymentMethod!.trim();
      }

      final expenseData = {
        'baslik': _titleController.text.trim(),
        'aciklama': _descriptionController.text.trim(),
        'giderTuru': _selectedType.value,
        'tutar': double.parse(_amountController.text),
        'giderTarihi': Timestamp.fromDate(_selectedDate),
        'vadeseTarihi': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        'durum': _selectedStatus.value,
        'tedarikci': _supplierController.text.trim().isNotEmpty
            ? _supplierController.text.trim()
            : null,
        'kategori': finalCategory,
        'odemeYontemi': finalPaymentMethod,
        'fisNo': _receiptNoController.text.trim().isNotEmpty
            ? _receiptNoController.text.trim()
            : null,
        'tekrarEden': _isRecurring,
        'kdvOrani': _taxRateController.text.isNotEmpty
            ? double.parse(_taxRateController.text)
            : null,
        'kdvTutari': taxAmount,
        // Custom değerler için metadata
        'hasCustomData':
            _selectedCategory == 'custom' || _selectedPaymentMethod == 'custom',
      };

      final controller = EducationExpensesController();
      await controller.addExpense(expenseData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Gider başarıyla eklendi');
        widget.onExpenseAdded();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildFormFields(),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF10B981),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Yeni Gider Ekle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Gider Başlığı *',
            hintText: 'Örn: Ocak Ayı Kira Ödemesi',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<EducationExpenseType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Gider Türü',
                  border: OutlineInputBorder(),
                ),
                items: EducationExpenseType.values.map((type) {
                  return DropdownMenuItem<EducationExpenseType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 16, color: type.color),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<ExpenseStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(),
                ),
                items: ExpenseStatus.values.map((status) {
                  return DropdownMenuItem<ExpenseStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺) *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _taxRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KDV Oranı (%)',
                  hintText: 'Örn: 18',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gider Tarihi',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _dueDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Vade Tarihi',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                        : 'Seçiniz',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CommonDropdownWithCustom<String>(
                label: 'Kategori',
                value: _selectedCategory,
                options: _categories,
                optionLabel: (category) => _getDisplayName(category),
                optionValue: (category) => category,
                customValue: _customCategory,
                customOptionLabel: 'Özel Kategori',
                customInputLabel: 'Kategori Adı',
                customInputHint: 'Yeni kategori adını girin...',
                isRequired: true,
                onChanged: (value) => setState(() => _selectedCategory = value),
                onCustomValueChanged: (value) =>
                    setState(() => _customCategory = value),
                validator: (value) {
                  if (value == null) return 'Kategori seçimi gerekli';
                  return null;
                },
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori adı gerekli';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommonDropdownWithCustom<String>(
                label: 'Ödeme Yöntemi',
                value: _selectedPaymentMethod,
                options: _paymentMethods,
                optionLabel: (method) => _getDisplayName(method),
                optionValue: (method) => method,
                customValue: _customPaymentMethod,
                customOptionLabel: 'Özel Ödeme Yöntemi',
                customInputLabel: 'Ödeme Yöntemi',
                customInputHint: 'Yeni ödeme yöntemi girin...',
                isRequired: false,
                onChanged: (value) =>
                    setState(() => _selectedPaymentMethod = value),
                onCustomValueChanged: (value) =>
                    setState(() => _customPaymentMethod = value),
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ödeme yöntemi adı gerekli';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Tedarikci/Satıcı',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _receiptNoController,
                decoration: const InputDecoration(
                  labelText: 'Fiş/Fatura No',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            hintText: 'Gider hakkında detay bilgi...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Tekrarlanan Gider'),
          subtitle: const Text('Bu gider düzenli olarak tekrarlanıyor mu?'),
          value: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
