// Refactored by Cursor

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'package:file_picker/file_picker.dart'; // Temporarily disabled
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../utils/validation_utils.dart';
import '../../utils/error_handler.dart';
import '../../utils/feedback_utils.dart';
import '../../core/widgets/form_field_with_custom_option.dart';
import '../../widgets/file_upload_widget.dart';
import '../../core/widgets/common_widgets.dart';

class AddEditCustomerPage extends StatefulWidget {
  final CustomerModel? customer;
  final String? currentUserId;

  const AddEditCustomerPage({Key? key, this.customer, this.currentUserId})
      : super(key: key);

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _tags = ['VIP', 'borçlu', 'ilk kez geldi', 'düzenli', 'özel'];
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _email = '';
  String _tag = 'VIP';
  String? _note;
  int _totalSessions = 0;
  int _usedSessions = 0;
  double _totalPayment = 0.0;
  double _paidAmount = 0.0;
  List<String> _documentUrls = [];
  String _gender = 'Kadın';
  DateTime? _birthDate;
  String _allergyInfo = '';
  String _preferredBrand = '';
  String _selectedGender = 'Kadın';
  bool _isUploading = false;
  bool _isLoading = false;

  // Belge yükleme durumları
  bool _hasIdentityDocuments = false;
  bool _hasContractDocuments = false;
  bool _hasServiceDocuments = false;

  final CustomerService _customerService = CustomerService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _allergyController;
  late final TextEditingController _preferredBrandController;
  late final TextEditingController _notesController;

  final List<String> _genders = ['Kadın', 'Erkek', 'Belirtmek İstemiyorum'];
  final List<String> _popularBrands = [
    'L\'Oréal',
    'Garnier',
    'Schwarzkopf',
    'Wella',
    'Matrix',
    'Kerastase',
    'Tigi',
    'Redken',
    'Paul Mitchell',
    'Sebastian',
  ];

  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();

    _nameController = TextEditingController(text: _firstName + ' ' + _lastName);
    _phoneController = TextEditingController(text: _phone);
    _emailController = TextEditingController(text: _email);
    _addressController = TextEditingController(text: '');
    _allergyController = TextEditingController(text: _allergyInfo);
    _preferredBrandController = TextEditingController(text: _preferredBrand);
    _notesController = TextEditingController(text: _note);

    if (_isEditMode) {
      _selectedGender = _gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _allergyController.dispose();
    _preferredBrandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    final c = widget.customer;
    if (c != null) {
      final nameParts = c.name.split(' ');
      _firstName = nameParts.isNotEmpty ? nameParts.first : '';
      _lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      _phone = c.phone;
      _email = c.email;
      _tag = 'VIP'; // Default tag - CustomerModel'de yok
      _note = c.notes; // notes field'ını kullan
      _totalSessions = 0; // Default value - CustomerModel'de yok
      _usedSessions = 0; // Default value - CustomerModel'de yok
      _totalPayment = 0.0; // Default value - CustomerModel'de yok
      _paidAmount = 0.0; // Default value - CustomerModel'de yok
      _documentUrls = <String>[]; // Default empty list - CustomerModel'de yok
      _gender = c.gender ?? 'Kadın';
      _birthDate = c.birthDate;
      _allergyInfo = c.allergyInfo;
      _preferredBrand = c.preferredBrand;
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (!kIsWeb) {
      setState(() => _isUploading = true);
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final ref = FirebaseStorage.instance
            .ref()
            .child('customer_docs/${const Uuid().v4()}_${file.name}');
        await ref.putData(file.bytes!);
        final url = await ref.getDownloadURL();
        setState(() {
          _documentUrls.add(url);
        });
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Müşteri Düzenle' : 'Yeni Müşteri',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[400],
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: Text(
              _isEditMode ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            _buildPersonalInfoCard(),
            const SizedBox(height: 16),
            _buildBeautyPreferencesCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
            const SizedBox(height: 16),
            _buildDocumentsCard(),
            if (_isEditMode) ...[
              const SizedBox(height: 24),
              _buildDeleteButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temel Bilgiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: ValidationUtils.validateName,
            ),
            const SizedBox(height: 16),
            FormFieldWithCustomOption<String>(
              label: 'Cinsiyet',
              value: _selectedGender,
              options: _genders,
              optionLabel: (gender) => gender,
              optionValue: (gender) => gender,
              icon: Icons.person_outline,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value ?? 'Kadın';
                });
              },
              customOptionLabel: 'Diğer',
              customInputLabel: 'Özel Cinsiyet',
              customInputHint: 'Lütfen belirtin...',
              fieldType: FormFieldType.dropdown,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? _formatDate(_birthDate!)
                            : 'Doğum tarihi seçin (opsiyonel)',
                        style: TextStyle(
                          fontSize: 16,
                          color: _birthDate != null
                              ? Colors.grey[800]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (_birthDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _birthDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İletişim Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: ValidationUtils.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // Email optional
                }
                return ValidationUtils.validateEmail(value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adres',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişisel Bilgiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allergyController,
              decoration: const InputDecoration(
                labelText: 'Alerji Bilgileri',
                prefixIcon: Icon(Icons.warning_amber),
                border: OutlineInputBorder(),
                hintText: 'Varsa alerji durumlarını yazın',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautyPreferencesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Güzellik Tercihleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _preferredBrandController,
              decoration: InputDecoration(
                labelText: 'Tercih Edilen Marka',
                prefixIcon: const Icon(Icons.favorite),
                border: const OutlineInputBorder(),
                hintText: 'Örn: L\'Oréal, Garnier',
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    _preferredBrandController.text = value;
                  },
                  itemBuilder: (context) {
                    return _popularBrands.map((brand) {
                      return PopupMenuItem(
                        value: brand,
                        child: Text(brand),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Popüler markalar için açılır menüyü kullanabilirsiniz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Müşteri notları',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                hintText: 'Özel notlar, tercihler, önemli bilgiler...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tehlikeli Bölge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteCustomer,
                icon: const Icon(Icons.delete),
                label: const Text('Müşteriyi Sil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    await ErrorHandler.handleAsync(
      () async {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('Kullanıcı oturum açmamış');

        final customer = CustomerModel(
          id: widget.customer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          gender: _selectedGender,
          birthDate: _birthDate,
          allergyInfo: _allergyController.text.trim(),
          preferredBrand: _preferredBrandController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: widget.customer?.createdAt ?? DateTime.now(),
          lastVisit: widget.customer?.lastVisit,
          totalVisits: widget.customer?.totalVisits ?? 0,
          totalSpent: widget.customer?.totalSpent ?? 0.0,
        );

        if (_isEditMode) {
          await _customerService.updateCustomer(customer);
        } else {
          await _customerService.addCustomer(customer);
        }

        return customer;
      },
      context,
      loadingMessage:
          _isEditMode ? 'Müşteri güncelleniyor...' : 'Müşteri ekleniyor...',
      successMessage: _isEditMode
          ? 'Müşteri başarıyla güncellendi'
          : 'Müşteri başarıyla eklendi',
      showLoading: true,
      showSuccess: true,
      onSuccess: () {
        if (mounted) Navigator.pop(context);
      },
      onError: () {
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await FeedbackUtils.showConfirmationDialog(
      context,
      title: 'Müşteriyi Sil',
      message: 'Bu müşteriyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      confirmText: 'Sil',
      cancelText: 'İptal',
      confirmColor: Colors.red,
    );

    if (confirmed == true && widget.customer != null) {
      await ErrorHandler.handleAsync(
        () async {
          await _customerService.deleteCustomer(widget.customer!.id);
        },
        context,
        loadingMessage: 'Müşteri siliniyor...',
        successMessage: 'Müşteri başarıyla silindi',
        showLoading: true,
        showSuccess: true,
        onSuccess: () {
          if (mounted) Navigator.pop(context);
        },
      );
    }
  }

  Widget _buildDocumentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, color: Colors.blue[400]),
                const SizedBox(width: 12),
                Text(
                  'Müşteri Belgeleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Müşteri ile ilgili sözleşmeler, kimlik belgeleri ve hizmet kayıtlarını yükleyebilirsiniz.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Kimlik Belgeleri
            Text(
              'Kimlik Belgeleri',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            FileUploadWidget(
              onUploadComplete: (result) {},
              module: 'customers',
              collection: 'identity_documents',
              additionalData: {
                'customerId': widget.customer?.id ?? 'new',
                'customerName': '${_nameController.text.trim()}',
                'documentType': 'identity',
              },
              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
              onUploadSuccess: () {
                setState(() {
                  _hasIdentityDocuments = true;
                });
              },
              onUploadError: (error) {
                setState(() {
                  _hasIdentityDocuments = false;
                });
              },
              isRequired: false,
              showPreview: true,
            ),

            const SizedBox(height: 16),

            // Sözleşme Belgeleri
            Text(
              'Sözleşme Belgeleri',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            FileUploadWidget(
              onUploadComplete: (result) {},
              module: 'customers',
              collection: 'contract_documents',
              additionalData: {
                'customerId': widget.customer?.id ?? 'new',
                'customerName': '${_nameController.text.trim()}',
                'documentType': 'contract',
              },
              allowedExtensions: ['pdf', 'doc', 'docx'],
              onUploadSuccess: () {
                setState(() {
                  _hasContractDocuments = true;
                });
              },
              onUploadError: (error) {
                setState(() {
                  _hasContractDocuments = false;
                });
              },
              isRequired: false,
              showPreview: true,
            ),

            const SizedBox(height: 16),

            // Hizmet Kayıtları
            Text(
              'Hizmet Kayıtları',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            FileUploadWidget(
              onUploadComplete: (result) {},
              module: 'customers',
              collection: 'service_documents',
              additionalData: {
                'customerId': widget.customer?.id ?? 'new',
                'customerName': '${_nameController.text.trim()}',
                'documentType': 'service_records',
              },
              allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
              onUploadSuccess: () {
                setState(() {
                  _hasServiceDocuments = true;
                });
              },
              onUploadError: (error) {
                setState(() {
                  _hasServiceDocuments = false;
                });
              },
              isRequired: false,
              showPreview: true,
            ),

            // Yüklenen Belge Özeti
            if (_hasIdentityDocuments ||
                _hasContractDocuments ||
                _hasServiceDocuments) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belgeler başarıyla yüklendi. Kaydetmek için "Kaydet" butonuna basın.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
