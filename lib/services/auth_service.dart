// CodeRabbit analyze fix: Dosya düzenlendi
// AuthService sadeleştirildi - AuthProvider'da bu işlevler zaten var

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'google_auth_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Şu anki kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Kullanıcı auth durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google ile giriş yap
  Future<UserCredential?> signInWithGoogle() async {
    return await _googleAuthService.signInWithGoogle();
  }

  // Google çıkış
  Future<void> signOutFromGoogle() async {
    await _googleAuthService.signOutFromGoogle();
  }

  // Kullanıcının Google ile giriş yapmış olup olmadığını kontrol et
  bool isSignedInWithGoogle() {
    return _googleAuthService.isSignedInWithGoogle();
  }

  // Kullanıcının sektör seçimi yapıp yapmadığını kontrol et
  Future<bool> hasUserSelectedSector() async {
    return await _googleAuthService.hasUserSelectedSector();
  }

  // Kullanıcının sektörünü güncelle
  Future<void> updateUserSector(String sector) async {
    await _googleAuthService.updateUserSector(sector);
  }

  // Kullanıcı bilgilerini güncelle (UserService ile duplikasyon önlendi)
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Kullanıcı silme (admin işlemi)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

// Cleaned for Web Build by Cursor
