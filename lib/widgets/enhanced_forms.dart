import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ==================== ENHANCED EMPLOYEE FORM ====================

class EnhancedBeautyEmployeeForm extends StatefulWidget {
  final String? employeeId;
  final VoidCallback onSaved;

  const EnhancedBeautyEmployeeForm({
    super.key,
    this.employeeId,
    required this.onSaved,
  });

  @override
  State<EnhancedBeautyEmployeeForm> createState() =>
      _EnhancedBeautyEmployeeFormState();
}

class _EnhancedBeautyEmployeeFormState
    extends State<EnhancedBeautyEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _commissionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _notesController = TextEditingController();
  final _customPositionController = TextEditingController();

  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedPosition;
  String? _selectedWorkingHours;
  DateTime? _selectedStartDate;
  List<String> _selectedSkills = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _showCustomPosition = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.employeeId != null;
    if (_isEditMode) {
      _loadEmployeeData();
    }
    _selectedStartDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize default values after localization is available
    if (_selectedGender == null) {
      final localizations = AppLocalizations.of(context)!;
      _selectedGender = localizations.genderFemale;
      _selectedStatus = 'active';
      _selectedPosition = 'Kuaför';
      _selectedWorkingHours = '09:00-18:00';
    }
  }

  List<String> get _genderOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.genderFemale,
      localizations.genderMale,
      localizations.genderNotSpecified
    ];
  }

  List<String> get _statusOptions {
    return ['active', 'leave', 'inactive'];
  }

  List<String> get _positionOptions {
    return [
      'Kuaför',
      'Estetisyen',
      'Makyöz',
      'Masöz',
      'Manikürcü',
      'Resepsiyon',
      'Müdür',
      '+ Yeni Pozisyon'
    ];
  }

  List<String> get _workingHoursOptions {
    return [
      '09:00-18:00',
      '10:00-19:00',
      '08:00-17:00',
      '09:00-17:00',
      'Esnek Çalışma'
    ];
  }

  List<String> get _availableSkills {
    return [
      'Saç Kesimi',
      'Saç Boyası',
      'Manikür',
      'Pedikür',
      'Kaş Alma',
      'Cilt Bakımı',
      'Makyaj',
      'Masaj',
      'Epilasyon',
      'Kalıcı Makyaj'
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _commissionController.dispose();
    _experienceController.dispose();
    _notesController.dispose();
    _customPositionController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    if (widget.employeeId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('salons')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('employees')
          .doc(widget.employeeId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _salaryController.text = data['salary']?.toString() ?? '';
        _commissionController.text = data['commission']?.toString() ?? '';
        _experienceController.text = data['experience']?.toString() ?? '';
        _notesController.text = data['notes'] ?? '';

        setState(() {
          _selectedGender = data['gender'] ?? _genderOptions.first;
          _selectedStatus = data['status'] ?? 'active';
          _selectedPosition = data['position'] ?? 'Kuaför';
          _selectedWorkingHours = data['workingHours'] ?? '09:00-18:00';
          _selectedStartDate =
              (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
          _selectedSkills = List<String>.from(data['skills'] ?? []);

          // Check if position is custom
          if (!_positionOptions.contains(_selectedPosition) &&
              _selectedPosition != '+ Yeni Pozisyon') {
            _customPositionController.text = _selectedPosition!;
            _selectedPosition = '+ Yeni Pozisyon';
            _showCustomPosition = true;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Çalışan bilgileri yüklenirken hata: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Determine final position
      String finalPosition = _selectedPosition!;
      if (_selectedPosition == '+ Yeni Pozisyon' &&
          _customPositionController.text.trim().isNotEmpty) {
        finalPosition = _customPositionController.text.trim();
      }

      final employeeData = {
        'userId': user.uid,
        'salonId': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'position': finalPosition,
        'status': _selectedStatus,
        'workingHours': _selectedWorkingHours,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'commission': double.tryParse(_commissionController.text) ?? 0.0,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'startDate': Timestamp.fromDate(_selectedStartDate!),
        'skills': _selectedSkills,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(user.uid)
            .collection('employees')
            .doc(widget.employeeId)
            .update(employeeData);
        _showSuccessSnackBar('Çalışan başarıyla güncellendi!');
      } else {
        employeeData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(user.uid)
            .collection('employees')
            .add(employeeData);
        _showSuccessSnackBar('Çalışan başarıyla eklendi!');
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Email is optional

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationEmail;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationRequired;
    }

    final phoneRegex = RegExp(r'^[0-9+\-\s\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationPhone;
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationRequired;
    }
    return null;
  }

  Widget _buildResponsiveField({
    required Widget child,
    int flex = 1,
    double? minWidth,
  }) {
    return Flexible(
      flex: flex,
      fit: FlexFit.loose,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 200,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft:
                      const Radius.circular(AppConstants.borderRadiusLarge),
                  topRight:
                      const Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditMode
                          ? 'Çalışan Düzenle'
                          : localizations.addNewEmployee,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information Section
                            _buildSectionHeader(
                                localizations.name, Icons.person),
                            const SizedBox(height: 16),

                            // Name field - full width
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: '${localizations.name} *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: _validateRequired,
                            ),

                            const SizedBox(height: 16),

                            // Phone and Gender - responsive row
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildResponsiveField(
                                  minWidth: 250,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: '${localizations.phone} *',
                                      border: const OutlineInputBorder(),
                                      prefixIcon:
                                          const Icon(Icons.phone_outlined),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                  ),
                                ),
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: InputDecoration(
                                      labelText: localizations.gender,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.wc_outlined),
                                    ),
                                    items: _genderOptions
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedGender = value),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: localizations.email,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),

                            const SizedBox(height: 24),

                            // Work Information Section
                            _buildSectionHeader(
                                'İş Bilgileri', Icons.work_outline),
                            const SizedBox(height: 16),

                            // Position with custom option
                            DropdownButtonFormField<String>(
                              value: _selectedPosition,
                              decoration: const InputDecoration(
                                labelText: 'Pozisyon *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: _positionOptions
                                  .map(
                                    (position) => DropdownMenuItem(
                                      value: position,
                                      child: Text(position),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPosition = value;
                                  _showCustomPosition =
                                      value == '+ Yeni Pozisyon';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Pozisyon seçiniz';
                                if (value == '+ Yeni Pozisyon' &&
                                    _customPositionController.text
                                        .trim()
                                        .isEmpty) {
                                  return 'Özel pozisyon adını giriniz';
                                }
                                return null;
                              },
                            ),

                            // Custom position input
                            if (_showCustomPosition) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _customPositionController,
                                decoration: const InputDecoration(
                                  labelText: 'Özel Pozisyon Adı *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.edit_outlined),
                                ),
                                validator: _showCustomPosition
                                    ? _validateRequired
                                    : null,
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Status and Working Hours - responsive row
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: localizations.status,
                                      border: const OutlineInputBorder(),
                                      prefixIcon:
                                          const Icon(Icons.info_outline),
                                    ),
                                    items: _statusOptions
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(_getStatusText(status)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedStatus = value),
                                  ),
                                ),
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedWorkingHours,
                                    decoration: const InputDecoration(
                                      labelText: 'Çalışma Saatleri',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.access_time_outlined),
                                    ),
                                    items: _workingHoursOptions
                                        .map(
                                          (hours) => DropdownMenuItem(
                                            value: hours,
                                            child: Text(hours),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedWorkingHours = value),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Salary and Commission - responsive row
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: TextFormField(
                                    controller: _salaryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Maaş (₺)',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.attach_money_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: TextFormField(
                                    controller: _commissionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Komisyon (%)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.percent_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: localizations.notes,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.notes_outlined),
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(localizations.cancel),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _saveEmployee,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 12),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isEditMode ? 'Güncelle' : 'Kaydet'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'leave':
        return 'İzinli';
      case 'inactive':
        return 'Pasif';
      default:
        return status;
    }
  }
}

// ==================== ENHANCED SERVICE FORM ====================

class EnhancedBeautyServiceForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? serviceId;

  const EnhancedBeautyServiceForm({
    Key? key,
    this.onSaved,
    this.serviceId,
  }) : super(key: key);

  @override
  State<EnhancedBeautyServiceForm> createState() =>
      _EnhancedBeautyServiceFormState();
}

class _EnhancedBeautyServiceFormState extends State<EnhancedBeautyServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;
  bool _showCustomCategory = false;

  List<String> get _categoryOptions {
    return [
      'Saç Bakımı',
      'Cilt Bakımı',
      'Tırnak Bakımı',
      'Masaj',
      'Ağda',
      'Makyaj',
      'Yüz Bakımı',
      'Vücut Bakımı',
      'Diğer',
      '+ Yeni Kategori'
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryOptions.first;
    if (widget.serviceId != null) {
      _loadServiceData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceData() async {
    if (widget.serviceId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('salons')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _priceController.text = (data['price'] ?? 0.0).toString();
          _durationController.text = (data['duration'] ?? 0).toString();
          _descriptionController.text = data['description'] ?? '';
          _isActive = data['isActive'] ?? true;

          // Handle category
          final category = data['category'] ?? 'Saç';
          if (_categoryOptions.contains(category)) {
            _selectedCategory = category;
          } else {
            _customCategoryController.text = category;
            _selectedCategory = '+ Yeni Kategori';
            _showCustomCategory = true;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Hizmet bilgileri yüklenirken hata oluştu: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Determine final category
      String finalCategory = _selectedCategory!;
      if (_selectedCategory == '+ Yeni Kategori' &&
          _customCategoryController.text.trim().isNotEmpty) {
        finalCategory = _customCategoryController.text.trim();
      }

      final serviceData = {
        'userId': user.uid,
        'salonId': user.uid,
        'name': _nameController.text.trim(),
        'category': finalCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.serviceId != null) {
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(user.uid)
            .collection('services')
            .doc(widget.serviceId)
            .update(serviceData);
        _showSuccessSnackBar('Hizmet başarıyla güncellendi!');
      } else {
        serviceData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('salons')
            .doc(user.uid)
            .collection('services')
            .add(serviceData);
        _showSuccessSnackBar('Hizmet başarıyla eklendi!');
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationRequired;
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationRequired;
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) {
      final localizations = AppLocalizations.of(context)!;
      return localizations.formValidationAmount;
    }
    return null;
  }

  Widget _buildResponsiveField({
    required Widget child,
    int flex = 1,
    double? minWidth,
  }) {
    return Flexible(
      flex: flex,
      fit: FlexFit.loose,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 200,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft:
                      const Radius.circular(AppConstants.borderRadiusLarge),
                  topRight:
                      const Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.design_services,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.serviceId != null
                          ? 'Hizmet Düzenle'
                          : localizations.addService,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Hizmet Adı *',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.design_services_outlined),
                              ),
                              validator: _validateRequired,
                            ),

                            const SizedBox(height: 16),

                            // Category with custom option
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Kategori *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categoryOptions
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _showCustomCategory =
                                      value == '+ Yeni Kategori';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Kategori seçiniz';
                                if (value == '+ Yeni Kategori' &&
                                    _customCategoryController.text
                                        .trim()
                                        .isEmpty) {
                                  return 'Özel kategori adını giriniz';
                                }
                                return null;
                              },
                            ),

                            // Custom category input
                            if (_showCustomCategory) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _customCategoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Özel Kategori Adı *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.edit_outlined),
                                ),
                                validator: _showCustomCategory
                                    ? _validateRequired
                                    : null,
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Price and Duration - responsive row
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: InputDecoration(
                                      labelText: '${localizations.price} (₺) *',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                          Icons.attach_money_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: _validateAmount,
                                  ),
                                ),
                                _buildResponsiveField(
                                  minWidth: 200,
                                  child: TextFormField(
                                    controller: _durationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Süre (dakika) *',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.access_time_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return localizations
                                            .formValidationRequired;
                                      }
                                      final duration =
                                          int.tryParse(value.trim());
                                      if (duration == null || duration <= 0) {
                                        return 'Geçerli bir süre giriniz';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 16),

                            // Active Status
                            SwitchListTile(
                              title: const Text('Aktif'),
                              subtitle:
                                  const Text('Hizmet müşterilere gösterilsin'),
                              value: _isActive,
                              onChanged: (value) =>
                                  setState(() => _isActive = value),
                              activeColor: AppConstants.primaryColor,
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(localizations.cancel),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _saveService,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 12),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(widget.serviceId != null
                                          ? 'Güncelle'
                                          : 'Kaydet'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
