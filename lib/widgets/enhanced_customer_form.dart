import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/app_constants.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../utils/feedback_utils.dart';

class EnhancedCustomerForm extends StatefulWidget {
  final String? customerId;
  final VoidCallback onSaved;

  const EnhancedCustomerForm({
    super.key,
    this.customerId,
    required this.onSaved,
  });

  @override
  State<EnhancedCustomerForm> createState() => _EnhancedCustomerFormState();
}

class _EnhancedCustomerFormState extends State<EnhancedCustomerForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _customerTagController = TextEditingController();
  final _debtAmountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  String _selectedGender = 'Kadın';
  DateTime? _selectedBirthDate;
  List<Map<String, dynamic>> _attachedFiles = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<String> _genderOptions = ['Kadın', 'Erkek', 'Belirtmek İstemiyor'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customerId != null;
    if (_isEditMode) {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    if (widget.customerId == null) return;

    try {
      setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final customer = CustomerModel.fromMap({...data, 'id': doc.id});

        // Form alanlarını doldur
        final nameParts = customer.name.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        _lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        _phoneController.text = customer.phone;
        _emailController.text = customer.email;
        _customerTagController.text = customer.customerTag;
        _debtAmountController.text = customer.debtAmount.toString();
        _notesController.text = customer.notes;

        setState(() {
          _selectedGender = data['gender'] ?? 'Kadın';
          _selectedBirthDate = customer.birthDate;
          _attachedFiles =
              List<Map<String, dynamic>>.from(data['attachedFiles'] ?? []);
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müşteri bilgileri yüklenirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _customerTagController.dispose();
    _debtAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Icon(
                        _isEditMode ? Icons.edit : Icons.person_add,
                        color: AppConstants.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditMode ? 'Müşteri Düzenle' : 'Yeni Müşteri Ekle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kişisel Bilgiler Bölümü
                            _buildSectionTitle(
                                'Kişisel Bilgiler', Icons.person),
                            const SizedBox(height: 16),

                            // Ad Soyad
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ad *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ad gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Soyad *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Soyad gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Telefon ve Cinsiyet
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon Numarası *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone_outlined),
                                      hintText: '05XX XXX XX XX',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Telefon numarası gerekli';
                                      }
                                      if (value.length < 10) {
                                        return 'Geçerli telefon numarası girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Cinsiyet',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.person_pin_outlined),
                                    ),
                                    items: _genderOptions
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Email ve Doğum Tarihi
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value)) {
                                          return 'Geçerli email adresi girin';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectBirthDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Doğum Tarihi',
                                        border: OutlineInputBorder(),
                                        prefixIcon:
                                            Icon(Icons.calendar_today_outlined),
                                      ),
                                      child: Text(
                                        _selectedBirthDate != null
                                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                            : 'Tarih seçin',
                                        style: TextStyle(
                                          color: _selectedBirthDate != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // İş Bilgileri Bölümü
                            _buildSectionTitle('İş Bilgileri', Icons.business),
                            const SizedBox(height: 16),

                            // Etiket ve Borç Tutarı
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerTagController,
                                    decoration: const InputDecoration(
                                      labelText: 'Müşteri Etiketi',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.label_outline),
                                      hintText: 'VIP, Düzenli, Yeni vb.',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _debtAmountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Borç Tutarı (₺)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons
                                          .account_balance_wallet_outlined),
                                      hintText: '0.00',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (double.tryParse(value) == null) {
                                          return 'Geçerli tutar girin';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Notlar
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note_outlined),
                                hintText: 'Müşteri hakkında özel notlar...',
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 24),

                            // Dosyalar Bölümü
                            _buildSectionTitle('Dosyalar', Icons.attach_file),
                            const SizedBox(height: 16),

                            // Dosya Ekleme Butonu
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label:
                                  const Text('Dosya Ekle (JPEG, PDF, Excel)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor
                                    .withValues(alpha: 0.1),
                                foregroundColor: AppConstants.primaryColor,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Ekli Dosyalar Listesi
                            if (_attachedFiles.isNotEmpty) ...[
                              const Text(
                                'Ekli Dosyalar:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_attachedFiles.length, (index) {
                                final file = _attachedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppConstants.primaryColor
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getFileIcon(file['extension']),
                                        color: AppConstants.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${file['extension'].toUpperCase()} • ${_formatFileSize(file['size'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeFile(index),
                                        icon: const Icon(Icons.delete_outline),
                                        color: AppConstants.errorColor,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveCustomer,
                        child: Text(_isEditMode ? 'Güncelle' : 'Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        FeedbackUtils.showError(context, 'Dosya seçimi iptal edildi');
        return;
      }

      final file = result.files.first;

      // Web/mobile dosya işleme
      if (kIsWeb) {
        if (file.bytes != null) {
          // Web'de bytes kullan
          setState(() {
            // _selectedFileName = file.name; // Removed unused field
          });
        }
      } else {
        if (file.path != null) {
          // Mobile'da path kullan
          setState(() {
            // _selectedFileName = file.name; // Removed unused field
          });
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Dosya seçerken hata oluştu: $e');
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Kullanıcı oturumu bulunamadı';

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final debtAmount = double.tryParse(_debtAmountController.text) ?? 0.0;

      final customerData = {
        'name': fullName,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'birthDate': _selectedBirthDate,
        'customerTag': _customerTagController.text.trim(),
        'debtAmount': debtAmount,
        'notes': _notesController.text.trim(),
        'attachedFiles': _attachedFiles,
        'userId': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.customerId)
            .update(customerData);
      } else {
        customerData['createdAt'] = FieldValue.serverTimestamp();
        customerData['totalSpent'] = 0.0;
        customerData['totalVisits'] = 0;
        customerData['loyaltyLevel'] = 'Yeni';
        customerData['lastVisit'] = null;

        await FirebaseFirestore.instance
            .collection('customers')
            .add(customerData);
      }

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
