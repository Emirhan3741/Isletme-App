import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/case_model.dart';
import '../../core/models/lawyer_client_model.dart';
import 'add_edit_case_page.dart';

class LawyerCasesPage extends StatefulWidget {
  const LawyerCasesPage({super.key});

  @override
  State<LawyerCasesPage> createState() => _LawyerCasesPageState();
}

class _LawyerCasesPageState extends State<LawyerCasesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = true;
  List<CaseModel> _cases = [];
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

      // Paralel olarak davaları ve müvekkilleri yükle
      final results = await Future.wait([
        _loadCases(user.uid),
        _loadClients(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _cases = results[0] as List<CaseModel>;
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

  Future<List<CaseModel>> _loadCases(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerCasesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('davaBaslangicTarihi', descending: true)
        .get();

    return snapshot.docs.map((doc) => CaseModel.fromFirestore(doc)).toList();
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

  List<CaseModel> get filteredCases {
    List<CaseModel> filtered = _cases;

    // Durum filtreleme
    if (_selectedFilter != 'tumu') {
      filtered = filtered
          .where((caseModel) => caseModel.davaDurumu == _selectedFilter)
          .toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((caseModel) {
        final client = _clients.firstWhere(
          (c) => c.id == caseModel.clientId,
          orElse: () => LawyerClientModel(
            id: '',
            userId: '',
            createdAt: DateTime.now(),
            name: 'Müvekkil Bulunamadı',
            phone: '',
          ),
        );
        return caseModel.davaAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseModel.mahkemeAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseModel.esasNo
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
                    hintText: 'Dava ara (Ad, Mahkeme, Esas No, Müvekkil)',
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
                      _buildFilterChip('Tümü', 'tumu'),
                      _buildFilterChip('Hazırlık', 'hazirlik'),
                      _buildFilterChip('Devam Eden', 'devam_ediyor'),
                      _buildFilterChip('Tamamlanan', 'tamamlandi'),
                      _buildFilterChip('Temyiz', 'temyiz'),
                      _buildFilterChip('İcra', 'icra'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dava listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCases.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredCases.length,
                        itemBuilder: (context, index) {
                          final caseModel = filteredCases[index];
                          return _buildCaseCard(caseModel);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCase(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
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

  Widget _buildCaseCard(CaseModel caseModel) {
    final client = _clients.firstWhere(
      (c) => c.id == caseModel.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

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
          // Üst satır - Dava adı ve durum
          Row(
            children: [
              Expanded(
                child: Text(
                  caseModel.davaAdi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: AppConstants.paddingXSmall,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(caseModel.davaDurumu)
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall),
                  border: Border.all(
                    color: _getStatusColor(caseModel.davaDurumu),
                    width: 1,
                  ),
                ),
                child: Text(
                  DavaDurumuConstants.getDurumDisplayName(caseModel.davaDurumu),
                  style: TextStyle(
                    color: _getStatusColor(caseModel.davaDurumu),
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
                    _buildInfoRow(Icons.location_city, caseModel.mahkemeAdi),
                    if (caseModel.esasNo.isNotEmpty)
                      _buildInfoRow(
                          Icons.folder, 'Esas No: ${caseModel.esasNo}'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        Icons.category,
                        DavaTuruConstants.getTurDisplayName(
                            caseModel.davaTuru)),
                    if (caseModel.davaBaslangicTarihi != null)
                      _buildInfoRow(Icons.event,
                          'Başlangıç: ${_formatDate(caseModel.davaBaslangicTarihi!)}'),
                    if (caseModel.davaGunu != null)
                      _buildInfoRow(
                          Icons.schedule, '${caseModel.davaGunu} gün'),
                  ],
                ),
              ),
            ],
          ),

          // Mali bilgiler (varsa)
          if (caseModel.vekaleUcreti != null ||
              caseModel.davaUcreti != null) ...[
            const SizedBox(height: AppConstants.paddingSmall),
            const Divider(),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                if (caseModel.vekaleUcreti != null) ...[
                  Icon(Icons.attach_money,
                      size: 16, color: AppConstants.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Vekale: ₺${caseModel.vekaleUcreti!.toStringAsFixed(0)}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  if (caseModel.davaUcreti != null) const SizedBox(width: 16),
                ],
                if (caseModel.davaUcreti != null) ...[
                  Icon(Icons.account_balance_wallet,
                      size: 16, color: AppConstants.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Dava: ₺${caseModel.davaUcreti!.toStringAsFixed(0)}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ],

          // Alt satır - İşlemler
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oluşturulma: ${_formatDate(caseModel.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _navigateToEditCase(caseModel),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.schedule, size: 18),
                    onPressed: () => _addHearing(caseModel),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => _viewCaseDetail(caseModel),
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
            Icons.gavel,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun dava bulunamadı'
                : 'Henüz dava eklenmemiş',
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
                : 'İlk davanızı eklemek için + butonuna tıklayın',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hazirlik':
        return Colors.orange;
      case 'devam_ediyor':
        return Colors.blue;
      case 'tamamlandi':
        return Colors.green;
      case 'temyiz':
        return Colors.purple;
      case 'icra':
        return Colors.red;
      case 'iptal':
        return Colors.grey;
      default:
        return AppConstants.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _navigateToAddCase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCasePage(clients: _clients),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToEditCase(CaseModel caseModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditCasePage(caseModel: caseModel, clients: _clients),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _addHearing(CaseModel caseModel) {
    // Duruşma ekleme modalı
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duruşma Ekle'),
        content: const Text('Duruşma ekleme özelliği yakında gelecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _viewCaseDetail(CaseModel caseModel) {
    // Dava detay sayfası
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(caseModel.davaAdi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mahkeme: ${caseModel.mahkemeAdi}'),
            if (caseModel.esasNo.isNotEmpty)
              Text('Esas No: ${caseModel.esasNo}'),
            Text(
                'Durum: ${DavaDurumuConstants.getDurumDisplayName(caseModel.davaDurumu)}'),
            if (caseModel.davaBaslangicTarihi != null)
              Text('Başlangıç: ${_formatDate(caseModel.davaBaslangicTarihi!)}'),
            if (caseModel.notlar != null && caseModel.notlar!.isNotEmpty)
              Text('Notlar: ${caseModel.notlar}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
