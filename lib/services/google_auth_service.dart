import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign-In instance - platform aware
  GoogleSignIn? _googleSignIn;

  /// Initialize Google Sign-In with correct configuration (Web için Firebase Auth kullan)
  Future<UserCredential?> _webSignIn() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    return await _auth.signInWithPopup(googleProvider);
  }

  /// Google ile giriş yap - Platform bağımsız
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web için Firebase Auth Provider kullan
        return await _webSignIn();
      } else {
        // Mobile için Google Sign-In SDK kullan
        // Mobile için basitleştirilmiş yaklaşım
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Web için Google Sign-In
  Future<UserCredential?> _signInWithGoogleWeb() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      UserCredential userCredential;
      
      try {
        // Web'de popup ile giriş
        userCredential = await _auth.signInWithPopup(googleProvider);
      } catch (popupError) {
        debugPrint('Popup failed, trying redirect: $popupError');
        // Popup başarısız olursa redirect dene
        await _auth.signInWithRedirect(googleProvider);
        userCredential = await _auth.getRedirectResult();
      }
      
      // Kullanıcı bilgilerini Firestore'a kaydet
      await _saveUserToFirestore(userCredential.user);
      
      return userCredential;
    } catch (e) {
      debugPrint('Google Web Sign-In Error: $e');
      return null;
    }
  }

  /// [KULLANILMIYOR] Eski mobile method - artık basitleştirilmiş provider kullanıyoruz
  Future<UserCredential?> _signInWithGoogleMobileOLD() async {
    try {
      // Bu method artık kullanılmıyor - basitleştirilmiş provider kullanıyoruz
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kullanıcıyı Firestore'a kaydet
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': user.email,
          'name': user.displayName ?? 'Google User',
          'displayName': user.displayName ?? 'Google User',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'signInMethod': 'google',
          'role': 'user',
          'isActive': true,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint('New Google user saved to Firestore: ${user.uid}');
      } else {
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Existing Google user login updated: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  /// Google'dan çıkış yap
  Future<void> signOutFromGoogle() async {
    try {
      if (!kIsWeb) {
        // Geçici comment out - v7+ API issues
        // Google Sign-In v7+ compatibility issues
        debugPrint('Google Sign-Out geçici olarak devre dışı');
      }
      await _auth.signOut();
      debugPrint('Google Sign-Out successful');
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }

  /// Kullanıcı Google ile giriş yapmış mı?
  bool isSignedInWithGoogle() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
  }

  /// Kullanıcı sektör seçmiş mi?
  Future<bool> hasUserSelectedSector() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      return data?['sector'] != null && data!['sector'].toString().isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user sector: $e');
      return false;
    }
  }

  /// Kullanıcının sektörünü güncelle
  Future<void> updateUserSector(String sector) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'sector': sector,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User sector updated: $sector');
    } catch (e) {
      debugPrint('Error updating user sector: $e');
    }
  }

  /// Mevcut kullanıcı bilgilerini al
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Kullanıcı giriş durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Test amaçlı - Current user info
  Future<void> debugCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('Current User: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('Display Name: ${user.displayName}');
      debugPrint('Photo URL: ${user.photoURL}');
    } else {
      debugPrint('No user signed in');
    }
  }
}