import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_selector_widget.dart';
import '../../widgets/address_section_widget.dart';
// import '../../widgets/timezone_section_widget.dart';  // Widget silindi
import '../../core/constants/app_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedCurrency = '₺';
  final _currencies = const ['₺', '\$', '€', '£', '¥', '₹', '₩'];

  // Adres bilgileri
  String? _selectedCountry;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedZipCode;
  String? _selectedFullAddress;

  // Saat dilimi
  String? _selectedTimeZone;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final settings = data['settings'] as Map<String, dynamic>?;

          setState(() {
            _selectedCurrency = settings?['currency'] ?? '₺';
            // Adres bilgileri
            _selectedCountry = data['country'];
            _selectedCity = data['city'];
            _selectedDistrict = data['district'];
            _selectedZipCode = data['zipCode'];
            _selectedFullAddress = data['fullAddress'];
            // Saat dilimi
            _selectedTimeZone = data['timeZone'];
          });
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _saveCurrencySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'settings.currency': _selectedCurrency,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsSaved),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.error),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveAddressAndTimeZone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'country': _selectedCountry,
          'city': _selectedCity,
          'district': _selectedDistrict,
          'zipCode': _selectedZipCode,
          'fullAddress': _selectedFullAddress,
          'timeZone': _selectedTimeZone,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: const Text('Adres ve saat dilimi ayarları kaydedildi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ayarlar kaydedilemedi: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            _buildSectionCard(
              icon: Icons.language,
              title: localizations.language,
              subtitle: LocaleProvider
                      .languageNames[localeProvider.locale.languageCode] ??
                  'Türkçe',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.selectLanguage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const LanguageSelectorWidget(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 25),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations.languageChangeNote,
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Currency Section
            _buildSectionCard(
              icon: Icons.attach_money,
              title: localizations.currency,
              subtitle: _selectedCurrency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.selectCurrency,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.textLight),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                      color: AppConstants.surfaceColor,
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(
                            '${_getCurrencyName(currency)} ($currency)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                          _saveCurrencySettings();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Address Section
            _buildSectionCard(
              icon: Icons.location_on,
              title: 'Adres Bilgileri',
              subtitle: _getAddressSubtitle(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    isRequired: false,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ElevatedButton(
                    onPressed: _saveAddressAndTimeZone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Adres Bilgilerini Kaydet'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Timezone Section
            _buildSectionCard(
              icon: Icons.access_time,
              title: 'Saat Dilimi',
              subtitle: _selectedTimeZone ?? 'Seçilmedi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TimezoneSectionWidget widget silindi - geçici olarak kapatıldı
                  /*
                  TimezoneSectionWidget(
                    initialTimeZone: _selectedTimeZone,
                    onTimeZoneChanged: (value) {
                      setState(() {
                        _selectedTimeZone = value;
                      });
                      _saveAddressAndTimeZone();
                    },
                    isRequired: false,
                  ),
                  */
                  Text('Saat Dilimi: ${_selectedTimeZone ?? "Seçilmedi"}'),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // System Information
            _buildSectionCard(
              icon: Icons.info,
              title: localizations.systemInfo,
              subtitle: localizations.currentLanguage,
              child: Column(
                children: [
                  _buildInfoRow(
                    localizations.currentLanguage,
                    LocaleProvider.languageNames[
                            localeProvider.locale.languageCode] ??
                        'Türkçe',
                  ),
                  _buildInfoRow(
                    localizations.textDirection,
                    localeProvider.isRTL
                        ? localizations.rtl
                        : localizations.ltr,
                  ),
                  _buildInfoRow(
                    localizations.dateFormat,
                    DateFormat.yMd(localeProvider.locale.languageCode)
                        .format(DateTime.now()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Quick Language Switch
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          localizations.quickLanguageSwitch,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    ElevatedButton(
                      onPressed: () {
                        LanguageSelectorWidget.showLanguageModal(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                          vertical: AppConstants.paddingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language),
                          const SizedBox(width: 8),
                          Text(localizations.changeLanguage),
                        ],
                      ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppConstants.textDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppConstants.textMedium,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppConstants.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencyName(String symbol) {
    switch (symbol) {
      case '₺':
        return 'Turkish Lira';
      case '\$':
        return 'US Dollar';
      case '€':
        return 'Euro';
      case '£':
        return 'British Pound';
      case '¥':
        return 'Japanese Yen';
      case '₹':
        return 'Indian Rupee';
      case '₩':
        return 'Korean Won';
      default:
        return 'Unknown Currency';
    }
  }

  String _getAddressSubtitle() {
    if (_selectedCity?.isNotEmpty == true) {
      return _selectedCity!;
    }
    return 'Henüz girilmedi';
  }
}
