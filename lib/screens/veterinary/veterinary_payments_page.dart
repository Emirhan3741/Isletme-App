import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

// Ödeme Model
class VeterinaryPayment {
  final String? id;
  final String userId;
  final String patientId;
  final String patientName;
  final String description;
  final double amount;
  final DateTime paymentDate;
  final String paymentType; // nakit, kart, transfer
  final String status; // completed, pending, cancelled
  final String? receiptNo;
  final String? notes;
  final DateTime createdAt;

  VeterinaryPayment({
    this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.description,
    required this.amount,
    required this.paymentDate,
    required this.paymentType,
    required this.status,
    this.receiptNo,
    this.notes,
    required this.createdAt,
  });

  factory VeterinaryPayment.fromMap(
      Map<String, dynamic> map, String documentId) {
    return VeterinaryPayment(
      id: documentId,
      userId: map['userId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      paymentType: map['paymentType'] ?? 'nakit',
      status: map['status'] ?? 'completed',
      receiptNo: map['receiptNo'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'patientName': patientName,
      'description': description,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentType': paymentType,
      'status': status,
      'receiptNo': receiptNo,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedAmount => '₺${amount.toStringAsFixed(2)}';

  String get paymentTypeDisplay {
    switch (paymentType) {
      case 'nakit':
        return 'Nakit';
      case 'kart':
        return 'Kart';
      case 'transfer':
        return 'Transfer';
      default:
        return paymentType;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }
}

class VeterinaryPaymentsPage extends StatefulWidget {
  const VeterinaryPaymentsPage({super.key});

  @override
  State<VeterinaryPaymentsPage> createState() => _VeterinaryPaymentsPageState();
}

class _VeterinaryPaymentsPageState extends State<VeterinaryPaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<VeterinaryPayment> _payments = [];
  List<VeterinaryPayment> _filteredPayments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedPaymentTypeFilter = 'tümü';
  String _selectedStatusFilter = 'tümü';

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredPayments = _payments.where((payment) {
      // Arama filtresi
      final matchesSearch = _searchQuery.isEmpty ||
          payment.patientName.toLowerCase().contains(_searchQuery) ||
          payment.description.toLowerCase().contains(_searchQuery) ||
          (payment.receiptNo?.toLowerCase().contains(_searchQuery) ?? false);

      // Ödeme türü filtresi
      final matchesPaymentType = _selectedPaymentTypeFilter == 'tümü' ||
          payment.paymentType == _selectedPaymentTypeFilter;

      // Durum filtresi
      final matchesStatus = _selectedStatusFilter == 'tümü' ||
          payment.status == _selectedStatusFilter;

      return matchesSearch && matchesPaymentType && matchesStatus;
    }).toList();

    // Tarihe göre sırala (en yeniler üstte)
    _filteredPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('paymentDate', descending: true)
          .get();

      final payments = snapshot.docs.map((doc) {
        final data = doc.data();
        return VeterinaryPayment(
          id: doc.id,
          userId: data['userId'] ?? '',
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? '',
          description: data['description'] ?? '',
          amount: (data['amount'] ?? 0.0).toDouble(),
          paymentDate: (data['paymentDate'] as Timestamp).toDate(),
          paymentType: data['paymentType'] ?? '',
          status: data['status'] ?? '',
          receiptNo: data['receiptNo'] ?? '',
          notes: data['notes'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() {
        _payments = payments;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Ödemeler yüklenirken hata: $e');
      setState(() {
        _payments = [];
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(
        onPaymentAdded: () => _loadPayments(),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
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
              Icons.payment,
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
                  'Ödemeler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Hasta ödemelerini yönetin',
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
                    hintText: 'Hasta adı, işlem açıklaması, fiş no ara...',
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
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ödeme Ekle'),
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
    if (_isLoading || _payments.isEmpty) return const SizedBox.shrink();

    final totalAmount =
        _filteredPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final completedPayments =
        _filteredPayments.where((p) => p.status == 'completed').length;
    final pendingPayments =
        _filteredPayments.where((p) => p.status == 'pending').length;

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
              'Toplam Tutar',
              '₺${totalAmount.toStringAsFixed(2)}',
              Icons.payments,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Tamamlanan',
              completedPayments.toString(),
              Icons.check_circle,
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Bekleyen',
              pendingPayments.toString(),
              Icons.schedule,
              const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Toplam Ödeme',
              _filteredPayments.length.toString(),
              Icons.receipt_long,
              const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            'Ödeme Türü',
            _selectedPaymentTypeFilter,
            ['tümü', 'nakit', 'kart', 'transfer'],
            (value) {
              setState(() {
                _selectedPaymentTypeFilter = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Durum',
            _selectedStatusFilter,
            ['tümü', 'completed', 'pending', 'cancelled'],
            (value) {
              setState(() {
                _selectedStatusFilter = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedPaymentTypeFilter = 'tümü';
                _selectedStatusFilter = 'tümü';
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              });
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Filtreleri Temizle',
          ),
        ],
      ),
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
      case 'nakit':
        return 'Nakit';
      case 'kart':
        return 'Kart';
      case 'transfer':
        return 'Transfer';
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return value;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.payment,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz ödeme kaydı yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk ödeme kaydınızı oluşturun',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: const Text('İlk Ödemeyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        return _buildPaymentCard(_filteredPayments[index]);
      },
    );
  }

  Widget _buildPaymentCard(VeterinaryPayment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                child: Text(
                  payment.patientName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: payment.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            payment.statusDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: payment.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ödeme detayları
          Row(
            children: [
              Expanded(
                child: _buildPaymentInfoChip(
                  Icons.payments,
                  'Tutar',
                  payment.formattedAmount,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentInfoChip(
                  Icons.account_balance_wallet,
                  'Tür',
                  payment.paymentTypeDisplay,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentInfoChip(
                  Icons.calendar_today,
                  'Tarih',
                  DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          if (payment.receiptNo != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Fiş No: ${payment.receiptNo}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // İşlemler
          Row(
            children: [
              Text(
                'Oluşturulma: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              // TODO: Fatura oluştur butonu
              IconButton(
                onPressed: () => _generateInvoice(payment),
                icon: const Icon(Icons.receipt_long, size: 18),
                tooltip: 'Fatura Oluştur',
              ),
              // TODO: Ödeme düzenle butonu
              IconButton(
                onPressed: () => _showEditPaymentDialog(payment),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Düzenle',
              ),
              // TODO: Ödeme iptal et butonu
              if (payment.status != 'cancelled')
                IconButton(
                  onPressed: () => _cancelPayment(payment),
                  icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                  tooltip: 'İptal Et',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // TODO: Fatura entegrasyonu
  void _generateInvoice(VeterinaryPayment payment) {
    FeedbackUtils.showInfo(
        context, 'Fatura oluşturma özelliği yakında eklenecek');
  }

  // TODO: Ödeme düzenleme
  void _showEditPaymentDialog(VeterinaryPayment payment) {
    FeedbackUtils.showInfo(
        context, 'Ödeme düzenleme özelliği yakında eklenecek');
  }

  // TODO: Ödeme iptal etme
  void _cancelPayment(VeterinaryPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeyi İptal Et'),
        content: Text(
            '${payment.patientName} için ${payment.formattedAmount} tutarındaki ödemeyi iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Firebase update
              FeedbackUtils.showSuccess(context, 'Ödeme iptal edildi');
              _loadPayments();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }
}

class _AddPaymentDialog extends StatefulWidget {
  final VoidCallback onPaymentAdded;

  const _AddPaymentDialog({required this.onPaymentAdded});

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentType = 'nakit';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Eksik değişkenler eklendi
  String _selectedPatientId = '';
  String _selectedPatientName = '';
  String _selectedStatus = 'Beklemede';

  final List<String> _paymentTypes = ['nakit', 'kart', 'transfer'];

  @override
  void dispose() {
    _patientNameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _receiptNoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final payment = {
        'userId': user.uid,
        'patientId': _selectedPatientId,
        'patientName': _selectedPatientName,
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'paymentDate': Timestamp.fromDate(_selectedDate),
        'paymentType': _selectedPaymentType,
        'status': _selectedStatus,
        'receiptNo': _receiptNoController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('veterinary_payments')
          .add(payment);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Ödeme başarıyla eklendi');
        widget.onPaymentAdded();
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
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
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
            'Yeni Ödeme Ekle',
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
          controller: _patientNameController,
          decoration: const InputDecoration(
            labelText: 'Hasta Adı *',
            hintText: 'Örn: Pamuk (Kedi)',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'İşlem Açıklaması *',
            hintText: 'Örn: Genel muayene ve aşı',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
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
              child: DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: const InputDecoration(
                  labelText: 'Ödeme Türü',
                  border: OutlineInputBorder(),
                ),
                items: _paymentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(_getPaymentTypeDisplay(type)),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedPaymentType = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Ödeme Tarihi',
              border: OutlineInputBorder(),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _receiptNoController,
          decoration: const InputDecoration(
            labelText: 'Fiş Numarası',
            hintText: 'Opsiyonel',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notlar',
            hintText: 'Ödeme ile ilgili ek bilgiler...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  String _getPaymentTypeDisplay(String type) {
    switch (type) {
      case 'nakit':
        return 'Nakit';
      case 'kart':
        return 'Kart';
      case 'transfer':
        return 'Transfer';
      default:
        return type;
    }
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
          onPressed: _isLoading ? null : _savePayment,
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
