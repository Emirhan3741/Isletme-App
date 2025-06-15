import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

// Firebase imports (sadece web ve mobil)
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

// Local storage
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Platform kontrolü
  bool get isFirebaseSupported => 
      kIsWeb || Platform.isAndroid || Platform.isIOS;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      if (isFirebaseSupported) {
        // Firebase auth state listener
        firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
          _handleFirebaseAuthStateChange(firebaseUser);
        });
      } else {
        // Desktop local auth check
        await _checkLocalAuth();
      }
    } catch (e) {
      _setError('Giriş durumu kontrol edilemedi: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _handleFirebaseAuthStateChange(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> _checkLocalAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        final userMaps = await DatabaseService.instance.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        
        if (userMaps.isNotEmpty) {
          _user = UserModel.fromMap(userMaps.first, userMaps.first['id'] ?? '');
        }
      }
    } catch (e) {
      debugPrint('Local auth check error: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (isFirebaseSupported) {
        final credential = await firebase_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        return credential.user != null;
      } else {
        // Desktop local auth
        return await _localSignIn(email, password);
      }
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailAndPassword(
      String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (isFirebaseSupported) {
        final credential = await firebase_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        
        if (credential.user != null) {
          await credential.user!.updateDisplayName(displayName);
          return true;
        }
        return false;
      } else {
        // Desktop local registration
        return await _localRegister(email, password, displayName);
      }
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!isFirebaseSupported) {
      _setError('Google Sign-In sadece mobil ve web platformlarda desteklenir');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      return userCredential.user != null;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _localSignIn(String email, String password) async {
    try {
      final userMaps = await DatabaseService.instance.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (userMaps.isEmpty) {
        _setError('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
        return false;
      }
      
      // Note: In a real app, you should hash and verify passwords
      // For demo purposes, we're skipping password verification
      
      final user = UserModel.fromMap(userMaps.first, userMaps.first['id'] ?? '');
      _user = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Giriş yapılamadı: $e');
      return false;
    }
  }

  Future<bool> _localRegister(String email, String password, String displayName) async {
    try {
      // Check if user already exists
      final existingUsers = await DatabaseService.instance.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (existingUsers.isNotEmpty) {
        _setError('Bu e-posta adresi zaten kayıtlı');
        return false;
      }
      
      // Create new user
      final user = UserModel.fromMap(userMaps.first, userMaps.first['id'] ?? '');
      
      await DatabaseService.instance.insert('users', user.toMap());
      
      _user = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kayıt oluşturulamadı: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      if (isFirebaseSupported) {
        await firebase_auth.FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Çıkış yapılamadı: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    if (!isFirebaseSupported) {
      _setError('Şifre sıfırlama sadece mobil ve web platformlarda desteklenir');
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'weak-password':
          return 'Şifre çok zayıf.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'user-disabled':
          return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        case 'too-many-requests':
          return 'Çok fazla istek. Lütfen daha sonra tekrar deneyin.';
        default:
          return 'Bir hata oluştu: ${error.message}';
      }
    }
    return error.toString();
  }

  Future<void> loadUser(String userId) async {
    final users = await _userService.getUsers();
    _user = users.firstWhere((u) => u.email == userId, orElse: () => UserModel(name: '', email: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
} 