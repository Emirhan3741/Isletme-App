import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class AddressSectionWidget extends StatefulWidget {
  final String? initialCountry;
  final String? initialCity;
  final String? initialDistrict;
  final String? initialZipCode;
  final String? initialFullAddress;
  final Function(String?) onCountryChanged;
  final Function(String?) onCityChanged;
  final Function(String?) onDistrictChanged;
  final Function(String?) onZipCodeChanged;
  final Function(String?) onFullAddressChanged;
  final bool isRequired;

  const AddressSectionWidget({
    super.key,
    this.initialCountry,
    this.initialCity,
    this.initialDistrict,
    this.initialZipCode,
    this.initialFullAddress,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onDistrictChanged,
    required this.onZipCodeChanged,
    required this.onFullAddressChanged,
    this.isRequired = true,
  });

  @override
  State<AddressSectionWidget> createState() => _AddressSectionWidgetState();
}

class _AddressSectionWidgetState extends State<AddressSectionWidget> {
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _zipCodeController;
  late TextEditingController _fullAddressController;

  String? _selectedCountry;

  // Ülke listesi
  final List<Map<String, String>> _countries = [
    {'code': 'TR', 'name': 'Türkiye'},
    {'code': 'US', 'name': 'Amerika Birleşik Devletleri'},
    {'code': 'DE', 'name': 'Almanya'},
    {'code': 'FR', 'name': 'Fransa'},
    {'code': 'GB', 'name': 'Birleşik Krallık'},
    {'code': 'IT', 'name': 'İtalya'},
    {'code': 'ES', 'name': 'İspanya'},
    {'code': 'NL', 'name': 'Hollanda'},
    {'code': 'BE', 'name': 'Belçika'},
    {'code': 'AT', 'name': 'Avusturya'},
    {'code': 'CH', 'name': 'İsviçre'},
    {'code': 'SE', 'name': 'İsveç'},
    {'code': 'NO', 'name': 'Norveç'},
    {'code': 'DK', 'name': 'Danimarka'},
    {'code': 'FI', 'name': 'Finlandiya'},
    {'code': 'CA', 'name': 'Kanada'},
    {'code': 'AU', 'name': 'Avustralya'},
    {'code': 'JP', 'name': 'Japonya'},
    {'code': 'KR', 'name': 'Güney Kore'},
    {'code': 'SG', 'name': 'Singapur'},
    {'code': 'AE', 'name': 'Birleşik Arap Emirlikleri'},
    {'code': 'SA', 'name': 'Suudi Arabistan'},
    {'code': 'BR', 'name': 'Brezilya'},
    {'code': 'MX', 'name': 'Meksika'},
    {'code': 'AR', 'name': 'Arjantin'},
    {'code': 'CL', 'name': 'Şili'},
    {'code': 'IN', 'name': 'Hindistan'},
    {'code': 'CN', 'name': 'Çin'},
    {'code': 'RU', 'name': 'Rusya'},
    {'code': 'ZA', 'name': 'Güney Afrika'},
    {'code': 'EG', 'name': 'Mısır'},
    {'code': 'MA', 'name': 'Fas'},
    {'code': 'NG', 'name': 'Nijerya'},
  ];

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity);
    _districtController = TextEditingController(text: widget.initialDistrict);
    _zipCodeController = TextEditingController(text: widget.initialZipCode);
    _fullAddressController =
        TextEditingController(text: widget.initialFullAddress);
    _selectedCountry = widget.initialCountry;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _zipCodeController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppConstants.textLight.withValues(alpha: 0.3)),
        color: AppConstants.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              const Text(
                'Adres Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppConstants.errorColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Ülke Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Ülke',
              prefixIcon: Icon(Icons.flag),
            ),
            items: _countries.map((country) {
              return DropdownMenuItem<String>(
                value: country['code'],
                child: Text(country['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
              widget.onCountryChanged(value);
            },
            validator: widget.isRequired
                ? (value) => value?.isEmpty == true ? 'Ülke seçiniz' : null
                : null,
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Şehir ve İlçe - Yan yana
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onChanged: widget.onCityChanged,
                  validator: widget.isRequired
                      ? (value) =>
                          value?.isEmpty == true ? 'Şehir gereklidir' : null
                      : null,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'İlçe / Bölge',
                    prefixIcon: Icon(Icons.map),
                  ),
                  onChanged: widget.onDistrictChanged,
                  validator: widget.isRequired
                      ? (value) =>
                          value?.isEmpty == true ? 'İlçe gereklidir' : null
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Posta Kodu
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'Posta Kodu',
                prefixIcon: Icon(Icons.markunread_mailbox),
              ),
              keyboardType: TextInputType.text,
              onChanged: widget.onZipCodeChanged,
              validator: widget.isRequired
                  ? (value) =>
                      value?.isEmpty == true ? 'Posta kodu gereklidir' : null
                  : null,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Açık Adres
          TextFormField(
            controller: _fullAddressController,
            decoration: const InputDecoration(
              labelText: 'Açık Adres',
              prefixIcon: Icon(Icons.home),
              hintText: 'Mahalle, sokak, bina no, daire no vb.',
            ),
            maxLines: 3,
            onChanged: widget.onFullAddressChanged,
            validator: widget.isRequired
                ? (value) =>
                    value?.isEmpty == true ? 'Açık adres gereklidir' : null
                : null,
          ),
        ],
      ),
    );
  }
}

// Ülke kod helper fonksiyonu
class CountryHelper {
  static String getCountryName(String? countryCode) {
    if (countryCode == null) return '';

    const countries = {
      'TR': 'Türkiye',
      'US': 'Amerika Birleşik Devletleri',
      'DE': 'Almanya',
      'FR': 'Fransa',
      'GB': 'Birleşik Krallık',
      'IT': 'İtalya',
      'ES': 'İspanya',
      'NL': 'Hollanda',
      'BE': 'Belçika',
      'AT': 'Avusturya',
      'CH': 'İsviçre',
      'SE': 'İsveç',
      'NO': 'Norveç',
      'DK': 'Danimarka',
      'FI': 'Finlandiya',
      'CA': 'Kanada',
      'AU': 'Avustralya',
      'JP': 'Japonya',
      'KR': 'Güney Kore',
      'SG': 'Singapur',
      'AE': 'Birleşik Arap Emirlikleri',
      'SA': 'Suudi Arabistan',
      'BR': 'Brezilya',
      'MX': 'Meksika',
      'AR': 'Arjantin',
      'CL': 'Şili',
      'IN': 'Hindistan',
      'CN': 'Çin',
      'RU': 'Rusya',
      'ZA': 'Güney Afrika',
      'EG': 'Mısır',
      'MA': 'Fas',
      'NG': 'Nijerya',
    };

    return countries[countryCode] ?? countryCode;
  }
}
