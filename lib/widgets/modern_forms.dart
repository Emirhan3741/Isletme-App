import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/beauty_customer_service.dart';
import '../services/beauty_employee_service.dart';
import '../services/beauty_service_service.dart';
import '../models/customer_model.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// ==================== MODERN FORM COMPONENTS ====================

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final bool autofocus;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.onChanged,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textDirection: textDirection,
        textAlign: textAlign,
        autofocus: autofocus,
        // TextEditingController davranışını iyileştirmek için key kullanımı
        key: ValueKey(controller.hashCode),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF3366FF)) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3366FF), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // Text selection davranışını iyileştir
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}

// Eski ModernDropdown (backward compatibility için)
class ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final IconData? icon;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const ModernDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    this.icon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF3366FF)) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3366FF), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// Gelişmiş ModernDropdown - Custom Option Desteği ile
class ModernDropdownWithCustom<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final String Function(T) optionValue;
  final String label;
  final IconData? icon;
  final void Function(T?)? onChanged;
  final void Function(String?)? onCustomValueChanged;
  final String? customValue;
  final String? Function(T?)? validator;
  final String? Function(String?)? customValidator;
  final String? hint;
  final String customOptionLabel;
  final String customInputLabel;
  final String customInputHint;
  final bool enabled;
  final bool isRequired;

  const ModernDropdownWithCustom({
    super.key,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.optionValue,
    required this.label,
    this.icon,
    this.onChanged,
    this.onCustomValueChanged,
    this.customValue,
    this.validator,
    this.customValidator,
    this.hint,
    this.customOptionLabel = 'Diğer',
    this.customInputLabel = 'Özel Değer',
    this.customInputHint = 'Lütfen açıklayın...',
    this.enabled = true,
    this.isRequired = false,
  });

  @override
  State<ModernDropdownWithCustom<T>> createState() =>
      _ModernDropdownWithCustomState<T>();
}

class _ModernDropdownWithCustomState<T>
    extends State<ModernDropdownWithCustom<T>> {
  late TextEditingController _customController;
  bool _isCustomSelected = false;
  T? _customOptionValue;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.customValue);

    // Custom option value oluştur (String tipinde "custom" değeri)
    if (T == String) {
      _customOptionValue = 'custom' as T;
    }

    // Eğer value custom option ise, custom mode'a geç
    if (widget.value != null &&
        !widget.options.contains(widget.value) &&
        widget.customValue != null) {
      _isCustomSelected = true;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernDropdownWithCustom<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Custom value değişti mi kontrol et
    if (widget.customValue != oldWidget.customValue) {
      _customController.text = widget.customValue ?? '';
    }

    // Value değişti mi ve custom option mı kontrol et
    if (widget.value != oldWidget.value) {
      _isCustomSelected = widget.value != null &&
          !widget.options.contains(widget.value) &&
          widget.customValue != null;
    }
  }

  void _onOptionChanged(T? newValue) {
    if (newValue == _customOptionValue) {
      // Custom option seçildi
      setState(() {
        _isCustomSelected = true;
      });
      widget.onChanged?.call(newValue);
    } else {
      // Normal option seçildi
      setState(() {
        _isCustomSelected = false;
      });
      widget.onChanged?.call(newValue);

      // Custom value'yu temizle
      if (widget.onCustomValueChanged != null) {
        _customController.clear();
        widget.onCustomValueChanged!('');
      }
    }
  }

  void _onCustomValueChanged(String value) {
    widget.onCustomValueChanged?.call(value);
  }

  List<T> get _enhancedOptions {
    final options = List<T>.from(widget.options);
    if (_customOptionValue != null && !options.contains(_customOptionValue)) {
      options.add(_customOptionValue!);
    }
    return options;
  }

  String _getOptionLabel(T option) {
    if (option == _customOptionValue) {
      return widget.customOptionLabel;
    }
    return widget.optionLabel(option);
  }

  String? _validateField(T? value) {
    // Eğer custom seçildi ise, custom validator kullan
    if (_isCustomSelected) {
      return widget.customValidator?.call(_customController.text);
    }

    // Normal validation
    if (widget.isRequired && value == null) {
      return '${widget.label} seçimi gerekli';
    }

    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana Dropdown
          DropdownButtonFormField<T>(
            value: _isCustomSelected ? _customOptionValue : widget.value,
            items: _enhancedOptions.map((option) {
              return DropdownMenuItem<T>(
                value: option,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null && option == _enhancedOptions.first)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(widget.icon,
                            size: 16, color: const Color(0xFF6B7280)),
                      ),
                    Flexible(
                        child: Text(_getOptionLabel(option),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.enabled ? _onOptionChanged : null,
            validator: _validateField,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.icon != null
                  ? Icon(widget.icon, color: const Color(0xFF3366FF))
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3366FF), width: 2),
              ),
              filled: true,
              fillColor:
                  widget.enabled ? Colors.white : const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),

          // Custom Input Field (göster/gizle)
          if (_isCustomSelected) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customController,
              onChanged: _onCustomValueChanged,
              enabled: widget.enabled,
              validator: widget.customValidator,
              decoration: InputDecoration(
                labelText: widget.customInputLabel,
                hintText: widget.customInputHint,
                prefixIcon: const Icon(Icons.edit, color: Color(0xFF3366FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF3366FF), width: 2),
                ),
                filled: true,
                fillColor:
                    widget.enabled ? Colors.white : const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF3366FF) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF3366FF),
          side: isPrimary ? null : const BorderSide(color: Color(0xFF3366FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ==================== CUSTOMER FORM ====================

class BeautyCustomerForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? customerId; // Düzenleme için

  const BeautyCustomerForm({
    Key? key,
    this.onSaved,
    this.customerId,
  }) : super(key: key);

  @override
  State<BeautyCustomerForm> createState() => _BeautyCustomerFormState();
}

class _BeautyCustomerFormState extends State<BeautyCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _debtAmountController = TextEditingController();

  String? _selectedGender;
  String? _selectedTag;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  List<String> get _genderOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.genderFemale,
      localizations.genderMale,
      localizations.genderNotSpecified
    ];
  }

  List<String> get _tagOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.customerTagNew,
      localizations.customerTagVip,
      localizations.customerTagPremium,
      localizations.customerTagStandard
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomerData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize default values after localization is available
    if (_selectedGender == null) {
      final localizations = AppLocalizations.of(context)!;
      _selectedGender = localizations.genderFemale;
      _selectedTag = localizations.customerTagNew;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _debtAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    if (widget.customerId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _debtAmountController.text = (data['debtAmount'] ?? 0).toString();
          _selectedGender = data['gender'] ?? 'Kadın';
          _selectedTag = data['customerTag'] ?? 'Yeni';
          if (data['birthDate'] != null) {
            _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar('${localizations.customerLoadError}: $e', isError: true);
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı oturumu bulunamadı', isError: true);
        return;
      }

      final customerData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _selectedGender,
        'birthDate': _selectedBirthDate,
        'customerTag': _selectedTag,
        'debtAmount': double.tryParse(_debtAmountController.text) ?? 0.0,
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalVisits': 0,
        'totalSpent': 0.0,
      };

      if (widget.customerId != null) {
        // Güncelleme
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.customerId)
            .update(customerData);
        _showSnackBar('Müşteri başarıyla güncellendi!');
      } else {
        // Yeni ekleme
        await FirebaseFirestore.instance
            .collection('customers')
            .add(customerData);
        _showSnackBar('Müşteri başarıyla eklendi!');
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.customerId != null
                        ? 'Müşteri Düzenle'
                        : 'Yeni Müşteri',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ad Soyad
                      ModernTextField(
                        label: 'Ad Soyad',
                        hint: 'Müşterinin adı ve soyadı',
                        controller: _nameController,
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ad soyad gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Telefon
                      ModernTextField(
                        label: 'Telefon',
                        hint: '0555 123 45 67',
                        controller: _phoneController,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Telefon numarası gerekli';
                          }
                          if (value.length < 10) {
                            return 'Geçerli bir telefon numarası girin';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email
                      ModernTextField(
                        label: 'E-posta',
                        hint: 'ornek@email.com',
                        controller: _emailController,
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Cinsiyet ve Doğum Tarihi
                      Row(
                        children: [
                          Expanded(
                            child: ModernDropdown<String>(
                              label: 'Cinsiyet',
                              value: _selectedGender,
                              items: _genderOptions.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedGender = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernTextField(
                              label: 'Doğum Tarihi',
                              hint: 'Tarih seçin',
                              controller: TextEditingController(
                                text: _selectedBirthDate != null
                                    ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                    : '',
                              ),
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _selectBirthDate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Müşteri Etiketi ve Borç Tutarı
                      Row(
                        children: [
                          Expanded(
                            child: ModernDropdown<String>(
                              label: 'Müşteri Etiketi',
                              value: _selectedTag,
                              items: _tagOptions.map((tag) {
                                return DropdownMenuItem(
                                  value: tag,
                                  child: Text(tag),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedTag = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernTextField(
                              label: 'Borç Tutarı',
                              hint: '0.00',
                              controller: _debtAmountController,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Adres
                      ModernTextField(
                        label: 'Adres',
                        hint: 'Müşterinin adresi',
                        controller: _addressController,
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Notlar
                      ModernTextField(
                        label: 'Notlar',
                        hint: 'Müşteri hakkında notlar...',
                        controller: _notesController,
                        icon: Icons.note,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: ModernButton(
                              text: 'İptal',
                              isPrimary: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernButton(
                              text: widget.customerId != null
                                  ? 'Güncelle'
                                  : 'Kaydet',
                              isPrimary: true,
                              isLoading: _isLoading,
                              onPressed: _saveCustomer,
                            ),
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

// ==================== APPOINTMENT FORM ====================

class BeautyAppointmentForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? appointmentId;

  const BeautyAppointmentForm({
    Key? key,
    this.onSaved,
    this.appointmentId,
  }) : super(key: key);

  @override
  State<BeautyAppointmentForm> createState() => _BeautyAppointmentFormState();
}

class _BeautyAppointmentFormState extends State<BeautyAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  // Beauty-specific services for proper list synchronization
  final BeautyCustomerService _customerService = BeautyCustomerService();
  final BeautyEmployeeService _employeeService = BeautyEmployeeService();
  final BeautyServiceService _serviceService = BeautyServiceService();

  String? _selectedCustomerId;
  String? _selectedServiceId;
  String? _selectedEmployeeId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStatus;
  bool _isLoading = false;

  // Custom değerler için yeni state alanları
  String? _customCustomerName;
  String? _customServiceName;
  String? _customEmployeeName;
  String? _customStatus;

  List<String> get _statusOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.appointmentStatusPending,
      localizations.appointmentStatusConfirmed,
      localizations.appointmentStatusCompleted,
      localizations.appointmentStatusCancelled
    ];
  }

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.appointmentId != null) {
      _loadAppointmentData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize default values after localization is available
    if (_selectedStatus == null) {
      final localizations = AppLocalizations.of(context)!;
      _selectedStatus = localizations.appointmentStatusPending;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Initialize salon for all services
      await Future.wait([
        _customerService.initializeSalon(),
        _employeeService.initializeSalon(),
        _serviceService.initializeSalon(),
      ]);

      // Load data using beauty-specific services
      final customers = await _customerService.getCustomers();
      final services = await _serviceService.getServices();
      final employees = await _employeeService.getEmployees();

      if (mounted) {
        setState(() {
          _customers = customers
              .map((customer) => {
                    'id': customer.id,
                    'name': '${customer.firstName} ${customer.lastName}'.trim(),
                  })
              .toList();

          _services = services
              .map((service) => {
                    'id': service['id'],
                    'name': service['name'],
                    'price': service['price'],
                  })
              .toList();

          _employees = employees
              .map((employee) => {
                    'id': employee['id'],
                    'name': employee['name'],
                  })
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('${AppLocalizations.of(context)!.dataLoadError}: $e',
            isError: true);
      }
    }
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _selectedCustomerId = data['customerId'];
          _selectedServiceId = data['serviceId'];
          _selectedEmployeeId = data['employeeId'];
          _selectedStatus = data['status'] ?? 'Beklemede';
          _priceController.text = (data['price'] ?? 0.0).toString();
          _notesController.text = data['notes'] ?? '';

          if (data['appointmentDate'] != null) {
            final dateTime = (data['appointmentDate'] as Timestamp).toDate();
            _selectedDate =
                DateTime(dateTime.year, dateTime.month, dateTime.day);
            _selectedTime =
                TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          }
        });
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.appointmentLoadError}: $e',
          isError: true);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar(AppLocalizations.of(context)!.userSessionNotFound,
            isError: true);
        return;
      }

      // Custom değerleri işle
      String? finalCustomerId = _selectedCustomerId;
      String? finalServiceId = _selectedServiceId;
      String? finalEmployeeId = _selectedEmployeeId;

      // Custom müşteri oluştur
      if (_selectedCustomerId == 'custom' &&
          _customCustomerName != null &&
          _customCustomerName!.trim().isNotEmpty) {
        final names = _customCustomerName!.trim().split(' ');
        final customer = CustomerModel(
          id: '',
          firstName: names.isNotEmpty ? names.first : '',
          lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
          phone: '',
          email: '',
          userId: FirebaseAuth.instance.currentUser!.uid,
          createdAt: DateTime.now(),
        );

        await _customerService.addCustomer(customer);
        // Refresh customer list to get the new customer ID
        final updatedCustomers = await _customerService.getCustomers();
        final newCustomer = updatedCustomers.lastWhere(
          (c) =>
              c.firstName == customer.firstName &&
              c.lastName == customer.lastName,
        );
        finalCustomerId = newCustomer.id;

        // Update the customer list in the UI
        if (mounted) {
          setState(() {
            _customers = updatedCustomers
                .map((customer) => {
                      'id': customer.id,
                      'name':
                          '${customer.firstName} ${customer.lastName}'.trim(),
                    })
                .toList();
          });
        }
      }

      // Custom hizmet oluştur
      if (_selectedServiceId == 'custom' &&
          _customServiceName != null &&
          _customServiceName!.trim().isNotEmpty) {
        final serviceData = {
          'name': _customServiceName!.trim(),
          'description': 'Randevu sırasında oluşturulan özel hizmet',
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'durationMinutes': 60, // Varsayılan süre
          'category': 'other',
          'isActive': true,
        };

        await _serviceService.addService(serviceData);
        // Refresh service list to get the new service ID
        final updatedServices = await _serviceService.getServices();
        final newService = updatedServices.lastWhere(
          (s) => s['name'] == serviceData['name'],
        );
        finalServiceId = newService['id'];

        // Update the service list in the UI
        if (mounted) {
          setState(() {
            _services = updatedServices
                .map((service) => {
                      'id': service['id'],
                      'name': service['name'],
                      'price': service['price'],
                    })
                .toList();
          });
        }
      }

      // Custom çalışan oluştur
      if (_selectedEmployeeId == 'custom' &&
          _customEmployeeName != null &&
          _customEmployeeName!.trim().isNotEmpty) {
        final employeeData = {
          'name': _customEmployeeName!.trim(),
          'email': '',
          'phone': '',
          'role': 'beautician',
          'isActive': true,
        };

        await _employeeService.addEmployee(employeeData);
        // Refresh employee list to get the new employee ID
        final updatedEmployees = await _employeeService.getEmployees();
        final newEmployee = updatedEmployees.lastWhere(
          (e) => e['name'] == employeeData['name'],
        );
        finalEmployeeId = newEmployee['id'];

        // Update the employee list in the UI
        if (mounted) {
          setState(() {
            _employees = updatedEmployees
                .map((employee) => {
                      'id': employee['id'],
                      'name': employee['name'],
                    })
                .toList();
          });
        }
      }

      // Final validation
      if (finalCustomerId == null || finalCustomerId == 'custom') {
        _showSnackBar(AppLocalizations.of(context)!.customerSelectionRequired,
            isError: true);
        return;
      }

      if (finalServiceId == null || finalServiceId == 'custom') {
        _showSnackBar(AppLocalizations.of(context)!.serviceSelectionRequired,
            isError: true);
        return;
      }

      if (_selectedDate == null || _selectedTime == null) {
        _showSnackBar(
            '${AppLocalizations.of(context)!.dateSelectionRequired} - ${AppLocalizations.of(context)!.timeSelectionRequired}',
            isError: true);
        return;
      }

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Çakışma kontrolü
      if (widget.appointmentId == null) {
        final conflictCheck = await FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: user.uid)
            .where('appointmentDate',
                isEqualTo: Timestamp.fromDate(appointmentDateTime))
            .where('status', whereIn: ['Beklemede', 'Onaylandı']).get();

        if (conflictCheck.docs.isNotEmpty) {
          _showSnackBar(AppLocalizations.of(context)!.conflictingAppointment,
              isError: true);
          return;
        }
      }

      final appointmentData = {
        'userId': user.uid,
        'customerId': finalCustomerId,
        'serviceId': finalServiceId,
        'employeeId': finalEmployeeId,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'status': _selectedStatus,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Custom değerler için metadata (isteğe bağlı)
        'hasCustomData': _selectedCustomerId == 'custom' ||
            _selectedServiceId == 'custom' ||
            _selectedEmployeeId == 'custom',
      };

      if (widget.appointmentId != null) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update(appointmentData);
        _showSnackBar(AppLocalizations.of(context)!.appointmentUpdated);
      } else {
        appointmentData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);
        _showSnackBar(AppLocalizations.of(context)!.appointmentSaved);
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.appointmentId != null
                        ? AppLocalizations.of(context)!.editAppointment
                        : AppLocalizations.of(context)!.newAppointment,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri Seçimi
                      ModernDropdownWithCustom<String>(
                        label: AppLocalizations.of(context)!.customer,
                        value: _selectedCustomerId,
                        options: _customers
                            .map((customer) => customer['id'] as String)
                            .toList(),
                        optionLabel: (id) {
                          final customer = _customers.firstWhere(
                              (c) => c['id'] == id,
                              orElse: () => {'name': 'Bilinmeyen Müşteri'});
                          return customer['name'] as String;
                        },
                        optionValue: (id) => id,
                        icon: Icons.person,
                        customValue: _customCustomerName,
                        customOptionLabel:
                            AppLocalizations.of(context)!.newCustomer,
                        customInputLabel:
                            AppLocalizations.of(context)!.customerName,
                        customInputHint:
                            AppLocalizations.of(context)!.enterCustomerName,
                        isRequired: true,
                        onChanged: (value) {
                          setState(() => _selectedCustomerId = value);
                        },
                        onCustomValueChanged: (value) {
                          setState(() => _customCustomerName = value);
                        },
                        validator: (value) {
                          if (value == null)
                            return AppLocalizations.of(context)!
                                .customerSelectionRequired;
                          return null;
                        },
                        customValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!
                                .customerNameRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Hizmet Seçimi
                      ModernDropdownWithCustom<String>(
                        label: AppLocalizations.of(context)!.service,
                        value: _selectedServiceId,
                        options: _services
                            .map((service) => service['id'] as String)
                            .toList(),
                        optionLabel: (id) {
                          final service = _services.firstWhere(
                              (s) => s['id'] == id,
                              orElse: () =>
                                  {'name': 'Bilinmeyen Hizmet', 'price': 0.0});
                          return '${service['name']} - ₺${service['price']}';
                        },
                        optionValue: (id) => id,
                        icon: Icons.design_services,
                        customValue: _customServiceName,
                        customOptionLabel:
                            AppLocalizations.of(context)!.newService,
                        customInputLabel:
                            AppLocalizations.of(context)!.serviceName,
                        customInputHint:
                            AppLocalizations.of(context)!.enterServiceName,
                        isRequired: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceId = value;
                            if (value != null && value != 'custom') {
                              // Hizmet seçildiğinde fiyatı otomatik doldur
                              final selectedService = _services.firstWhere(
                                (service) => service['id'] == value,
                                orElse: () => {'price': 0.0},
                              );
                              _priceController.text =
                                  selectedService['price'].toString();
                            } else {
                              // Custom hizmet seçildiğinde fiyatı sıfırla
                              _priceController.text = '';
                            }
                          });
                        },
                        onCustomValueChanged: (value) {
                          setState(() => _customServiceName = value);
                        },
                        validator: (value) {
                          if (value == null)
                            return AppLocalizations.of(context)!
                                .serviceSelectionRequired;
                          return null;
                        },
                        customValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!
                                .serviceNameRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Çalışan Seçimi (Opsiyonel)
                      ModernDropdownWithCustom<String>(
                        label:
                            '${AppLocalizations.of(context)!.employee} ${AppLocalizations.of(context)!.optional}',
                        value: _selectedEmployeeId,
                        options: _employees
                            .map((employee) => employee['id'] as String)
                            .toList(),
                        optionLabel: (id) {
                          final employee = _employees.firstWhere(
                              (e) => e['id'] == id,
                              orElse: () => {'name': 'Bilinmeyen Çalışan'});
                          return employee['name'] as String;
                        },
                        optionValue: (id) => id,
                        icon: Icons.work,
                        customValue: _customEmployeeName,
                        customOptionLabel:
                            AppLocalizations.of(context)!.newEmployee,
                        customInputLabel:
                            AppLocalizations.of(context)!.employeeName,
                        customInputHint:
                            AppLocalizations.of(context)!.enterEmployeeName,
                        isRequired: false,
                        onChanged: (value) {
                          setState(() => _selectedEmployeeId = value);
                        },
                        onCustomValueChanged: (value) {
                          setState(() => _customEmployeeName = value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tarih ve Saat Seçimi - Layout constraint sorunlarını düzelt
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Geniş ekranlar için Row kullan
                            return Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 200),
                                    child: ModernTextField(
                                      label: AppLocalizations.of(context)!.date,
                                      hint: AppLocalizations.of(context)!
                                          .selectDate,
                                      controller: TextEditingController(
                                        text: _selectedDate != null
                                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                            : '',
                                      ),
                                      icon: Icons.calendar_today,
                                      readOnly: true,
                                      onTap: _selectDate,
                                      validator: (value) {
                                        if (_selectedDate == null)
                                          return AppLocalizations.of(context)!
                                              .dateSelectionRequired;
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  flex: 1,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 200),
                                    child: ModernTextField(
                                      label: AppLocalizations.of(context)!.time,
                                      hint: AppLocalizations.of(context)!
                                          .selectTime,
                                      controller: TextEditingController(
                                        text: _selectedTime != null
                                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                            : '',
                                      ),
                                      icon: Icons.access_time,
                                      readOnly: true,
                                      onTap: _selectTime,
                                      validator: (value) {
                                        if (_selectedTime == null)
                                          return AppLocalizations.of(context)!
                                              .timeSelectionRequired;
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Dar ekranlar için Column kullan
                            return Column(
                              children: [
                                ModernTextField(
                                  label: AppLocalizations.of(context)!.date,
                                  hint:
                                      AppLocalizations.of(context)!.selectDate,
                                  controller: TextEditingController(
                                    text: _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : '',
                                  ),
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: _selectDate,
                                  validator: (value) {
                                    if (_selectedDate == null)
                                      return AppLocalizations.of(context)!
                                          .dateSelectionRequired;
                                    return null;
                                  },
                                ),
                                ModernTextField(
                                  label: AppLocalizations.of(context)!.time,
                                  hint:
                                      AppLocalizations.of(context)!.selectTime,
                                  controller: TextEditingController(
                                    text: _selectedTime != null
                                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                        : '',
                                  ),
                                  icon: Icons.access_time,
                                  readOnly: true,
                                  onTap: _selectTime,
                                  validator: (value) {
                                    if (_selectedTime == null)
                                      return AppLocalizations.of(context)!
                                          .timeSelectionRequired;
                                    return null;
                                  },
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Durum ve Fiyat - Layout constraint sorunlarını düzelt
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Geniş ekranlar için Row kullan
                            return Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 200),
                                    child: ModernDropdown<String>(
                                      label:
                                          AppLocalizations.of(context)!.status,
                                      value: _selectedStatus,
                                      items: _statusOptions.map((status) {
                                        return DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                              () => _selectedStatus = value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  flex: 1,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 200),
                                    child: ModernTextField(
                                      label:
                                          AppLocalizations.of(context)!.price,
                                      hint: '0.00',
                                      controller: _priceController,
                                      icon: Icons.attach_money,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      textAlign: TextAlign.start,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!
                                              .priceRequired;
                                        }
                                        final amount =
                                            double.tryParse(value.trim());
                                        if (amount == null || amount < 0) {
                                          return AppLocalizations.of(context)!
                                              .validPriceRequired;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Dar ekranlar için Column kullan
                            return Column(
                              children: [
                                ModernDropdown<String>(
                                  label: AppLocalizations.of(context)!.status,
                                  value: _selectedStatus,
                                  items: _statusOptions.map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedStatus = value);
                                    }
                                  },
                                ),
                                ModernTextField(
                                  label: AppLocalizations.of(context)!.price,
                                  hint: '0.00',
                                  controller: _priceController,
                                  icon: Icons.attach_money,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.start,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .priceRequired;
                                    }
                                    final amount =
                                        double.tryParse(value.trim());
                                    if (amount == null || amount < 0) {
                                      return AppLocalizations.of(context)!
                                          .validPriceRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Notlar - Text input sorunlarını düzelt
                      Container(
                        width: double.infinity,
                        child: ModernTextField(
                          label: AppLocalizations.of(context)!.notes,
                          hint: AppLocalizations.of(context)!.appointmentNotes,
                          controller: _notesController,
                          icon: Icons.note,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: ModernButton(
                              text: AppLocalizations.of(context)!.cancel,
                              isPrimary: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernButton(
                              text: widget.appointmentId != null
                                  ? AppLocalizations.of(context)!.update
                                  : AppLocalizations.of(context)!.save,
                              isPrimary: true,
                              isLoading: _isLoading,
                              onPressed: _saveAppointment,
                            ),
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

// ==================== SERVICE FORM ====================

class BeautyServiceForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? serviceId;

  const BeautyServiceForm({
    Key? key,
    this.onSaved,
    this.serviceId,
  }) : super(key: key);

  @override
  State<BeautyServiceForm> createState() => _BeautyServiceFormState();
}

class _BeautyServiceFormState extends State<BeautyServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı oturumu bulunamadı', isError: true);
        return;
      }

      // Custom kategori işleme
      String finalCategory = _selectedCategory ?? 'Saç';

      final serviceData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'category': finalCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        // Custom kategori olup olmadığını belirt
        'hasCustomCategory': _selectedCategory != null,
      };

      if (widget.serviceId != null) {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.serviceId)
            .update(serviceData);
        _showSnackBar('Hizmet başarıyla güncellendi!');
      } else {
        serviceData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('services')
            .add(serviceData);
        _showSnackBar('Hizmet başarıyla eklendi!');
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.design_services,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.serviceId != null ? 'Hizmet Düzenle' : 'Yeni Hizmet',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hizmet Adı
                      ModernTextField(
                        label: 'Hizmet Adı',
                        hint: 'Ör: Saç Kesimi, Makyaj',
                        controller: _nameController,
                        icon: Icons.design_services,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Hizmet adı gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Kategori
                      ModernDropdownWithCustom<String>(
                        label: 'Kategori',
                        value: _selectedCategory,
                        options: [
                          'Saç',
                          'Makyaj',
                          'Cilt Bakımı',
                          'Manikür',
                          'Pedikür',
                          'Masaj',
                          'Epilasyon',
                          'Kaş-Kirpik'
                        ],
                        optionLabel: (category) => category,
                        optionValue: (category) => category,
                        icon: Icons.category,
                        customValue: _selectedCategory,
                        customOptionLabel: 'Özel Kategori',
                        customInputLabel: 'Kategori Adı',
                        customInputHint: 'Yeni kategori adını girin...',
                        isRequired: true,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                        onCustomValueChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Kategori seçimi gerekli';
                          return null;
                        },
                        customValidator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kategori adı gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Fiyat ve Süre
                      Row(
                        children: [
                          Expanded(
                            child: ModernTextField(
                              label: 'Fiyat (₺)',
                              hint: '0.00',
                              controller: _priceController,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Fiyat gerekli';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Geçerli bir fiyat girin';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernTextField(
                              label: 'Süre (dakika)',
                              hint: '60',
                              controller: _durationController,
                              icon: Icons.timer,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Süre gerekli';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null || duration <= 0) {
                                  return 'Geçerli bir süre girin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Aktif/Pasif
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hizmet Durumu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'Aktif - Randevu alınabilir'
                                        : 'Pasif - Randevu alınamaz',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() => _isActive = value);
                              },
                              activeColor: AppConstants.primaryColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Açıklama
                      ModernTextField(
                        label: 'Açıklama',
                        hint: 'Hizmet hakkında detaylar...',
                        controller: _descriptionController,
                        icon: Icons.description,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: ModernButton(
                              text: 'İptal',
                              isPrimary: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernButton(
                              text: widget.serviceId != null
                                  ? 'Güncelle'
                                  : 'Kaydet',
                              isPrimary: true,
                              isLoading: _isLoading,
                              onPressed: _saveService,
                            ),
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

// ==================== TRANSACTION FORM ====================

class BeautyTransactionForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? transactionId;

  const BeautyTransactionForm({
    Key? key,
    this.onSaved,
    this.transactionId,
  }) : super(key: key);

  @override
  State<BeautyTransactionForm> createState() => _BeautyTransactionFormState();
}

class _BeautyTransactionFormState extends State<BeautyTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _selectedDate;
  bool _isLoading = false;

  List<String> get _typeOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.transactionTypeIncome,
      localizations.transactionTypeExpense
    ];
  }

  List<String> get _paymentMethodOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.paymentMethodCash,
      localizations.paymentMethodCard,
      localizations.paymentMethodTransfer
    ];
  }

  Map<String, List<String>> get _categoryOptions {
    final localizations = AppLocalizations.of(context)!;
    return {
      localizations.transactionTypeIncome: [
        localizations.incomeCategoryAppointment,
        localizations.incomeCategoryProductSale,
        localizations.incomeCategoryOther
      ],
      localizations.transactionTypeExpense: [
        localizations.expenseCategoryRent,
        localizations.expenseCategorySalary,
        localizations.expenseCategoryBill,
        localizations.expenseCategoryEquipment,
        localizations.expenseCategoryMaterial,
        localizations.expenseCategoryCleaning,
        localizations.expenseCategoryAdvertising,
        localizations.expenseCategoryOther
      ],
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (widget.transactionId != null) {
      _loadTransactionData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize default values after localization is available
    if (_selectedType == null) {
      final localizations = AppLocalizations.of(context)!;
      _selectedType = localizations.transactionTypeIncome;
      _selectedCategory = localizations.incomeCategoryAppointment;
      _selectedPaymentMethod = localizations.paymentMethodCash;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionData() async {
    if (widget.transactionId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _amountController.text = (data['amount'] ?? 0.0).toString();
          _selectedType = data['type'] == 'income' ? 'Gelir' : 'Gider';
          _selectedCategory = _getCategoryDisplayName(data['category'] ?? '');
          _selectedPaymentMethod = data['paymentMethod'] ?? 'Nakit';
          _descriptionController.text = data['description'] ?? '';

          if (data['createdAt'] != null) {
            _selectedDate = (data['createdAt'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar('${localizations.transactionLoadError}: $e', isError: true);
    }
  }

  String _getCategoryDisplayName(String categoryKey) {
    final categoryMap = {
      'appointment': 'Randevu',
      'productSale': 'Ürün Satışı',
      'otherIncome': 'Diğer Gelir',
      'rent': 'Kira',
      'salary': 'Maaş',
      'invoice': 'Fatura',
      'equipment': 'Ekipman',
      'otherExpense': 'Diğer Gider',
    };
    return categoryMap[categoryKey] ?? 'Diğer';
  }

  String _getCategoryKey(String displayName) {
    final categoryMap = {
      'Randevu': 'appointment',
      'Ürün Satışı': 'productSale',
      'Diğer Gelir': 'otherIncome',
      'Kira': 'rent',
      'Maaş': 'salary',
      'Fatura': 'invoice',
      'Ekipman': 'equipment',
      'Malzeme': 'equipment',
      'Temizlik': 'otherExpense',
      'Reklam': 'otherExpense',
      'Diğer Gider': 'otherExpense',
    };
    return categoryMap[displayName] ?? 'otherIncome';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showSnackBar('Tarih seçimi gerekli', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı oturumu bulunamadı', isError: true);
        return;
      }

      final transactionData = {
        'userId': user.uid,
        'type': _selectedType == 'Gelir' ? 'income' : 'expense',
        'category': _getCategoryKey(_selectedCategory ?? ''),
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'paymentMethod': _selectedPaymentMethod,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.transactionId != null) {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(widget.transactionId)
            .update(transactionData);
        _showSnackBar('İşlem başarıyla güncellendi!');
      } else {
        transactionData['createdAt'] = Timestamp.fromDate(_selectedDate!);
        await FirebaseFirestore.instance
            .collection('transactions')
            .add(transactionData);
        _showSnackBar('İşlem başarıyla eklendi!');
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Hata: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.transactionId != null
                        ? 'İşlem Düzenle'
                        : 'Yeni İşlem',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      ModernTextField(
                        label: 'Açıklama',
                        hint:
                            'İşlem açıklaması (örn: Saç kesimi, Kira ödemesi)',
                        controller: _titleController,
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Açıklama gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tür ve Kategori
                      Row(
                        children: [
                          Expanded(
                            child: ModernDropdown<String>(
                              label: 'Tür',
                              value: _selectedType,
                              icon: Icons.trending_up,
                              items: _typeOptions.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = value;
                                    // Tür değiştiğinde kategorileri güncelle
                                    final categories =
                                        _categoryOptions[value] ?? [];
                                    if (categories.isNotEmpty &&
                                        !categories
                                            .contains(_selectedCategory)) {
                                      _selectedCategory = categories.first;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernDropdown<String>(
                              label: 'Kategori',
                              value: _selectedCategory,
                              icon: Icons.category,
                              items: (_categoryOptions[_selectedType] ?? [])
                                  .map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tutar ve Tarih
                      Row(
                        children: [
                          Expanded(
                            child: ModernTextField(
                              label: 'Tutar (₺)',
                              hint: '0.00',
                              controller: _amountController,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tutar gerekli';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Geçerli bir tutar girin';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernTextField(
                              label: 'Tarih',
                              hint: 'Tarih seçin',
                              controller: TextEditingController(
                                text: _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : '',
                              ),
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _selectDate,
                              validator: (value) {
                                if (_selectedDate == null)
                                  return 'Tarih seçimi gerekli';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Ödeme Yöntemi
                      ModernDropdown<String>(
                        label: 'Ödeme Tipi',
                        value: _selectedPaymentMethod,
                        icon: Icons.credit_card,
                        items: _paymentMethodOptions.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPaymentMethod = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Notlar
                      ModernTextField(
                        label: 'Notlar',
                        hint: 'İşlem hakkında ek bilgiler...',
                        controller: _descriptionController,
                        icon: Icons.note,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: ModernButton(
                              text: 'İptal',
                              isPrimary: false,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ModernButton(
                              text: widget.transactionId != null
                                  ? 'Güncelle'
                                  : 'Kaydet',
                              isPrimary: true,
                              isLoading: _isLoading,
                              onPressed: _saveTransaction,
                            ),
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

// ==================== EXPENSE FORM ====================

class BeautyExpenseForm extends StatefulWidget {
  final VoidCallback? onSaved;
  final String? expenseId;

  const BeautyExpenseForm({
    Key? key,
    this.onSaved,
    this.expenseId,
  }) : super(key: key);

  @override
  State<BeautyExpenseForm> createState() => _BeautyExpenseFormState();
}

class _BeautyExpenseFormState extends State<BeautyExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Diğer';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Kira',
    'Maaş',
    'Malzeme',
    'Pazarlama',
    'Faturalar',
    'Bakım',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _loadExpenseData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenseData() async {
    if (widget.expenseId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('expenses')
          .doc(widget.expenseId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _amountController.text = (data['amount'] ?? 0.0).toString();
          _descriptionController.text = data['description'] ?? '';
          _selectedCategory = data['category'] ?? 'Diğer';
          _isRecurring = data['isRecurring'] ?? false;

          if (data['date'] != null) {
            _selectedDate = (data['date'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      _showSnackBar('Gider bilgileri yüklenirken hata oluştu', isError: true);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Kullanıcı oturumu bulunamadı', isError: true);
        return;
      }

      final expenseData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'date': Timestamp.fromDate(_selectedDate),
        'isRecurring': _isRecurring,
        'description': _descriptionController.text.trim(),
        'isPaid': false,
        'priority': 'medium',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.expenseId != null) {
        // Güncelleme
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.expenseId)
            .update(expenseData);
        _showSnackBar('Gider başarıyla güncellendi');
      } else {
        // Yeni ekleme
        expenseData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('expenses')
            .add(expenseData);
        _showSnackBar('Gider başarıyla eklendi');
      }

      if (widget.onSaved != null) {
        widget.onSaved!();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Gider kaydedilirken hata: $e');
      _showSnackBar('Gider kaydedilirken hata oluştu', isError: true);
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.money_off_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.expenseId != null
                        ? 'Gider Düzenle'
                        : 'Yeni Gider Ekle',
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
                          // Gider Adı
                          ModernTextField(
                            controller: _titleController,
                            label: 'Gider Adı',
                            icon: Icons.title,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Gider adı gerekli';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Tutar
                          ModernTextField(
                            controller: _amountController,
                            label: 'Tutar (₺)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tutar gerekli';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Geçerli bir tutar girin';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Kategori ve Tarih
                          Row(
                            children: [
                              Expanded(
                                child: ModernDropdown<String>(
                                  label: 'Kategori',
                                  value: _selectedCategory,
                                  icon: Icons.category,
                                  items: _categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCategory = value);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Kategori seçin';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ModernTextField(
                                  label: 'Tarih',
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text:
                                        "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}",
                                  ),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sürekli Gider Checkbox
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.repeat_outlined,
                                  color: AppConstants.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sürekli Gider',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Bu gider her ay tekrar eder',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isRecurring,
                                  onChanged: (value) {
                                    setState(() => _isRecurring = value);
                                  },
                                  activeColor: AppConstants.primaryColor,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Açıklama
                          ModernTextField(
                            controller: _descriptionController,
                            label: 'Açıklama',
                            icon: Icons.description,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 24),

                          // Kaydet Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ModernButton(
                              onPressed: _isLoading ? null : _saveExpense,
                              isPrimary: true,
                              text: widget.expenseId != null
                                  ? 'Güncelle'
                                  : 'Kaydet',
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== EMPLOYEE FORM ====================

class BeautyEmployeeForm extends StatefulWidget {
  final String? employeeId;
  final VoidCallback onSaved;

  const BeautyEmployeeForm({
    super.key,
    this.employeeId,
    required this.onSaved,
  });

  @override
  State<BeautyEmployeeForm> createState() => _BeautyEmployeeFormState();
}

class _BeautyEmployeeFormState extends State<BeautyEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _commissionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Kadın';
  String _selectedStatus = 'active';
  String _selectedWorkingHours = '09:00-18:00';
  DateTime? _selectedStartDate;
  List<String> _selectedSkills = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<String> _genderOptions = ['Kadın', 'Erkek', 'Belirtmek İstemiyor'];
  final List<String> _statusOptions = ['active', 'leave', 'inactive'];
  final List<String> _workingHoursOptions = [
    '09:00-18:00',
    '10:00-19:00',
    '08:00-17:00',
    '09:00-17:00',
    'Esnek Çalışma'
  ];
  final List<String> _availableSkills = [
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _commissionController.dispose();
    _experienceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    if (widget.employeeId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.employeeId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _positionController.text = data['position'] ?? '';
        _salaryController.text = data['salary']?.toString() ?? '';
        _commissionController.text = data['commission']?.toString() ?? '';
        _experienceController.text = data['experience']?.toString() ?? '';
        _notesController.text = data['notes'] ?? '';

        setState(() {
          _selectedGender = data['gender'] ?? 'Kadın';
          _selectedStatus = data['status'] ?? 'active';
          _selectedWorkingHours = data['workingHours'] ?? '09:00-18:00';
          _selectedStartDate =
              (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
          _selectedSkills = List<String>.from(data['skills'] ?? []);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Çalışan bilgileri yüklenirken hata: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
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
                      _isEditMode ? 'Çalışan Düzenle' : 'Yeni Çalışan',
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
                            // Kişisel Bilgiler
                            _buildSectionTitle(
                                'Kişisel Bilgiler', Icons.person),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Ad Soyad *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ad soyad gerekli';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Telefon gerekli';
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
                                      prefixIcon: Icon(Icons.wc_outlined),
                                    ),
                                    items: _genderOptions
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedGender = value!),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 24),

                            // İş Bilgileri
                            _buildSectionTitle(
                                'İş Bilgileri', Icons.work_outline),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _positionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Pozisyon *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Pozisyon gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    decoration: const InputDecoration(
                                      labelText: 'Durum',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.info_outline),
                                    ),
                                    items: _statusOptions
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(_getStatusText(status)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedStatus = value!),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
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
                                const SizedBox(width: 16),
                                Expanded(
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

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedWorkingHours,
                                    decoration: const InputDecoration(
                                      labelText: 'Çalışma Saatleri',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.schedule_outlined),
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
                                        () => _selectedWorkingHours = value!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _experienceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Deneyim (Yıl)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.timeline_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // İşe Başlama Tarihi
                            GestureDetector(
                              onTap: () => _selectStartDate(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined),
                                    const SizedBox(width: 12),
                                    Text(
                                      'İşe Başlama: ${_formatDate(_selectedStartDate!)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Yetenekler
                            _buildSectionTitle(
                                'Yetenekler', Icons.star_outline),
                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableSkills.map((skill) {
                                final isSelected =
                                    _selectedSkills.contains(skill);
                                return FilterChip(
                                  label: Text(skill),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSkills.add(skill);
                                      } else {
                                        _selectedSkills.remove(skill);
                                      }
                                    });
                                  },
                                  backgroundColor: AppConstants.surfaceColor,
                                  selectedColor: Colors.purple.shade100,
                                  checkmarkColor: Colors.purple.shade600,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Notlar
                            _buildSectionTitle('Notlar', Icons.note_outlined),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Ek Notlar',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note_outlined),
                                hintText: 'Çalışan hakkında ek bilgiler...',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditMode ? 'Güncelle' : 'Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedStartDate = date);
    }
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartDate == null) {
      _showErrorSnackBar('İşe başlama tarihi seçimi gerekli');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final employeeData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'position': _positionController.text.trim(),
        'status': _selectedStatus,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'commission': double.tryParse(_commissionController.text) ?? 0.0,
        'workingHours': _selectedWorkingHours,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'startDate': Timestamp.fromDate(_selectedStartDate!),
        'skills': _selectedSkills,
        'notes': _notesController.text.trim(),
        'createdAt': _isEditMode ? null : Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'rating': 5.0, // Varsayılan değer
        'monthlyTarget': 0,
        'completedTarget': 0,
        'isActive': _selectedStatus == 'active',
      };

      if (_isEditMode) {
        employeeData.remove('createdAt');
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(widget.employeeId)
            .update(employeeData);
      } else {
        await FirebaseFirestore.instance
            .collection('employees')
            .add(employeeData);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Çalışan kaydedilirken hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }
}

// ==================== TODO FORM ====================

class BeautyTodoForm extends StatefulWidget {
  final String? todoId;
  final VoidCallback onSaved;

  const BeautyTodoForm({
    super.key,
    this.todoId,
    required this.onSaved,
  });

  @override
  State<BeautyTodoForm> createState() => _BeautyTodoFormState();
}

class _BeautyTodoFormState extends State<BeautyTodoForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Genel';
  String _selectedPriority = 'medium';
  String _assignedTo = '';
  DateTime? _selectedDueDate;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<String> _categories = [
    'Genel',
    'Müşteri',
    'Malzeme',
    'Pazarlama',
    'Bakım',
    'Eğitim',
    'Finans',
  ];

  final List<String> _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.todoId != null;
    _selectedDueDate = DateTime.now().add(const Duration(days: 1));
    if (_isEditMode) {
      _loadTodoData();
    }
  }

  Future<void> _loadTodoData() async {
    if (widget.todoId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('todos')
          .doc(widget.todoId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';

        setState(() {
          _selectedCategory = data['category'] ?? 'Genel';
          _selectedPriority = data['priority'] ?? 'medium';
          _assignedTo = data['assignedTo'] ?? '';
          _selectedDueDate =
              (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
          _isCompleted = data['isCompleted'] ?? false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Görev bilgileri yüklenirken hata: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.add_task,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditMode ? 'Görev Düzenle' : 'Yeni Görev',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
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
                            // Görev Başlığı
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Görev Başlığı *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.task_outlined),
                                hintText: 'Görev adını girin',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Görev başlığı gerekli';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Açıklama
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description_outlined),
                                hintText: 'Görev detayları...',
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 16),

                            // Kategori ve Öncelik
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: _categories
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedCategory = value!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPriority,
                                    decoration: const InputDecoration(
                                      labelText: 'Öncelik',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.priority_high_outlined),
                                    ),
                                    items: _priorities
                                        .map(
                                          (priority) => DropdownMenuItem(
                                            value: priority,
                                            child: Text(
                                                _getPriorityText(priority)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => _selectedPriority = value!),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Atanan Kişi
                            TextFormField(
                              initialValue: _assignedTo,
                              decoration: const InputDecoration(
                                labelText: 'Atanan Kişi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Çalışan adı (isteğe bağlı)',
                              ),
                              onChanged: (value) => _assignedTo = value,
                            ),

                            const SizedBox(height: 16),

                            // Son Tarih
                            GestureDetector(
                              onTap: () => _selectDueDate(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Son Tarih: ${_formatDate(_selectedDueDate!)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Tamamlandı Durumu (Sadece düzenleme modunda)
                            if (_isEditMode) ...[
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isCompleted,
                                    onChanged: (value) => setState(
                                        () => _isCompleted = value ?? false),
                                    activeColor: Colors.orange.shade600,
                                  ),
                                  const Text(
                                    'Görev tamamlandı',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditMode ? 'Güncelle' : 'Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      default:
        return priority;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDueDate == null) {
      _showErrorSnackBar('Son tarih seçimi gerekli');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final todoData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'assignedTo': _assignedTo.trim(),
        'dueDate': Timestamp.fromDate(_selectedDueDate!),
        'isCompleted': _isCompleted,
        'createdAt': _isEditMode ? null : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      if (_isEditMode) {
        todoData.remove('createdAt');
        await FirebaseFirestore.instance
            .collection('todos')
            .doc(widget.todoId)
            .update(todoData);
      } else {
        await FirebaseFirestore.instance.collection('todos').add(todoData);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Görev kaydedilirken hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }
}
