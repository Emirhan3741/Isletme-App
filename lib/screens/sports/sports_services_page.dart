import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

// Hizmet Model
class SportsService {
  final String? id;
  final String ad;
  final String aciklama;
  final int sure; // dakika cinsinden
  final double ucret;
  final String egitmen;
  final bool aktif;
  final String kategori;
  final List<String> gerekliEkipmanlar;
  final int maksimumKatilimci;
  final Timestamp olusturmaTarihi;

  SportsService({
    this.id,
    required this.ad,
    required this.aciklama,
    required this.sure,
    required this.ucret,
    required this.egitmen,
    required this.aktif,
    required this.kategori,
    required this.gerekliEkipmanlar,
    required this.maksimumKatilimci,
    required this.olusturmaTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'aciklama': aciklama,
      'sure': sure,
      'ucret': ucret,
      'egitmen': egitmen,
      'aktif': aktif,
      'kategori': kategori,
      'gerekliEkipmanlar': gerekliEkipmanlar,
      'maksimumKatilimci': maksimumKatilimci,
      'olusturmaTarihi': olusturmaTarihi,
    };
  }

  static SportsService fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportsService(
      id: doc.id,
      ad: data['ad'] ?? '',
      aciklama: data['aciklama'] ?? '',
      sure: data['sure'] ?? 60,
      ucret: (data['ucret'] ?? 0.0).toDouble(),
      egitmen: data['egitmen'] ?? '',
      aktif: data['aktif'] ?? true,
      kategori: data['kategori'] ?? 'Genel',
      gerekliEkipmanlar: List<String>.from(data['gerekliEkipmanlar'] ?? []),
      maksimumKatilimci: data['maksimumKatilimci'] ?? 10,
      olusturmaTarihi: data['olusturmaTarihi'] ?? Timestamp.now(),
    );
  }
}

class SportsServicesPage extends StatefulWidget {
  const SportsServicesPage({super.key});

  @override
  State<SportsServicesPage> createState() => _SportsServicesPageState();
}

class _SportsServicesPageState extends State<SportsServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool? _activeFilter;

  final List<String> _categories = [
    'Tümü',
    'Fitness',
    'Pilates',
    'Yoga',
    'CrossFit',
    'Bireysel PT',
    'Grup Dersleri',
    'Özel Eğitim'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // 🔥 Firebase'den hizmetleri yükle
  Stream<List<SportsService>> _loadServices() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      var query = FirebaseFirestore.instance
          .collection('sports_services')
          .where('userId', isEqualTo: user.uid)
          .orderBy('olusturmaTarihi', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SportsService.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Hizmet yükleme hatası: $e');
      return Stream.value([]);
    }
  }

  // 🗑️ Hizmet sil
  Future<void> _deleteService(String serviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('sports_services')
          .doc(serviceId)
          .delete();

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Hizmet başarıyla silindi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Hizmet silme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Hizmet silinirken hata oluştu');
      }
    }
  }

  // ✏️ Hizmet durumunu değiştir
  Future<void> _toggleServiceStatus(
      String serviceId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('sports_services')
          .doc(serviceId)
          .update({'aktif': !currentStatus});

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Hizmet durumu güncellendi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Durum güncelleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Durum güncellenirken hata oluştu');
      }
    }
  }

  // 🎯 Filtreleme
  List<SportsService> _filterServices(List<SportsService> services) {
    return services.where((service) {
      // Arama filtresi
      bool matchesSearch = _searchQuery.isEmpty ||
          service.ad.toLowerCase().contains(_searchQuery) ||
          service.egitmen.toLowerCase().contains(_searchQuery) ||
          service.kategori.toLowerCase().contains(_searchQuery);

      // Kategori filtresi
      bool matchesCategory =
          _selectedCategory == 'Tümü' || service.kategori == _selectedCategory;

      // Aktiflik filtresi
      bool matchesActive =
          _activeFilter == null || service.aktif == _activeFilter;

      return matchesSearch && matchesCategory && matchesActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hizmetler'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'all':
                    _activeFilter = null;
                    break;
                  case 'active':
                    _activeFilter = true;
                    break;
                  case 'inactive':
                    _activeFilter = false;
                    break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tüm Hizmetler')),
              const PopupMenuItem(
                  value: 'active', child: Text('Aktif Hizmetler')),
              const PopupMenuItem(
                  value: 'inactive', child: Text('Pasif Hizmetler')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Arama ve kategori filtresi
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Hizmet adı, eğitmen veya kategori ara...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange[700]!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.orange[100],
                          checkmarkColor: Colors.orange[700],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 📋 Hizmetler listesi
          Expanded(
            child: StreamBuilder<List<SportsService>>(
              stream: _loadServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Veri yüklenirken hata oluştu',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final allServices = snapshot.data ?? [];
                final filteredServices = _filterServices(allServices);

                if (filteredServices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Arama kriterlerine uygun hizmet bulunamadı'
                              : 'Henüz hizmet eklenmedi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return _buildServiceCard(service);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(),
        backgroundColor: Colors.orange[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🎨 Hizmet kartı
  Widget _buildServiceCard(SportsService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: service.aktif ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: service.aktif ? Colors.green[700] : Colors.red[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.ad,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        service.kategori,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Durum değiştirme switch'i
                Switch(
                  value: service.aktif,
                  onChanged: (value) =>
                      _toggleServiceStatus(service.id!, service.aktif),
                  activeColor: Colors.green,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditServiceDialog(service);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(service);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.aciklama,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.access_time, '${service.sure} dk'),
                const SizedBox(width: 8),
                _buildInfoChip(
                    Icons.attach_money, '₺${service.ucret.toStringAsFixed(0)}'),
                const SizedBox(width: 8),
                _buildInfoChip(
                    Icons.people, '${service.maksimumKatilimci} kişi'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Eğitmen: ${service.egitmen}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (service.gerekliEkipmanlar.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: service.gerekliEkipmanlar.map((ekipman) {
                  return Chip(
                    label: Text(ekipman),
                    backgroundColor: Colors.blue[50],
                    labelStyle:
                        TextStyle(color: Colors.blue[800], fontSize: 10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ➕ Hizmet ekleme dialog'u
  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddServiceDialog(
        onServiceAdded: () {
          // StreamBuilder otomatik refresh ediyor
        },
      ),
    );
  }

  // ✏️ Hizmet düzenleme dialog'u
  void _showEditServiceDialog(SportsService service) {
    showDialog(
      context: context,
      builder: (context) => EditServiceDialog(
        service: service,
        onServiceUpdated: () {
          // StreamBuilder otomatik refresh ediyor
        },
      ),
    );
  }

  // 🗑️ Silme onayı
  void _showDeleteConfirmation(SportsService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hizmeti Sil'),
        content:
            Text('${service.ad} hizmetini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(service.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ➕ Hizmet Ekleme Dialog'u
class AddServiceDialog extends StatefulWidget {
  final VoidCallback onServiceAdded;

  const AddServiceDialog({super.key, required this.onServiceAdded});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _sureController = TextEditingController();
  final TextEditingController _ucretController = TextEditingController();
  final TextEditingController _egitmenController = TextEditingController();
  final TextEditingController _maksimumController = TextEditingController();
  final TextEditingController _ekipmanController = TextEditingController();

  String _selectedKategori = 'Fitness';
  List<String> _ekipmanlar = [];
  bool _aktif = true;
  bool _isLoading = false;

  final List<String> _kategoriler = [
    'Fitness',
    'Pilates',
    'Yoga',
    'CrossFit',
    'Bireysel PT',
    'Grup Dersleri',
    'Özel Eğitim'
  ];

  @override
  void dispose() {
    _adController.dispose();
    _aciklamaController.dispose();
    _sureController.dispose();
    _ucretController.dispose();
    _egitmenController.dispose();
    _maksimumController.dispose();
    _ekipmanController.dispose();
    super.dispose();
  }

  void _addEkipman() {
    final ekipman = _ekipmanController.text.trim();
    if (ekipman.isNotEmpty && !_ekipmanlar.contains(ekipman)) {
      setState(() {
        _ekipmanlar.add(ekipman);
        _ekipmanController.clear();
      });
    }
  }

  void _removeEkipman(String ekipman) {
    setState(() {
      _ekipmanlar.remove(ekipman);
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      final service = {
        'userId': user.uid,
        'ad': _adController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'sure': int.parse(_sureController.text.trim()),
        'ucret': double.parse(_ucretController.text.trim()),
        'egitmen': _egitmenController.text.trim(),
        'kategori': _selectedKategori,
        'gerekliEkipmanlar': _ekipmanlar,
        'maksimumKatilimci': int.parse(_maksimumController.text.trim()),
        'aktif': _aktif,
        'olusturmaTarihi': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('sports_services')
          .add(service);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Hizmet başarıyla eklendi');
        widget.onServiceAdded();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Hizmet ekleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Hizmet eklenirken hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Hizmet Ekle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hizmet adı
                TextFormField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Hizmet Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: _aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Kategori
                DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    border: OutlineInputBorder(),
                  ),
                  items: _kategoriler.map((kategori) {
                    return DropdownMenuItem(
                        value: kategori, child: Text(kategori));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedKategori = value!),
                ),
                const SizedBox(height: 16),

                // Süre ve Ücret
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sureController,
                        decoration: const InputDecoration(
                          labelText: 'Süre (dakika) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ucretController,
                        decoration: const InputDecoration(
                          labelText: 'Ücret (₺) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Eğitmen
                TextFormField(
                  controller: _egitmenController,
                  decoration: const InputDecoration(
                    labelText: 'Eğitmen *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Maksimum katılımcı
                TextFormField(
                  controller: _maksimumController,
                  decoration: const InputDecoration(
                    labelText: 'Maksimum Katılımcı *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Gerekli ekipmanlar
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ekipmanController,
                        decoration: const InputDecoration(
                          labelText: 'Gerekli Ekipman',
                          hintText: 'Örn: Mat, Dumbbell',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addEkipman(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addEkipman,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                if (_ekipmanlar.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _ekipmanlar.map((ekipman) {
                      return Chip(
                        label: Text(ekipman),
                        onDeleted: () => _removeEkipman(ekipman),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Aktiflik durumu
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _aktif,
                  onChanged: (value) => setState(() => _aktif = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveService,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}

// ✏️ Hizmet Düzenleme Dialog'u
class EditServiceDialog extends StatefulWidget {
  final SportsService service;
  final VoidCallback onServiceUpdated;

  const EditServiceDialog({
    super.key,
    required this.service,
    required this.onServiceUpdated,
  });

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adController;
  late final TextEditingController _aciklamaController;
  late final TextEditingController _sureController;
  late final TextEditingController _ucretController;
  late final TextEditingController _egitmenController;
  late final TextEditingController _maksimumController;
  final TextEditingController _ekipmanController = TextEditingController();

  late String _selectedKategori;
  late List<String> _ekipmanlar;
  late bool _aktif;
  bool _isLoading = false;

  final List<String> _kategoriler = [
    'Fitness',
    'Pilates',
    'Yoga',
    'CrossFit',
    'Bireysel PT',
    'Grup Dersleri',
    'Özel Eğitim'
  ];

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.service.ad);
    _aciklamaController = TextEditingController(text: widget.service.aciklama);
    _sureController =
        TextEditingController(text: widget.service.sure.toString());
    _ucretController =
        TextEditingController(text: widget.service.ucret.toString());
    _egitmenController = TextEditingController(text: widget.service.egitmen);
    _maksimumController = TextEditingController(
        text: widget.service.maksimumKatilimci.toString());
    _selectedKategori = widget.service.kategori;
    _ekipmanlar = List.from(widget.service.gerekliEkipmanlar);
    _aktif = widget.service.aktif;
  }

  @override
  void dispose() {
    _adController.dispose();
    _aciklamaController.dispose();
    _sureController.dispose();
    _ucretController.dispose();
    _egitmenController.dispose();
    _maksimumController.dispose();
    _ekipmanController.dispose();
    super.dispose();
  }

  void _addEkipman() {
    final ekipman = _ekipmanController.text.trim();
    if (ekipman.isNotEmpty && !_ekipmanlar.contains(ekipman)) {
      setState(() {
        _ekipmanlar.add(ekipman);
        _ekipmanController.clear();
      });
    }
  }

  void _removeEkipman(String ekipman) {
    setState(() {
      _ekipmanlar.remove(ekipman);
    });
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'ad': _adController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'sure': int.parse(_sureController.text.trim()),
        'ucret': double.parse(_ucretController.text.trim()),
        'egitmen': _egitmenController.text.trim(),
        'kategori': _selectedKategori,
        'gerekliEkipmanlar': _ekipmanlar,
        'maksimumKatilimci': int.parse(_maksimumController.text.trim()),
        'aktif': _aktif,
      };

      await FirebaseFirestore.instance
          .collection('sports_services')
          .doc(widget.service.id)
          .update(updatedData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Hizmet başarıyla güncellendi');
        widget.onServiceUpdated();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Hizmet güncelleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Hizmet güncellenirken hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hizmet Düzenle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hizmet adı
                TextFormField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Hizmet Adı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: _aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Kategori
                DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    border: OutlineInputBorder(),
                  ),
                  items: _kategoriler.map((kategori) {
                    return DropdownMenuItem(
                        value: kategori, child: Text(kategori));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedKategori = value!),
                ),
                const SizedBox(height: 16),

                // Süre ve Ücret
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sureController,
                        decoration: const InputDecoration(
                          labelText: 'Süre (dakika) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ucretController,
                        decoration: const InputDecoration(
                          labelText: 'Ücret (₺) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Eğitmen
                TextFormField(
                  controller: _egitmenController,
                  decoration: const InputDecoration(
                    labelText: 'Eğitmen *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Maksimum katılımcı
                TextFormField(
                  controller: _maksimumController,
                  decoration: const InputDecoration(
                    labelText: 'Maksimum Katılımcı *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Gerekli ekipmanlar
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ekipmanController,
                        decoration: const InputDecoration(
                          labelText: 'Gerekli Ekipman',
                          hintText: 'Örn: Mat, Dumbbell',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addEkipman(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addEkipman,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                if (_ekipmanlar.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _ekipmanlar.map((ekipman) {
                      return Chip(
                        label: Text(ekipman),
                        onDeleted: () => _removeEkipman(ekipman),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Aktiflik durumu
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _aktif,
                  onChanged: (value) => setState(() => _aktif = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateService,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Güncelle'),
        ),
      ],
    );
  }
}
