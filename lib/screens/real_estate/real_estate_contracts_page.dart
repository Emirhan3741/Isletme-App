import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/feedback_utils.dart';

class RealEstateContractsPage extends StatefulWidget {
  const RealEstateContractsPage({super.key});

  @override
  State<RealEstateContractsPage> createState() =>
      _RealEstateContractsPageState();
}

class _RealEstateContractsPageState extends State<RealEstateContractsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'tümü';
  String _selectedType = 'tümü';
  bool _isLoading = false;
  List<RealEstateContract> _contracts = [];

  final List<String> _statusOptions = [
    'tümü',
    'taslak',
    'aktif',
    'tamamlandı',
    'iptal'
  ];
  final List<String> _typeOptions = [
    'tümü',
    'satış',
    'kira',
    'komisyon',
    'danışmanlık'
  ];

  @override
  void initState() {
    super.initState();
    _loadContracts();
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

  List<RealEstateContract> get _filteredContracts {
    return _contracts.where((contract) {
      final matchesSearch = _searchQuery.isEmpty ||
          contract.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contract.clientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          contract.propertyAddress
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == 'tümü' || contract.status == _selectedStatus;
      final matchesType =
          _selectedType == 'tümü' || contract.contractType == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  Future<void> _loadContracts() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('real_estate_contracts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _contracts = snapshot.docs
            .map((doc) => RealEstateContract.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Sözleşmeler yüklenirken hata: $e');
    }
  }

  Future<void> _saveContract(RealEstateContract contract) async {
    try {
      setState(() => _isLoading = true);

      if (contract.id.isEmpty) {
        await FirebaseFirestore.instance
            .collection('real_estate_contracts')
            .add(contract.toMap());
        FeedbackUtils.showSuccess(context, 'Sözleşme başarıyla eklendi');
      } else {
        await FirebaseFirestore.instance
            .collection('real_estate_contracts')
            .doc(contract.id)
            .update(contract.toMap());
        FeedbackUtils.showSuccess(context, 'Sözleşme başarıyla güncellendi');
      }

      _loadContracts();
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Sözleşme kaydedilirken hata: $e');
    }
  }

  Future<void> _deleteContract(String contractId) async {
    try {
      await FirebaseFirestore.instance
          .collection('real_estate_contracts')
          .doc(contractId)
          .delete();

      FeedbackUtils.showSuccess(context, 'Sözleşme başarıyla silindi');
      _loadContracts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sözleşme silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _buildStatusCards(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigo))
                : _filteredContracts.isEmpty
                    ? _buildEmptyState()
                    : _buildContractsList(),
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
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.description, color: Colors.indigo, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sözleşme Yönetimi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Sözleşmelerinizi oluşturun ve yönetin',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddContractDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sözleşme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
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
                hintText: 'Sözleşme adı, müşteri, mülk adı ile ara...',
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
          _buildStatusFilter(),
          const SizedBox(width: 12),
          _buildTypeFilter(),
        ],
      ),
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

  Widget _buildTypeFilter() {
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
            Text(_getTypeLabel(_selectedType)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => _typeOptions.map((type) {
        return PopupMenuItem(
          value: type,
          child: Text(_getTypeLabel(type)),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          _selectedType = value;
        });
      },
    );
  }

  Widget _buildStatusCards() {
    final draftCount = _contracts.where((c) => c.status == 'taslak').length;
    final activeCount = _contracts.where((c) => c.status == 'aktif').length;
    final completedCount =
        _contracts.where((c) => c.status == 'tamamlandı').length;
    final cancelledCount = _contracts.where((c) => c.status == 'iptal').length;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Taslak',
              '$draftCount',
              Icons.description,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatusCard(
              'Aktif',
              '$activeCount',
              Icons.play_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatusCard(
              'Tamamlandı',
              '$completedCount',
              Icons.check_circle,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatusCard(
              'İptal',
              '$cancelledCount',
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.description,
              size: 64,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz sözleşme yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk sözleşmenizi oluşturarak başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddContractDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Sözleşmeyi Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
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

  Widget _buildContractsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredContracts.length,
      itemBuilder: (context, index) {
        return _buildContractCard(_filteredContracts[index]);
      },
    );
  }

  Widget _buildContractCard(RealEstateContract contract) {
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
                color: _getStatusColor(contract.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getContractIcon(contract.contractType),
                color: _getStatusColor(contract.status),
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
                        contract.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (contract.amount > 0)
                        Text(
                          '₺${NumberFormat('#,##0.00', 'tr_TR').format(contract.amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${contract.clientName} • ${contract.propertyAddress}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
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
                          color: _getTypeColor(contract.contractType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(contract.contractType),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getTypeColor(contract.contractType),
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
                          color: _getStatusColor(contract.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(contract.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(contract.status),
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
                        DateFormat('dd.MM.yyyy').format(contract.startDate),
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
                    _showEditContractDialog(contract);
                    break;
                  case 'duplicate':
                    _duplicateContract(contract);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(contract);
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
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 16),
                      const SizedBox(width: 8),
                      Text('Kopyala'),
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

  void _showAddContractDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditContractDialog(
        onSaved: _saveContract,
      ),
    );
  }

  void _showEditContractDialog(RealEstateContract contract) {
    showDialog(
      context: context,
      builder: (context) => _AddEditContractDialog(
        contract: contract,
        onSaved: _saveContract,
      ),
    );
  }

  void _duplicateContract(RealEstateContract contract) {
    final duplicatedContract = RealEstateContract(
      id: '',
      userId: contract.userId,
      title: '${contract.title} (Kopya)',
      contractType: contract.contractType,
      clientName: contract.clientName,
      clientPhone: contract.clientPhone,
      clientEmail: contract.clientEmail,
      propertyAddress: contract.propertyAddress,
      amount: contract.amount,
      startDate: DateTime.now(),
      endDate: contract.endDate,
      status: 'taslak',
      terms: contract.terms,
      notes: contract.notes,
      createdAt: DateTime.now(),
    );

    _saveContract(duplicatedContract);
  }

  void _showDeleteConfirmation(RealEstateContract contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeyi Sil'),
        content: Text(
            '${contract.title} sözleşmesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContract(contract.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'tümü':
        return 'Tüm Durumlar';
      case 'taslak':
        return 'Taslak';
      case 'aktif':
        return 'Aktif';
      case 'tamamlandı':
        return 'Tamamlandı';
      case 'iptal':
        return 'İptal';
      default:
        return status;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'tümü':
        return 'Tüm Tipler';
      case 'satış':
        return 'Satış';
      case 'kira':
        return 'Kira';
      case 'komisyon':
        return 'Komisyon';
      case 'danışmanlık':
        return 'Danışmanlık';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'taslak':
        return Colors.orange;
      case 'aktif':
        return Colors.green;
      case 'tamamlandı':
        return Colors.blue;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'satış':
        return Colors.green;
      case 'kira':
        return Colors.blue;
      case 'komisyon':
        return Colors.orange;
      case 'danışmanlık':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getContractIcon(String type) {
    switch (type) {
      case 'satış':
        return Icons.home;
      case 'kira':
        return Icons.key;
      case 'komisyon':
        return Icons.monetization_on;
      case 'danışmanlık':
        return Icons.support_agent;
      default:
        return Icons.description;
    }
  }
}

class RealEstateContract {
  final String id;
  final String userId;
  final String title;
  final String contractType;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String propertyAddress;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String terms;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RealEstateContract({
    required this.id,
    required this.userId,
    required this.title,
    required this.contractType,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.propertyAddress,
    required this.amount,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.terms,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  static RealEstateContract fromMap(Map<String, dynamic> map, String id) {
    return RealEstateContract(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      contractType: map['contractType'] ?? 'satış',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'taslak',
      terms: map['terms'] ?? '',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'contractType': contractType,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'propertyAddress': propertyAddress,
      'amount': amount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'terms': terms,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class _AddEditContractDialog extends StatefulWidget {
  final RealEstateContract? contract;
  final Function(RealEstateContract) onSaved;

  const _AddEditContractDialog({
    this.contract,
    required this.onSaved,
  });

  @override
  State<_AddEditContractDialog> createState() => _AddEditContractDialogState();
}

class _AddEditContractDialogState extends State<_AddEditContractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'satış';
  String _selectedStatus = 'taslak';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _titleController.text = widget.contract!.title;
      _clientNameController.text = widget.contract!.clientName;
      _clientPhoneController.text = widget.contract!.clientPhone;
      _clientEmailController.text = widget.contract!.clientEmail;
      _propertyAddressController.text = widget.contract!.propertyAddress;
      _amountController.text = widget.contract!.amount.toString();
      _termsController.text = widget.contract!.terms;
      _notesController.text = widget.contract!.notes ?? '';
      _selectedType = widget.contract!.contractType;
      _selectedStatus = widget.contract!.status;
      _startDate = widget.contract!.startDate;
      _endDate = widget.contract!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _propertyAddressController.dispose();
    _amountController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.contract == null ? 'Yeni Sözleşme' : 'Sözleşmeyi Düzenle'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Sözleşme Başlığı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sözleşme başlığı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Sözleşme Tipi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'satış', child: Text('Satış')),
                          DropdownMenuItem(value: 'kira', child: Text('Kira')),
                          DropdownMenuItem(
                              value: 'komisyon', child: Text('Komisyon')),
                          DropdownMenuItem(
                              value: 'danışmanlık', child: Text('Danışmanlık')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedType = value!),
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
                              value: 'taslak', child: Text('Taslak')),
                          DropdownMenuItem(
                              value: 'aktif', child: Text('Aktif')),
                          DropdownMenuItem(
                              value: 'tamamlandı', child: Text('Tamamlandı')),
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
                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Müşteri adı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _clientPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefon *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefon gerekli';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _clientEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email gerekli';
                          }
                          if (!value.contains('@')) {
                            return 'Geçerli bir email giriniz';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _propertyAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Mülk Adresi *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mülk adresi gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_lira),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Geçerli bir tutar giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Başlangıç Tarihi *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Bitiş Tarihi',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('dd.MM.yyyy').format(_endDate!)
                                : 'Seçiniz',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _termsController,
                  decoration: const InputDecoration(
                    labelText: 'Sözleşme Şartları *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sözleşme şartları gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _saveContract,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveContract() {
    if (_formKey.currentState!.validate()) {
      final contract = RealEstateContract(
        id: widget.contract?.id ?? '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        title: _titleController.text,
        contractType: _selectedType,
        clientName: _clientNameController.text,
        clientPhone: _clientPhoneController.text,
        clientEmail: _clientEmailController.text,
        propertyAddress: _propertyAddressController.text,
        amount: double.tryParse(_amountController.text) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
        terms: _termsController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.contract?.createdAt ?? DateTime.now(),
        updatedAt: widget.contract != null ? DateTime.now() : null,
      );

      widget.onSaved(contract);
      Navigator.pop(context);
    }
  }
}
