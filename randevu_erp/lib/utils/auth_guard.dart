import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final String? redirectRoute;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Kullanıcı giriş yapmamış
        if (authProvider.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Rol kontrolü
        if (allowedRoles != null && authProvider.currentUserModel != null) {
          final userRole = authProvider.currentUserModel!.rol;
          if (!allowedRoles!.contains(userRole)) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Erişim Engellendi'),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bu sayfaya erişim yetkiniz yok.',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lütfen yöneticinizle iletişime geçin.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return child;
      },
    );
  }
}

class RouteGuard {
  static const Map<String, List<UserRole>> _routePermissions = {
    '/admin/employees': [UserRole.owner],
    '/admin/settings': [UserRole.owner],
    '/reports': [UserRole.owner],
    '/admin': [UserRole.owner],
  };

  static bool canAccessRoute(String route, UserRole? userRole) {
    if (userRole == null) return false;

    // Owner her yere erişebilir
    if (userRole == UserRole.owner) return true;

    // Specific route permissions
    final allowedRoles = _routePermissions[route];
    if (allowedRoles == null) return true; // No restrictions

    return allowedRoles.contains(userRole);
  }

  static Widget guardRoute(String route, Widget child) {
    return AuthGuard(
      allowedRoles: _routePermissions[route],
      child: child,
    );
  }
}

class SessionManager {
  static const Duration _sessionTimeout = Duration(hours: 8);
  static Timer? _sessionTimer;
  static DateTime? _lastActivity;

  static void startSession() {
    _lastActivity = DateTime.now();
    _resetSessionTimer();
  }

  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  static void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () {
      _handleSessionTimeout();
    });
  }

  static void _handleSessionTimeout() {
    // Session timeout - logout user
    FirebaseAuth.instance.signOut();
  }

  static void endSession() {
    _sessionTimer?.cancel();
    _lastActivity = null;
  }

  static bool get isSessionActive {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) < _sessionTimeout;
  }
}

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yükleniyor...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          SessionManager.startSession();
          return FutureBuilder<UserModel?>(
            future: _getUserModel(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData) {
                return child;
              } else {
                // User data not found, redirect to profile setup
                return const ProfileSetupPage();
              }
            },
          );
        } else {
          SessionManager.endSession();
          return const LoginPage();
        }
      },
    );
  }

  Future<UserModel?> _getUserModel(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Error logged for debugging only in development
      return null;
    }
  }
}

// Placeholder pages - bunları gerçek sayfalarla değiştirin
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: const Center(
        child: Text('Login Page - Implement your login UI here'),
      ),
    );
  }
}

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kurulumu')),
      body: const Center(
        child: Text('Profile Setup Page - Implement profile setup UI here'),
      ),
    );
  }
}

// GestureDetector wrapper for activity tracking
class ActivityTracker extends StatelessWidget {
  final Widget child;

  const ActivityTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SessionManager.updateActivity(),
      onPanDown: (_) => SessionManager.updateActivity(),
      child: child,
    );
  }
} 