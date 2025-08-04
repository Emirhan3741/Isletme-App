import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class EducationSettingsPage extends StatefulWidget {
  const EducationSettingsPage({super.key});

  @override
  State<EducationSettingsPage> createState() => _EducationSettingsPageState();
}

class _EducationSettingsPageState extends State<EducationSettingsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  // Form controllers
  final _institutionNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Settings
  String _selectedSector = 'education';
  String _defaultCurrency = 'TRY';
  bool _enableNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enableSMSNotifications = false;
  bool _autoBackup = true;
  String _classTimeFormat = '24h';
  String _dateFormat = 'dd/MM/yyyy';
  String _language = 'tr';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _institutionNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.educationSettingsCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _settings = doc.data() ?? {};
        _populateFields();
      } else {
        // İlk kez ayarlara geliyorsa default değerler
        _setDefaultSettings();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Ayarlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    _institutionNameController.text = _settings['institutionName'] ?? '';
    _emailController.text = _settings['email'] ?? '';
    _phoneController.text = _settings['phone'] ?? '';
    _addressController.text = _settings['address'] ?? '';

    _selectedSector = _settings['sector'] ?? 'education';
    _defaultCurrency = _settings['defaultCurrency'] ?? 'TRY';
    _enableNotifications = _settings['enableNotifications'] ?? true;
    _enableEmailNotifications = _settings['enableEmailNotifications'] ?? true;
    _enableSMSNotifications = _settings['enableSMSNotifications'] ?? false;
    _autoBackup = _settings['autoBackup'] ?? true;
    _classTimeFormat = _settings['classTimeFormat'] ?? '24h';
    _dateFormat = _settings['dateFormat'] ?? 'dd/MM/yyyy';
    _language = _settings['language'] ?? 'tr';
  }

  void _setDefaultSettings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _institutionNameController.text = '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final settings = {
        'institutionName': _institutionNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'sector': _selectedSector,
        'defaultCurrency': _defaultCurrency,
        'enableNotifications': _enableNotifications,
        'enableEmailNotifications': _enableEmailNotifications,
        'enableSMSNotifications': _enableSMSNotifications,
        'autoBackup': _autoBackup,
        'classTimeFormat': _classTimeFormat,
        'dateFormat': _dateFormat,
        'language': _language,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.educationSettingsCollection)
          .doc(user.uid)
          .set(settings, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar başarıyla kaydedildi'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar kaydedilirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Kurum Bilgileri
                  _buildInstitutionSettings(),
                  const SizedBox(height: 16),

                  // Branş Ayarları
                  _buildSectorSettings(),
                  const SizedBox(height: 16),

                  // Sistem Ayarları
                  _buildSystemSettings(),
                  const SizedBox(height: 16),

                  // Bildirim Ayarları
                  _buildNotificationSettings(),
                  const SizedBox(height: 16),

                  // Yedekleme Ayarları
                  _buildBackupSettings(),
                  const SizedBox(height: 16),

                  // Dil ve Format Ayarları
                  _buildLanguageSettings(),
                  const SizedBox(height: 32),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ayarları Kaydet',
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
    );
  }

  Widget _buildInstitutionSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kurum Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _institutionNameController,
              decoration: InputDecoration(
                labelText: 'Kurum Adı *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Adres',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Branş Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedSector,
              onChanged: (value) {
                setState(() => _selectedSector = value!);
              },
              decoration: InputDecoration(
                labelText: 'Eğitim Branşı',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.school),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'education',
                  child: Text('🎓 Genel Eğitim'),
                ),
                DropdownMenuItem(
                  value: 'language',
                  child: Text('🌍 Dil Okulu'),
                ),
                DropdownMenuItem(
                  value: 'music',
                  child: Text('🎵 Müzik Kursu'),
                ),
                DropdownMenuItem(
                  value: 'driving',
                  child: Text('🚗 Sürücü Kursu'),
                ),
                DropdownMenuItem(
                  value: 'tutoring',
                  child: Text('📚 Dershane'),
                ),
                DropdownMenuItem(
                  value: 'art',
                  child: Text('🎨 Sanat Kursu'),
                ),
                DropdownMenuItem(
                  value: 'computer',
                  child: Text('💻 Bilgisayar Kursu'),
                ),
                DropdownMenuItem(
                  value: 'sports',
                  child: Text('⚽ Spor Kursu'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.infoColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info,
                    color: AppConstants.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Branş seçimi, sistem özelliklerini ve raporları etkiler.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.infoColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sistem Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _defaultCurrency,
              onChanged: (value) {
                setState(() => _defaultCurrency = value!);
              },
              decoration: InputDecoration(
                labelText: 'Varsayılan Para Birimi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.monetization_on),
              ),
              items: const [
                DropdownMenuItem(value: 'TRY', child: Text('₺ Türk Lirası')),
                DropdownMenuItem(
                    value: 'USD', child: Text('\$ Amerikan Doları')),
                DropdownMenuItem(value: 'EUR', child: Text('€ Euro')),
                DropdownMenuItem(
                    value: 'GBP', child: Text('£ İngiliz Sterlini')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bildirim Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Bildirimleri Etkinleştir'),
              subtitle: const Text('Sistem bildirimlerini alın'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() => _enableNotifications = value);
              },
              activeColor: const Color(0xFF7C3AED),
            ),
            SwitchListTile(
              title: const Text('E-posta Bildirimleri'),
              subtitle: const Text('Önemli güncellemeleri e-posta ile alın'),
              value: _enableEmailNotifications,
              onChanged: _enableNotifications
                  ? (value) {
                      setState(() => _enableEmailNotifications = value);
                    }
                  : null,
              activeColor: const Color(0xFF7C3AED),
            ),
            SwitchListTile(
              title: const Text('SMS Bildirimleri'),
              subtitle: const Text('Acil durumları SMS ile öğrenin'),
              value: _enableSMSNotifications,
              onChanged: _enableNotifications
                  ? (value) {
                      setState(() => _enableSMSNotifications = value);
                    }
                  : null,
              activeColor: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.backup,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Yedekleme Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Otomatik Yedekleme'),
              subtitle: const Text('Verileriniz otomatik olarak yedeklenir'),
              value: _autoBackup,
              onChanged: (value) {
                setState(() => _autoBackup = value);
              },
              activeColor: const Color(0xFF7C3AED),
            ),
            if (_autoBackup) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppConstants.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verileriniz her gün otomatik olarak yedeklenir.',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              AppConstants.successColor.withValues(alpha: 0.8),
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

  Widget _buildLanguageSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dil ve Format Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _language,
                    onChanged: (value) {
                      setState(() => _language = value!);
                    },
                    decoration: InputDecoration(
                      labelText: 'Dil',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                      DropdownMenuItem(
                          value: 'en', child: Text('🇺🇸 English')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _dateFormat,
                    onChanged: (value) {
                      setState(() => _dateFormat = value!);
                    },
                    decoration: InputDecoration(
                      labelText: 'Tarih Formatı',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.date_range),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'dd/MM/yyyy', child: Text('GG/AA/YYYY')),
                      DropdownMenuItem(
                          value: 'MM/dd/yyyy', child: Text('AA/GG/YYYY')),
                      DropdownMenuItem(
                          value: 'yyyy-MM-dd', child: Text('YYYY-AA-GG')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _classTimeFormat,
              onChanged: (value) {
                setState(() => _classTimeFormat = value!);
              },
              decoration: InputDecoration(
                labelText: 'Saat Formatı',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
              items: const [
                DropdownMenuItem(value: '24h', child: Text('24 Saat (14:30)')),
                DropdownMenuItem(
                    value: '12h', child: Text('12 Saat (2:30 PM)')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
