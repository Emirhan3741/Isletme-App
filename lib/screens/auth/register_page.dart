import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/locale_provider.dart';
import '../../providers/currency_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/address_section_widget.dart';
// import '../../widgets/timezone_section_widget.dart'; // Widget eksik - geçici olarak kapatıldı
import '../../widgets/google_sign_in_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'owner';
  String _selectedSector = 'güzellik_salon';
  String _selectedLanguage = 'tr';
  String _selectedCurrency = '₺';

  // Adres bilgileri
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedZipCode;
  String? _selectedFullAddress;

  // Saat dilimi
  String? _selectedTimeZone;

  final List<Map<String, String>> _roles = [
    {'value': 'owner', 'label': 'İşyeri Sahibi'},
    {'value': 'worker', 'label': 'Çalışan'},
  ];

  final List<Map<String, String>> _sectors = [
    {'value': 'güzellik_salon', 'label': 'Güzellik Salonu / Kuaför'},
    {'value': 'estetik', 'label': 'Estetik Merkezi / Klinik'},
    {'value': 'psikoloji', 'label': 'Psikolog / Psikiyatrist'},
    {'value': 'sağlık', 'label': 'Sağlık / Klinik / Doktor'},
    {'value': 'veteriner', 'label': 'Veteriner Klinik'},
    {'value': 'avukat', 'label': 'Avukat / Hukuk Bürosu'},
    {'value': 'emlak', 'label': 'Emlak Ofisi / Gayrimenkul'},
    {'value': 'eğitim', 'label': 'Eğitim / Kurs / Öğretim'},
    {'value': 'fitness', 'label': 'Spor / Fitness / Koçluk'},
    {'value': 'masaj', 'label': 'Masaj Terapisti / SPA'},
    {'value': 'diyetisyen', 'label': 'Diyetisyen / Beslenme'},
  ];

  // Eski sector değerlerini yeni değerlerle eşleştir
  String _mapSectorValue(String value) {
    final sectorMapping = {
      // Psikoloji - eski değerler
      'psikolog': 'psikoloji',
      'psychology': 'psikoloji',
      'terapi': 'psikoloji',
      'clinic': 'psikoloji',

      // Güzellik - eski değerler
      'güzellik': 'güzellik_salon',
      'beauty': 'güzellik_salon',
      'kuaför': 'güzellik_salon',
      'berber': 'güzellik_salon',

      // Sağlık - eski değerler
      'klinik': 'sağlık',
      'doktor': 'sağlık',
      'hekim': 'sağlık',
      'diş': 'sağlık',
      'health': 'sağlık',

      // Eğitim - eski değerler
      'eğitmen': 'eğitim',
      'education': 'eğitim',
      'egitim': 'eğitim',
      'kurs': 'eğitim',
      'kurs_merkezi': 'eğitim',
      'öğretmen': 'eğitim',
      'akademi': 'eğitim',
      'course': 'eğitim',

      // Spor - eski değerler
      'spor': 'fitness',
      'koçluk': 'fitness',
      'coaching': 'fitness',
      'yoga': 'fitness',
      'pilates': 'fitness',
      'antrenör': 'fitness',
      'beslenme': 'fitness',

      // Hukuk - eski değerler
      'lawyer': 'avukat',
      'hukuk': 'avukat',
      'hukuk_bürosu': 'avukat',

      // Emlak - eski değerler
      'real_estate': 'emlak',
      'emlak_ofisi': 'emlak',
      'gayrimenkul': 'emlak',

      // Masaj/SPA - eski değerler
      'spa': 'masaj',
      'massage': 'masaj',
      'solaryum': 'masaj',

      // Estetik - eski değerler
      'aesthetic': 'estetik',
      'nail_art': 'estetik',

      // Veteriner - eski değerler
      'vet': 'veteriner',
    };

    // Eğer mapping'de varsa, yeni değeri döndür
    if (sectorMapping.containsKey(value)) {
      return sectorMapping[value]!;
    }

    // Eğer değer zaten _sectors listesinde varsa, olduğu gibi döndür
    final validSectors = _sectors.map((s) => s['value']).toList();
    if (validSectors.contains(value)) {
      return value;
    }

    // Eğer hiçbiri uymazsa, varsayılan değer döndür
    return 'güzellik_salon';
  }

  // Dil seçenekleri
  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
  ];

  @override
  void initState() {
    super.initState();

    // Route arguments'ı kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments['sector'] != null) {
        setState(() {
          _selectedSector = _mapSectorValue(arguments['sector']);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      final currencyProvider =
          Provider.of<CurrencyProvider>(context, listen: false);

      // AuthProvider ile kullanıcı oluştur
      final success = await authProvider.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (success) {
        // Kullanıcı profiliğine dil ve para birimi bilgilerini ekle
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'languageCode': _selectedLanguage,
            'currencySymbol': _selectedCurrency,
            // Adres bilgileri
            'country': _selectedCountry,
            'city': _selectedCity,
            'district': _selectedDistrict,
            'zipCode': _selectedZipCode,
            'fullAddress': _selectedFullAddress,
            // Saat dilimi
            'timeZone': _selectedTimeZone,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Provider'ları güncelle
          await localeProvider.setLocale(Locale(_selectedLanguage));
          await currencyProvider.setCurrency(_selectedCurrency);
        }

        if (mounted) {
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kayıt başarılı! Hoş geldiniz ${_nameController.text.trim()}!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // 1 saniye bekle ve otomatik olarak dashboard'a yönlendir
          await Future.delayed(Duration(seconds: 1));

          if (mounted) {
            // AuthWrapper otomatik olarak doğru dashboard'a yönlendirecek
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf. En az 6 karakter olmalı.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanılıyor.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        default:
          errorMessage = 'Kayıt sırasında hata oluştu: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withValues(alpha: 102),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${localizations.register} 🚀",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.welcome,
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Ad Soyad
                  _CustomTextField(
                    hint: localizations.fullName,
                    controller: _nameController,
                    prefixIcon: Icons.person_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.required;
                      }
                      if (value.trim().length < 2) {
                        return '${localizations.fullName} en az 2 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // E-posta
                  _CustomTextField(
                    hint: localizations.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '${localizations.email} ${localizations.required.toLowerCase()}';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rol Seçimi
                  _CustomDropdown(
                    hint: localizations.role,
                    value: _selectedRole,
                    prefixIcon: Icons.work_outlined,
                    items: [
                      {'value': 'owner', 'label': localizations.owner},
                      {'value': 'worker', 'label': localizations.employee},
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Meslek Grubu Seçimi
                  _CustomDropdown(
                    hint: localizations.sector,
                    value: _selectedSector,
                    prefixIcon: Icons.business_outlined,
                    items: _sectors,
                    onChanged: (value) {
                      setState(() {
                        _selectedSector = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dil Seçimi
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: InputDecoration(
                        hintText: localizations.selectLanguage,
                        prefixIcon: Icon(
                          Icons.language_outlined,
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _languages.map((language) {
                        return DropdownMenuItem<String>(
                          value: language['code'],
                          child: Row(
                            children: [
                              Text(
                                language['flag']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                language['name']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                                                  onChanged: (value) async {
                              setState(() {
                                _selectedLanguage = value!;
                              });
                              
                              // Dil seçimi anında uygulanmalı
                              final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
                              await localeProvider.setLocale(Locale(_selectedLanguage));
                              
                              debugPrint('🌐 Dil anında değiştirildi: $_selectedLanguage');
                            },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Para Birimi Seçimi
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        hintText: localizations.selectCurrency,
                        prefixIcon: Icon(
                          Icons.attach_money_outlined,
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          CurrencyProvider.supportedCurrencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency['symbol'],
                          child: Text(
                            '${currency['name']} (${currency['symbol']})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Adres Bölümü
                  AddressSectionWidget(
                    initialCountry: _selectedCountry,
                    initialCity: _selectedCity,
                    initialDistrict: _selectedDistrict,
                    initialZipCode: _selectedZipCode,
                    initialFullAddress: _selectedFullAddress,
                    onCountryChanged: (value) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    },
                    onCityChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    },
                    onDistrictChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    onZipCodeChanged: (value) {
                      setState(() {
                        _selectedZipCode = value;
                      });
                    },
                    onFullAddressChanged: (value) {
                      setState(() {
                        _selectedFullAddress = value;
                      });
                    },
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),

                  // Saat Dilimi Bölümü - Temporarily disabled
                  /*
                  TimezoneSectionWidget(
                    initialTimeZone: _selectedTimeZone,
                    onTimeZoneChanged: (value) {
                      setState(() {
                        _selectedTimeZone = value;
                      });
                    },
                    isRequired: false,
                  ),
                  */
                  const SizedBox(height: 24),

                  // Şifre
                  _CustomTextField(
                    hint: localizations.password,
                    obscure: _obscurePassword,
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '${localizations.password} ${localizations.required.toLowerCase()}';
                      }
                      if (value.length < 6) {
                        return '${localizations.password} en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre Tekrar
                  _CustomTextField(
                    hint: localizations.confirmPassword,
                    obscure: _obscureConfirmPassword,
                    controller: _confirmPasswordController,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '${localizations.confirmPassword} ${localizations.required.toLowerCase()}';
                      }
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Kayıt Ol Butonu
                  _PrimaryButton(
                    label: _isLoading
                        ? "${localizations.register}..."
                        : localizations.register,
                    onTap: _isLoading ? null : _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Ayırıcı (veya)
                  // Ayırıcı widget
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(localizations.or),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                  // Google ile Kayıt Ol Butonu
                  GoogleSignInButton(
                    buttonText: localizations.signUpWithGoogle,
                  ),
                  const SizedBox(height: 20),

                  // Giriş Yap Butonu
                  _SecondaryButton(
                    label: AppLocalizations.of(context)!.login,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ana Sayfaya Dön
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Text(
                      localizations.home,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Primary Button
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.blue.shade100,
      ),
      onPressed: onTap,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}

// Modern Secondary Button
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A73E8),
        side: const BorderSide(color: Color(0xFF1A73E8)),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

// Modern Custom TextField
class _CustomTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey.shade600)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// Modern Custom Dropdown
class _CustomDropdown extends StatelessWidget {
  final String hint;
  final String value;
  final IconData? prefixIcon;
  final List<Map<String, String>> items;
  final ValueChanged<String?> onChanged;

  const _CustomDropdown({
    required this.hint,
    required this.value,
    this.prefixIcon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Value'nun items listesinde olup olmadığını kontrol et
    String? validValue = value;
    final hasValue = items.any((item) => item['value'] == value);
    if (!hasValue) {
      validValue = null; // Eğer value items'da yoksa null yap
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey.shade600)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(
              item['label']!,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
