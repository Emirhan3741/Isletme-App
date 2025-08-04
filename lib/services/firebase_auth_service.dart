import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role = 'worker',
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'role': role,
      });
    }
    return user;
  }

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<void> signOut() async => await _auth.signOut();
}

Future<UserRole?> getUserRole(String uid) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final roleStr = snapshot.data()?['role'] as String? ?? '';
  if (roleStr.isEmpty) return null;
  return UserRole.values.firstWhere((e) => e.name == roleStr);
}
