import 'package:flutter/material.dart';

// Not kartı oluşturma fonksiyonu örneği:
Widget _buildNoteCard(NoteModel note) {
  return Card(
    color: Color(note.color),
    child: ListTile(
      title: Text(note.title),
      subtitle: Text(note.content),
      trailing: Text(
        note.updatedAt?.toString() ?? note.createdAt?.toString() ?? '',
        style: TextStyle(fontSize: 12),
      ),
    ),
  );
}

// Cleaned for Web Build by Cursor 