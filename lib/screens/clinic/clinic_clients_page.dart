import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicClientsPage extends StatefulWidget {
  const ClinicClientsPage({super.key});

  @override
  State<ClinicClientsPage> createState() => _ClinicClientsPageState();
}

class _ClinicClientsPageState extends State<ClinicClientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<ClinicPatient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPatientsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final patients = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicPatient(
          id: doc.id,
          userId: user.uid,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'],
          tcNo: data['tcNo'],
          birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
          gender: data['gender'] ?? 'Kadın',
          address: data['address'],
          emergencyContact: data['emergencyContact'],
          medicalHistory: data['medicalHistory'],
          chronicDiseases: List<String>.from(data['chronicDiseases'] ?? []),
          bloodType: data['bloodType'],
          allergies: data['allergies'],
          notes: data['notes'],
          isVip: data['isVip'] ?? false,
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ClinicPatient> get filteredPatients {
    List<ClinicPatient> filtered = _patients;

    // Durum filtreleme
    if (_selectedFilter == 'vip') {
      filtered = filtered.where((patient) => patient.isVip).toList();
    } else if (_selectedFilter == 'aktif') {
      filtered = filtered.where((patient) => patient.isActive).toList();
    } else if (_selectedFilter == 'pasif') {
      filtered = filtered.where((patient) => !patient.isActive).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((patient) =>
              patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              patient.phone.contains(_searchQuery) ||
              (patient.tcNo?.contains(_searchQuery) ?? false) ||
              (patient.email
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Üst başlık ve yeni danışan butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hastalar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPatientDialog(),
                  icon: const Icon(Icons.person_add,
                      size: 18, color: Colors.white),
                  label: const Text('Yeni Hasta',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hasta ara (İsim, Telefon, TC No)',
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
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide:
                      BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtre butonları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', 'tumu'),
                  _buildFilterChip('VIP', 'vip'),
                  _buildFilterChip('Aktif', 'aktif'),
                  _buildFilterChip('Pasif', 'pasif'),
                ],
              ),
            ),
          ),

          // Danışan listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
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
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: AppConstants.surfaceColor,
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

  Widget _buildPatientCard(ClinicPatient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _showPatientDetail(patient),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - İsim ve etiketler
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (patient.isVip) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall,
                        vertical: AppConstants.paddingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSmall,
                      vertical: AppConstants.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: (patient.isActive ? Colors.green : Colors.grey)
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadiusSmall),
                      border: Border.all(
                        color: patient.isActive ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      patient.isActive ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        color: patient.isActive ? Colors.green : Colors.grey,
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
                        _buildInfoRow(Icons.phone, patient.phone),
                        if (patient.tcNo != null)
                          _buildInfoRow(Icons.badge, 'TC: ${patient.tcNo}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.person, patient.gender),
                        if (patient.birthDate != null)
                          _buildInfoRow(Icons.cake,
                              'Yaş: ${_calculateAge(patient.birthDate!)}'),
                      ],
                    ),
                  ),
                ],
              ),

              // Tıbbi bilgiler
              if (patient.bloodType != null ||
                  patient.allergies != null ||
                  patient.medicalHistory != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Divider(color: AppConstants.borderColor),
                const SizedBox(height: AppConstants.paddingSmall),
                if (patient.bloodType != null)
                  _buildInfoRow(
                      Icons.bloodtype, 'Kan Grubu: ${patient.bloodType}'),
                if (patient.allergies != null && patient.allergies!.isNotEmpty)
                  _buildInfoRow(Icons.warning, 'Alerji: ${patient.allergies}'),
                if (patient.medicalHistory != null &&
                    patient.medicalHistory!.isNotEmpty)
                  _buildInfoRow(Icons.medical_services,
                      'Tıbbi Geçmiş: ${patient.medicalHistory}'),
              ],

              // Alt satır - Tarihler ve işlemler
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kayıt: ${_formatDate(patient.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditPatientDialog(patient),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, size: 20),
                        onPressed: () => _callPatient(patient.phone),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, size: 20),
                        onPressed: () => _scheduleAppointment(patient),
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
        ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
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
            Icons.people_outline,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun hasta bulunamadı'
                : 'Henüz hasta eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk hastanızı eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditPatientDialog(
        onSaved: _loadPatients,
      ),
    );
  }

  void _showEditPatientDialog(ClinicPatient patient) {
    showDialog(
      context: context,
      builder: (context) => _AddEditPatientDialog(
        patient: patient,
        onSaved: _loadPatients,
      ),
    );
  }

  void _showPatientDetail(ClinicPatient patient) {
    // Hasta detay sayfası
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Telefon: ${patient.phone}'),
              if (patient.tcNo != null) Text('TC No: ${patient.tcNo}'),
              if (patient.email != null) Text('Email: ${patient.email}'),
              Text('Cinsiyet: ${patient.gender}'),
              if (patient.birthDate != null)
                Text('Yaş: ${_calculateAge(patient.birthDate!)}'),
              if (patient.bloodType != null)
                Text('Kan Grubu: ${patient.bloodType}'),
              if (patient.allergies != null)
                Text('Alerji: ${patient.allergies}'),
              if (patient.address != null) Text('Adres: ${patient.address}'),
              if (patient.emergencyContact != null)
                Text('Acil Durum: ${patient.emergencyContact}'),
              if (patient.medicalHistory != null)
                Text('Tıbbi Geçmiş: ${patient.medicalHistory}'),
              if (patient.notes != null) Text('Notlar: ${patient.notes}'),
            ],
          ),
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

  void _callPatient(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phoneNumber aranıyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scheduleAppointment(ClinicPatient patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${patient.name} için randevu oluşturuluyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Hasta modeli
class ClinicPatient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? tcNo;
  final DateTime? birthDate;
  final String gender;
  final String? address;
  final String? emergencyContact;
  final String? medicalHistory;
  final List<String> chronicDiseases;
  final String? bloodType;
  final String? allergies;
  final String? notes;
  final bool isVip;
  final bool isActive;
  final DateTime createdAt;

  ClinicPatient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.tcNo,
    this.birthDate,
    required this.gender,
    this.address,
    this.emergencyContact,
    this.medicalHistory,
    this.chronicDiseases = const [],
    this.bloodType,
    this.allergies,
    this.notes,
    required this.isVip,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'tcNo': tcNo,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'address': address,
      'emergencyContact': emergencyContact,
      'medicalHistory': medicalHistory,
      'chronicDiseases': chronicDiseases,
      'bloodType': bloodType,
      'allergies': allergies,
      'notes': notes,
      'isVip': isVip,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Hasta ekleme/düzenleme dialog'u
class _AddEditPatientDialog extends StatefulWidget {
  final ClinicPatient? patient;
  final VoidCallback onSaved;

  const _AddEditPatientDialog({
    this.patient,
    required this.onSaved,
  });

  @override
  State<_AddEditPatientDialog> createState() => _AddEditPatientDialogState();
}

class _AddEditPatientDialogState extends State<_AddEditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tcNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Kadın';
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;
  bool _isVip = false;
  bool _isActive = true;
  bool _isLoading = false;
  List<String> _chronicDiseases = [];

  bool get isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadPatientData();
    }
  }

  void _loadPatientData() {
    final patient = widget.patient!;
    _nameController.text = patient.name;
    _phoneController.text = patient.phone;
    _emailController.text = patient.email ?? '';
    _tcNoController.text = patient.tcNo ?? '';
    _addressController.text = patient.address ?? '';
    _emergencyContactController.text = patient.emergencyContact ?? '';
    _medicalHistoryController.text = patient.medicalHistory ?? '';
    _allergiesController.text = patient.allergies ?? '';
    _notesController.text = patient.notes ?? '';
    _selectedGender = patient.gender;
    _selectedBloodType = patient.bloodType;
    _selectedBirthDate = patient.birthDate;
    _isVip = patient.isVip;
    _isActive = patient.isActive;
    _chronicDiseases = List.from(patient.chronicDiseases);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Text(
                      isEditing ? 'Hasta Düzenle' : 'Yeni Hasta Ekle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Ad Soyad
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ad soyad gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Telefon
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefon *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Telefon gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // TC No
                      TextFormField(
                        controller: _tcNoController,
                        decoration: const InputDecoration(
                          labelText: 'TC Kimlik No',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          // Cinsiyet
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Cinsiyet',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: ['Kadın', 'Erkek'].map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGender = value!);
                              },
                            ),
                          ),

                          const SizedBox(width: AppConstants.paddingMedium),

                          // Doğum Tarihi
                          Expanded(
                            child: InkWell(
                              onTap: _selectBirthDate,
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadiusSmall),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cake, color: Colors.grey),
                                    const SizedBox(
                                        width: AppConstants.paddingMedium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Doğum Tarihi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _selectedBirthDate != null
                                                ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                                : 'Tarih seçin',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Kan Grubu
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: const InputDecoration(
                          labelText: 'Kan Grubu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.bloodtype),
                        ),
                        items: [
                          'A Rh+',
                          'A Rh-',
                          'B Rh+',
                          'B Rh-',
                          'AB Rh+',
                          'AB Rh-',
                          '0 Rh+',
                          '0 Rh-'
                        ].map((bloodType) {
                          return DropdownMenuItem(
                            value: bloodType,
                            child: Text(bloodType),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBloodType = value);
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Alerjiler
                      TextFormField(
                        controller: _allergiesController,
                        decoration: const InputDecoration(
                          labelText: 'Alerjiler',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Adres
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adres',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Acil Durum İletişim
                      TextFormField(
                        controller: _emergencyContactController,
                        decoration: const InputDecoration(
                          labelText: 'Acil Durum İletişim',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.emergency),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tıbbi Geçmiş
                      TextFormField(
                        controller: _medicalHistoryController,
                        decoration: const InputDecoration(
                          labelText: 'Tıbbi Geçmiş',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Notlar
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notlar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Durum Kontrolleri
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('VIP Hasta'),
                              value: _isVip,
                              onChanged: (value) {
                                setState(() => _isVip = value ?? false);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Aktif'),
                              value: _isActive,
                              onChanged: (value) {
                                setState(() => _isActive = value ?? true);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Güncelle' : 'Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final patientData = ClinicPatient(
        id: isEditing
            ? widget.patient!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        tcNo: _tcNoController.text.trim().isEmpty
            ? null
            : _tcNoController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        medicalHistory: _medicalHistoryController.text.trim().isEmpty
            ? null
            : _medicalHistoryController.text.trim(),
        chronicDiseases: _chronicDiseases,
        bloodType: _selectedBloodType,
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isVip: _isVip,
        isActive: _isActive,
        createdAt: isEditing ? widget.patient!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicPatientsCollection)
            .doc(widget.patient!.id)
            .update(patientData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicPatientsCollection)
            .doc(patientData.id)
            .set(patientData.toMap());
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Hasta başarıyla güncellendi'
              : 'Hasta başarıyla eklendi'),
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
