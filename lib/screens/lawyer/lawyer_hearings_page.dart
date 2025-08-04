import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/court_date_model.dart';
import '../../core/models/case_model.dart';
import '../../core/models/lawyer_client_model.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class LawyerHearingsPage extends StatefulWidget {
  const LawyerHearingsPage({super.key});

  @override
  State<LawyerHearingsPage> createState() => _LawyerHearingsPageState();
}

class _LawyerHearingsPageState extends State<LawyerHearingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  String _dateFilter = 'yaklaşan';
  bool _isLoading = true;
  List<CourtDateModel> _hearings = [];
  List<CaseModel> _cases = [];
  List<LawyerClientModel> _clients = [];

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
        _loadHearings(user.uid),
        _loadCases(user.uid),
        _loadClients(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _hearings = results[0] as List<CourtDateModel>;
          _cases = results[1] as List<CaseModel>;
          _clients = results[2] as List<LawyerClientModel>;
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

  Future<List<CourtDateModel>> _loadHearings(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.courtDatesCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('durusmaTarihi', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => CourtDateModel.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
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

  List<CourtDateModel> get filteredHearings {
    List<CourtDateModel> filtered = _hearings;

    // Durum filtreleme
    if (_selectedFilter != 'tumu') {
      filtered = filtered
          .where((hearing) => hearing.durusmaDurumu == _selectedFilter)
          .toList();
    }

    // Tarih filtreleme
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'yaklaşan':
        filtered = filtered
            .where((hearing) => hearing.durusmaTarihi.isAfter(now))
            .toList();
        break;
      case 'geçmiş':
        filtered = filtered
            .where((hearing) => hearing.durusmaTarihi.isBefore(now))
            .toList();
        break;
      case 'bugün':
        filtered = filtered.where((hearing) => hearing.bugunDurusma).toList();
        break;
      case 'bu_hafta':
        filtered =
            filtered.where((hearing) => hearing.haftaIcindeKiDurusma).toList();
        break;
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((hearing) {
        final caseData = _cases.firstWhere(
          (c) => c.id == hearing.caseId,
          orElse: () => CaseModel(
            id: '',
            userId: '',
            createdAt: DateTime.now(),
            clientId: '',
            davaAdi: 'Dava Bulunamadı',
            davaKodu: '',
            davaTuru: '',
            mahkemeAdi: '',
          ),
        );

        return hearing.baslik
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            hearing.mahkemeAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            caseData.davaAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (hearing.hakim
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);
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
                : filteredHearings.isEmpty
                    ? _buildEmptyState()
                    : _buildHearingsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHearingDialog(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Duruşma'),
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
                  Icons.gavel,
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
                      'Duruşmalar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Mahkeme duruşmalarınızı yönetin',
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
              hintText: 'Duruşma, dava veya mahkeme ara...',
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
              'Tarih',
              _dateFilter,
              {
                'yaklaşan': 'Yaklaşan',
                'bugün': 'Bugün',
                'bu_hafta': 'Bu Hafta',
                'geçmiş': 'Geçmiş',
                'tumu': 'Tümü',
              },
              (value) => setState(() => _dateFilter = value),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              'Durum',
              _selectedFilter,
              {
                'tumu': 'Tümü',
                'bekliyor': 'Bekliyor',
                'tamamlandi': 'Tamamlandı',
                'ertelendi': 'Ertelendi',
                'iptal': 'İptal',
              },
              (value) => setState(() => _selectedFilter = value),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'tumu';
                  _dateFilter = 'yaklaşan';
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

  Widget _buildHearingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredHearings.length,
      itemBuilder: (context, index) {
        final hearing = filteredHearings[index];
        return _buildHearingCard(hearing);
      },
    );
  }

  Widget _buildHearingCard(CourtDateModel hearing) {
    final caseData = _cases.firstWhere(
      (c) => c.id == hearing.caseId,
      orElse: () => CaseModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        clientId: '',
        davaAdi: 'Dava Bulunamadı',
        davaKodu: '',
        davaTuru: '',
        mahkemeAdi: '',
      ),
    );

    final clientData = _clients.firstWhere(
      (c) => c.id == hearing.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

    final isUpcoming = hearing.durusmaTarihi.isAfter(DateTime.now());
    final isPast = hearing.durusmaTarihi.isBefore(DateTime.now());
    final isToday = hearing.bugunDurusma;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;

    switch (hearing.durusmaDurumu) {
      case 'bekliyor':
        statusColor =
            isToday ? Colors.orange : (isUpcoming ? Colors.blue : Colors.grey);
        statusIcon = isToday ? Icons.today : Icons.schedule;
        break;
      case 'tamamlandi':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ertelendi':
        statusColor = Colors.orange;
        statusIcon = Icons.update;
        break;
      case 'iptal':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
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
        onTap: () => _showHearingDetail(hearing),
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
                          hearing.baslik,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DurusmaDurumuConstants.getDurumDisplayName(
                              hearing.durusmaDurumu),
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BUGÜN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleHearingAction(value, hearing),
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
                        value: 'postpone',
                        child: Row(
                          children: [
                            Icon(Icons.update, size: 18),
                            const SizedBox(width: 8),
                            Text('Ertele'),
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
                      Icons.calendar_today,
                      'Tarih',
                      '${hearing.durusmaTarihi.day}/${hearing.durusmaTarihi.month}/${hearing.durusmaTarihi.year}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Saat',
                      '${hearing.durusmaSaati.hour.toString().padLeft(2, '0')}:${hearing.durusmaSaati.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.account_balance,
                      'Mahkeme',
                      hearing.mahkemeAdi,
                    ),
                  ),
                  if (hearing.salonNo.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.room,
                        'Salon',
                        hearing.salonNo,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.gavel,
                      'Dava',
                      caseData.davaAdi,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      'Müvekkil',
                      clientData.name,
                    ),
                  ),
                ],
              ),
              if (hearing.hazirlikNotlari != null &&
                  hearing.hazirlikNotlari!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hearing.hazirlikNotlari!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
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
              Icons.gavel_outlined,
              size: 48,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz duruşma yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk duruşmanızı ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddHearingDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Duruşmayı Ekle'),
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

  void _showAddHearingDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditHearingDialog(
        cases: _cases,
        clients: _clients,
        onSaved: () {
          _loadData();
          FeedbackUtils.showSuccess(context, 'Duruşma başarıyla eklendi');
        },
      ),
    );
  }

  void _showEditHearingDialog(CourtDateModel hearing) {
    showDialog(
      context: context,
      builder: (context) => _AddEditHearingDialog(
        hearing: hearing,
        cases: _cases,
        clients: _clients,
        onSaved: () {
          _loadData();
          FeedbackUtils.showSuccess(context, 'Duruşma başarıyla güncellendi');
        },
      ),
    );
  }

  void _showHearingDetail(CourtDateModel hearing) {
    showDialog(
      context: context,
      builder: (context) => _HearingDetailDialog(
        hearing: hearing,
        cases: _cases,
        clients: _clients,
        onEdit: () => _showEditHearingDialog(hearing),
      ),
    );
  }

  void _handleHearingAction(String action, CourtDateModel hearing) async {
    switch (action) {
      case 'edit':
        _showEditHearingDialog(hearing);
        break;
      case 'complete':
        await _updateHearingStatus(hearing, 'tamamlandi');
        break;
      case 'postpone':
        await _updateHearingStatus(hearing, 'ertelendi');
        break;
      case 'delete':
        await _deleteHearing(hearing);
        break;
    }
  }

  Future<void> _updateHearingStatus(
      CourtDateModel hearing, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.courtDatesCollection)
          .doc(hearing.id)
          .update({
        'durusmaDurumu': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadData();
      FeedbackUtils.showSuccess(context, 'Duruşma durumu güncellendi');
    } catch (e) {
      FeedbackUtils.showError(context, 'Güncelleme hatası: $e');
    }
  }

  Future<void> _deleteHearing(CourtDateModel hearing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duruşmayı Sil'),
        content: const Text('Bu duruşmayı silmek istediğinizden emin misiniz?'),
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
            .collection(AppConstants.courtDatesCollection)
            .doc(hearing.id)
            .update({
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _loadData();
        FeedbackUtils.showSuccess(context, 'Duruşma silindi');
      } catch (e) {
        FeedbackUtils.showError(context, 'Silme hatası: $e');
      }
    }
  }
}

// Duruşma Ekleme/Düzenleme Dialog'u
class _AddEditHearingDialog extends StatefulWidget {
  final CourtDateModel? hearing;
  final List<CaseModel> cases;
  final List<LawyerClientModel> clients;
  final VoidCallback onSaved;

  const _AddEditHearingDialog({
    this.hearing,
    required this.cases,
    required this.clients,
    required this.onSaved,
  });

  @override
  State<_AddEditHearingDialog> createState() => _AddEditHearingDialogState();
}

class _AddEditHearingDialogState extends State<_AddEditHearingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courtController = TextEditingController();
  final _roomController = TextEditingController();
  final _judgeController = TextEditingController();
  final _prosecutorController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCaseId;
  String? _selectedClientId;
  String _selectedType = 'hazirlik';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _reminderActive = true;
  int _reminderMinutes = 60;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.hearing != null) {
      _initializeFromHearing();
    }
  }

  void _initializeFromHearing() {
    final hearing = widget.hearing!;
    _titleController.text = hearing.baslik;
    _courtController.text = hearing.mahkemeAdi;
    _roomController.text = hearing.salonNo;
    _judgeController.text = hearing.hakim ?? '';
    _prosecutorController.text = hearing.savci ?? '';
    _notesController.text = hearing.hazirlikNotlari ?? '';
    _selectedCaseId = hearing.caseId;
    _selectedClientId = hearing.clientId;
    _selectedType = hearing.durusmaTuru;
    _selectedDate = hearing.durusmaTarihi;
    _selectedTime = hearing.durusmaSaati;
    _reminderActive = hearing.hatirlaticiAktif;
    _reminderMinutes = hearing.hatirlaticiSuresi;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courtController.dispose();
    _roomController.dispose();
    _judgeController.dispose();
    _prosecutorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
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
            widget.hearing == null ? Icons.add : Icons.edit,
            color: const Color(0xFF4F46E5),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.hearing == null ? 'Yeni Duruşma' : 'Duruşmayı Düzenle',
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
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Duruşma Başlığı *',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCaseId,
          decoration: const InputDecoration(
            labelText: 'Dava *',
            border: OutlineInputBorder(),
          ),
          items: widget.cases.map((caseData) {
            return DropdownMenuItem(
              value: caseData.id,
              child: Text(
                caseData.davaAdi,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCaseId = value;
              // Dava seçildiğinde müvekkili otomatik seç
              if (value != null) {
                final selectedCase =
                    widget.cases.firstWhere((c) => c.id == value);
                _selectedClientId = selectedCase.clientId;
              }
            });
          },
          validator: (value) => value == null ? 'Dava seçiniz' : null,
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
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Duruşma Türü *',
            border: OutlineInputBorder(),
          ),
          items: DurusmaTuruConstants.tumTurler.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(DurusmaTuruConstants.getTurDisplayName(type)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courtController,
          decoration: const InputDecoration(
            labelText: 'Mahkeme Adı *',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _roomController,
          decoration: const InputDecoration(
            labelText: 'Salon No',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _judgeController,
                decoration: const InputDecoration(
                  labelText: 'Hakim',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _prosecutorController,
                decoration: const InputDecoration(
                  labelText: 'Savcı',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Hazırlık Notları',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildReminderSettings(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tarih *',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Saat *',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hatırlatıcı Ayarları',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: _reminderActive,
              onChanged: (value) => setState(() => _reminderActive = value),
            ),
            const SizedBox(width: 8),
            const Text('Hatırlatıcı aktif'),
          ],
        ),
        if (_reminderActive) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _reminderMinutes,
            decoration: const InputDecoration(
              labelText: 'Hatırlatıcı Süresi',
              border: OutlineInputBorder(),
            ),
            items: [15, 30, 60, 120, 1440].map((minutes) {
              String label;
              if (minutes == 1440) {
                label = '1 gün önce';
              } else if (minutes >= 60) {
                label = '${minutes ~/ 60} saat önce';
              } else {
                label = '$minutes dakika önce';
              }
              return DropdownMenuItem(
                value: minutes,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) => setState(() => _reminderMinutes = value!),
          ),
        ],
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
          onPressed: _isLoading ? null : _saveHearing,
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
              : Text(widget.hearing == null ? 'Kaydet' : 'Güncelle'),
        ),
      ],
    );
  }

  Future<void> _saveHearing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      final hearingData = {
        'userId': user.uid,
        'caseId': _selectedCaseId!,
        'clientId': _selectedClientId!,
        'baslik': _titleController.text.trim(),
        'durusmaTarihi': Timestamp.fromDate(_selectedDate),
        'durusmaSaati': {
          'hour': _selectedTime.hour,
          'minute': _selectedTime.minute,
        },
        'mahkemeAdi': _courtController.text.trim(),
        'salonNo': _roomController.text.trim(),
        'durusmaTuru': _selectedType,
        'durusmaDurumu': widget.hearing?.durusmaDurumu ?? 'bekliyor',
        'hakim': _judgeController.text.trim().isNotEmpty
            ? _judgeController.text.trim()
            : null,
        'savci': _prosecutorController.text.trim().isNotEmpty
            ? _prosecutorController.text.trim()
            : null,
        'hazirlikNotlari': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'hatirlaticiAktif': _reminderActive,
        'hatirlaticiSuresi': _reminderMinutes,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.hearing == null) {
        hearingData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection(AppConstants.courtDatesCollection)
            .add(hearingData);
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.courtDatesCollection)
            .doc(widget.hearing!.id)
            .update(hearingData);
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

// Duruşma Detay Dialog'u
class _HearingDetailDialog extends StatelessWidget {
  final CourtDateModel hearing;
  final List<CaseModel> cases;
  final List<LawyerClientModel> clients;
  final VoidCallback onEdit;

  const _HearingDetailDialog({
    required this.hearing,
    required this.cases,
    required this.clients,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final caseData = cases.firstWhere(
      (c) => c.id == hearing.caseId,
      orElse: () => CaseModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        clientId: '',
        davaAdi: 'Dava Bulunamadı',
        davaKodu: '',
        davaTuru: '',
        mahkemeAdi: '',
      ),
    );

    final clientData = clients.firstWhere(
      (c) => c.id == hearing.clientId,
      orElse: () => LawyerClientModel(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        name: 'Müvekkil Bulunamadı',
        phone: '',
      ),
    );

    return Dialog(
      child: Container(
        width: 500,
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
                    Icons.gavel,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hearing.baslik,
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
            _buildDetailItem(
                'Durum',
                DurusmaDurumuConstants.getDurumDisplayName(
                    hearing.durusmaDurumu)),
            _buildDetailItem('Tür',
                DurusmaTuruConstants.getTurDisplayName(hearing.durusmaTuru)),
            _buildDetailItem('Tarih',
                '${hearing.durusmaTarihi.day}/${hearing.durusmaTarihi.month}/${hearing.durusmaTarihi.year}'),
            _buildDetailItem('Saat',
                '${hearing.durusmaSaati.hour.toString().padLeft(2, '0')}:${hearing.durusmaSaati.minute.toString().padLeft(2, '0')}'),
            _buildDetailItem('Mahkeme', hearing.mahkemeAdi),
            if (hearing.salonNo.isNotEmpty)
              _buildDetailItem('Salon', hearing.salonNo),
            _buildDetailItem('Dava', caseData.davaAdi),
            _buildDetailItem('Müvekkil', clientData.name),
            if (hearing.hakim != null)
              _buildDetailItem('Hakim', hearing.hakim!),
            if (hearing.savci != null)
              _buildDetailItem('Savcı', hearing.savci!),
            if (hearing.hazirlikNotlari != null &&
                hearing.hazirlikNotlari!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Hazırlık Notları:',
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
                  hearing.hazirlikNotlari!,
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
