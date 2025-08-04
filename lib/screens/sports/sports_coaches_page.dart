import 'package:flutter/material.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/models/sports_trainer_model.dart';
import '../../controllers/sports_trainers_controller.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class SportsCoachesPage extends StatefulWidget {
  const SportsCoachesPage({super.key});

  @override
  State<SportsCoachesPage> createState() => _SportsCoachesPageState();
}

class _SportsCoachesPageState extends State<SportsCoachesPage> {
  late final SportsTrainersController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SportsTrainersController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.updateSearch(_searchController.text);
  }

  void _showAddTrainerDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTrainerDialog(
        onTrainerAdded: () => _controller.refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: PaginatedListView<SportsTrainer>(
              controller: _controller,
              emptyTitle: 'Henüz antrenör yok',
              emptySubtitle: 'İlk antrenörünüzü ekleyerek başlayın',
              emptyIcon: Icons.sports,
              emptyActionLabel: 'İlk Antrenörü Ekle',
              onEmptyAction: _showAddTrainerDialog,
              color: const Color(0xFFFF6B35),
              itemSpacing: 16,
              itemBuilder: (context, trainer, index) {
                return _buildTrainerCard(trainer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Antrenör ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAddTrainerDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Yeni Antrenör'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Uzmanlık',
                _controller.selectedSpecialityFilter,
                [
                  'tümü',
                  'fitness',
                  'pilates',
                  'yoga',
                  'crossfit',
                  'kardio',
                  'güç',
                ],
                (value) => _controller.updateSpecialityFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Durum',
                _controller.selectedStatusFilter,
                ['tümü', 'aktif', 'pasif'],
                (value) => _controller.updateStatusFilter(value),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _controller.clearFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                tooltip: 'Filtreleri Temizle',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: ${_getDisplayName(currentValue)}'),
        backgroundColor: currentValue != 'tümü'
            ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
            : Colors.grey[100],
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(_getDisplayName(option)),
        );
      }).toList(),
      onSelected: onChanged,
    );
  }

  String _getDisplayName(String value) {
    switch (value) {
      case 'tümü':
        return 'Tümü';
      case 'fitness':
        return 'Fitness';
      case 'pilates':
        return 'Pilates';
      case 'yoga':
        return 'Yoga';
      case 'crossfit':
        return 'CrossFit';
      case 'kardio':
        return 'Kardiyovasküler';
      case 'güç':
        return 'Güç Antrenmanı';
      case 'aktif':
        return 'Aktif';
      case 'pasif':
        return 'Pasif';
      default:
        return value;
    }
  }

  Widget _buildTrainerCard(SportsTrainer trainer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                child: Text(
                  trainer.fullName.isNotEmpty
                      ? trainer.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainer.speciality,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trainer.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trainer.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: trainer.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Çalışma Saatleri: ${trainer.workingHoursDisplay}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Çalışma Günleri: ${trainer.workingDaysDisplay}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.work,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${trainer.experience} yıl deneyim',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showEditTrainerDialog(trainer),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Düzenle',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(trainer),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Sil',
              ),
              IconButton(
                onPressed: () => _toggleTrainerStatus(trainer),
                icon: Icon(
                  trainer.isActive ? Icons.pause_circle : Icons.play_circle,
                  size: 20,
                  color: trainer.isActive ? Colors.orange : Colors.green,
                ),
                tooltip: trainer.isActive ? 'Pasif Et' : 'Aktif Et',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditTrainerDialog(SportsTrainer trainer) {
    // TODO: Implement edit trainer dialog
    FeedbackUtils.showInfo(context, 'Düzenleme özelliği yakında eklenecek');
  }

  void _showDeleteConfirmation(SportsTrainer trainer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antrenörü Sil'),
        content: Text(
            '${trainer.fullName} antrenörünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteTrainer(trainer.id!);
                if (mounted) {
                  FeedbackUtils.showSuccess(context, 'Antrenör silindi');
                }
              } catch (e) {
                if (mounted) {
                  FeedbackUtils.showError(context, 'Silme hatası: $e');
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleTrainerStatus(SportsTrainer trainer) async {
    try {
      await _controller.toggleTrainerStatus(trainer);
      if (mounted) {
        FeedbackUtils.showSuccess(
          context,
          '${trainer.fullName} ${trainer.isActive ? 'pasif' : 'aktif'} edildi',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Durum değiştirme hatası: $e');
      }
    }
  }
}

class _AddTrainerDialog extends StatefulWidget {
  final VoidCallback onTrainerAdded;

  const _AddTrainerDialog({required this.onTrainerAdded});

  @override
  State<_AddTrainerDialog> createState() => _AddTrainerDialogState();
}

class _AddTrainerDialogState extends State<_AddTrainerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();

  List<String> _selectedWorkingDays = [];
  List<String> _workingHours = [];
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _availableDays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  final List<String> _availableSpecialities = [
    'Fitness',
    'Pilates',
    'Yoga',
    'CrossFit',
    'Kardiyovasküler',
    'Güç Antrenmanı'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _specialityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final trainerData = {
        'fullName': _nameController.text.trim(),
        'speciality': _specialityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'workingDays': _selectedWorkingDays,
        'workingHours': _workingHours,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'isActive': _isActive,
      };

      final controller = SportsTrainersController();
      await controller.addTrainer(trainerData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Antrenör başarıyla eklendi');
        widget.onTrainerAdded();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_add,
            color: Color(0xFFFF6B35),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Yeni Antrenör Ekle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Uzmanlık Alanı',
            border: OutlineInputBorder(),
          ),
          items: _availableSpecialities.map((speciality) {
            return DropdownMenuItem<String>(
              value: speciality,
              child: Text(speciality),
            );
          }).toList(),
          onChanged: (value) => _specialityController.text = value ?? '',
          validator: (value) => value == null ? 'Uzmanlık alanı seçin' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validatePhone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateEmail,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Deneyim (Yıl)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Deneyim giriniz';
            if (int.tryParse(value) == null) return 'Geçerli sayı giriniz';
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Çalışma Günleri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _availableDays.map((day) {
            final isSelected = _selectedWorkingDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWorkingDays.add(day);
                  } else {
                    _selectedWorkingDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // TODO: Add working hours selection widget
        const Text(
          'Not: Çalışma saatleri seçimi özelliği yakında eklenecek',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Aktif'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTrainer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
