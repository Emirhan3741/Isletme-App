import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({Key? key, this.note}) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final NoteService _noteService = NoteService();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  int _selectedColor = 0;
  bool _isLoading = false;
  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _selectedColor = note?.color ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          updatedAt: DateTime.now(),
        );
        await _noteService.updateNote(updatedNote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not güncellendi'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newNote = NoteModel(
          id: null,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          color: _selectedColor,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _noteService.addNote(newNote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not eklendi'), backgroundColor: Colors.green),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Not Düzenle' : 'Yeni Not'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            child: Text(
              _isEditMode ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Not Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık *',
                        prefixIcon: Icon(Icons.title),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Başlık alanı gereklidir';
                        }
                        if (value.trim().length < 3) {
                          return 'Başlık en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'İçerik',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    // Renk seçimi (örnek)
                    Row(
                      children: [
                        const Text('Renk:'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedColor,
                          items: List.generate(10, (i) => DropdownMenuItem(
                            value: i,
                            child: Container(width: 24, height: 24, color: Colors.primaries[i]),
                          )),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedColor = value);
                          },
                        ),
                      ],
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