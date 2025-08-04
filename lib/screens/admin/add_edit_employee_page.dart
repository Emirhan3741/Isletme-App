// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/user_model.dart';

import '../../utils/auth_guard.dart';
import '../../widgets/file_upload_widget.dart';
import '../../models/user_model.dart';

class AddEditEmployeePage extends StatefulWidget {
  final UserModel? employee;

  const AddEditEmployeePage({Key? key, this.employee}) : super(key: key);

  @override
  State<AddEditEmployeePage> createState() => _AddEditEmployeePageState();
}

class _AddEditEmployeePageState extends State<AddEditEmployeePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _sectorController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _positionController;
  late final TextEditingController _salaryController;
  bool _isLoading = false;
  bool _hasCvUploaded = false;
  bool _hasContractUploaded = false;
  bool get _isEditMode => widget.employee != null;
  user_role.UserRole? _selectedRole;
  String _selectedDepartment = 'Genel';

  final List<String> _departments = [
    'Genel',
    'İnsan Kaynakları',
    'Muhasebe',
    'Pazarlama',
    'Satış',
    'Teknik',
    'Müşteri Hizmetleri',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee?.name ?? '');
    _emailController = TextEditingController(text: employee?.email ?? '');
    _displayNameController =
        TextEditingController(text: employee?.displayName ?? '');
    _sectorController = TextEditingController(text: employee?.sector ?? '');
    _phoneController = TextEditingController(text: '');
    _addressController = TextEditingController(text: '');
    _positionController = TextEditingController(text: '');
    _salaryController = TextEditingController(text: '');
    _selectedRole = employee?.role != null 
        ? user_role.UserRoleExtension.fromString(employee!.role) 
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _sectorController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final employeeData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'role': (_selectedRole ?? user_role.UserRole.worker).toString(),
        'sector': _sectorController.text.trim(),
        'department': _selectedDepartment,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'position': _positionController.text.trim(),
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'hasCv': _hasCvUploaded,
        'hasContract': _hasContractUploaded,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Güncelleme
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(widget.employee!.id)
            .update(employeeData);
      } else {
        // Yeni kayıt
        employeeData['createdAt'] = FieldValue.serverTimestamp();
        employeeData['isActive'] = true;
        await FirebaseFirestore.instance
            .collection('employees')
            .add(employeeData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çalışan ${_isEditMode ? 'güncellendi' : 'eklendi'}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRoles: const ['admin', 'owner'],
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            _isEditMode ? 'Çalışan Düzenle' : 'Yeni Çalışan',
            style: const TextStyle(color: AppConstants.textPrimary),
          ),
          backgroundColor: AppConstants.surfaceColor,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveEmployee,
              child: Text(
                _isEditMode ? 'Güncelle' : 'Kaydet',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kişisel Bilgiler
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Bilgiler',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),

                        // Ad Soyad
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad *',
                            hintText: 'Çalışanın tam adı',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad Soyad gereklidir';
                            }
                            if (value.trim().length < 3) {
                              return 'Ad Soyad en az 3 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // E-posta ve Telefon
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'E-posta *',
                                  hintText: 'ornek@email.com',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'E-posta gereklidir';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Geçerli e-posta giriniz';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Telefon',
                                  hintText: '05xx xxx xx xx',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Adres
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Adres',
                            hintText: 'Ev adresi',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // İş Bilgileri
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İş Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),

                        // Pozisyon ve Departman
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _positionController,
                                decoration: InputDecoration(
                                  labelText: 'Pozisyon *',
                                  hintText: 'İş unvanı',
                                  prefixIcon: Icon(Icons.work),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Pozisyon gereklidir';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                decoration: InputDecoration(
                                  labelText: 'Departman',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept,
                                    child: Text(dept),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Rol ve Maaş
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<UserRole>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Rol *',
                                  prefixIcon: Icon(Icons.security),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: UserRole.values.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(_getRoleDisplayName(role)),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Rol seçiniz';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: TextFormField(
                                controller: _salaryController,
                                decoration: InputDecoration(
                                  labelText: 'Maaş',
                                  hintText: '0.00',
                                  prefixIcon: Icon(Icons.attach_money),
                                  suffixText: '₺',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Sektör
                        TextFormField(
                          controller: _sectorController,
                          decoration: InputDecoration(
                            labelText: 'Sektör/Branş',
                            hintText: 'Çalışma alanı',
                            prefixIcon: Icon(Icons.domain),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // CV Yükleme
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CV ve Özgeçmiş',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'Çalışanın CV dosyasını yükleyerek İK süreçlerinizi tamamlayabilirsiniz.',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        FileUploadWidget(
                          onUploadComplete: (result) {},
                          module: 'employees',
                          collection: 'employee_cvs',
                          additionalData: {
                            'employeeId': widget.employee?.id ?? 'new',
                            'employeeName': _nameController.text.trim(),
                            'documentType': 'cv',
                            'position': _positionController.text.trim(),
                          },
                          allowedExtensions: ['pdf', 'doc', 'docx'],
                          onUploadSuccess: () {
                            setState(() {
                              _hasCvUploaded = true;
                            });
                          },
                          onUploadError: (error) {
                            setState(() {
                              _hasCvUploaded = false;
                            });
                          },
                          isRequired: false,
                          showPreview: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Sözleşme Yükleme
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İş Sözleşmesi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'İş sözleşmesi belgesini yükleyerek çalışan dosyasını tamamlayabilirsiniz.',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        FileUploadWidget(
                          onUploadComplete: (result) {},
                          module: 'employees',
                          collection: 'employee_contracts',
                          additionalData: {
                            'employeeId': widget.employee?.id ?? 'new',
                            'employeeName': _nameController.text.trim(),
                            'documentType': 'contract',
                            'position': _positionController.text.trim(),
                            'salary':
                                double.tryParse(_salaryController.text) ?? 0.0,
                          },
                          allowedExtensions: ['pdf', 'doc', 'docx'],
                          onUploadSuccess: () {
                            setState(() {
                              _hasContractUploaded = true;
                            });
                          },
                          onUploadError: (error) {
                            setState(() {
                              _hasContractUploaded = false;
                            });
                          },
                          isRequired: false,
                          showPreview: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditMode
                                ? 'Çalışanı Güncelle'
                                : 'Çalışanı Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Sahip';
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.worker:
        return 'Çalışan';
      default:
        return 'Çalışan';
    }
  }
}
// Cleaned for Web Build by Cursor
