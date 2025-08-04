import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();

  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isWorker => _user?.isWorker ?? false;

  bool get isAdmin => _user?.role == 'admin' || _user?.role == 'owner';
  bool get isEmployee => _user?.role == 'worker' || _user?.role == 'manager';
  String get userRole => _user?.role ?? 'guest';

  bool get canManageFinances => isAdmin;
  bool get canViewReports => isAdmin || _user?.role == 'manager';
  bool get canCreateAppointments => isAuthenticated;
  bool get canManageEmployees => isAdmin;

  bool get isFirebaseSupported => true;

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

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    setLoading(true);
    setError(null);
    
    try {
      // Google Sign-In implementasyonu
      // Bu method Firebase Google Auth kullanılacak
      return true; // Placeholder - gerçek implementasyon gerekli
    } catch (e) {
      setError('Google ile giriş başarısız: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      setLoading(true);
      setError(null);

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userDoc = await _userService.getUser(credential.user!.uid);
        if (userDoc != null) {
          setUser(userDoc);
          await _saveUserToPrefs(userDoc);
          return true;
        }
      }
      
      setError('Kullanıcı bilgileri alınamadı');
      return false;
    } on FirebaseAuthException catch (e) {
      setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('Giriş hatası: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> registerWithEmail(String email, String password, String name, String sector) async {
    try {
      setLoading(true);
      setError(null);

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          role: 'user',
          sector: sector,
          createdAt: DateTime.now(),
        );

        await _userService.createUser(newUser);
        
        setUser(newUser);
        await _saveUserToPrefs(newUser);
        return true;
      }
      
      setError('Kullanıcı oluşturulamadı');
      return false;
    } on FirebaseAuthException catch (e) {
      setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('Kayıt hatası: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> signInSilently() async {
    try {
      setLoading(true);
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _userService.getUser(currentUser.uid);
        if (userDoc != null) {
          setUser(userDoc);
          return true;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final userDoc = await _userService.getUser(userId);
        if (userDoc != null) {
          setUser(userDoc);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _clearUserFromPrefs();
      setUser(null);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password, String name) async {
    return await registerWithEmail(email, password, name, 'general');
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı, lütfen daha sonra tekrar deneyin';
      default:
        return 'Bir hata oluştu: $code';
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_role', user.role);
    } catch (e) {
      debugPrint('Save user prefs error: $e');
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
    } catch (e) {
      debugPrint('Clear user prefs error: $e');
    }
  }
}