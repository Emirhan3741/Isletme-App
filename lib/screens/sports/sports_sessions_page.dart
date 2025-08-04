import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/sports_session_model.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../controllers/sports_sessions_controller.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class SportsSessionsPage extends StatefulWidget {
  const SportsSessionsPage({super.key});

  @override
  State<SportsSessionsPage> createState() => _SportsSessionsPageState();
}

class _SportsSessionsPageState extends State<SportsSessionsPage> {
  late final SportsSessionsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SportsSessionsController();
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

  void _showAddSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddSessionDialog(
        onSessionAdded: () => _controller.refresh(),
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
            child: PaginatedListView<SportsSession>(
              controller: _controller,
              emptyTitle: 'Henüz seans yok',
              emptySubtitle: 'İlk seansınızı ekleyerek başlayın',
              emptyIcon: Icons.schedule,
              emptyActionLabel: 'İlk Seansı Ekle',
              onEmptyAction: _showAddSessionDialog,
              color: const Color(0xFFFF6B35),
              itemSpacing: 16,
              itemBuilder: (context, session, index) {
                return _buildSessionCard(session);
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
                    hintText: 'Seans ara...',
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
                onPressed: _showAddSessionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Seans'),
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
                'Durum',
                _controller.selectedStatusFilter,
                [
                  'tümü',
                  'planlandi',
                  'tamamlandi',
                  'iptal_edildi',
                ],
                (value) => _controller.updateStatusFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Tür',
                _controller.selectedTypeFilter,
                [
                  'tümü',
                  'bireysel_antrenman',
                  'grup_dersi',
                  'pilates',
                  'yoga',
                  'crossfit',
                ],
                (value) => _controller.updateTypeFilter(value),
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
      case 'planlandi':
        return 'Planlandı';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'iptal_edildi':
        return 'İptal Edildi';
      case 'bireysel_antrenman':
        return 'Bireysel';
      case 'grup_dersi':
        return 'Grup Dersi';
      case 'pilates':
        return 'Pilates';
      case 'yoga':
        return 'Yoga';
      case 'crossfit':
        return 'CrossFit';
      default:
        return value;
    }
  }

  Widget _buildSessionCard(SportsSession session) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.statusEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                session.formatliTutar,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${session.seansTarihi.day}/${session.seansTarihi.month}/${session.seansTarihi.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${session.sure} dk',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (session.notlar != null && session.notlar!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              session.notlar!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddSessionDialog extends StatefulWidget {
  final VoidCallback onSessionAdded;

  const _AddSessionDialog({required this.onSessionAdded});

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedType = 'bireysel_antrenman';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 60;
  bool _isLoading = false;

  final List<Map<String, String>> _sessionTypes = [
    {'value': 'bireysel_antrenman', 'label': 'Bireysel Antrenman'},
    {'value': 'grup_dersi', 'label': 'Grup Dersi'},
    {'value': 'pilates', 'label': 'Pilates'},
    {'value': 'yoga', 'label': 'Yoga'},
    {'value': 'crossfit', 'label': 'CrossFit'},
    {'value': 'kardio', 'label': 'Kardiyovasküler'},
    {'value': 'strength', 'label': 'Güç Antrenmanı'},
    {'value': 'functional', 'label': 'Fonksiyonel Antrenman'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final sessionData = {
        'seansTipi': _selectedType,
        'baslik': _titleController.text.trim(),
        'seansTarihi': Timestamp.fromDate(sessionDateTime),
        'sure': _duration,
        'ucret': double.tryParse(_priceController.text) ?? 0.0,
        'notlar': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'durum': 'planlandi',
      };

      final controller = SportsSessionsController();
      await controller.addSession(sessionData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Seans başarıyla eklendi');
        widget.onSessionAdded();
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
            Icons.add_circle_outline,
            color: Color(0xFFFF6B35),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Yeni Seans Ekle',
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
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Seans Başlığı',
            hintText: 'Örn: Bireysel Antrenman - Kardio',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Seans Tipi',
            border: OutlineInputBorder(),
          ),
          items: _sessionTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['value'],
              child: Text(type['label']!),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDurationPicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildPriceField()),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notlar (İsteğe bağlı)',
            hintText: 'Seans hakkında özel notlar...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tarih',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Saat',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildDurationPicker() {
    return DropdownButtonFormField<int>(
      value: _duration,
      decoration: const InputDecoration(
        labelText: 'Süre (dakika)',
        border: OutlineInputBorder(),
      ),
      items: [30, 45, 60, 75, 90, 120].map((duration) {
        return DropdownMenuItem<int>(
          value: duration,
          child: Text('$duration dk'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _duration = value!),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Ücret (₺)',
        border: OutlineInputBorder(),
      ),
      validator: ValidationUtils.validatePrice,
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
          onPressed: _isLoading ? null : _saveSession,
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
