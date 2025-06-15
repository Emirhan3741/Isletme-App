// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
 