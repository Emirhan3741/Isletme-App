import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Google Sign-In Result Model
class GoogleSignInResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  GoogleSignInResult({required this.isSuccess, this.user, this.errorMessage});
}

class GoogleSignInCompleteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Google Sign-In v7+ singleton instance ✅ Fixed
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// 🎯 Ana Google Sign-In Metodu ✅ v7+ API fixes
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      debugPrint('🚀 Google Sign-In başlatılıyor...');

      // Google Sign-In v7+ API kullanımı
      final googleSignIn = _googleSignIn;
      
      // Initialize if needed (web platformu için gerekli olabilir)
      try {
        await googleSignIn.initialize();
      } catch (e) {
        debugPrint('Initialize hatası (genellikle normal): $e');
      }

      // ✅ authenticate() kullanarak giriş yap (v7+ API)
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      if (googleUser == null) {
        debugPrint('❌ Kullanıcı Google giriş işlemini iptal etti');
        return GoogleSignInResult(
          isSuccess: false, 
          errorMessage: 'Giriş iptal edildi'
        );
      }

      debugPrint('✅ Google kullanıcı alındı: ${googleUser.email}');

      // Authentication token al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('📱 idToken: ${googleAuth.idToken != null ? "✅ Alındı" : "❌ Null"}');
      
      // Firebase credential oluştur ✅ accessToken kaldırıldı
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken artık mevcut değil v7+ API'da
      );

      debugPrint('🔐 Firebase credential oluşturuldu');

      // Firebase ile giriş yap
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        debugPrint('🎉 Firebase giriş başarılı: ${firebaseUser.email}');

        // Kullanıcıyı Firestore'a kaydet ✅ isNewUser parametresi kaldırıldı
        final userModel = await _saveUserToFirestore(firebaseUser, 'google');
        
        return GoogleSignInResult(
          isSuccess: true, 
          user: userModel
        );
      } else {
        debugPrint('❌ Firebase user null');
        return GoogleSignInResult(
          isSuccess: false, 
          errorMessage: 'Firebase kullanıcı bilgisi alınamadı'
        );
      }

    } catch (e) {
      debugPrint('❌ Google Sign-In hatası: $e');
      return GoogleSignInResult(
        isSuccess: false, 
        errorMessage: 'Google giriş hatası: ${e.toString()}'
      );
    }
  }

  /// 🔇 Silent Google Sign-In ✅ v7+ API fixes
  Future<GoogleSignInResult> signInSilently() async {
    try {
      debugPrint('🤫 Silent Google giriş deneniyor...');
      
      final googleSignIn = _googleSignIn;
      
      // ✅ attemptLightweightAuthentication() kullan (v7+ API)
      final GoogleSignInAccount? googleUser = await googleSignIn.attemptLightweightAuthentication();
      
      if (googleUser == null) {
        debugPrint('🤷 Silent giriş mevcut değil');
        return GoogleSignInResult(
          isSuccess: false, 
          errorMessage: 'Silent giriş mevcut değil'
        );
      }

      debugPrint('✅ Silent Google kullanıcı bulundu: ${googleUser.email}');

      // Authentication token al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Firebase credential oluştur ✅ accessToken kaldırıldı
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase ile giriş yap
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        debugPrint('🎉 Silent Firebase giriş başarılı: ${firebaseUser.email}');

        // Kullanıcıyı Firestore'dan al veya oluştur
        final userModel = await _saveUserToFirestore(firebaseUser, 'google');
        
        return GoogleSignInResult(
          isSuccess: true, 
          user: userModel
        );
      } else {
        return GoogleSignInResult(
          isSuccess: false, 
          errorMessage: 'Silent Firebase giriş başarısız'
        );
      }

    } catch (e) {
      debugPrint('❌ Silent sign-in hatası: $e');
      return GoogleSignInResult(
        isSuccess: false, 
        errorMessage: 'Silent giriş hatası: ${e.toString()}'
      );
    }
  }

  /// 🚪 Google Sign-Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ Google çıkış başarılı');
    } catch (e) {
      debugPrint('❌ Google çıkış hatası: $e');
    }
  }

  /// 💾 Kullanıcıyı Firestore'a kaydet ✅ isNewUser parametresi kaldırıldı
  Future<UserModel> _saveUserToFirestore(User firebaseUser, String provider) async {
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        // Mevcut kullanıcıyı döndür
        final userData = userDoc.data()!;
        return UserModel.fromMap(userData);
      } else {
        // Yeni kullanıcı oluştur
        final newUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Google Kullanıcı',
          email: firebaseUser.email ?? '',
          role: 'worker',
          sector: 'general',
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        debugPrint('✅ Yeni kullanıcı Firestore\'a kaydedildi');
        return newUser;
      }
    } catch (e) {
      debugPrint('❌ Firestore kullanıcı kaydetme hatası: $e');
      // Fallback user model
      return UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Kullanıcı',
        email: firebaseUser.email ?? '',
        role: 'worker',
        sector: 'general',
      );
    }
  }
}