// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı giriş yap
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  // Kullanıcı çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şu anki kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        return 'Registration failed. Please try again.';
      }
      UserModel userModel = UserModel(
        id: user.uid,
        name: displayName ?? '',
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      await user.updateDisplayName(displayName);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      } else {
        return 'Registration failed: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }
}
 
// Cleaned for Web Build by Cursor 