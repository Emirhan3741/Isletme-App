import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/education_grade_model.dart';
import '../../controllers/education_grades_controller.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class EducationGradesPage extends StatefulWidget {
  const EducationGradesPage({super.key});

  @override
  State<EducationGradesPage> createState() => _EducationGradesPageState();
}

class _EducationGradesPageState extends State<EducationGradesPage> {
  late final EducationGradesController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = EducationGradesController();
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

  void _showAddGradeDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGradeDialog(
        onGradeAdded: () => _controller.refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilterBar(),
          Expanded(
            child: PaginatedListView<EducationGrade>(
              controller: _controller,
              emptyTitle: 'Henüz not yok',
              emptySubtitle: 'İlk notu ekleyerek başlayın',
              emptyIcon: Icons.grade,
              emptyActionLabel: 'İlk Notu Ekle',
              onEmptyAction: _showAddGradeDialog,
              color: const Color(0xFF667EEA),
              itemSpacing: 12,
              itemBuilder: (context, grade, index) {
                return _buildGradeCard(grade);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGradeDialog,
        backgroundColor: const Color(0xFF667EEA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.grade,
              color: Color(0xFF667EEA),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notlar & Puanlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Öğrenci başarılarını değerlendirin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
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
                    hintText: 'Not başlığı, açıklama veya öğretmen notu ara...',
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
                onPressed: _showAddGradeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Not Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
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
                'Öğrenci',
                _controller.selectedStudentFilter,
                [
                  'tümü',
                  'öğrenci1',
                  'öğrenci2'
                ], // TODO: Gerçek öğrenci listesi
                (value) => _controller.updateStudentFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Ders',
                _controller.selectedCourseFilter,
                [
                  'tümü',
                  'matematik',
                  'türkçe',
                  'ingilizce'
                ], // TODO: Gerçek ders listesi
                (value) => _controller.updateCourseFilter(value),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Not Türü',
                _controller.selectedGradeTypeFilter,
                [
                  'tümü',
                  ...GradeType.values.map((type) => type.value),
                ],
                (value) => _controller.updateGradeTypeFilter(value),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _controller.clearAllFilters();
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
            ? const Color(0xFF667EEA).withValues(alpha: 0.1)
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
      case 'exam':
        return 'Sınav';
      case 'quiz':
        return 'Quiz';
      case 'homework':
        return 'Ödev';
      case 'project':
        return 'Proje';
      case 'participation':
        return 'Katılım';
      case 'midterm':
        return 'Ara Sınav';
      case 'final':
        return 'Final';
      case 'other':
        return 'Diğer';
      default:
        return value.substring(0, 1).toUpperCase() + value.substring(1);
    }
  }

  Widget _buildGradeCard(EducationGrade grade) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: grade.basariRengi.withValues(alpha: 0.2),
          width: 2,
        ),
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
                  color: grade.notTuru.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  grade.notTuru.icon,
                  color: grade.notTuru.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.baslik,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      grade.notTuru.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Harf notu
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: grade.basariRengi,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade.harfNotu,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Puan ve yüzde bilgileri
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Puan',
                  grade.formatliPuan,
                  Icons.numbers,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Yüzde',
                  grade.formatliYuzde,
                  Icons.percent,
                  grade.basariRengi,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Durum',
                  grade.basariDurumu,
                  Icons.flag,
                  grade.basariRengi,
                ),
              ),
            ],
          ),
          if (grade.aciklama.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              grade.aciklama,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (grade.ogretmenNotu != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Öğretmen Notu: ${grade.ogretmenNotu}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Tarih ve işlemler
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(grade.notTarihi),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              // TODO: Not düzenleme özelliği
              IconButton(
                onPressed: () => _showEditGradeDialog(grade),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Düzenle',
              ),
              // TODO: Not silme özelliği
              IconButton(
                onPressed: () => _showDeleteConfirmation(grade),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Not düzenleme dialog'u
  void _showEditGradeDialog(EducationGrade grade) {
    FeedbackUtils.showInfo(context, 'Not düzenleme özelliği yakında eklenecek');
  }

  // TODO: Not silme onayı
  void _showDeleteConfirmation(EducationGrade grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content:
            Text('${grade.baslik} notunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteGrade(
                    grade.id!, 'Kullanıcı tarafından silindi');
                if (mounted) {
                  FeedbackUtils.showSuccess(context, 'Not başarıyla silindi');
                }
              } catch (e) {
                if (mounted) {
                  FeedbackUtils.showError(context, 'Not silinirken hata: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _AddGradeDialog extends StatefulWidget {
  final VoidCallback onGradeAdded;

  const _AddGradeDialog({required this.onGradeAdded});

  @override
  State<_AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<_AddGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController();
  final _totalScoreController = TextEditingController();
  final _teacherNoteController = TextEditingController();

  GradeType _selectedType = GradeType.exam;
  DateTime _selectedDate = DateTime.now();
  final double _weight = 1.0;
  final bool _passed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    _totalScoreController.dispose();
    _teacherNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final gradeData = {
        'ogrenciId': 'dummy_student_id', // TODO: Gerçek öğrenci seçimi
        'dersId': 'dummy_course_id', // TODO: Gerçek ders seçimi
        'baslik': _titleController.text.trim(),
        'aciklama': _descriptionController.text.trim(),
        'notTuru': _selectedType.value,
        'alinanPuan': double.parse(_scoreController.text),
        'toplamPuan': double.parse(_totalScoreController.text),
        'notTarihi': Timestamp.fromDate(_selectedDate),
        'gectiMi': _passed,
        'agirlik': _weight,
        'ogretmenNotu': _teacherNoteController.text.trim().isNotEmpty
            ? _teacherNoteController.text.trim()
            : null,
        'aktif': true,
      };

      final controller = EducationGradesController();
      await controller.addGrade(gradeData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Not başarıyla eklendi');
        widget.onGradeAdded();
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
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildFormFields(),
                ),
              ),
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
            color: const Color(0xFF667EEA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF667EEA),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Yeni Not Ekle',
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
            labelText: 'Not Başlığı *',
            hintText: 'Örn: 1. Dönem Ara Sınavı',
            border: OutlineInputBorder(),
          ),
          validator: ValidationUtils.validateRequired,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<GradeType>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Not Türü',
            border: OutlineInputBorder(),
          ),
          items: GradeType.values.map((type) {
            return DropdownMenuItem<GradeType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, size: 16, color: type.color),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Alınan Puan *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _totalScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Toplam Puan *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Not Tarihi',
              border: OutlineInputBorder(),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            hintText: 'Not hakkında ek bilgi...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _teacherNoteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Öğretmen Notu',
            hintText: 'Öğrenci performansı hakkında not...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Öğrenci ve ders seçimi eklenecek
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TODO: Öğrenci ve ders seçimi eklenecek',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
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
          onPressed: _isLoading ? null : _saveGrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
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
