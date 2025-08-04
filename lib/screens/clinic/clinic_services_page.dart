import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicServicesPage extends StatefulWidget {
  const ClinicServicesPage({super.key});

  @override
  State<ClinicServicesPage> createState() => _ClinicServicesPageState();
}

class _ClinicServicesPageState extends State<ClinicServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<ClinicService> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicServicesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final services = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicService(
          id: doc.id,
          userId: user.uid,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          duration: data['duration'] ?? 60,
          description: data['description'],
          category: data['category'] ?? 'Genel',
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ClinicService> get filteredServices {
    List<ClinicService> filtered = _services;

    // Durum filtreleme
    if (_selectedFilter == 'aktif') {
      filtered = filtered.where((service) => service.isActive).toList();
    } else if (_selectedFilter == 'pasif') {
      filtered = filtered.where((service) => !service.isActive).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((service) =>
              service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              service.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (service.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Üst başlık ve yeni hizmet butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hizmetler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddServiceDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni Hizmet',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hizmet ara (İsim, kategori, açıklama)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide:
                      BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtre butonları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', 'tumu'),
                  _buildFilterChip('Aktif', 'aktif'),
                  _buildFilterChip('Pasif', 'pasif'),
                ],
              ),
            ),
          ),

          // Hizmet listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return _buildServiceCard(service);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: AppConstants.surfaceColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildServiceCard(ClinicService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _showServiceDetail(service),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Hizmet adı ve durum
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSmall,
                      vertical: AppConstants.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: (service.isActive ? Colors.green : Colors.grey)
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadiusSmall),
                      border: Border.all(
                        color: service.isActive ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      service.isActive ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        color: service.isActive ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Kategori
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          service.category,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Açıklama
              if (service.description != null &&
                  service.description!.isNotEmpty)
                Text(
                  service.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Alt satır - Fiyat, süre ve işlemler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₺${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${service.duration} dakika',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditServiceDialog(service),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: Icon(
                          service.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => _toggleServiceStatus(service),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteService(service),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun hizmet bulunamadı'
                : 'Henüz hizmet eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk hizmetinizi eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditServiceDialog(
        onSaved: _loadServices,
      ),
    );
  }

  void _showEditServiceDialog(ClinicService service) {
    showDialog(
      context: context,
      builder: (context) => _AddEditServiceDialog(
        service: service,
        onSaved: _loadServices,
      ),
    );
  }

  void _showServiceDetail(ClinicService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategori: ${service.category}'),
              Text('Fiyat: ₺${service.price.toStringAsFixed(0)}'),
              Text('Süre: ${service.duration} dakika'),
              if (service.description != null)
                Text('Açıklama: ${service.description}'),
              Text('Durum: ${service.isActive ? 'Aktif' : 'Pasif'}'),
              Text('Oluşturulma: ${_formatDate(service.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServiceStatus(ClinicService service) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.clinicServicesCollection)
          .doc(service.id)
          .update({'isActive': !service.isActive});

      await _loadServices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Hizmet ${!service.isActive ? 'aktif' : 'pasif'} edildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteService(ClinicService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hizmeti Sil'),
        content: Text(
            '${service.name} hizmetini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicServicesCollection)
            .doc(service.id)
            .delete();

        await _loadServices();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hizmet başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// Hizmet modeli
class ClinicService {
  final String id;
  final String userId;
  final String name;
  final double price;
  final int duration;
  final String? description;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  ClinicService({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.duration,
    this.description,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'price': price,
      'duration': duration,
      'description': description,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Hizmet ekleme/düzenleme dialog'u
class _AddEditServiceDialog extends StatefulWidget {
  final ClinicService? service;
  final VoidCallback onSaved;

  const _AddEditServiceDialog({
    this.service,
    required this.onSaved,
  });

  @override
  State<_AddEditServiceDialog> createState() => _AddEditServiceDialogState();
}

class _AddEditServiceDialogState extends State<_AddEditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Genel';
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Genel',
    'Muayene',
    'Tedavi',
    'Konsültasyon',
    'Ameliyat',
    'Kontrol',
    'Fizyoterapi',
    'Rehabilitasyon',
    'Laboratuvar',
    'Görüntüleme',
    'Diğer',
  ];

  bool get isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadServiceData();
    } else {
      _durationController.text = '60';
      _priceController.text = '0';
    }
  }

  void _loadServiceData() {
    final service = widget.service!;
    _nameController.text = service.name;
    _priceController.text = service.price.toStringAsFixed(0);
    _durationController.text = service.duration.toString();
    _descriptionController.text = service.description ?? '';
    _selectedCategory = service.category;
    _isActive = service.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Text(
                      isEditing ? 'Hizmet Düzenle' : 'Yeni Hizmet Ekle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Hizmet Adı
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Hizmet Adı *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Hizmet adı gerekli';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Kategori
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          // Fiyat
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Fiyat (₺) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Fiyat gerekli';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Geçerli bir fiyat girin';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: AppConstants.paddingMedium),

                          // Süre
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Süre (dk) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Süre gerekli';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Geçerli bir süre girin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Açıklama
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Aktif/Pasif
                      CheckboxListTile(
                        title: const Text('Aktif'),
                        subtitle: const Text(
                            'Hizmet randevu sisteminde görünür olsun'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value ?? true);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Güncelle' : 'Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final serviceData = ClinicService(
        id: isEditing
            ? widget.service!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        duration: int.parse(_durationController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        isActive: _isActive,
        createdAt: isEditing ? widget.service!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicServicesCollection)
            .doc(widget.service!.id)
            .update(serviceData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicServicesCollection)
            .doc(serviceData.id)
            .set(serviceData.toMap());
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Hizmet başarıyla güncellendi'
              : 'Hizmet başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
