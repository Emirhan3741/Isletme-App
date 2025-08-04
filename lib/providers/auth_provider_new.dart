import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/email_service.dart';
import '../services/google_signin_complete_service.dart';

class AuthProvider with ChangeNotifier {
  // State variables
  UserModel? _user;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();
  final GoogleSignInCompleteService _googleSignInService = GoogleSignInCompleteService();

  // Getters
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isWorker => _user?.isWorker ?? false;

  // Role-based access control
  bool get isAdmin => _user?.role == 'admin' || _user?.role == 'owner';
  bool get isEmployee => _user?.role == 'worker' || _user?.role == 'manager';
  String get userRole => _user?.role ?? 'guest';

  // Platform support
  bool get isFirebaseSupported => true;

  // Set user state
  void setUser(UserModel? userModel) {
    if (userModel != null) {
      _user = userModel;
      _role = userModel.role;
    } else {
      _user = null;
      _role = null;
    }
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
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Şifre çok zayıf.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'user-not-found':
          return 'Kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Yanlış şifre.';
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

  /// Email ile giriş
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateUserState(credential.user!);
        return true;
      }
      return false;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Email ile kayıt
  Future<bool> registerWithEmail(String email, String password, String name, String sector) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          role: 'worker',
          sector: sector,
        );

        await _userService.saveUser(user);
        await _updateUserState(credential.user!);
        await _sendWelcomeEmailIfNeeded(credential.user!, 'email', isNewUser: true);
        return true;
      }
      return false;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google ile giriş
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      final result = await _googleSignInService.signInWithGoogle();
      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.errorMessage ?? 'Google giriş hatası');
        return false;
      }
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Silent Google giriş
  Future<bool> signInSilently() async {
    try {
      final result = await _googleSignInService.signInSilently();
      return result.isSuccess;
    } catch (e) {
      debugPrint('Silent sign-in hatası: $e');
      return false;
    }
  }

  /// Çıkış
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseAuth.instance.signOut();
      await _googleSignInService.signOut();

      _user = null;
      _role = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      _setError('Çıkış hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı state güncelleme
  Future<void> _updateUserState(User firebaseUser) async {
    try {
      final userDoc = await _userService.getUser(firebaseUser.uid);
      if (userDoc != null) {
        _user = userDoc;
        _role = userDoc.role;
        notifyListeners();
      } else {
        // Fallback - minimal user model oluştur
        _user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Kullanıcı',
          email: firebaseUser.email ?? '',
          role: 'worker',
          sector: 'general',
        );
        _role = 'worker';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Kullanıcı state güncelleme hatası: $e');
    }
  }

  /// FCM token kaydetme
  Future<void> _saveFCMToken(String userId) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getFCMToken();
      if (token != null) {
        await notificationService.saveTokenToFirestore(userId, token);
      }
    } catch (e) {
      debugPrint('FCM token kaydetme hatası: $e');
    }
  }

  /// Hoş geldin e-postası
  Future<void> _sendWelcomeEmailIfNeeded(User firebaseUser, String provider, {bool isNewUser = false}) async {
    if (isNewUser) {
      try {
        final emailService = EmailService();
        await emailService.sendWelcomeEmail(
          toEmail: firebaseUser.email ?? '',
          userName: firebaseUser.displayName ?? 'Kullanıcı',
        );
      } catch (e) {
        debugPrint('Hoş geldin e-postası hatası: $e');
      }
    }
  }

  /// Alias method for register_page.dart compatibility
  Future<bool> createUserWithEmailAndPassword(String email, String password, String name) async {
    return await registerWithEmail(email, password, name, 'general');
  }
}