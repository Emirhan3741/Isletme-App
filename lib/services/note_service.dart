// Refactored by Cursor

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/note_model.dart';

class NoteService {
  final CollectionReference _notesCollection =
      FirebaseFirestore.instance.collection('notes');

  Future<void> addNote(NoteModel note) async {
    try {
      if (kDebugMode) debugPrint('🔄 Not ekleniyor...');
      
      // Null kontrolü
      if (note.title.trim().isEmpty) {
        throw Exception('Not başlığı boş olamaz');
      }
      
      final docRef = await _notesCollection.add(note.toMap());
      
      // ID'yi güncellemek isterseniz:
      await docRef.update({'id': docRef.id});
      
      if (kDebugMode) debugPrint('✅ Not başarıyla eklendi: ${docRef.id}');
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase not ekleme hatası: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'failed-precondition':
          if (e.message?.contains('index') == true) {
            final indexUrl = _extractIndexUrl(e.message ?? '');
            debugPrint('🔍 Index gerekli - URL: $indexUrl');
            throw Exception('Veritabanı indexi eksik. Lütfen FIRESTORE_INDEX_URLS.md dosyasındaki URLleri açın.');
          }
          throw Exception('Veritabanı koşulları sağlanmamış: ${e.message}');
        case 'permission-denied':
          throw Exception('Bu işlem için yetkiniz yok. Giriş yapınız.');
        case 'unavailable':
          throw Exception('Veritabanı servis kullanılamıyor. İnternet bağlantınızı kontrol edin.');
        default:
          throw Exception('Not eklenemedi: ${e.message ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen not ekleme hatası: $e');
      throw Exception('Not eklenemedi: $e');
    }
  }
  
  String _extractIndexUrl(String errorMessage) {
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0) ?? 'FIRESTORE_INDEX_URLS.md dosyasına bakın';
  }

  Future<void> updateNote(NoteModel note) async {
    await _notesCollection.doc(note.id).update(note.toMap());
  }

  Future<void> addOrUpdateNote(NoteModel note) async {
    if (note.id.isEmpty) {
      await addNote(note);
    } else {
      await updateNote(note);
    }
  }

  Future<List<NoteModel>> getNotes() async {
    final snapshot =
        await _notesCollection.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return NoteModel.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<List<NoteModel>> getNotesByUserId(String userId) async {
    try {
      if (kDebugMode) debugPrint('🔄 Kullanıcı notları yükleniyor: $userId');
      
      if (userId.trim().isEmpty) {
        throw Exception('Kullanıcı ID\'si boş olamaz');
      }
      
      final snapshot = await _notesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final notes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NoteModel.fromMap({...data, 'id': doc.id});
      }).toList();
      
      if (kDebugMode) debugPrint('✅ ${notes.length} not yüklendi');
      return notes;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase not yükleme hatası: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'failed-precondition':
          if (e.message?.contains('index') == true) {
            final indexUrl = _extractIndexUrl(e.message ?? '');
            debugPrint('🔍 Index gerekli - URL: $indexUrl');
            throw Exception('Veritabanı indexi eksik. ÇÖZÜM: 1. FIRESTORE_INDEX_URLS.md dosyasını açın 2. Notes Collection bölümündeki URLyi tarayıcıda açın 3. Create Index butonuna tıklayın 4. 2-3 dakika bekleyin');
          }
          throw Exception('Veritabanı koşulları sağlanmamış: ${e.message}');
        case 'permission-denied':
          throw Exception('Bu işlem için yetkiniz yok. Giriş yapınız.');
        case 'unavailable':
          throw Exception('Veritabanı servis kullanılamıyor. İnternet bağlantınızı kontrol edin.');
        default:
          throw Exception('Notlar yüklenemedi: ${e.message ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen not yükleme hatası: $e');
      throw Exception('Notlar yüklenemedi: $e');
    }
  }

  Stream<List<NoteModel>> getNotesStream() {
    return _notesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NoteModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Stream<List<NoteModel>> getNotesStreamByUserId(String userId) {
    return _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NoteModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<void> deleteNote(String id) async {
    await _notesCollection.doc(id).delete();
  }

  Future<void> updateNoteStatus(String id, NoteStatus status) async {
    await _notesCollection.doc(id).update({'status': status.name});
  }

  Future<void> updateNotePriority(String id, NotePriority priority) async {
    await _notesCollection.doc(id).update({'priority': priority.name});
  }

  Future<List<NoteModel>> getAllNotes() async {
    return await getNotes();
  }

  // Cleaned for Web Build by Cursor
}
