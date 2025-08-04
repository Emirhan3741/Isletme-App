import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;
  final String? userId;
  const AddEditNotePage({Key? key, this.note, this.userId}) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final NoteService _noteService = NoteService();

  NoteStatus _selectedStatus = NoteStatus.active;
  NotePriority _selectedPriority = NotePriority.medium;
  String _selectedCategory = 'general';
  String _selectedColor = 'blue';
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedStatus = widget.note!.status;
      _selectedPriority = widget.note!.priority;
      _selectedCategory = widget.note!.category;
      _selectedColor = widget.note!.color;
      _deadline = widget.note!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    // Ek validasyonlar
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Not başlığı boş olamaz');
      return;
    }
    
    if (_contentController.text.trim().isEmpty) {
      _showErrorMessage('Not içeriği boş olamaz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = NoteModel(
        id: widget.note?.id ?? '',
        userId: widget.userId ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        status: _selectedStatus,
        priority: _selectedPriority,
        category: _selectedCategory,
        deadline: _deadline,
        color: _selectedColor,
        tags: widget.note?.tags,
      );

      if (widget.note == null) {
        await _noteService.addNote(note);
        if (mounted) {
          _showSuccessMessage('Not başarıyla eklendi');
          _clearForm(); // Form temizle
        }
      } else {
        await _noteService.updateNote(note);
        if (mounted) {
          _showSuccessMessage('Not başarıyla güncellendi');
        }
      }

      // Kısa gecikme ile sayfayı kapat (kullanıcı mesajı görsün)
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showErrorMessage('İşlem başarısız: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedStatus = NoteStatus.pending;
      _selectedPriority = NotePriority.medium;
      _selectedCategory = 'general';
      _deadline = null;
      _selectedColor = 'blue';
    });
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Yeni Not' : 'Notu Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            child: Text(
              widget.note == null ? 'Kaydet' : 'Güncelle',
              style: TextStyle(
                color:
                    _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Not Bilgileri',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Başlık *',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Başlık gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'İçerik *',
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'İçerik gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<NoteStatus>(
                            value: _selectedStatus,
                            items: NoteStatus.values
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.text),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedStatus = val!),
                            decoration: const InputDecoration(
                              labelText: 'Durum',
                              prefixIcon: Icon(Icons.info),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<NotePriority>(
                            value: _selectedPriority,
                            items: NotePriority.values
                                .map((priority) => DropdownMenuItem(
                                      value: priority,
                                      child: Text(priority.text),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedPriority = val!),
                            decoration: const InputDecoration(
                              labelText: 'Öncelik',
                              prefixIcon: Icon(Icons.priority_high),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            items: NoteCategory.values
                                .map((category) => DropdownMenuItem(
                                      value: category.name,
                                      child: Text(category.displayName),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val!),
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: Text(_deadline == null
                                ? 'Son Tarih Seçiniz'
                                : 'Son Tarih: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_deadline != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(() => _deadline = null),
                                  ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                            onTap: _selectDeadline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Cleaned for Web Build by Cursor
