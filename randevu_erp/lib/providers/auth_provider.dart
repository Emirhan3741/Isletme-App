import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Mevcut kullanıcıyı yükle
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    try {
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.uid);
        if (_user == null) {
          // Firestore'da kullanıcı yoksa oluştur
          _user = UserModel.fromFirebaseUser(
            currentUser,
            createdAt: DateTime.now(),
            lastSignIn: DateTime.now(),
          );
          await _authService.updateUserData(_user!);
        }
      }
    } catch (e) {
      _setError('Kullanıcı bilgileri yüklenirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // E-posta ile kayıt ol
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String? displayName,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      
      if (_user != null) {
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Kayıt sırasında bir hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // E-posta ile giriş yap
  Future<bool> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      
      if (_user != null) {
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Giriş sırasında bir hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google ile giriş yap
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _authService.signInWithGoogle();
      
      if (_user != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google ile giriş sırasında hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Şifre sıfırlama e-postası gönderilirken hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Çıkış sırasında hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<bool> updateUserData(UserModel updatedUser) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kullanıcı bilgileri güncellenirken hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını ayarla
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Hata mesajını temizle
  void _clearError() {
    _errorMessage = null;
  }

  // Firebase Auth hata mesajlarını Türkçe'ye çevir
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz giriş bilgileri.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  // Hata mesajını temizle (dışarıdan erişim için)
  void clearError() {
    _clearError();
  }
} 