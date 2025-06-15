// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  // Mevcut kullanıcı bilgilerini al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı profilini Firestore'dan getir
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Kullanıcı profili getirme hatası: $e');
      return null;
    }
  }

  // Mevcut kullanıcının profilini getir
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUser == null) return null;
    return await getUserProfile(currentUser!.uid);
  }

  // Kullanıcı profilini kaydet/güncelle
  Future<bool> saveUserProfile(UserModel userModel) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userModel.id)
          .set(userModel.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Kullanıcı profili kaydetme hatası: $e');
      return false;
    }
  }

  // Yeni çalışan oluştur (owner only)
  Future<Map<String, dynamic>> createEmployee({
    required String adSoyad,
    required String eposta,
    required String sifre,
  }) async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return {
          'success': false,
          'message': 'Bu işlem için yetkiniz yok!'
        };
      }

      // Yeni kullanıcı oluştur
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );

      // Kullanıcı profili oluştur
      final userModel = UserModel(
        id: userCredential.user!.uid,
        adSoyad: adSoyad,
        eposta: eposta,
        rol: UserRole.worker,
        oluşturulmaTarihi: Timestamp.now(),
        lastSignIn: DateTime.now(),
      );

      // Firestore'a kaydet
      await saveUserProfile(userModel);

      // Display name güncelle
      await userCredential.user!.updateDisplayName(adSoyad);

      return {
        'success': true,
        'message': 'Çalışan başarıyla oluşturuldu',
        'user': userModel
      };
    } catch (e) {
      print('Çalışan oluşturma hatası: $e');
      
      String errorMessage = 'Bilinmeyen bir hata oluştu';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Bu e-posta adresi zaten kullanımda';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz e-posta adresi';
            break;
          case 'weak-password':
            errorMessage = 'Şifre çok zayıf';
            break;
          default:
            errorMessage = e.message ?? 'Kimlik doğrulama hatası';
        }
      }

      return {
        'success': false,
        'message': errorMessage
      };
    }
  }

  // Tüm çalışanları getir (owner only)
  Future<List<UserModel>> getAllEmployees() async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('oluşturulmaTarihi', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Çalışanları getirme hatası: $e');
      return [];
    }
  }

  // Sadece worker'ları getir (owner only)
  Future<List<UserModel>> getWorkers() async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('rol', isEqualTo: 'worker')
          .orderBy('oluşturulmaTarihi', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Worker listesi getirme hatası: $e');
      return [];
    }
  }

  // Kullanıcı güncelle (owner only)
  Future<bool> updateEmployee(UserModel userModel) async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return false;
      }

      return await saveUserProfile(userModel);
    } catch (e) {
      print('Çalışan güncelleme hatası: $e');
      return false;
    }
  }

  // Kullanıcı sil (owner only)
  Future<bool> deleteEmployee(String userId) async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return false;
      }

      // Kendi hesabını silemez
      if (userId == currentUser?.uid) {
        return false;
      }

      // Firestore'dan sil
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();

      // TODO: Firebase Auth'dan kullanıcıyı silmek için Admin SDK gerekir
      // Bu işlem şimdilik Firestore'dan silme ile sınırlı

      return true;
    } catch (e) {
      print('Çalışan silme hatası: $e');
      return false;
    }
  }

  // Kullanıcının rolünü kontrol et
  Future<UserRole?> getCurrentUserRole() async {
    final userProfile = await getCurrentUserProfile();
    return userProfile?.rol;
  }

  // Owner kontrolü
  Future<bool> isCurrentUserOwner() async {
    final userProfile = await getCurrentUserProfile();
    return userProfile?.isOwner ?? false;
  }

  // Worker kontrolü
  Future<bool> isCurrentUserWorker() async {
    final userProfile = await getCurrentUserProfile();
    return userProfile?.isWorker ?? false;
  }

  // İlk giriş kontrolü ve profil oluşturma
  Future<UserModel?> initializeUserProfile({UserRole? defaultRole}) async {
    if (currentUser == null) return null;

    try {
      // Mevcut profili kontrol et
      UserModel? existingProfile = await getCurrentUserProfile();
      
      if (existingProfile != null) {
        // Mevcut profil varsa, son giriş zamanını güncelle
        final updatedProfile = existingProfile.copyWith(
          lastSignIn: DateTime.now(),
        );
        await saveUserProfile(updatedProfile);
        return updatedProfile;
      }

      // Yeni profil oluştur
      final newProfile = UserModel(
        id: currentUser!.uid,
        adSoyad: currentUser!.displayName ?? 'Kullanıcı',
        eposta: currentUser!.email ?? '',
        rol: defaultRole ?? UserRole.owner, // İlk kullanıcı owner olur
        oluşturulmaTarihi: Timestamp.now(),
        photoURL: currentUser!.photoURL,
        lastSignIn: DateTime.now(),
      );

      await saveUserProfile(newProfile);
      return newProfile;
    } catch (e) {
      print('Kullanıcı profili başlatma hatası: $e');
      return null;
    }
  }

  // Kullanıcı sayısını getir
  Future<int> getUserCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Kullanıcı sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Owner sayısını getir
  Future<int> getOwnerCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('rol', isEqualTo: 'owner')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Owner sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Worker sayısını getir
  Future<int> getWorkerCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('rol', isEqualTo: 'worker')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Worker sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Kullanıcı arama
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Sadece owner bu işlemi yapabilir
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.isOwner != true) {
        return [];
      }

      if (query.isEmpty) {
        return await getAllEmployees();
      }

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) =>
              user.adSoyad.toLowerCase().contains(query.toLowerCase()) ||
              user.eposta.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Kullanıcı arama hatası: $e');
      return [];
    }
  }

  // Stream: Real-time kullanıcı listesi (owner only)
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('oluşturulmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromMap(doc.data()))
                .toList());
  }

  // Stream: Real-time worker listesi (owner only)
  Stream<List<UserModel>> getWorkersStream() {
    return _firestore
        .collection(_usersCollection)
        .where('rol', isEqualTo: 'worker')
        .orderBy('oluşturulmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromMap(doc.data()))
                .toList());
  }
} 