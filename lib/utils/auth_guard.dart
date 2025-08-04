// CodeRabbit analyze fix: Dosya düzenlendi

// AuthGuard widget eklendi. // Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart' as auth_provider;

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

// Role-based Access Control Widget
class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> requiredRoles;
  final Widget? fallback;

  const RoleGuard({
    required this.child,
    required this.requiredRoles,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, auth, _) {
        // Authentication kontrolü
        if (!auth.isAuthenticated) {
          return fallback ??
              const Center(
                child: Text('Giriş gerekli.'),
              );
        }

        // Role kontrolü
        final userRole = auth.userRole;
        final hasPermission = requiredRoles.contains(userRole) ||
            (userRole == 'admin' || userRole == 'owner');

        if (!hasPermission) {
          return fallback ??
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bu sayfaya erişim yetkiniz yok.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
        }

        return child;
      },
    );
  }
}

// Permission-based Access Control Widget
class PermissionGuard extends StatelessWidget {
  final Widget child;
  final bool Function(auth_provider.AuthProvider) hasPermission;
  final Widget? fallback;

  const PermissionGuard({
    required this.child,
    required this.hasPermission,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return fallback ??
              const Center(
                child: Text('Giriş gerekli.'),
              );
        }

        if (!hasPermission(auth)) {
          return fallback ??
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bu işlemi yapmaya yetkiniz yok.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
        }

        return child;
      },
    );
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
    return UserModel.fromMap(doc.data()!);
  }
}

// AuthGuard Fix by Cursor

// Cleaned for Web Build by Cursor
