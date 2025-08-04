import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';

class ClinicDocumentsPage extends StatefulWidget {
  const ClinicDocumentsPage({super.key});

  @override
  State<ClinicDocumentsPage> createState() => _ClinicDocumentsPageState();
}

class _ClinicDocumentsPageState extends State<ClinicDocumentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<ClinicDocument> _documents = [];
  List<ClinicPatient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDocuments(),
      _loadPatients(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadDocuments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicDocumentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('uploadDate', descending: true)
          .get();

      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicDocument(
          id: doc.id,
          userId: user.uid,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? '',
          fileName: data['fileName'] ?? '',
          fileType: data['fileType'] ?? '',
          fileSize: data['fileSize'] ?? 0,
          fileUrl: data['fileUrl'] ?? '',
          category: data['category'] ?? '',
          description: data['description'] ?? '',
          uploadDate: (data['uploadDate'] as Timestamp).toDate(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _documents = documents);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Belgeleri yüklerken hata: $e'),
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
          email: data['email'] ?? '',
          tcNo: data['tcNo'] ?? '',
          birthDate: data['birthDate'] != null
              ? (data['birthDate'] as Timestamp).toDate()
              : null,
          gender: data['gender'] ?? '',
          address: data['address'] ?? '',
          emergencyContact: data['emergencyContact'] ?? '',
          emergencyPhone: data['emergencyPhone'] ?? '',
          bloodType: data['bloodType'] ?? '',
          allergies: data['allergies'] ?? '',
          chronicDiseases: data['chronicDiseases'] ?? '',
          medications: data['medications'] ?? '',
          medicalHistory: data['medicalHistory'] ?? '',
          notes: data['notes'] ?? '',
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

  List<ClinicDocument> get filteredDocuments {
    List<ClinicDocument> filtered = _documents;

    // Kategori filtreleme
    if (_selectedFilter != 'tumu') {
      filtered =
          filtered.where((doc) => doc.category == _selectedFilter).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((doc) =>
              doc.patientName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doc.description
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
          // Üst başlık ve yeni belge yükleme butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Belgeler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUploadDocumentDialog(),
                  icon: const Icon(Icons.upload_file,
                      size: 18, color: Colors.white),
                  label: const Text('Belge Yükle',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
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
                hintText: 'Belge ara (Hasta adı, dosya adı, açıklama)',
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
                  _buildFilterChip('Tıbbi Rapor', 'tibbi_rapor'),
                  _buildFilterChip('Test Sonucu', 'test_sonucu'),
                  _buildFilterChip('Reçete', 'recete'),
                  _buildFilterChip('Görüntüleme', 'goruntuleme'),
                  _buildFilterChip('Diğer', 'diger'),
                ],
              ),
            ),
          ),

          // Belge listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final document = filteredDocuments[index];
                          return _buildDocumentCard(document);
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

  Widget _buildDocumentCard(ClinicDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _viewDocument(document),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Hasta adı ve kategori
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(document.category)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(document.category),
                            color: _getCategoryColor(document.category),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.patientName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                document.fileName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppConstants.textSecondary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(document.category)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _getCategoryColor(document.category)),
                    ),
                    child: Text(
                      _getCategoryLabel(document.category),
                      style: TextStyle(
                        color: _getCategoryColor(document.category),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Açıklama
              if (document.description.isNotEmpty)
                Text(
                  document.description,
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
                            const Icon(Icons.schedule,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(document.uploadDate),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.storage,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formatFileSize(document.fileSize),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _viewDocument(document),
                        tooltip: 'Görüntüle',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () => _downloadDocument(document),
                        tooltip: 'İndir',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDocument(document),
                        tooltip: 'Sil',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun belge bulunamadı'
                : 'Henüz belge yüklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk belgenizi yüklemek için "Belge Yükle" butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tibbi_rapor':
        return Colors.red;
      case 'test_sonucu':
        return Colors.blue;
      case 'recete':
        return Colors.green;
      case 'goruntuleme':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tibbi_rapor':
        return Icons.medical_information;
      case 'test_sonucu':
        return Icons.science;
      case 'recete':
        return Icons.medication;
      case 'goruntuleme':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tibbi_rapor':
        return 'Tıbbi Rapor';
      case 'test_sonucu':
        return 'Test Sonucu';
      case 'recete':
        return 'Reçete';
      case 'goruntuleme':
        return 'Görüntüleme';
      default:
        return 'Diğer';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showUploadDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => _UploadDocumentDialog(
        patients: _patients,
        onSaved: _loadDocuments,
      ),
    );
  }

  void _viewDocument(ClinicDocument document) {
    // Belge görüntüleme modalı
    showDialog(
      context: context,
      builder: (context) => _DocumentViewDialog(document: document),
    );
  }

  void _downloadDocument(ClinicDocument document) {
    // Belge indirme - web için link açma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${document.fileName} indiriliyor...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteDocument(ClinicDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belge Sil'),
        content: Text(
            '${document.fileName} dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteDocument(document);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteDocument(ClinicDocument document) async {
    try {
      // Firebase Storage'dan dosyayı sil
      await FirebaseStorage.instance.refFromURL(document.fileUrl).delete();

      // Firestore'dan kaydı sil
      await FirebaseFirestore.instance
          .collection(AppConstants.clinicDocumentsCollection)
          .doc(document.id)
          .delete();

      _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge silinirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Model sınıfları
class ClinicDocument {
  final String id;
  final String userId;
  final String patientId;
  final String patientName;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;
  final String category;
  final String description;
  final DateTime uploadDate;
  final DateTime createdAt;

  ClinicDocument({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
    required this.category,
    required this.description,
    required this.uploadDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'patientName': patientName,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'category': category,
      'description': description,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ClinicPatient sınıfı
class ClinicPatient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String tcNo;
  final DateTime? birthDate;
  final String gender;
  final String address;
  final String emergencyContact;
  final String emergencyPhone;
  final String bloodType;
  final String allergies;
  final String chronicDiseases;
  final String medications;
  final String medicalHistory;
  final String notes;
  final bool isVip;
  final bool isActive;
  final DateTime createdAt;

  ClinicPatient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.tcNo,
    this.birthDate,
    required this.gender,
    required this.address,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.bloodType,
    required this.allergies,
    required this.chronicDiseases,
    required this.medications,
    required this.medicalHistory,
    required this.notes,
    required this.isVip,
    required this.isActive,
    required this.createdAt,
  });
}

// Belge yükleme dialog'u
class _UploadDocumentDialog extends StatefulWidget {
  final List<ClinicPatient> patients;
  final VoidCallback onSaved;

  const _UploadDocumentDialog({
    required this.patients,
    required this.onSaved,
  });

  @override
  State<_UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedPatientId;
  String _selectedCategory = 'tibbi_rapor';
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'tibbi_rapor',
    'test_sonucu',
    'recete',
    'goruntuleme',
    'diger',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                      color: Colors.brown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: const Icon(Icons.upload_file, color: Colors.brown),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  const Expanded(
                    child: Text(
                      'Belge Yükle',
                      style: TextStyle(
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
                          const Icon(Icons.star, color: Colors.amber, size: 16),
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

              // Kategori seçimi
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Dosya seçimi
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.file_present
                            : Icons.file_upload,
                        size: 48,
                        color:
                            _selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : 'Dosya seçmek için tıklayın',
                        style: TextStyle(
                          color: _selectedFile != null
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: _selectedFile != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (_selectedFile != null)
                        Text(
                          _formatFileSize(_selectedFile!.size),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
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
                      onPressed: _isLoading ? null : _uploadDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
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
                          : const Text('Yükle'),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Dosya seçerken hata: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen bir dosya seçin'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final patient =
          widget.patients.firstWhere((p) => p.id == _selectedPatientId);

      // Dosyayı Firebase Storage'a yükle
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('clinic_documents')
          .child(user.uid)
          .child(patient.id)
          .child(fileName);

      final uploadTask = storageRef.putData(_selectedFile!.bytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'a kaydet
      final docId = FirebaseFirestore.instance.collection('temp').doc().id;
      final documentData = ClinicDocument(
        id: docId,
        userId: user.uid,
        patientId: patient.id,
        patientName: patient.name,
        fileName: _selectedFile!.name,
        fileType: _selectedFile!.extension ?? '',
        fileSize: _selectedFile!.size,
        fileUrl: downloadUrl,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        uploadDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.clinicDocumentsCollection)
          .doc(docId)
          .set(documentData.toMap());

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge başarıyla yüklendi'),
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tibbi_rapor':
        return 'Tıbbi Rapor';
      case 'test_sonucu':
        return 'Test Sonucu';
      case 'recete':
        return 'Reçete';
      case 'goruntuleme':
        return 'Görüntüleme';
      default:
        return 'Diğer';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Belge görüntüleme dialog'u
class _DocumentViewDialog extends StatelessWidget {
  final ClinicDocument document;

  const _DocumentViewDialog({required this.document});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.blue,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Text(
                    document.fileName,
                    style: const TextStyle(
                      fontSize: 18,
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

            const Divider(),

            // Belge bilgileri
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hasta: ${document.patientName}'),
                  Text('Kategori: ${_getCategoryLabel(document.category)}'),
                  Text('Yüklenme Tarihi: ${_formatDate(document.uploadDate)}'),
                  Text('Dosya Boyutu: ${_formatFileSize(document.fileSize)}'),
                  if (document.description.isNotEmpty)
                    Text('Açıklama: ${document.description}'),
                ],
              ),
            ),

            // Belge içeriği placeholder'ı
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Belge Önizlemesi',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belgeyi indirmek için "İndir" butonuna tıklayın',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Alt butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // İndirme işlemi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${document.fileName} indiriliyor...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('İndir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tibbi_rapor':
        return 'Tıbbi Rapor';
      case 'test_sonucu':
        return 'Test Sonucu';
      case 'recete':
        return 'Reçete';
      case 'goruntuleme':
        return 'Görüntüleme';
      default:
        return 'Diğer';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
