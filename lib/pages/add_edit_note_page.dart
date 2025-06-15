import 'package:flutter/material.dart';

class AddEditNotePage extends StatefulWidget {
  // ... (existing code)
  @override
  _AddEditNotePageState createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  int _selectedColor = 0;

  void _saveNote() {
    final note = NoteModel(
      title: _titleController.text,
      content: _contentController.text,
      color: _selectedColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // Notu kaydetmek için servis çağrısı
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
}

// Cleaned for Web Build by Cursor 