import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class VeterinaryInventoryPage extends StatefulWidget {
  const VeterinaryInventoryPage({super.key});

  @override
  State<VeterinaryInventoryPage> createState() =>
      _VeterinaryInventoryPageState();
}

class _VeterinaryInventoryPageState extends State<VeterinaryInventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'tümü';
  bool _showLowStockOnly = false;

  final List<Map<String, String>> _inventoryCategories = [
    {'value': 'tümü', 'label': 'Tümü'},
    {'value': 'ilaç', 'label': 'İlaçlar'},
    {'value': 'aşı', 'label': 'Aşılar'},
    {'value': 'malzeme', 'label': 'Tıbbi Malzemeler'},
    {'value': 'temizlik', 'label': 'Temizlik'},
    {'value': 'gıda', 'label': 'Hayvan Gıdaları'},
    {'value': 'aksesuar', 'label': 'Aksesuarlar'},
    {'value': 'diğer', 'label': 'Diğer'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddInventoryItemDialog(
        onItemAdded: () => setState(() {}),
        categories: _inventoryCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildFilterSection(),
          _buildLowStockWarning(),
          Expanded(child: _buildInventoryList()),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
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
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stok Takibi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'İlaç ve malzeme stoklarınızı yönetin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Ürün'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                    hintText: 'Ürün ara...',
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
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _inventoryCategories.firstWhere((c) =>
                                c['value'] == _selectedCategory)['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                  itemBuilder: (context) =>
                      _inventoryCategories.map((category) {
                    return PopupMenuItem(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onSelected: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _showLowStockOnly = !_showLowStockOnly),
                icon: Icon(
                    _showLowStockOnly ? Icons.warning : Icons.warning_outlined),
                label: Text(_showLowStockOnly ? 'Düşük Stok' : 'Tümü'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _showLowStockOnly ? Colors.orange : Colors.grey[100],
                  foregroundColor:
                      _showLowStockOnly ? Colors.white : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockWarning() {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _buildLowStockQuery(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final lowStockCount = snapshot.data!.length;

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$lowStockCount ürünün stoku kritik seviyede!',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _showLowStockOnly = true;
                  _selectedCategory = 'tümü';
                }),
                child: const Text('Görüntüle'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildInventoryQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildInventoryCard(data, doc.id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildInventoryQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('veterinary_inventory')
        .where('userId', isEqualTo: user.uid)
        .orderBy('productName');

    if (_selectedCategory != 'tümü') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Stream<List<DocumentSnapshot>> _buildLowStockQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('veterinary_inventory')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final lowStockDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final currentStock = data['currentStock'] as int? ?? 0;
        final criticalLevel = data['criticalLevel'] as int? ?? 5;
        return currentStock <= criticalLevel;
      }).toList();

      return lowStockDocs;
    });
  }

  Widget _buildInventoryCard(Map<String, dynamic> data, String id) {
    final currentStock = data['currentStock'] as int? ?? 0;
    final criticalLevel = data['criticalLevel'] as int? ?? 5;
    final isLowStock = currentStock <= criticalLevel;
    final expiryDate = data['expiryDate'] != null
        ? (data['expiryDate'] as Timestamp).toDate()
        : null;
    final isExpiringSoon = expiryDate != null &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(data['category']),
                  color: const Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['productName'] ?? 'Ürün',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      _inventoryCategories.firstWhere(
                        (c) => c['value'] == data['category'],
                        orElse: () => _inventoryCategories.last,
                      )['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$currentStock ${data['unit'] ?? 'adet'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isLowStock)
                    const Text(
                      'Kritik Seviye!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (data['supplier'] != null) ...[
                Icon(Icons.business, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  data['supplier'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
              ],
              if (expiryDate != null) ...[
                Icon(
                  isExpiringSoon ? Icons.warning : Icons.calendar_today,
                  size: 14,
                  color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'SKT: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpiringSoon ? Colors.orange : Colors.grey[600],
                    fontWeight:
                        isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Min: ${criticalLevel} ${data['unit'] ?? 'adet'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (data['batchNumber'] != null || data['location'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (data['batchNumber'] != null) ...[
                    Text(
                      'Lot: ${data['batchNumber']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (data['location'] != null) const SizedBox(width: 16),
                  ],
                  if (data['location'] != null)
                    Text(
                      'Konum: ${data['location']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'ilaç':
        return Icons.medication;
      case 'aşı':
        return Icons.vaccines;
      case 'malzeme':
        return Icons.medical_services;
      case 'temizlik':
        return Icons.cleaning_services;
      case 'gıda':
        return Icons.pets;
      case 'aksesuar':
        return Icons.shopping_bag;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.inventory_2,
                size: 50,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz ürün yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk ürününüzü ekleyerek başlayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Ürünü Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddInventoryItemDialog extends StatefulWidget {
  final VoidCallback onItemAdded;
  final List<Map<String, String>> categories;

  const _AddInventoryItemDialog({
    required this.onItemAdded,
    required this.categories,
  });

  @override
  State<_AddInventoryItemDialog> createState() =>
      _AddInventoryItemDialogState();
}

class _AddInventoryItemDialogState extends State<_AddInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _criticalLevelController = TextEditingController();
  final _supplierController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'ilaç';
  String _selectedUnit = 'adet';
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<String> _units = [
    'adet',
    'kutu',
    'şişe',
    'ml',
    'gr',
    'kg',
    'litre'
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _currentStockController.dispose();
    _criticalLevelController.dispose();
    _supplierController.dispose();
    _batchNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final itemData = {
        'userId': user.uid,
        'productName': _productNameController.text.trim(),
        'category': _selectedCategory,
        'currentStock': int.parse(_currentStockController.text),
        'criticalLevel': int.parse(_criticalLevelController.text),
        'unit': _selectedUnit,
        'supplier': _supplierController.text.trim().isNotEmpty
            ? _supplierController.text.trim()
            : null,
        'batchNumber': _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        'expiryDate':
            _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('veterinary_inventory')
          .add(itemData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Ürün başarıyla eklendi');
        widget.onItemAdded();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Yeni Ürün Ekle',
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
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.categories
                            .where((c) => c['value'] != 'tümü')
                            .map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Birim *',
                          border: OutlineInputBorder(),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedUnit = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut Stok *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            ValidationUtils.validateNonNegativeNumber(
                                value, 'Stok miktarı'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _criticalLevelController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kritik Seviye *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            ValidationUtils.validateNonNegativeNumber(
                                value, 'Kritik seviye'),
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
                          labelText: 'Tedarikçi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() => _expiryDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Son Kullanma Tarihi',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _expiryDate != null
                                ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                                : 'Tarih seçin',
                            style: TextStyle(
                              color: _expiryDate != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
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
                      child: TextFormField(
                        controller: _batchNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Lot/Seri No',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Konum/Raf',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
