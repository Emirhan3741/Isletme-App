import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_client_model.dart';

class LawyerTransactionsPage extends StatefulWidget {
  const LawyerTransactionsPage({super.key});

  @override
  State<LawyerTransactionsPage> createState() => _LawyerTransactionsPageState();
}

class _LawyerTransactionsPageState extends State<LawyerTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  String _selectedType = 'tumu';
  bool _isLoading = true;
  List<LawyerTransaction> _transactions = [];
  List<LawyerClientModel> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Paralel olarak işlemleri ve müvekkilleri yükle
      final results = await Future.wait([
        _loadTransactions(user.uid),
        _loadClients(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _transactions = results[0] as List<LawyerTransaction>;
          _clients = results[1] as List<LawyerClientModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<LawyerTransaction>> _loadTransactions(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerTransactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('tarih', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LawyerTransaction.fromFirestore(doc))
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

  List<LawyerTransaction> get filteredTransactions {
    List<LawyerTransaction> filtered = _transactions;

    // Tip filtreleme (gelir/gider)
    if (_selectedType != 'tumu') {
      filtered = filtered.where((tx) => tx.kategori == _selectedType).toList();
    }

    // Durum filtreleme (ödendi/bekliyor)
    if (_selectedFilter != 'tumu') {
      filtered =
          filtered.where((tx) => tx.odemeDurumu == _selectedFilter).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final client = _clients.firstWhere(
          (c) => c.id == tx.clientId,
          orElse: () => LawyerClientModel(
            id: '',
            userId: '',
            createdAt: DateTime.now(),
            name: 'Müvekkil Bulunamadı',
            phone: '',
          ),
        );
        return tx.aciklama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Arama ve filtre alanı
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Column(
              children: [
                // Arama kutusu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'İşlem ara (Açıklama, Müvekkil)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                      borderSide: BorderSide(
                          color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Filtre butonları
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Tip filtreleri
                      _buildFilterChip('Tümü', 'tumu', _selectedType, (value) {
                        setState(() => _selectedType = value);
                      }),
                      _buildFilterChip('Gelir', 'gelir', _selectedType,
                          (value) {
                        setState(() => _selectedType = value);
                      }),
                      _buildFilterChip('Gider', 'gider', _selectedType,
                          (value) {
                        setState(() => _selectedType = value);
                      }),

                      const SizedBox(width: 16),
                      Container(width: 1, height: 20, color: Colors.grey),
                      const SizedBox(width: 16),

                      // Durum filtreleri
                      _buildFilterChip('Ödendi', 'odendi', _selectedFilter,
                          (value) {
                        setState(() => _selectedFilter = value);
                      }),
                      _buildFilterChip('Bekliyor', 'bekliyor', _selectedFilter,
                          (value) {
                        setState(() => _selectedFilter = value);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // İşlem listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue,
      Function(String) onChanged) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          onChanged(value);
        },
        backgroundColor: Colors.white,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(LawyerTransaction transaction) {
    final client = _clients.firstWhere(
      (c) => c.id == transaction.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

    final isIncome = transaction.kategori == 'gelir';
    final isPaid = transaction.odemeDurumu == 'odendi';

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır - Tutar ve durum
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}₺${transaction.tutar.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      transaction.aciklama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: AppConstants.paddingXSmall,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall),
                  border: Border.all(
                    color: isPaid ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  isPaid ? 'Ödendi' : 'Bekliyor',
                  style: TextStyle(
                    color: isPaid ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingSmall),

          // Bilgiler
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.person, 'Müvekkil: ${client.name}'),
                    _buildInfoRow(Icons.category,
                        '${isIncome ? 'Gelir' : 'Gider'} - ${_getCategoryDisplayName(transaction.kategoriDetay ?? 'genel')}'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.event,
                        'Tarih: ${_formatDate(transaction.tarih)}'),
                    if (transaction.odemeTarihi != null)
                      _buildInfoRow(Icons.payment,
                          'Ödeme: ${_formatDate(transaction.odemeTarihi!)}'),
                  ],
                ),
              ),
            ],
          ),

          // Alt satır - İşlemler
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oluşturulma: ${_formatDate(transaction.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPaid)
                    IconButton(
                      icon: const Icon(Icons.payment,
                          size: 18, color: Colors.green),
                      onPressed: () => _markAsPaid(transaction),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editTransaction(transaction),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteTransaction(transaction),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingXSmall),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              overflow: TextOverflow.ellipsis,
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
          Icon(
            Icons.attach_money,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun işlem bulunamadı'
                : 'Henüz mali işlem eklenmemiş',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk işleminizi eklemek için + butonuna tıklayın',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'vekalet_ucreti':
        return 'Vekalet Ücreti';
      case 'dava_ucreti':
        return 'Dava Ücreti';
      case 'danismanlik':
        return 'Danışmanlık';
      case 'harc':
        return 'Harç';
      case 'masraf':
        return 'Masraf';
      case 'genel':
        return 'Genel';
      default:
        return category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        clients: _clients,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  void _editTransaction(LawyerTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        clients: _clients,
        transaction: transaction,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _markAsPaid(LawyerTransaction transaction) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerTransactionsCollection)
          .doc(transaction.id)
          .update({
        'odemeDurumu': 'odendi',
        'odemeTarihi': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem ödendi olarak işaretlendi'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTransaction(LawyerTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text('Bu işlemi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerTransactionsCollection)
            .doc(transaction.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );

        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Mali işlem modeli
class LawyerTransaction {
  final String id;
  final String userId;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double tutar;
  final String aciklama;
  final String kategori; // gelir, gider
  final String?
      kategoriDetay; // vekalet_ucreti, dava_ucreti, danismanlik, harc, masraf
  final DateTime tarih;
  final String odemeDurumu; // odendi, bekliyor
  final DateTime? odemeTarihi;

  LawyerTransaction({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    required this.tutar,
    required this.aciklama,
    required this.kategori,
    this.kategoriDetay,
    required this.tarih,
    required this.odemeDurumu,
    this.odemeTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tutar': tutar,
      'aciklama': aciklama,
      'kategori': kategori,
      'kategoriDetay': kategoriDetay,
      'tarih': Timestamp.fromDate(tarih),
      'odemeDurumu': odemeDurumu,
      'odemeTarihi':
          odemeTarihi != null ? Timestamp.fromDate(odemeTarihi!) : null,
    };
  }

  static LawyerTransaction fromMap(Map<String, dynamic> map) {
    return LawyerTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      tutar: (map['tutar'] ?? 0.0).toDouble(),
      aciklama: map['aciklama'] ?? '',
      kategori: map['kategori'] ?? '',
      kategoriDetay: map['kategoriDetay'],
      tarih: (map['tarih'] as Timestamp).toDate(),
      odemeDurumu: map['odemeDurumu'] ?? 'bekliyor',
      odemeTarihi: map['odemeTarihi'] != null
          ? (map['odemeTarihi'] as Timestamp).toDate()
          : null,
    );
  }

  static LawyerTransaction fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LawyerTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      clientId: data['clientId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tutar: (data['tutar'] ?? 0.0).toDouble(),
      aciklama: data['aciklama'] ?? '',
      kategori: data['kategori'] ?? '',
      kategoriDetay: data['kategoriDetay'],
      tarih: (data['tarih'] as Timestamp).toDate(),
      odemeDurumu: data['odemeDurumu'] ?? 'bekliyor',
      odemeTarihi: data['odemeTarihi'] != null
          ? (data['odemeTarihi'] as Timestamp).toDate()
          : null,
    );
  }
}

// İşlem ekleme dialog'u
class AddTransactionDialog extends StatefulWidget {
  final List<LawyerClientModel> clients;
  final LawyerTransaction? transaction;
  final VoidCallback onSaved;

  const AddTransactionDialog({
    super.key,
    required this.clients,
    this.transaction,
    required this.onSaved,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tutarController = TextEditingController();
  final _aciklamaController = TextEditingController();

  String? _selectedClientId;
  String _selectedKategori = 'gelir';
  String _selectedKategoriDetay = 'vekalet_ucreti';
  String _selectedOdemeDurumu = 'bekliyor';
  DateTime _selectedTarih = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadTransactionData();
    }
  }

  void _loadTransactionData() {
    final tx = widget.transaction!;
    _tutarController.text = tx.tutar.toString();
    _aciklamaController.text = tx.aciklama;
    _selectedClientId = tx.clientId;
    _selectedKategori = tx.kategori;
    _selectedKategoriDetay = tx.kategoriDetay ?? 'vekalet_ucreti';
    _selectedOdemeDurumu = tx.odemeDurumu;
    _selectedTarih = tx.tarih;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'İşlem Düzenle' : 'Yeni İşlem Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Müvekkil seçimi
              DropdownButtonFormField<String>(
                value: _selectedClientId,
                decoration: const InputDecoration(
                  labelText: 'Müvekkil *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Müvekkil seçin'),
                  ),
                  ...widget.clients
                      .map((client) => DropdownMenuItem<String>(
                            value: client.id,
                            child: Text(client.name),
                          ))
                      .toList(),
                ],
                onChanged: (value) => setState(() => _selectedClientId = value),
                validator: (value) =>
                    value == null ? 'Müvekkil seçimi zorunludur' : null,
              ),

              const SizedBox(height: 16),

              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'gelir', child: Text('Gelir')),
                  DropdownMenuItem(value: 'gider', child: Text('Gider')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedKategori = value!),
              ),

              const SizedBox(height: 16),

              // Kategori detay
              DropdownButtonFormField<String>(
                value: _selectedKategoriDetay,
                decoration: const InputDecoration(
                  labelText: 'Alt Kategori',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'vekalet_ucreti', child: Text('Vekalet Ücreti')),
                  DropdownMenuItem(
                      value: 'dava_ucreti', child: Text('Dava Ücreti')),
                  DropdownMenuItem(
                      value: 'danismanlik', child: Text('Danışmanlık')),
                  DropdownMenuItem(value: 'harc', child: Text('Harç')),
                  DropdownMenuItem(value: 'masraf', child: Text('Masraf')),
                  DropdownMenuItem(value: 'genel', child: Text('Genel')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedKategoriDetay = value!),
              ),

              const SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _tutarController,
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tutar zorunludur';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama zorunludur';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Ödeme durumu
              DropdownButtonFormField<String>(
                value: _selectedOdemeDurumu,
                decoration: const InputDecoration(
                  labelText: 'Ödeme Durumu',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'bekliyor', child: Text('Bekliyor')),
                  DropdownMenuItem(value: 'odendi', child: Text('Ödendi')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedOdemeDurumu = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTransaction,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Güncelle' : 'Kaydet'),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      final now = DateTime.now();
      final transactionData = LawyerTransaction(
        id: isEditing
            ? widget.transaction!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        clientId: _selectedClientId!,
        createdAt: isEditing ? widget.transaction!.createdAt : now,
        updatedAt: now,
        tutar: double.parse(_tutarController.text.trim()),
        aciklama: _aciklamaController.text.trim(),
        kategori: _selectedKategori,
        kategoriDetay: _selectedKategoriDetay,
        tarih: _selectedTarih,
        odemeDurumu: _selectedOdemeDurumu,
        odemeTarihi: _selectedOdemeDurumu == 'odendi' ? now : null,
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerTransactionsCollection)
            .doc(widget.transaction!.id)
            .update(transactionData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.lawyerTransactionsCollection)
            .doc(transactionData.id)
            .set(transactionData.toMap());
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'İşlem başarıyla güncellendi'
              : 'İşlem başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
