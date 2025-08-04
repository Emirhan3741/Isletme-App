import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/feedback_utils.dart';

class RealEstateClientsPage extends StatefulWidget {
  const RealEstateClientsPage({super.key});

  @override
  State<RealEstateClientsPage> createState() => _RealEstateClientsPageState();
}

class _RealEstateClientsPageState extends State<RealEstateClientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'tümü';
  String _selectedType = 'tümü';
  bool _isLoading = false;
  List<RealEstateClient> _clients = [];

  final List<String> _statusOptions = [
    'tümü',
    'aktif',
    'potansiyel',
    'beklemede',
    'kapalı'
  ];
  final List<String> _typeOptions = [
    'tümü',
    'alıcı',
    'satıcı',
    'kiracı',
    'kiraya_veren'
  ];

  @override
  void initState() {
    super.initState();
    _loadClients();
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

  List<RealEstateClient> get _filteredClients {
    return _clients.where((client) {
      final matchesSearch = _searchQuery.isEmpty ||
          client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.phone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == 'tümü' || client.status == _selectedStatus;
      final matchesType =
          _selectedType == 'tümü' || client.clientType == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  Future<void> _loadClients() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.realEstateClientsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _clients = snapshot.docs
            .map((doc) => RealEstateClient.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      FeedbackUtils.showError(context, 'Müşteriler yüklenirken hata: $e');
    }
  }

  Future<void> _saveClient(RealEstateClient client) async {
    try {
      setState(() => _isLoading = true);

      if (client.id.isEmpty) {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstateClientsCollection)
            .add(client.toMap());
        FeedbackUtils.showSuccess(context, 'Müşteri başarıyla eklendi');
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstateClientsCollection)
            .doc(client.id)
            .update(client.toMap());
        FeedbackUtils.showSuccess(context, 'Müşteri başarıyla güncellendi');
      }

      _loadClients();
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Müşteri kaydedilirken hata: $e');
    }
  }

  Future<void> _deleteClient(String clientId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.realEstateClientsCollection)
          .doc(clientId)
          .delete();

      FeedbackUtils.showSuccess(context, 'Müşteri başarıyla silindi');
      _loadClients();
    } catch (e) {
      FeedbackUtils.showError(context, 'Müşteri silinirken hata: $e');
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : _buildClientsList(),
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
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Müşteri Yönetimi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Müşterilerinizi ve portföyünüzü yönetin',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showAddClientDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Müşteri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
                hintText: 'Müşteri adı, telefon, email ile ara...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz müşteri yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk müşterinizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddClientDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Müşteriyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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

  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        return _buildClientCard(_filteredClients[index]);
      },
    );
  }

  Widget _buildClientCard(RealEstateClient client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
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
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(client.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(client.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(client.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${client.phone} • ${client.email}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(client.clientType),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(client.createdAt),
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
                    _showEditClientDialog(client);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(client);
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

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditClientDialog(
        onSaved: _saveClient,
      ),
    );
  }

  void _showEditClientDialog(RealEstateClient client) {
    showDialog(
      context: context,
      builder: (context) => _AddEditClientDialog(
        client: client,
        onSaved: _saveClient,
      ),
    );
  }

  void _showDeleteConfirmation(RealEstateClient client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteriyi Sil'),
        content: Text(
            '${client.name} adlı müşteriyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClient(client.id);
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
      case 'aktif':
        return 'Aktif';
      case 'potansiyel':
        return 'Potansiyel';
      case 'beklemede':
        return 'Beklemede';
      case 'kapalı':
        return 'Kapalı';
      default:
        return status;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'tümü':
        return 'Tüm Tipler';
      case 'alıcı':
        return 'Alıcı';
      case 'satıcı':
        return 'Satıcı';
      case 'kiracı':
        return 'Kiracı';
      case 'kiraya_veren':
        return 'Kiraya Veren';
      default:
        return type;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aktif':
        return Colors.green;
      case 'potansiyel':
        return Colors.orange;
      case 'beklemede':
        return Colors.blue;
      case 'kapalı':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class RealEstateClient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String clientType;
  final String status;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RealEstateClient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.clientType,
    required this.status,
    this.address,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  static RealEstateClient fromMap(Map<String, dynamic> map, String id) {
    return RealEstateClient(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      clientType: map['clientType'] ?? 'alıcı',
      status: map['status'] ?? 'aktif',
      address: map['address'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'clientType': clientType,
      'status': status,
      'address': address,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class _AddEditClientDialog extends StatefulWidget {
  final RealEstateClient? client;
  final Function(RealEstateClient) onSaved;

  const _AddEditClientDialog({
    this.client,
    required this.onSaved,
  });

  @override
  State<_AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<_AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'alıcı';
  String _selectedStatus = 'aktif';

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _nameController.text = widget.client!.name;
      _phoneController.text = widget.client!.phone;
      _emailController.text = widget.client!.email;
      _addressController.text = widget.client!.address ?? '';
      _notesController.text = widget.client!.notes ?? '';
      _selectedType = widget.client!.clientType;
      _selectedStatus = widget.client!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.client == null ? 'Yeni Müşteri' : 'Müşteriyi Düzenle'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
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
                TextFormField(
                  controller: _phoneController,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Müşteri Tipi',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'alıcı', child: Text('Alıcı')),
                          DropdownMenuItem(
                              value: 'satıcı', child: Text('Satıcı')),
                          DropdownMenuItem(
                              value: 'kiracı', child: Text('Kiracı')),
                          DropdownMenuItem(
                              value: 'kiraya_veren',
                              child: Text('Kiraya Veren')),
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
                              value: 'aktif', child: Text('Aktif')),
                          DropdownMenuItem(
                              value: 'potansiyel', child: Text('Potansiyel')),
                          DropdownMenuItem(
                              value: 'beklemede', child: Text('Beklemede')),
                          DropdownMenuItem(
                              value: 'kapalı', child: Text('Kapalı')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
          onPressed: _saveClient,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final client = RealEstateClient(
        id: widget.client?.id ?? '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        clientType: _selectedType,
        status: _selectedStatus,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        updatedAt: widget.client != null ? DateTime.now() : null,
      );

      widget.onSaved(client);
      Navigator.pop(context);
    }
  }
}
