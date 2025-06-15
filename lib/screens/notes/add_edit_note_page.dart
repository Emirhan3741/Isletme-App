import 'package:flutter/material.dart';
import 'package:randevu_erp/models/note_model.dart';
import 'package:randevu_erp/services/note_service.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;
  const AddEditNotePage({Key? key, this.note}) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _selectedColor = 0;
  final NoteService _noteService = NoteService();

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedColor = widget.note!.color;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_isEditMode) {
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        color: _selectedColor,
        updatedAt: DateTime.now(),
        id: widget.note!.id,
      );
      await _noteService.updateNote(updatedNote);
    } else {
      final newNote = NoteModel(
        id: UniqueKey().toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        color: _selectedColor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _noteService.addNote(newNote);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Note' : 'Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                validator: (value) => value == null || value.isEmpty ? 'Content required' : null,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Color:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedColor,
                    items: List.generate(5, (index) => DropdownMenuItem(
                      value: index,
                      child: Container(width: 24, height: 24, color: Colors.primaries[index]),
                    )),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedColor = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveNote,
                child: Text(_isEditMode ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Cleaned for Web Build by Cursor