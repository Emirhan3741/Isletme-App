import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // E-posta ile kayıt ol
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String? displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Kullanıcı profil bilgilerini güncelle
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }

        // Firestore'a kullanıcı bilgilerini kaydet
        UserModel userModel = UserModel.fromFirebaseUser(
          user,
          createdAt: DateTime.now(),
          lastSignIn: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
    return null;
  }

  // E-posta ile giriş yap
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Son giriş zamanını güncelle
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignIn': DateTime.now().toIso8601String(),
        });

        // Firestore'dan kullanıcı bilgilerini al
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          // Eğer Firestore'da kullanıcı yoksa oluştur
          UserModel userModel = UserModel.fromFirebaseUser(
            user,
            createdAt: DateTime.now(),
            lastSignIn: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
          return userModel;
        }
      }
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
    return null;
  }

  // Google ile giriş yap
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Firestore'da kullanıcı var mı kontrol et
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        UserModel userModel;
        if (doc.exists) {
          userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          // Son giriş zamanını güncelle
          await _firestore.collection('users').doc(user.uid).update({
            'lastSignIn': DateTime.now().toIso8601String(),
          });
        } else {
          // Yeni kullanıcı oluştur
          userModel = UserModel.fromFirebaseUser(
            user,
            createdAt: DateTime.now(),
            lastSignIn: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        }

        return userModel;
      }
    } catch (e) {
      print('Google giriş hatası: $e');
      rethrow;
    }
    return null;
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı bilgilerini Firestore'dan al
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Kullanıcı bilgileri alma hatası: $e');
    }
    return null;
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Kullanıcı bilgileri güncelleme hatası: $e');
      rethrow;
    }
  }
} 