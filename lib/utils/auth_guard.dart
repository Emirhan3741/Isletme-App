// CodeRabbit analyze fix: Dosya düzenlendi 

// AuthGuard widget eklendi. // Refactored by Cursor
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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