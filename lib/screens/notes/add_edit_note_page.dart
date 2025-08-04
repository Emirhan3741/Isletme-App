// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../core/widgets/form_field_with_custom_option.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;
  final String userId;
  final String? defaultCategory;

  const AddEditNotePage({
    Key? key,
    this.note,
    required this.userId,
    this.defaultCategory,
  }) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _category = 'İş Geliştirme';
  NotePriority _priority = NotePriority.medium;
  NoteStatus _status = NoteStatus.pending;
  DateTime? _deadline;
  bool _isLoading = false;

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;

    _titleController.text = note?.title ?? '';
    _contentController.text = note?.encryptedContent ?? '';
    _category = note?.category ?? widget.defaultCategory ?? 'İş Geliştirme';
    _priority = note?.priority ?? NotePriority.medium;
    _status = note?.status ?? NoteStatus.pending;
    _deadline = note?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Tarih',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _deadline ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF1A73E8),
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _deadline = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _deadline != null
                      ? const Color(0xFF1A73E8)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _deadline != null
                        ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_deadline!)
                        : 'Tarih seçin (opsiyonel)',
                    style: TextStyle(
                      color: _deadline != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontWeight: _deadline != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (_deadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => setState(() => _deadline = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final note = NoteModel(
        id: widget.note?.id ?? now.microsecondsSinceEpoch.toString(),
        userId: widget.userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        status: _status,
        priority: _priority,
        category: _category,
        deadline: _deadline,
        color: widget.note?.color ?? 'blue',
      );

      await NoteService().addOrUpdateNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Not başarıyla güncellendi! ✅'
                  : 'Not başarıyla oluşturuldu! 🎉',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Not Düzenle ✏️' : 'Yeni Not 📝',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isEditMode ? Icons.save : Icons.add, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _isEditMode ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Not Bilgileri Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            color:
                                const Color(0xFF1A73E8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.note,
                            color: Color(0xFF1A73E8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Not Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCustomTextField(
                      controller: _titleController,
                      label: 'Başlık *',
                      icon: Icons.title,
                      hint: 'Not başlığını girin',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Başlık gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _contentController,
                      label: 'İçerik',
                      icon: Icons.description,
                      maxLines: 5,
                      hint: 'Not içeriğini yazın...',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori ve Öncelik Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            color: _priority.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _priority.icon,
                            color: _priority.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Kategori ve Öncelik',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormFieldWithCustomOption<String>(
                      label: 'Kategori *',
                      value: _category,
                      options: const [
                        'İş Geliştirme',
                        'Hatırlatıcı',
                        'Yapılacaklar',
                        'Kişisel',
                        'Proje'
                      ],
                      optionLabel: (category) {
                        switch (category) {
                          case 'İş Geliştirme':
                            return '📊 İş Geliştirme';
                          case 'Hatırlatıcı':
                            return '⏰ Hatırlatıcı';
                          case 'Yapılacaklar':
                            return '✅ Yapılacaklar';
                          case 'Kişisel':
                            return '👤 Kişisel';
                          case 'Proje':
                            return '🎯 Proje';
                          default:
                            return category;
                        }
                      },
                      optionValue: (category) => category,
                      icon: Icons.category,
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'İş Geliştirme'),
                      customOptionLabel: 'Özel Kategori',
                      customInputLabel: 'Özel Kategori',
                      customInputHint: 'Özel kategori adı...',
                      fieldType: FormFieldType.dropdown,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    FormFieldWithCustomOption<NotePriority>(
                      label: 'Öncelik *',
                      value: _priority,
                      options: NotePriority.values,
                      optionLabel: (priority) => priority.text,
                      optionValue: (priority) => priority.name,
                      icon: Icons.priority_high,
                      onChanged: (value) => setState(
                          () => _priority = value ?? NotePriority.medium),
                      customOptionLabel: 'Özel Öncelik',
                      customInputLabel: 'Özel Öncelik',
                      customInputHint: 'Özel öncelik açıklaması...',
                      fieldType: FormFieldType.dropdown,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    FormFieldWithCustomOption<NoteStatus>(
                      label: 'Durum *',
                      value: _status,
                      options: NoteStatus.values,
                      optionLabel: (status) => status.text,
                      optionValue: (status) => status.name,
                      icon: Icons.info,
                      onChanged: (value) =>
                          setState(() => _status = value ?? NoteStatus.pending),
                      customOptionLabel: 'Özel Durum',
                      customInputLabel: 'Özel Durum',
                      customInputHint: 'Özel durum açıklaması...',
                      fieldType: FormFieldType.dropdown,
                      isRequired: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarih Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Zaman Planlaması',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDateSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// Cleaned for Web Build by Cursor
