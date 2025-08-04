import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

// Antrenör Model
class SportsTrainer {
  final String? id;
  final String firstName;
  final String lastName;
  final String specialization;
  final String phone;
  final List<String> workingDays;
  final String workStartTime;
  final String workEndTime;
  final bool isActive;
  final Timestamp registrationDate;

  SportsTrainer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.phone,
    required this.workingDays,
    required this.workStartTime,
    required this.workEndTime,
    required this.isActive,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
      'phone': phone,
      'workingDays': workingDays,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'isActive': isActive,
      'registrationDate': registrationDate,
    };
  }

  static SportsTrainer fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SportsTrainer(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      specialization: data['specialization'] ?? '',
      phone: data['phone'] ?? '',
      workingDays: List<String>.from(data['workingDays'] ?? []),
      workStartTime: data['workStartTime'] ?? '',
      workEndTime: data['workEndTime'] ?? '',
      isActive: data['isActive'] ?? true,
      registrationDate: data['registrationDate'] ?? Timestamp.now(),
    );
  }
}

class SportsTrainersPage extends StatefulWidget {
  const SportsTrainersPage({super.key});

  @override
  State<SportsTrainersPage> createState() => _SportsTrainersPageState();
}

class _SportsTrainersPageState extends State<SportsTrainersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  // 🔥 Firebase'den antrenörleri yükle
  Stream<List<SportsTrainer>> _loadTrainers() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      var query = FirebaseFirestore.instance
          .collection('sports_trainers')
          .where('userId', isEqualTo: user.uid)
          .orderBy('registrationDate', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SportsTrainer.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Antrenör yükleme hatası: $e');
      return Stream.value([]);
    }
  }

  // 🗑️ Antrenör sil
  Future<void> _deleteTrainer(String trainerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('sports_trainers')
          .doc(trainerId)
          .delete();

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Antrenör başarıyla silindi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Antrenör silme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Antrenör silinirken hata oluştu');
      }
    }
  }

  // ✏️ Antrenör durumunu değiştir
  Future<void> _toggleTrainerStatus(
      String trainerId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('sports_trainers')
          .doc(trainerId)
          .update({'isActive': !currentStatus});

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Antrenör durumu güncellendi');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Durum güncelleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Durum güncellenirken hata oluştu');
      }
    }
  }

  // 🎯 Filtreleme
  List<SportsTrainer> _filterTrainers(List<SportsTrainer> trainers) {
    return trainers.where((trainer) {
      // Arama filtresi
      bool matchesSearch = _searchQuery.isEmpty ||
          trainer.firstName.toLowerCase().contains(_searchQuery) ||
          trainer.lastName.toLowerCase().contains(_searchQuery) ||
          trainer.specialization.toLowerCase().contains(_searchQuery);

      // Aktiflik filtresi
      bool matchesActive =
          _activeFilter == null || trainer.isActive == _activeFilter;

      return matchesSearch && matchesActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Antrenörler'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TODO: Export işlemi için ikon eklenecek
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
              const PopupMenuItem(value: 'all', child: Text('Tümü')),
              const PopupMenuItem(value: 'active', child: Text('Aktif')),
              const PopupMenuItem(value: 'inactive', child: Text('Pasif')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Arama bölümü
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Antrenör adı veya uzmanlık alanı ara...',
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
          ),

          // 📋 Antrenör listesi
          Expanded(
            child: StreamBuilder<List<SportsTrainer>>(
              stream: _loadTrainers(),
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

                final allTrainers = snapshot.data ?? [];
                final filteredTrainers = _filterTrainers(allTrainers);

                if (filteredTrainers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Arama kriterlerine uygun antrenör bulunamadı'
                              : 'Henüz antrenör eklenmedi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTrainers.length,
                  itemBuilder: (context, index) {
                    final trainer = filteredTrainers[index];
                    return _buildTrainerCard(trainer);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTrainerDialog(),
        backgroundColor: Colors.orange[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🎨 Antrenör kartı
  Widget _buildTrainerCard(SportsTrainer trainer) {
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
                CircleAvatar(
                  backgroundColor:
                      trainer.isActive ? Colors.green[100] : Colors.red[100],
                  child: Icon(
                    Icons.person,
                    color:
                        trainer.isActive ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trainer.firstName} ${trainer.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        trainer.specialization,
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
                  value: trainer.isActive,
                  onChanged: (value) =>
                      _toggleTrainerStatus(trainer.id!, trainer.isActive),
                  activeColor: Colors.green,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditTrainerDialog(trainer);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(trainer);
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
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(trainer.phone, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${trainer.workStartTime} - ${trainer.workEndTime}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (trainer.workingDays.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: trainer.workingDays.map((gun) {
                  return Chip(
                    label: Text(gun),
                    backgroundColor: Colors.orange[100],
                    labelStyle:
                        TextStyle(color: Colors.orange[800], fontSize: 12),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ➕ Antrenör ekleme dialog'u
  void _showAddTrainerDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTrainerDialog(
        onTrainerAdded: () {
          // Otomatik refresh - StreamBuilder zaten handle ediyor
        },
      ),
    );
  }

  // ✏️ Antrenör düzenleme dialog'u
  void _showEditTrainerDialog(SportsTrainer trainer) {
    showDialog(
      context: context,
      builder: (context) => EditTrainerDialog(
        trainer: trainer,
        onTrainerUpdated: () {
          // Otomatik refresh - StreamBuilder zaten handle ediyor
        },
      ),
    );
  }

  // 🗑️ Silme onayı
  void _showDeleteConfirmation(SportsTrainer trainer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antrenörü Sil'),
        content: Text(
            '${trainer.firstName} ${trainer.lastName} adlı antrenörü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTrainer(trainer.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ➕ Antrenör Ekleme Dialog'u
class AddTrainerDialog extends StatefulWidget {
  final VoidCallback onTrainerAdded;

  const AddTrainerDialog({super.key, required this.onTrainerAdded});

  @override
  State<AddTrainerDialog> createState() => _AddTrainerDialogState();
}

class _AddTrainerDialogState extends State<AddTrainerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  List<String> _workingDays = [];
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workingDays.isEmpty) {
      FeedbackUtils.showError(context, 'En az bir çalışma günü seçin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      final trainer = {
        'userId': user.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'workingDays': _workingDays,
        'workStartTime': _startTimeController.text.trim(),
        'workEndTime': _endTimeController.text.trim(),
        'isActive': _isActive,
        'registrationDate': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('sports_trainers')
          .add(trainer);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Antrenör başarıyla eklendi');
        widget.onTrainerAdded();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Antrenör ekleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Antrenör eklenirken hata oluştu');
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
      title: const Text('Yeni Antrenör Ekle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ad
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Soyad
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Uzmanlık
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Uzmanlık Alanı *',
                    hintText: 'Örn: Pilates, Yoga, CrossFit',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validatePhone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Çalışma saatleri
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Başlama Saati *',
                          hintText: '09:00',
                          border: OutlineInputBorder(),
                        ),
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Bitiş Saati *',
                          hintText: '17:00',
                          border: OutlineInputBorder(),
                        ),
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Çalışma günleri
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Çalışma Günleri *',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _days.map((gun) {
                    final isSelected = _workingDays.contains(gun);
                    return FilterChip(
                      label: Text(gun),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _workingDays.add(gun);
                          } else {
                            _workingDays.remove(gun);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Aktiflik durumu
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
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
          onPressed: _isLoading ? null : _saveTrainer,
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

// ✏️ Antrenör Düzenleme Dialog'u
class EditTrainerDialog extends StatefulWidget {
  final SportsTrainer trainer;
  final VoidCallback onTrainerUpdated;

  const EditTrainerDialog({
    super.key,
    required this.trainer,
    required this.onTrainerUpdated,
  });

  @override
  State<EditTrainerDialog> createState() => _EditTrainerDialogState();
}

class _EditTrainerDialogState extends State<EditTrainerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _specializationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  late List<String> _workingDays;
  late bool _isActive;
  bool _isLoading = false;

  final List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.trainer.firstName);
    _lastNameController = TextEditingController(text: widget.trainer.lastName);
    _specializationController =
        TextEditingController(text: widget.trainer.specialization);
    _phoneController = TextEditingController(text: widget.trainer.phone);
    _startTimeController =
        TextEditingController(text: widget.trainer.workStartTime);
    _endTimeController =
        TextEditingController(text: widget.trainer.workEndTime);
    _workingDays = List.from(widget.trainer.workingDays);
    _isActive = widget.trainer.isActive;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateTrainer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workingDays.isEmpty) {
      FeedbackUtils.showError(context, 'En az bir çalışma günü seçin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'workingDays': _workingDays,
        'workStartTime': _startTimeController.text.trim(),
        'workEndTime': _endTimeController.text.trim(),
        'isActive': _isActive,
      };

      await FirebaseFirestore.instance
          .collection('sports_trainers')
          .doc(widget.trainer.id)
          .update(updatedData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Antrenör başarıyla güncellendi');
        widget.onTrainerUpdated();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Antrenör güncelleme hatası: $e');
      if (mounted) {
        FeedbackUtils.showError(context, 'Antrenör güncellenirken hata oluştu');
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
      title: const Text('Antrenör Düzenle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ad
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Soyad
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Uzmanlık
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Uzmanlık Alanı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validatePhone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Çalışma saatleri
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Başlama Saati *',
                          border: OutlineInputBorder(),
                        ),
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Bitiş Saati *',
                          border: OutlineInputBorder(),
                        ),
                        validator: ValidationUtils.validateRequired,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Çalışma günleri
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Çalışma Günleri *',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _days.map((gun) {
                    final isSelected = _workingDays.contains(gun);
                    return FilterChip(
                      label: Text(gun),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _workingDays.add(gun);
                          } else {
                            _workingDays.remove(gun);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Aktiflik durumu
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
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
          onPressed: _isLoading ? null : _updateTrainer,
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
