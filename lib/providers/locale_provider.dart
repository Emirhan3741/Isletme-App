import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌐 Çok Dilli Destek Provider
/// Kullanıcı kayıt sırasında seçtiği dil sabit kalır
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('tr', 'TR'); // Varsayılan Türkçe
  bool _isInitialized = false;

  /// Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'), // Türkçe (default)
    Locale('en', 'US'), // İngilizce
    Locale('de', 'DE'), // Almanca
    Locale('es', 'ES'), // İspanyolca
    Locale('fr', 'FR'), // Fransızca
  ];

  /// Dil adları
  static const Map<String, String> languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
  };

  /// Current locale
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// RTL desteği (şimdilik hiçbiri RTL değil)
  bool get isRTL => false;

  /// Dil kodu
  String get languageCode => _locale.languageCode;

  /// Provider'ı başlat
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('user_language');
      
      if (savedLanguageCode != null) {
        final savedLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguageCode,
          orElse: () => const Locale('tr', 'TR'),
        );
        _locale = savedLocale;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Locale initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Dil değiştir (sadece kayıt sırasında kullanılmalı)
  Future<void> setLocale(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) {
      debugPrint('Unsupported locale: $newLocale');
      return;
    }

    _locale = newLocale;
    notifyListeners();

    // SharedPreferences'a kaydet
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_language', newLocale.languageCode);
      debugPrint('🌐 Dil değiştirildi: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('Locale save error: $e');
    }
  }

  /// Kullanıcı kayıt sırasında dil seçimini kaydet
  Future<void> setUserLanguageOnRegistration(String languageCode) async {
    final newLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('tr', 'TR'),
    );
    
    await setLocale(newLocale);
    debugPrint('📝 Kayıt sırasında dil seçildi: $languageCode');
  }

  /// Desteklenen dil mi kontrol et
  bool isLanguageSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }

  /// Dil adını getir
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  /// Tüm desteklenen dilleri getir
  List<Map<String, String>> getSupportedLanguages() {
    return supportedLocales.map((locale) => {
      'code': locale.languageCode,
      'name': getLanguageName(locale.languageCode),
    }).toList();
  }

  /// Dil kodu için bayrak emoji döndür
  String getLanguageFlag(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }
}