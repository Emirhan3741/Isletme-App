import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';

/// 🌐 Dil Yardımcı Sınıfı
/// Sabit çok dilli destek için yardımcı fonksiyonlar
class LanguageHelper {
  static const String _languageKeyPrefix = 'user_language_';
  static const String _languageKey = 'user_language';

  /// Kullanıcı kayıt sırasında dil tercihi kaydet
  static Future<void> saveUserLanguagePreference({
    required String userId,
    required String languageCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kullanıcı bazlı kayıt
      await prefs.setString('${_languageKeyPrefix}$userId', languageCode);
      
      // Global kayıt (current user için)
      await prefs.setString(_languageKey, languageCode);
      
      debugPrint('💾 Kullanıcı dil tercihi kaydedildi: $userId -> $languageCode');
    } catch (e) {
      debugPrint('❌ Dil tercihi kaydetme hatası: $e');
    }
  }

  /// Kullanıcı dilini yükle
  static Future<String?> getUserLanguagePreference({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Önce kullanıcı bazlı kontrol et
      if (userId != null) {
        final userLanguage = prefs.getString('${_languageKeyPrefix}$userId');
        if (userLanguage != null) {
          return userLanguage;
        }
      }
      
      // Global kontrol et
      return prefs.getString(_languageKey);
    } catch (e) {
      debugPrint('❌ Dil tercihi yükleme hatası: $e');
      return null;
    }
  }

  /// Varsayılan dili ayarla
  static Future<void> setDefaultLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      debugPrint('🌐 Varsayılan dil ayarlandı: $languageCode');
    } catch (e) {
      debugPrint('❌ Varsayılan dil ayarlama hatası: $e');
    }
  }

  /// Desteklenen dil mi kontrol et
  static bool isSupportedLanguage(String languageCode) {
    return LocaleProvider.supportedLocales
        .any((locale) => locale.languageCode == languageCode);
  }

  /// Locale'den dil kodu al
  static String getLanguageCodeFromLocale(Locale locale) {
    return locale.languageCode;
  }

  /// Dil kodundan Locale oluştur
  static Locale? getLocaleFromLanguageCode(String languageCode) {
    try {
      return LocaleProvider.supportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
      );
    } catch (e) {
      debugPrint('❌ Geçersiz dil kodu: $languageCode');
      return null;
    }
  }

  /// Sistem dilini al (fallback için)
  static String getSystemLanguage() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final systemLanguageCode = systemLocale.languageCode;
    
    // Desteklenen dil mi kontrol et
    if (isSupportedLanguage(systemLanguageCode)) {
      return systemLanguageCode;
    }
    
    // Varsayılan olarak Türkçe dön
    return 'tr';
  }

  /// Kullanıcı çıkış yaptığında dil tercihini temizle
  static Future<void> clearUserLanguagePreference(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_languageKeyPrefix}$userId');
      debugPrint('🗑️ Kullanıcı dil tercihi temizlendi: $userId');
    } catch (e) {
      debugPrint('❌ Dil tercihi temizleme hatası: $e');
    }
  }

  /// Tüm dil tercihlerini temizle (debug için)
  static Future<void> clearAllLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.startsWith(_languageKeyPrefix) || key == _languageKey) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('🗑️ Tüm dil tercihleri temizlendi');
    } catch (e) {
      debugPrint('❌ Dil tercihleri temizleme hatası: $e');
    }
  }

  /// Dil tercihlerini debug için yazdır
  static Future<void> debugPrintLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      debugPrint('🔍 Kayıtlı dil tercihleri:');
      for (String key in keys) {
        if (key.startsWith(_languageKeyPrefix) || key == _languageKey) {
          final value = prefs.getString(key);
          debugPrint('  $key: $value');
        }
      }
    } catch (e) {
      debugPrint('❌ Dil tercihleri debug hatası: $e');
    }
  }

  /// Kayıt sayfası için dil seçimi rehberi
  static Map<String, String> getRegistrationLanguageGuide() {
    return {
      'tr': 'Kayıt sırasında seçtiğiniz dil kalıcı olacaktır',
      'en': 'The language you select during registration will be permanent',
      'de': 'Die während der Registrierung gewählte Sprache bleibt dauerhaft',
      'es': 'El idioma que seleccione durante el registro será permanente',
      'fr': 'La langue que vous sélectionnez lors de l\'inscription sera permanente',
    };
  }
}