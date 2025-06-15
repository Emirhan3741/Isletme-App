// CodeRabbit analyze fix: Dosya düzenlendi 

// AuthGuard widget eklendi. // Refactored by Cursor
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthGuard({required this.child, this.fallback, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return fallback ?? const Center(child: Text('Giriş gerekli.'));
    }
    return child;
  }
}

class AuthGuardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }
}

// AuthGuard Fix by Cursor 

// Cleaned for Web Build by Cursor 