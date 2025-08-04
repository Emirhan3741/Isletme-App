import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// 🔐 Enhanced AuthProvider with Language & Panel Support
class AuthProviderEnhanced extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // Constructor
  AuthProviderEnhanced() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _user = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 Kullanıcı verisi yükleniyor: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userData = doc.data()!;
        debugPrint('📊 Firebase User Data: $userData');
        
        _user = UserModel.fromMap(userData);
        
        debugPrint('👤 User Model: ${_user?.name}');
        debugPrint('🎯 Selected Panel: ${_user?.selectedPanel}');
        debugPrint('🌐 Language Code: ${_user?.languageCode}');
      } else {
        debugPrint('❌ Kullanıcı belgesi bulunamadı');
        _user = null;
      }
    } catch (e) {
      debugPrint('💥 Kullanıcı verisi yükleme hatası: $e');
      _error = 'Kullanıcı verisi yüklenemedi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 🌐 Kullanıcının dil tercihini güncelle
  Future<bool> updateUserLanguage(String languageCode) async {
    setLoading(true);
    setError(null);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setError('Kullanıcı giriş yapmamış');
        return false;
      }

      // Firestore'da kullanıcı belgesini güncelle
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'languageCode': languageCode});

      // Mevcut user model'i güncelle
      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          role: _user!.role,
          sector: _user!.sector,
          languageCode: languageCode,
          selectedPanel: _user!.selectedPanel,
          createdAt: _user!.createdAt,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      setError('Dil güncellemesi başarısız: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 🎯 Kullanıcının seçili panel tercihini güncelle
  Future<bool> updateUserSelectedPanel(String selectedPanel) async {
    setLoading(true);
    setError(null);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setError('Kullanıcı giriş yapmamış');
        return false;
      }

      // Firestore'da kullanıcı belgesini güncelle
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'selectedPanel': selectedPanel});

      // Mevcut user model'i güncelle
      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          role: _user!.role,
          sector: _user!.sector,
          languageCode: _user!.languageCode,
          selectedPanel: selectedPanel,
          createdAt: _user!.createdAt,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      setError('Panel seçimi güncellemesi başarısız: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 🌐 Kullanıcının mevcut dil tercihini al
  String? getCurrentUserLanguage() {
    return _user?.languageCode;
  }

  /// 🎯 Kullanıcının mevcut panel tercihini al
  String? getCurrentUserSelectedPanel() {
    return _user?.selectedPanel;
  }

  /// 🚀 Panel seçimi sonrası doğru route'a yönlendirme
  String? getRecommendedRoute() {
    final panel = getCurrentUserSelectedPanel();
    if (panel == null) return null;

    switch (panel.toLowerCase()) {
      case 'beauty':
      case 'güzellik':
      case 'güzellik_salon':
        return '/beauty-dashboard';
      case 'lawyer':
      case 'avukat':
      case 'hukuk':
        return '/lawyer-dashboard';
      case 'psychology':
      case 'psikoloji':
      case 'psikolog':
        return '/psychology-dashboard';
      case 'veterinary':
      case 'veteriner':
      case 'veterinarianism':
        return '/veterinary-dashboard';
      case 'sports':
      case 'spor':
      case 'gym':
        return '/sports-dashboard';
      case 'clinic':
      case 'klinik':
      case 'health':
        return '/clinic-dashboard';
      case 'education':
      case 'eğitim':
      case 'school':
        return '/education-dashboard';
      case 'real_estate':
      case 'emlak':
        return '/real-estate-dashboard';
      default:
        return null;
    }
  }

  /// 🔐 Google Sign-In
  Future<bool> signInWithGoogle() async {
    setLoading(true);
    setError(null);
    try {
      debugPrint('🔐 AuthProviderEnhanced: Google Sign-In başlatılıyor...');
      
      // Google Sign-In placeholder - gerçek implementasyon için google_sign_in paketi gerekli
      // Şimdilik test amaçlı başarılı döndürüyoruz
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Test kullanıcısı oluştur
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('✅ Firebase User zaten mevcut: ${currentUser.uid}');
        await _loadUserData(currentUser.uid);
        return true;
      }
      
      debugPrint('📝 Test kullanıcısı giriş simülasyonu yapılıyor...');
      return true;
      
    } catch (e) {
      debugPrint('❌ Google Sign-In hatası: $e');
      setError('Google ile giriş başarısız: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 🚪 Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      setError('Çıkış yapılırken hata: $e');
    }
  }
}