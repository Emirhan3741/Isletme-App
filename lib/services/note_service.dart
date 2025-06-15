import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _notesCollection = 'notes';
  static const String _usersCollection = 'users';

  // Mevcut kullanıcı bilgilerini al
  User? get currentUser => _auth.currentUser;

  // Kullanıcının rolünü kontrol et
  Future<bool> isOwner() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'owner';
      }
      return false;
    } catch (e) {
      print('Rol kontrolü hatası: $e');
      return false;
    }
  }

  // Yeni not ekle
  Future<String?> addNote(NoteModel note) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Note verilerini hazırla
      final noteData = note.copyWith(
        kullaniciId: currentUser!.uid,
        olusturulmaTarihi: Timestamp.now(),
      ).toMap();

      // Firestore'a ekle
      final docRef = await _firestore
          .collection(_notesCollection)
          .add(noteData);

      return docRef.id;
    } catch (e) {
      print('Not ekleme hatası: $e');
      throw Exception('Not eklenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Not güncelle
  Future<void> updateNote(NoteModel note) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Notun sahibini kontrol et
      final existingNote = await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .get();

      if (!existingNote.exists) {
        throw Exception('Not bulunamadı');
      }

      final existingData = existingNote.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi notlarını güncelleyebilir
      if (!userIsOwner && existingData['kullaniciId'] != currentUser!.uid) {
        throw Exception('Bu notu güncelleme yetkiniz yok');
      }

      // Güncelleme verilerini hazırla (kullaniciId ve olusturulmaTarihi korunur)
      final updateData = note.toMap();
      updateData.remove('kullaniciId');
      updateData.remove('olusturulmaTarihi');

      await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .update(updateData);

    } catch (e) {
      print('Not güncelleme hatası: $e');
      throw Exception('Not güncellenirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Not sil
  Future<void> deleteNote(String noteId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      // Notun sahibini kontrol et
      final noteDoc = await _firestore
          .collection(_notesCollection)
          .doc(noteId)
          .get();

      if (!noteDoc.exists) {
        throw Exception('Not bulunamadı');
      }

      final noteData = noteDoc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Kullanıcı owner değilse, sadece kendi notlarını silebilir
      if (!userIsOwner && noteData['kullaniciId'] != currentUser!.uid) {
        throw Exception('Bu notu silme yetkiniz yok');
      }

      await _firestore
          .collection(_notesCollection)
          .doc(noteId)
          .delete();

    } catch (e) {
      print('Not silme hatası: $e');
      throw Exception('Not silinirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Tüm notları getir (kullanıcı yetkisine göre filtrelenir)
  Stream<List<NoteModel>> getNotes() {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notesCollection)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<NoteModel> notes = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm notları, normal kullanıcı sadece kendi notlarını görebilir
            if (userIsOwner || data['kullaniciId'] == currentUser!.uid) {
              try {
                final note = NoteModel.fromMap(data, doc.id);
                notes.add(note);
              } catch (e) {
                print('Not parsing hatası: $e');
              }
            }
          }
          
          return notes;
        });
  }

  // Kategoriye göre notları getir
  Stream<List<NoteModel>> getNotesByCategory(String category) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notesCollection)
        .where('kategori', isEqualTo: category)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<NoteModel> notes = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm notları, normal kullanıcı sadece kendi notlarını görebilir
            if (userIsOwner || data['kullaniciId'] == currentUser!.uid) {
              try {
                final note = NoteModel.fromMap(data, doc.id);
                notes.add(note);
              } catch (e) {
                print('Not parsing hatası: $e');
              }
            }
          }
          
          return notes;
        });
  }

  // Tamamlanma durumuna göre notları getir
  Stream<List<NoteModel>> getNotesByCompletion(bool tamamlandi) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notesCollection)
        .where('tamamlandi', isEqualTo: tamamlandi)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<NoteModel> notes = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm notları, normal kullanıcı sadece kendi notlarını görebilir
            if (userIsOwner || data['kullaniciId'] == currentUser!.uid) {
              try {
                final note = NoteModel.fromMap(data, doc.id);
                notes.add(note);
              } catch (e) {
                print('Not parsing hatası: $e');
              }
            }
          }
          
          return notes;
        });
  }

  // Öncelik seviyesine göre notları getir
  Stream<List<NoteModel>> getNotesByPriority(int onem) {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notesCollection)
        .where('onem', isEqualTo: onem)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final bool userIsOwner = await isOwner();
          
          final List<NoteModel> notes = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Owner tüm notları, normal kullanıcı sadece kendi notlarını görebilir
            if (userIsOwner || data['kullaniciId'] == currentUser!.uid) {
              try {
                final note = NoteModel.fromMap(data, doc.id);
                notes.add(note);
              } catch (e) {
                print('Not parsing hatası: $e');
              }
            }
          }
          
          return notes;
        });
  }

  // Tek not getir
  Future<NoteModel?> getNote(String noteId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      final doc = await _firestore
          .collection(_notesCollection)
          .doc(noteId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final bool userIsOwner = await isOwner();

      // Owner tüm notları, normal kullanıcı sadece kendi notlarını görebilir
      if (!userIsOwner && data['kullaniciId'] != currentUser!.uid) {
        throw Exception('Bu notu görüntüleme yetkiniz yok');
      }

      return NoteModel.fromMap(data, doc.id);
    } catch (e) {
      print('Not getirme hatası: $e');
      throw Exception('Not getirilirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Not tamamlanma durumunu değiştir
  Future<void> toggleNoteCompletion(String noteId) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      final note = await getNote(noteId);
      if (note != null) {
        final updatedNote = note.copyWith(tamamlandi: !note.tamamlandi);
        await updateNote(updatedNote);
      }
    } catch (e) {
      print('Not tamamlanma durumu değiştirme hatası: $e');
      throw Exception('Not durumu değiştirilirken bir hata oluştu: ${e.toString()}');
    }
  }

  // Toplam not sayısı
  Future<int> getTotalNotesCount() async {
    if (currentUser == null) {
      return 0;
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Toplam not sayısı hatası: $e');
      return 0;
    }
  }

  // Tamamlanan not sayısı
  Future<int> getCompletedNotesCount() async {
    if (currentUser == null) {
      return 0;
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection)
          .where('tamamlandi', isEqualTo: true);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Tamamlanan not sayısı hatası: $e');
      return 0;
    }
  }

  // Bekleyen not sayısı
  Future<int> getPendingNotesCount() async {
    if (currentUser == null) {
      return 0;
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection)
          .where('tamamlandi', isEqualTo: false);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Bekleyen not sayısı hatası: $e');
      return 0;
    }
  }

  // Kategori özeti
  Future<Map<String, int>> getCategoryNotesCount() async {
    if (currentUser == null) {
      return {};
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      final Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final kategori = data['kategori'] ?? '';
        
        categoryCounts[kategori] = (categoryCounts[kategori] ?? 0) + 1;
      }

      return categoryCounts;
    } catch (e) {
      print('Kategori not sayısı hatası: $e');
      return {};
    }
  }

  // Öncelik özeti
  Future<Map<int, int>> getPriorityNotesCount() async {
    if (currentUser == null) {
      return {};
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      final Map<int, int> priorityCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final onem = data['onem'] ?? 1;
        
        priorityCounts[onem] = (priorityCounts[onem] ?? 0) + 1;
      }

      return priorityCounts;
    } catch (e) {
      print('Öncelik not sayısı hatası: $e');
      return {};
    }
  }

  // Yüksek öncelikli bekleyen notları getir (dashboard için)
  Future<List<NoteModel>> getHighPriorityPendingNotes() async {
    if (currentUser == null) {
      return [];
    }

    try {
      final bool userIsOwner = await isOwner();
      Query query = _firestore.collection(_notesCollection)
          .where('tamamlandi', isEqualTo: false)
          .where('onem', whereIn: [4, 5]) // Yüksek ve çok yüksek öncelik
          .orderBy('onem', descending: true)
          .limit(5);

      if (!userIsOwner) {
        query = query.where('kullaniciId', isEqualTo: currentUser!.uid);
      }

      final snapshot = await query.get();
      
      final List<NoteModel> notes = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        try {
          final note = NoteModel.fromMap(data, doc.id);
          notes.add(note);
        } catch (e) {
          print('Not parsing hatası: $e');
        }
      }

      return notes;
    } catch (e) {
      print('Yüksek öncelikli not getirme hatası: $e');
      return [];
    }
  }
} 