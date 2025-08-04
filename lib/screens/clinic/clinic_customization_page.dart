import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/customization_model.dart';
import '../../core/models/user_profile_model.dart';

class ClinicCustomizationPage extends StatefulWidget {
  const ClinicCustomizationPage({super.key});

  @override
  State<ClinicCustomizationPage> createState() =>
      _ClinicCustomizationPageState();
}

class _ClinicCustomizationPageState extends State<ClinicCustomizationPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  CustomizationSettings? _customizationSettings;
  UserProfile? _userProfile;

  // Controllers for terminology
  final Map<String, TextEditingController> _terminologyControllers = {};

  // Service categories
  List<String> _serviceCategories = [];
  final _newCategoryController = TextEditingController();

  // Selected colors
  Color _primaryColor = AppConstants.primaryColor;
  Color _secondaryColor = const Color(0xFFF3F4F6);
  Color _accentColor = AppConstants.successColor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _terminologyControllers.values) {
      controller.dispose();
    }
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load user profile first
      final profileDoc = await FirebaseFirestore.instance
          .collection(AppConstants.userProfilesCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (profileDoc.docs.isNotEmpty) {
        _userProfile = UserProfile.fromMap(
            profileDoc.docs.first.data(), profileDoc.docs.first.id);
      }

      // Load or create customization settings
      final customDoc = await FirebaseFirestore.instance
          .collection(AppConstants.customizationSettingsCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (customDoc.docs.isNotEmpty) {
        _customizationSettings = CustomizationSettings.fromMap(
          customDoc.docs.first.data(),
          customDoc.docs.first.id,
        );
      } else {
        // Create default settings based on specialization
        final specialization = _userProfile?.specialization ?? 'Genel';
        _customizationSettings = CustomizationSettings.defaultForSpecialization(
          user.uid,
          specialization,
        );
      }

      _populateData();
    } catch (e) {
      if (kDebugMode) debugPrint('Veri yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veriler yüklenirken hata oluştu')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateData() {
    if (_customizationSettings != null) {
      // Populate terminology controllers
      _customizationSettings!.terminology.forEach((key, value) {
        _terminologyControllers[key] = TextEditingController(text: value);
      });

      // Populate service categories
      _serviceCategories = List.from(_customizationSettings!.serviceCategories);

      // Populate colors
      _primaryColor = Color(int.parse(
              _customizationSettings!.colors['primary'].substring(1),
              radix: 16) +
          0xFF000000);
      _secondaryColor = Color(int.parse(
              _customizationSettings!.colors['secondary'].substring(1),
              radix: 16) +
          0xFF000000);
      _accentColor = Color(int.parse(
              _customizationSettings!.colors['accent'].substring(1),
              radix: 16) +
          0xFF000000);
    }
  }

  Future<void> _saveCustomization() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Collect terminology data
      final terminologyMap = <String, String>{};
      _terminologyControllers.forEach((key, controller) {
        terminologyMap[key] = controller.text.trim();
      });

      // Collect color data
      final colorsMap = {
        'primary':
            '#${_primaryColor.toARGB32().toRadixString(16).substring(2)}',
        'secondary':
            '#${_secondaryColor.toARGB32().toRadixString(16).substring(2)}',
        'accent': '#${_accentColor.toARGB32().toRadixString(16).substring(2)}',
        'text': '#111827',
      };

      final updatedSettings = CustomizationSettings(
        id: _customizationSettings?.id ?? '',
        userId: user.uid,
        specialization: _userProfile?.specialization ?? 'Genel',
        terminology: terminologyMap,
        colors: colorsMap,
        serviceCategories: _serviceCategories,
        statusLabels: _customizationSettings?.statusLabels ?? {},
        createdAt: _customizationSettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_customizationSettings?.id.isEmpty ?? true) {
        // Create new settings
        await FirebaseFirestore.instance
            .collection(AppConstants.customizationSettingsCollection)
            .add(updatedSettings.toMap());
      } else {
        // Update existing settings
        await FirebaseFirestore.instance
            .collection(AppConstants.customizationSettingsCollection)
            .doc(_customizationSettings!.id)
            .update(updatedSettings.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Özelleştirmeler başarıyla kaydedildi')),
      );

      _loadData(); // Reload data
    } catch (e) {
      if (kDebugMode) debugPrint('Özelleştirme kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Özelleştirmeler kaydedilirken hata oluştu')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addServiceCategory() {
    final category = _newCategoryController.text.trim();
    if (category.isNotEmpty && !_serviceCategories.contains(category)) {
      setState(() {
        _serviceCategories.add(category);
        _newCategoryController.clear();
      });
    }
  }

  void _removeServiceCategory(String category) {
    setState(() {
      _serviceCategories.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Özelleştir - ${_userProfile?.specialization ?? 'Panel'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveCustomization,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialization Info
            if (_userProfile?.specialization != null) _buildInfoCard(),

            const SizedBox(height: AppConstants.paddingLarge),

            // Color Customization
            _buildColorSection(),

            const SizedBox(height: AppConstants.paddingLarge),

            // Terminology Customization
            _buildTerminologySection(),

            const SizedBox(height: AppConstants.paddingLarge),

            // Service Categories
            _buildServiceCategoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: _primaryColor),
              const SizedBox(width: AppConstants.paddingMedium),
              Text(
                'Branş Özelleştirmesi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Şu anda ${_userProfile!.specialization} branşı için özelleştirme yapıyorsunuz. '
            'Bu ayarlar sizin alanınıza özel terminoloji ve özellikleri içerir.',
            style: TextStyle(
              color: _primaryColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return _buildSectionCard(
      'Renk Teması',
      Icons.palette,
      [
        const Text(
          'Panelin ana renklerini özelleştirin:',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Row(
          children: [
            Expanded(
              child: _buildColorPicker(
                'Ana Renk',
                _primaryColor,
                (color) => setState(() => _primaryColor = color),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildColorPicker(
                'İkincil Renk',
                _secondaryColor,
                (color) => setState(() => _secondaryColor = color),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildColorPicker(
                'Vurgu Rengi',
                _accentColor,
                (color) => setState(() => _accentColor = color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerminologySection() {
    return _buildSectionCard(
      'Terminoloji',
      Icons.translate,
      [
        const Text(
          'Branşınıza özel terimleri özelleştirin:',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        ...(_terminologyControllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: _getTerminologyLabel(entry.key),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: BorderSide(color: AppConstants.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: BorderSide(color: _primaryColor),
                ),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildServiceCategoriesSection() {
    return _buildSectionCard(
      'Hizmet Kategorileri',
      Icons.category,
      [
        const Text(
          'Branşınıza özel hizmet kategorilerini yönetin:',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _newCategoryController,
                decoration: InputDecoration(
                  labelText: 'Yeni Kategori',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: BorderSide(color: AppConstants.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                ),
                onSubmitted: (_) => _addServiceCategory(),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            ElevatedButton(
              onPressed: _addServiceCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _serviceCategories.map((category) {
            return Chip(
              label: Text(category),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeServiceCategory(category),
              backgroundColor: _primaryColor.withValues(alpha: 0.1),
              side: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorPicker(
      String label, Color color, Function(Color) onColorChanged) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showColorPicker(color, onColorChanged),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renk Seç'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  String _getTerminologyLabel(String key) {
    switch (key) {
      case 'patient':
        return 'Hasta/Danışan Terimi';
      case 'appointment':
        return 'Randevu/Seans Terimi';
      case 'treatment':
        return 'Tedavi/Terapi Terimi';
      case 'service':
        return 'Hizmet/İşlem Terimi';
      case 'document':
        return 'Belge/Dosya Terimi';
      case 'clients':
        return 'Hasta Listesi Başlığı';
      case 'calendar':
        return 'Takvim Başlığı';
      case 'treatments':
        return 'Tedaviler Başlığı';
      case 'services':
        return 'Hizmetler Başlığı';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }
}

// Simple color picker widget
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  static const List<Color> _colors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF0D9488), // Teal
    Color(0xFF059669), // Green
    Color(0xFF7C3AED), // Purple
    Color(0xFFEA580C), // Orange
    Color(0xFFDC2626), // Red
    Color(0xFFF59E0B), // Yellow
    Color(0xFF6B7280), // Gray
    Color(0xFF1F2937), // Dark Gray
    Color(0xFF374151), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: pickerColor == color
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
