import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicTreatmentsPage extends StatefulWidget {
  const ClinicTreatmentsPage({super.key});

  @override
  State<ClinicTreatmentsPage> createState() => _ClinicTreatmentsPageState();
}

class _ClinicTreatmentsPageState extends State<ClinicTreatmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<ClinicTreatment> _treatments = [];
  List<ClinicPatient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadTreatments(),
      _loadPatients(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadTreatments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicTreatmentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('treatmentDate', descending: true)
          .get();

      final treatments = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicTreatment(
          id: doc.id,
          userId: user.uid,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? '',
          treatmentType: data['treatmentType'] ?? '',
          description: data['description'] ?? '',
          employeeName: data['employeeName'] ?? '',
          treatmentDate: (data['treatmentDate'] as Timestamp).toDate(),
          price: (data['price'] ?? 0.0).toDouble(),
          isCompleted: data['isCompleted'] ?? false,
          isPaid: data['isPaid'] ?? false,
          notes: data['notes'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _treatments = treatments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tedavileri yüklerken hata: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPatientsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final patients = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicPatient(
          id: doc.id,
          userId: user.uid,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          isVip: data['isVip'] ?? false,
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _patients = patients);
    } catch (e) {
      if (kDebugMode) debugPrint('Hastaları yüklerken hata: $e');
    }
  }

  List<ClinicTreatment> get filteredTreatments {
    List<ClinicTreatment> filtered = _treatments;

    // Durum filtreleme
    if (_selectedFilter == 'tamamlanan') {
      filtered = filtered.where((treatment) => treatment.isCompleted).toList();
    } else if (_selectedFilter == 'devam_eden') {
      filtered = filtered.where((treatment) => !treatment.isCompleted).toList();
    } else if (_selectedFilter == 'odenen') {
      filtered = filtered.where((treatment) => treatment.isPaid).toList();
    } else if (_selectedFilter == 'odenmemiş') {
      filtered = filtered.where((treatment) => !treatment.isPaid).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((treatment) =>
              treatment.patientName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              treatment.treatmentType
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              treatment.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
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
          // Üst başlık ve yeni tedavi butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tedavi & İşlemler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTreatmentDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni Tedavi',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
                hintText: 'Tedavi ara (Hasta adı, tedavi türü, açıklama)',
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
                  _buildFilterChip('Tamamlanan', 'tamamlanan'),
                  _buildFilterChip('Devam Eden', 'devam_eden'),
                  _buildFilterChip('Ödenen', 'odenen'),
                  _buildFilterChip('Ödenmemiş', 'odenmemiş'),
                ],
              ),
            ),
          ),

          // Tedavi listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTreatments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredTreatments.length,
                        itemBuilder: (context, index) {
                          final treatment = filteredTreatments[index];
                          return _buildTreatmentCard(treatment);
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
          setState(() => _selectedFilter = value);
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

  Widget _buildTreatmentCard(ClinicTreatment treatment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _showTreatmentDetail(treatment),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Hasta adı ve durum etiketleri
              Row(
                children: [
                  Expanded(
                    child: Text(
                      treatment.patientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      if (treatment.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('Tamamlandı',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 10)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              (treatment.isPaid ? Colors.blue : Colors.orange)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: treatment.isPaid
                                  ? Colors.blue
                                  : Colors.orange),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              treatment.isPaid
                                  ? Icons.payment
                                  : Icons.payment_outlined,
                              size: 12,
                              color: treatment.isPaid
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              treatment.isPaid ? 'Ödendi' : 'Ödenmedi',
                              style: TextStyle(
                                color: treatment.isPaid
                                    ? Colors.blue
                                    : Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Tedavi türü
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  treatment.treatmentType,
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Açıklama
              Text(
                treatment.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Alt satır - Bilgiler ve işlemler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              treatment.employeeName,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(treatment.treatmentDate),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${treatment.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!treatment.isCompleted)
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _updateTreatmentStatus(
                                  treatment, 'completed'),
                              tooltip: 'Tamamla',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          if (!treatment.isPaid)
                            IconButton(
                              icon:
                                  const Icon(Icons.payment, color: Colors.blue),
                              onPressed: () =>
                                  _updateTreatmentStatus(treatment, 'paid'),
                              tooltip: 'Ödendi İşaretle',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () =>
                                _showEditTreatmentDialog(treatment),
                            tooltip: 'Düzenle',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun tedavi bulunamadı'
                : 'Henüz tedavi kaydı eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk tedavi kaydınızı eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditTreatmentDialog(
        patients: _patients,
        onSaved: _loadTreatments,
      ),
    );
  }

  void _showEditTreatmentDialog(ClinicTreatment treatment) {
    showDialog(
      context: context,
      builder: (context) => _AddEditTreatmentDialog(
        treatment: treatment,
        patients: _patients,
        onSaved: _loadTreatments,
      ),
    );
  }

  void _showTreatmentDetail(ClinicTreatment treatment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(treatment.patientName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tedavi Türü: ${treatment.treatmentType}'),
              Text('Açıklama: ${treatment.description}'),
              Text('Uygulayan: ${treatment.employeeName}'),
              Text('Tarih: ${_formatDate(treatment.treatmentDate)}'),
              Text('Ücret: ₺${treatment.price.toStringAsFixed(0)}'),
              Text(
                  'Durum: ${treatment.isCompleted ? 'Tamamlandı' : 'Devam Ediyor'}'),
              Text('Ödeme: ${treatment.isPaid ? 'Ödendi' : 'Ödenmedi'}'),
              if (treatment.notes != null) Text('Notlar: ${treatment.notes}'),
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

  Future<void> _updateTreatmentStatus(
      ClinicTreatment treatment, String type) async {
    try {
      Map<String, dynamic> updateData = {};

      if (type == 'completed') {
        updateData['isCompleted'] = true;
      } else if (type == 'paid') {
        updateData['isPaid'] = true;
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.clinicTreatmentsCollection)
          .doc(treatment.id)
          .update(updateData);

      await _loadTreatments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tedavi ${type == 'completed' ? 'tamamlandı' : 'ödendi'} olarak işaretlendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// Model sınıfları
class ClinicTreatment {
  final String id;
  final String userId;
  final String patientId;
  final String patientName;
  final String treatmentType;
  final String description;
  final String employeeName;
  final DateTime treatmentDate;
  final double price;
  final bool isCompleted;
  final bool isPaid;
  final String? notes;
  final DateTime createdAt;

  ClinicTreatment({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.treatmentType,
    required this.description,
    required this.employeeName,
    required this.treatmentDate,
    required this.price,
    required this.isCompleted,
    required this.isPaid,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'patientName': patientName,
      'treatmentType': treatmentType,
      'description': description,
      'employeeName': employeeName,
      'treatmentDate': Timestamp.fromDate(treatmentDate),
      'price': price,
      'isCompleted': isCompleted,
      'isPaid': isPaid,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ClinicPatient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final bool isVip;
  final bool isActive;
  final DateTime createdAt;

  ClinicPatient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.isVip,
    required this.isActive,
    required this.createdAt,
  });
}

// Tedavi ekleme/düzenleme dialog'u
class _AddEditTreatmentDialog extends StatefulWidget {
  final ClinicTreatment? treatment;
  final List<ClinicPatient> patients;
  final VoidCallback onSaved;

  const _AddEditTreatmentDialog({
    this.treatment,
    required this.patients,
    required this.onSaved,
  });

  @override
  State<_AddEditTreatmentDialog> createState() =>
      _AddEditTreatmentDialogState();
}

class _AddEditTreatmentDialogState extends State<_AddEditTreatmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _treatmentTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  DateTime _selectedDate = DateTime.now();
  bool _isCompleted = false;
  bool _isPaid = false;
  bool _isLoading = false;

  final List<String> _treatmentTypes = [
    'Muayene',
    'Konsültasyon',
    'Tedavi',
    'Kontrol',
    'Ameliyat',
    'Test',
    'Fizyoterapi',
    'Rehabilitasyon',
    'Diğer',
  ];

  bool get isEditing => widget.treatment != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadTreatmentData();
    } else {
      _priceController.text = '0';
    }
  }

  void _loadTreatmentData() {
    final treatment = widget.treatment!;
    _selectedPatientId = treatment.patientId;
    _treatmentTypeController.text = treatment.treatmentType;
    _descriptionController.text = treatment.description;
    _employeeNameController.text = treatment.employeeName;
    _selectedDate = treatment.treatmentDate;
    _priceController.text = treatment.price.toStringAsFixed(0);
    _isCompleted = treatment.isCompleted;
    _isPaid = treatment.isPaid;
    _notesController.text = treatment.notes ?? '';
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
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child:
                        const Icon(Icons.medical_services, color: Colors.teal),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Text(
                      isEditing ? 'Tedavi Düzenle' : 'Yeni Tedavi',
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
                      // Hasta seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedPatientId,
                        decoration: const InputDecoration(
                          labelText: 'Hasta *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: widget.patients.map((patient) {
                          return DropdownMenuItem(
                            value: patient.id,
                            child: Row(
                              children: [
                                Expanded(child: Text(patient.name)),
                                if (patient.isVip)
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPatientId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Hasta seçimi gerekli' : null,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tedavi türü
                      DropdownButtonFormField<String>(
                        value: _treatmentTypes
                                .contains(_treatmentTypeController.text)
                            ? _treatmentTypeController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Tedavi Türü *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        items: _treatmentTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(
                              () => _treatmentTypeController.text = value!);
                        },
                        validator: (value) =>
                            value == null ? 'Tedavi türü gerekli' : null,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Açıklama
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Açıklama gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Uygulayan kişi
                      TextFormField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Uygulayan Kişi *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Uygulayan kişi gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          // Tarih seçimi
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
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
                                    const Icon(Icons.calendar_today,
                                        color: Colors.grey),
                                    const SizedBox(
                                        width: AppConstants.paddingMedium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tedavi Tarihi',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          Text(
                                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: AppConstants.paddingMedium),

                          // Ücret
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Ücret (₺) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ücret gerekli';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Geçerli bir ücret girin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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

                      // Durumlar
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Tedavi Tamamlandı'),
                              value: _isCompleted,
                              onChanged: (value) {
                                setState(() => _isCompleted = value ?? false);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Ücret Ödendi'),
                              value: _isPaid,
                              onChanged: (value) {
                                setState(() => _isPaid = value ?? false);
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
                      onPressed: _isLoading ? null : _saveTreatment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTreatment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hasta seçimi gerekli'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final patient =
          widget.patients.firstWhere((p) => p.id == _selectedPatientId);

      final treatmentData = ClinicTreatment(
        id: isEditing
            ? widget.treatment!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        patientId: patient.id,
        patientName: patient.name,
        treatmentType: _treatmentTypeController.text.trim(),
        description: _descriptionController.text.trim(),
        employeeName: _employeeNameController.text.trim(),
        treatmentDate: _selectedDate,
        price: double.parse(_priceController.text.trim()),
        isCompleted: _isCompleted,
        isPaid: _isPaid,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: isEditing ? widget.treatment!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicTreatmentsCollection)
            .doc(widget.treatment!.id)
            .update(treatmentData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicTreatmentsCollection)
            .doc(treatmentData.id)
            .set(treatmentData.toMap());
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Tedavi başarıyla güncellendi'
              : 'Tedavi başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
