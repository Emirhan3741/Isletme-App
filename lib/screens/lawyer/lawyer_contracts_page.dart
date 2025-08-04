import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_contract_model.dart';
import '../../core/models/lawyer_client_model.dart';
import '../../core/models/case_model.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class LawyerContractsPage extends StatefulWidget {
  const LawyerContractsPage({super.key});

  @override
  State<LawyerContractsPage> createState() => _LawyerContractsPageState();
}

class _LawyerContractsPageState extends State<LawyerContractsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  String _statusFilter = 'tumu';
  bool _isLoading = true;
  List<LawyerContractModel> _contracts = [];
  List<LawyerClientModel> _clients = [];
  List<CaseModel> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Paralel olarak verileri yükle
      final results = await Future.wait([
        _loadContracts(user.uid),
        _loadClients(user.uid),
        _loadCases(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _contracts = results[0] as List<LawyerContractModel>;
          _clients = results[1] as List<LawyerClientModel>;
          _cases = results[2] as List<CaseModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        FeedbackUtils.showError(context, 'Veriler yüklenirken hata oluştu: $e');
      }
    }
  }

  Future<List<LawyerContractModel>> _loadContracts(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerContractsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('sozlesmeTarihi', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LawyerContractModel.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  Future<List<LawyerClientModel>> _loadClients(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerClientsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => LawyerClientModel.fromFirestore(doc))
        .toList();
  }

  Future<List<CaseModel>> _loadCases(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerCasesCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => CaseModel.fromFirestore(doc)).toList();
  }

  List<LawyerContractModel> get filteredContracts {
    List<LawyerContractModel> filtered = _contracts;

    // Tür filtreleme
    if (_selectedFilter != 'tumu') {
      filtered = filtered
          .where((contract) => contract.sozlesmeTuru.value == _selectedFilter)
          .toList();
    }

    // Durum filtreleme
    if (_statusFilter != 'tumu') {
      filtered = filtered
          .where((contract) => contract.sozlesmeDurumu.value == _statusFilter)
          .toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contract) {
        final client = _clients.firstWhere(
          (c) => c.id == contract.clientId,
          orElse: () => LawyerClientModel(
            id: '',
            userId: '',
            createdAt: DateTime.now(),
            name: 'Müvekkil Bulunamadı',
            phone: '',
          ),
        );

        return contract.sozlesmeAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            contract.sozlesmeNo
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            client.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredContracts.isEmpty
                    ? _buildEmptyState()
                    : _buildContractsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContractDialog(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Sözleşme'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sözleşmeler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Hukuki sözleşmelerinizi yönetin',
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
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Sözleşme, müvekkil ara...',
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
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Tür',
              _selectedFilter,
              {
                'tumu': 'Tümü',
                'vekalet': 'Vekalet',
                'danismanlik': 'Danışmanlık',
                'arabuluculuk': 'Arabuluculuk',
                'tahsilat': 'Tahsilat',
                'dava_takip': 'Dava Takip',
              },
              (value) => setState(() => _selectedFilter = value),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              'Durum',
              _statusFilter,
              {
                'tumu': 'Tümü',
                'taslak': 'Taslak',
                'hazir': 'Hazır',
                'imzalandi': 'İmzalandı',
                'yururlukte': 'Yürürlükte',
                'tamamlandi': 'Tamamlandı',
              },
              (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'tumu';
                  _statusFilter = 'tumu';
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear_all),
              tooltip: 'Filtreleri Temizle',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    Map<String, String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: currentValue != options.keys.first
              ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: currentValue != options.keys.first
                ? const Color(0xFF4F46E5)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${options[currentValue]}',
              style: TextStyle(
                color: currentValue != options.keys.first
                    ? const Color(0xFF4F46E5)
                    : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: currentValue != options.keys.first
                  ? const Color(0xFF4F46E5)
                  : Colors.grey[700],
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options.entries.map((entry) {
        return PopupMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onSelected: onChanged,
    );
  }

  Widget _buildContractsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredContracts.length,
      itemBuilder: (context, index) {
        final contract = filteredContracts[index];
        return _buildContractCard(contract);
      },
    );
  }

  Widget _buildContractCard(LawyerContractModel contract) {
    final client = _clients.firstWhere(
      (c) => c.id == contract.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.description;

    switch (contract.sozlesmeDurumu) {
      case LawyerContractStatus.taslak:
        statusColor = Colors.orange;
        statusIcon = Icons.edit;
        break;
      case LawyerContractStatus.hazir:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case LawyerContractStatus.imzalandi:
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case LawyerContractStatus.yururlukte:
        statusColor = Colors.indigo;
        statusIcon = Icons.gavel;
        break;
      case LawyerContractStatus.tamamlandi:
        statusColor = Colors.green[800]!;
        statusIcon = Icons.task_alt;
        break;
      case LawyerContractStatus.feshedildi:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showContractDetail(contract),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.sozlesmeAdi,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.sozlesmeDurumu.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    contract.formatliUcret,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleContractAction(value, contract),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sign',
                        child: Row(
                          children: [
                            Icon(Icons.verified, size: 18),
                            const SizedBox(width: 8),
                            Text('İmzalandı İşaretle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 18),
                            const SizedBox(width: 8),
                            Text('Aktif Et'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 18),
                            const SizedBox(width: 8),
                            Text('Tamamlandı İşaretle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      'Müvekkil',
                      client.name,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.category,
                      'Tür',
                      contract.sozlesmeTuru.displayName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Tarih',
                      contract.formatliTarih,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.receipt,
                      'Sözleşme No',
                      contract.sozlesmeNo,
                    ),
                  ),
                ],
              ),
              if (contract.odenenTutar != null &&
                  contract.odenenTutar! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Ödeme: ${contract.odemeOrani.toStringAsFixed(1)}% (${contract.formatliKalanTutar} kalan)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (contract.yakindaSona) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Süresi yakında doluyor (${contract.kalanGun} gün kaldı)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 48,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz sözleşme yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk sözleşmenizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddContractDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Sözleşmeyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
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
    );
  }

  void _showAddContractDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditContractDialog(
        clients: _clients,
        cases: _cases,
        onSaved: () {
          _loadData();
          FeedbackUtils.showSuccess(context, 'Sözleşme başarıyla eklendi');
        },
      ),
    );
  }

  void _showEditContractDialog(LawyerContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => _AddEditContractDialog(
        contract: contract,
        clients: _clients,
        cases: _cases,
        onSaved: () {
          _loadData();
          FeedbackUtils.showSuccess(context, 'Sözleşme başarıyla güncellendi');
        },
      ),
    );
  }

  void _showContractDetail(LawyerContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => _ContractDetailDialog(
        contract: contract,
        clients: _clients,
        cases: _cases,
        onEdit: () => _showEditContractDialog(contract),
      ),
    );
  }

  void _handleContractAction(
      String action, LawyerContractModel contract) async {
    switch (action) {
      case 'edit':
        _showEditContractDialog(contract);
        break;
      case 'sign':
        await _updateContractStatus(contract, LawyerContractStatus.imzalandi);
        break;
      case 'activate':
        await _updateContractStatus(contract, LawyerContractStatus.yururlukte);
        break;
      case 'complete':
        await _updateContractStatus(contract, LawyerContractStatus.tamamlandi);
        break;
      case 'delete':
        await _deleteContract(contract);
        break;
    }
  }

  Future<void> _updateContractStatus(
      LawyerContractModel contract, LawyerContractStatus newStatus) async {
    try {
      final updateData = {
        'sozlesmeDurumu': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == LawyerContractStatus.imzalandi) {
        updateData['imzaTarihi'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerContractsCollection)
          .doc(contract.id)
          .update(updateData);

      await _loadData();
      FeedbackUtils.showSuccess(context, 'Sözleşme durumu güncellendi');
    } catch (e) {
      FeedbackUtils.showError(context, 'Güncelleme hatası: $e');
    }
  }

  Future<void> _deleteContract(LawyerContractModel contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeyi Sil'),
        content:
            const Text('Bu sözleşmeyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerContractsCollection)
            .doc(contract.id)
            .update({
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _loadData();
        FeedbackUtils.showSuccess(context, 'Sözleşme silindi');
      } catch (e) {
        FeedbackUtils.showError(context, 'Silme hatası: $e');
      }
    }
  }
}

// Sözleşme Ekleme/Düzenleme Dialog'u
class _AddEditContractDialog extends StatefulWidget {
  final LawyerContractModel? contract;
  final List<LawyerClientModel> clients;
  final List<CaseModel> cases;
  final VoidCallback onSaved;

  const _AddEditContractDialog({
    this.contract,
    required this.clients,
    required this.cases,
    required this.onSaved,
  });

  @override
  State<_AddEditContractDialog> createState() => _AddEditContractDialogState();
}

class _AddEditContractDialogState extends State<_AddEditContractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scopeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedClientId;
  String? _selectedCaseId;
  LawyerContractType _selectedType = LawyerContractType.vekalet;
  LawyerFeeType _selectedFeeType = LawyerFeeType.sabit;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _initializeFromContract();
    } else {
      _generateContractNumber();
    }
  }

  void _initializeFromContract() {
    final contract = widget.contract!;
    _nameController.text = contract.sozlesmeAdi;
    _numberController.text = contract.sozlesmeNo;
    _amountController.text = contract.ucretMiktari.toString();
    _descriptionController.text = contract.ucretAciklamasi ?? '';
    _scopeController.text = contract.hizmetKapsami ?? '';
    _notesController.text = contract.notlar ?? '';
    _selectedClientId = contract.clientId;
    _selectedCaseId = contract.caseId;
    _selectedType = contract.sozlesmeTuru;
    _selectedFeeType = contract.ucretTuru;
    _selectedDate = contract.sozlesmeTarihi;
    _startDate = contract.baslamaTarihi;
    _endDate = contract.bitisTarihi;
  }

  void _generateContractNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    _numberController.text = 'SZ-$year$month-$random';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _scopeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
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
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.contract == null ? Icons.add : Icons.edit,
            color: const Color(0xFF4F46E5),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.contract == null ? 'Yeni Sözleşme' : 'Sözleşmeyi Düzenle',
            style: const TextStyle(
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
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Sözleşme Adı *',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Sözleşme No *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<LawyerContractType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Sözleşme Türü *',
                  border: OutlineInputBorder(),
                ),
                items: LawyerContractType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedClientId,
          decoration: const InputDecoration(
            labelText: 'Müvekkil *',
            border: OutlineInputBorder(),
          ),
          items: widget.clients.map((client) {
            return DropdownMenuItem(
              value: client.id,
              child: Text(
                client.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedClientId = value),
          validator: (value) => value == null ? 'Müvekkil seçiniz' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCaseId,
          decoration: const InputDecoration(
            labelText: 'Bağlı Dava (İsteğe bağlı)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Dava seçiniz'),
            ),
            ...widget.cases.map((caseData) {
              return DropdownMenuItem(
                value: caseData.id,
                child: Text(
                  caseData.davaAdi,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedCaseId = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<LawyerFeeType>(
                value: _selectedFeeType,
                decoration: const InputDecoration(
                  labelText: 'Ücret Türü *',
                  border: OutlineInputBorder(),
                ),
                items: LawyerFeeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedFeeType = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ücret (₺) *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validatePrice,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Ücret Açıklaması',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStartDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildEndDatePicker()),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _scopeController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Hizmet Kapsamı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notlar',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
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
          labelText: 'Sözleşme Tarihi *',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildStartDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _startDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) {
          setState(() => _startDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Başlama Tarihi',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _startDate != null
              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
              : 'Tarih seçiniz',
        ),
      ),
    );
  }

  Widget _buildEndDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _endDate ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: _startDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (date != null) {
          setState(() => _endDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Bitiş Tarihi',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _endDate != null
              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
              : 'Süresiz',
        ),
      ),
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
          onPressed: _isLoading ? null : _saveContract,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
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
              : Text(widget.contract == null ? 'Kaydet' : 'Güncelle'),
        ),
      ],
    );
  }

  Future<void> _saveContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      final contractData = {
        'userId': user.uid,
        'clientId': _selectedClientId!,
        'caseId': _selectedCaseId,
        'sozlesmeAdi': _nameController.text.trim(),
        'sozlesmeNo': _numberController.text.trim(),
        'sozlesmeTuru': _selectedType.value,
        'sozlesmeDurumu': widget.contract?.sozlesmeDurumu.value ??
            LawyerContractStatus.taslak.value,
        'sozlesmeTarihi': Timestamp.fromDate(_selectedDate),
        'baslamaTarihi':
            _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'bitisTarihi': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'ucretTuru': _selectedFeeType.value,
        'ucretMiktari': double.tryParse(_amountController.text) ?? 0.0,
        'ucretAciklamasi': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'hizmetKapsami': _scopeController.text.trim().isNotEmpty
            ? _scopeController.text.trim()
            : null,
        'notlar': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.contract == null) {
        contractData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerContractsCollection)
            .add(contractData);
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerContractsCollection)
            .doc(widget.contract!.id)
            .update(contractData);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Kaydetme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Sözleşme Detay Dialog'u
class _ContractDetailDialog extends StatelessWidget {
  final LawyerContractModel contract;
  final List<LawyerClientModel> clients;
  final List<CaseModel> cases;
  final VoidCallback onEdit;

  const _ContractDetailDialog({
    required this.contract,
    required this.clients,
    required this.cases,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final client = clients.firstWhere(
      (c) => c.id == contract.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

    CaseModel? caseData;
    if (contract.caseId != null) {
      try {
        caseData = cases.firstWhere((c) => c.id == contract.caseId);
      } catch (e) {
        caseData = null;
      }
    }

    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contract.sozlesmeAdi,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem('Sözleşme No', contract.sozlesmeNo),
            _buildDetailItem('Tür', contract.sozlesmeTuru.displayName),
            _buildDetailItem('Durum', contract.sozlesmeDurumu.displayName),
            _buildDetailItem('Müvekkil', client.name),
            if (caseData != null)
              _buildDetailItem('Bağlı Dava', caseData.davaAdi),
            _buildDetailItem('Tarih', contract.formatliTarih),
            _buildDetailItem('Başlama', contract.formatliBaslamaTarihi),
            _buildDetailItem('Bitiş', contract.formatliBitisTarihi),
            _buildDetailItem('Ücret Türü', contract.ucretTuru.displayName),
            _buildDetailItem('Ücret', contract.formatliUcret),
            if (contract.odenenTutar != null && contract.odenenTutar! > 0)
              _buildDetailItem(
                  'Ödenen', '₺${contract.odenenTutar!.toStringAsFixed(0)}'),
            if (contract.hizmetKapsami != null &&
                contract.hizmetKapsami!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Hizmet Kapsamı:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contract.hizmetKapsami!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
            if (contract.notlar != null && contract.notlar!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notlar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contract.notlar!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
