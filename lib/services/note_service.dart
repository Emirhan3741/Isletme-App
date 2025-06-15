import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _notesCollection => _firestore.collection('notes');

  // Not ekle
  Future<void> addNote(NoteModel note) async {
    final data = note.toMap();
    await _notesCollection.add(data);
  }

  // Not güncelle
  Future<void> updateNote(NoteModel note) async {
    await _notesCollection.doc(note.id).update(note.toMap());
  }

  // Not sil
  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }

  // Tüm notları getir
  Future<List<NoteModel>> getNotes() async {
    final querySnapshot = await _notesCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => NoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}

// Cleaned for Web Build by Cursor 