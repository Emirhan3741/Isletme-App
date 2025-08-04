import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/education_teacher_model.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class EducationTeachersPage extends StatefulWidget {
  const EducationTeachersPage({super.key});

  @override
  State<EducationTeachersPage> createState() => _EducationTeachersPageState();
}

class _EducationTeachersPageState extends State<EducationTeachersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<EducationTeacher> _teachers = [];
  List<EducationTeacher> _filteredTeachers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'tümü';
  String _selectedSpecialtyFilter = 'tümü';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
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
    _filteredTeachers = _teachers.where((teacher) {
      // Arama filtresi
      final matchesSearch = _searchQuery.isEmpty ||
          teacher.tamIsim.toLowerCase().contains(_searchQuery) ||
          teacher.uzmanlikAlanlariStr.toLowerCase().contains(_searchQuery) ||
          teacher.telefon.contains(_searchQuery) ||
          (teacher.email?.toLowerCase().contains(_searchQuery) ?? false);

      // Durum filtresi
      final matchesStatus = _selectedStatusFilter == 'tümü' ||
          teacher.status == _selectedStatusFilter;

      // Uzmanlık filtresi
      final matchesSpecialty = _selectedSpecialtyFilter == 'tümü' ||
          teacher.uzmanlikAlanlari.contains(_selectedSpecialtyFilter);

      return matchesSearch && matchesStatus && matchesSpecialty;
    }).toList();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('education_teachers')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final teachers = snapshot.docs.map((doc) {
        final data = doc.data();
        return EducationTeacher(
          id: doc.id,
          userId: data['userId'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          ad: data['ad'] ?? '',
          soyad: data['soyad'] ?? '',
          telefon: data['telefon'] ?? '',
          email: data['email'] ?? '',
          uzmanlikAlanlari: List<String>.from(data['uzmanlikAlanlari'] ?? []),
          egitimDurumu: data['egitimDurumu'] ?? '',
          mezunOkul: data['mezunOkul'] ?? '',
          deneyimYili: data['deneyimYili'] ?? 0,
          status: data['status'] ?? 'active',
          saatlikUcret: (data['saatlikUcret'] ?? 0.0).toDouble(),
          iseBaslamaTarihi: data['iseBaslamaTarihi'] != null
              ? (data['iseBaslamaTarihi'] as Timestamp).toDate()
              : DateTime.now(),
          tamZamanli: data['tamZamanli'] ?? true,
          calismaGunleri: List<String>.from(data['calismaGunleri'] ?? []),
          calismaBaslangicSaati: data['calismaBaslangicSaati'] ?? '09:00',
          calismaBitisSaati: data['calismaBitisSaati'] ?? '17:00',
        );
      }).toList();

      setState(() {
        _teachers = teachers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Öğretmenler yüklenirken hata: $e');
      setState(() {
        _teachers = [];
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTeacherDialog(
        onTeacherAdded: () => _loadTeachers(),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTeachers.isEmpty
                    ? _buildEmptyState()
                    : _buildTeachersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        backgroundColor: const Color(0xFF667EEA),
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
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school,
              color: Color(0xFF667EEA),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öğretmenler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Öğretmen kadronuzu yönetin',
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
                    hintText: 'Öğretmen ara... (isim, uzmanlık, telefon)',
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
                onPressed: _showAddTeacherDialog,
                icon: const Icon(Icons.add),
                label: const Text('Öğretmen Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            'Durum',
            _selectedStatusFilter,
            ['tümü', 'active', 'inactive', 'on_leave', 'terminated'],
            (value) {
              setState(() {
                _selectedStatusFilter = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Uzmanlık',
            _selectedSpecialtyFilter,
            ['tümü', 'Matematik', 'İngilizce', 'Türkçe', 'Müzik', 'Fizik'],
            (value) {
              setState(() {
                _selectedSpecialtyFilter = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedStatusFilter = 'tümü';
                _selectedSpecialtyFilter = 'tümü';
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
            ? const Color(0xFF667EEA).withValues(alpha: 0.1)
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
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Pasif';
      case 'on_leave':
        return 'İzinli';
      case 'terminated':
        return 'Ayrıldı';
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
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school,
              size: 64,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz öğretmen yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk öğretmeninizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTeacherDialog,
            icon: const Icon(Icons.add),
            label: const Text('İlk Öğretmeni Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
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

  Widget _buildTeachersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredTeachers.length,
      itemBuilder: (context, index) {
        return _buildTeacherCard(_filteredTeachers[index]);
      },
    );
  }

  Widget _buildTeacherCard(EducationTeacher teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: teacher.statusColor.withValues(alpha: 0.2),
          width: 2,
        ),
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
                backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
                child: Text(
                  teacher.tamIsim
                      .split(' ')
                      .map((word) => word[0])
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA),
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
                            teacher.tamIsim,
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
                            color: teacher.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(teacher.statusEmoji),
                              const SizedBox(width: 4),
                              Text(
                                teacher.statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: teacher.statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher.uzmanlikAlanlariStr,
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
          // Öğretmen detay bilgileri
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.school,
                  'Deneyim',
                  teacher.deneyimAciklama,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  Icons.access_time,
                  'Çalışma',
                  teacher.calismaTipi,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  Icons.payments,
                  'Saatlik Ücret',
                  teacher.saatlikUcret != null
                      ? '₺${teacher.saatlikUcret!.toStringAsFixed(0)}'
                      : 'Belirtilmemiş',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // İletişim bilgileri
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                teacher.telefon,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(width: 24),
              if (teacher.email != null) ...[
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacher.email!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Çalışma günleri
          if (teacher.calismaGunleri.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Çalışma Günleri: ${teacher.calismaGunleriStr}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (teacher.calismaBaslangicSaati != null &&
              teacher.calismaBitisSaati != null) ...[
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Çalışma Saatleri: ${teacher.calismaBaslangicSaati} - ${teacher.calismaBitisSaati}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // İşlemler
          Row(
            children: [
              Text(
                'İşe Başlama: ${DateFormat('dd/MM/yyyy').format(teacher.iseBaslamaTarihi)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              // TODO: Düzenle butonu
              IconButton(
                onPressed: () => _showEditTeacherDialog(teacher),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Düzenle',
              ),
              // TODO: Detay görüntüle butonu
              IconButton(
                onPressed: () => _showTeacherDetails(teacher),
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'Detayları Görüntüle',
              ),
              // TODO: Sil butonu
              IconButton(
                onPressed: () => _showDeleteConfirmation(teacher),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
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

  // TODO: Öğretmen düzenleme dialog'u
  void _showEditTeacherDialog(EducationTeacher teacher) {
    FeedbackUtils.showInfo(
        context, 'Öğretmen düzenleme özelliği yakında eklenecek');
  }

  // TODO: Öğretmen detay görüntüleme
  void _showTeacherDetails(EducationTeacher teacher) {
    FeedbackUtils.showInfo(
        context, 'Öğretmen detay görüntüleme özelliği yakında eklenecek');
  }

  // TODO: Öğretmen silme onayı
  void _showDeleteConfirmation(EducationTeacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğretmeni Sil'),
        content: Text(
            '${teacher.tamIsim} öğretmenini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Firebase silme işlemi
              FeedbackUtils.showSuccess(context, 'Öğretmen başarıyla silindi');
              _loadTeachers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _AddTeacherDialog extends StatefulWidget {
  final VoidCallback onTeacherAdded;

  const _AddTeacherDialog({required this.onTeacherAdded});

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _educationController = TextEditingController();
  final _schoolController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  // Eksik controller'lar eklendi
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String _selectedStatus = 'active';
  final String _selectedEducationLevel = 'lisans'; // Eksik değişken eklendi
  int _experienceYears = 0;
  bool _isFullTime = true;
  final List<String> _selectedSpecialties = [];
  final List<String> _selectedWorkingDays = [];
  List<String> _workingDays = []; // Eksik değişken eklendi
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  DateTime _startDate = DateTime.now(); // Eksik değişken eklendi
  bool _isLoading = false;

  final List<String> _availableSpecialties = [
    'Matematik',
    'İngilizce',
    'Türkçe',
    'Müzik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
    'Resim',
    'Beden Eğitimi'
  ];

  final List<String> _weekDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _educationController.dispose();
    _schoolController.dispose();
    _hourlyRateController.dispose();
    // Yeni controller'lar da dispose edildi
    _nameController.dispose();
    _surnameController.dispose();
    _experienceController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialties.isEmpty) {
      FeedbackUtils.showError(context, 'En az bir uzmanlık alanı seçmelisiniz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final teacher = {
        'userId': user.uid,
        'ad': _nameController.text.trim(),
        'soyad': _surnameController.text.trim(),
        'telefon': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'uzmanlikAlanlari': _selectedSpecialties,
        'egitimDurumu': _selectedEducationLevel,
        'mezunOkul': _schoolController.text.trim(),
        'deneyimYili': int.tryParse(_experienceController.text.trim()) ?? 0,
        'status': 'active',
        'saatlikUcret':
            double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
        'iseBaslamaTarihi': Timestamp.fromDate(_startDate),
        'tamZamanli': _isFullTime,
        'calismaGunleri': _workingDays,
        'calismaBaslangicSaati': _startTimeController.text.trim(),
        'calismaBitisSaati': _endTimeController.text.trim(),
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('education_teachers')
          .add(teacher);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Öğretmen başarıyla eklendi');
        widget.onTeacherAdded();
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
            color: const Color(0xFF667EEA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_add,
            color: Color(0xFF667EEA),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Yeni Öğretmen Ekle',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kişisel bilgiler
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon *',
                  hintText: '0532 123 45 67',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateEmail,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Eğitim bilgileri
        const Text(
          'Eğitim Bilgileri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Eğitim Durumu',
                  hintText: 'Lisans, Yüksek Lisans, Doktora',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _experienceYears,
                decoration: const InputDecoration(
                  labelText: 'Deneyim (Yıl)',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(21, (index) => index).map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year == 0 ? 'Yeni başlayan' : '$year yıl'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _experienceYears = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _schoolController,
          decoration: const InputDecoration(
            labelText: 'Mezun Olduğu Okul',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // Uzmanlık alanları
        const Text(
          'Uzmanlık Alanları *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSpecialties.map((specialty) {
            final isSelected = _selectedSpecialties.contains(specialty);
            return FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecialties.add(specialty);
                  } else {
                    _selectedSpecialties.remove(specialty);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Çalışma bilgileri
        const Text(
          'Çalışma Bilgileri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  const DropdownMenuItem(
                      value: 'inactive', child: Text('Pasif')),
                  const DropdownMenuItem(
                      value: 'on_leave', child: Text('İzinli')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saatlik Ücret (₺)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Tam Zamanlı'),
          subtitle: Text(
              _isFullTime ? 'Tam zamanlı çalışan' : 'Yarı zamanlı çalışan'),
          value: _isFullTime,
          onChanged: (value) => setState(() => _isFullTime = value),
        ),
        const SizedBox(height: 16),
        // Çalışma günleri
        const Text('Çalışma Günleri'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final isSelected = _selectedWorkingDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWorkingDays.add(day);
                  } else {
                    _selectedWorkingDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Çalışma saatleri
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() => _startTime = time);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç Saati',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (time != null) {
                    setState(() => _endTime = time);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bitiş Saati',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                      '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ),
          ],
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
          onPressed: _isLoading ? null : _saveTeacher,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
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
