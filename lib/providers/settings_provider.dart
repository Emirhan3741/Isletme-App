import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  final String language;
  final String currency;
  final String dateFormat;
  final bool darkMode;
  final bool notifications;

  SettingsModel({
    this.language = 'tr',
    this.currency = 'TRY',
    this.dateFormat = 'dd/MM/yyyy',
    this.darkMode = false,
    this.notifications = true,
  });

  SettingsModel copyWith({
    String? language,
    String? currency,
    String? dateFormat,
    bool? darkMode,
    bool? notifications,
  }) {
    return SettingsModel(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'currency': currency,
      'dateFormat': dateFormat,
      'darkMode': darkMode,
      'notifications': notifications,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      language: map['language'] ?? 'tr',
      currency: map['currency'] ?? 'TRY',
      dateFormat: map['dateFormat'] ?? 'dd/MM/yyyy',
      darkMode: map['darkMode'] ?? false,
      notifications: map['notifications'] ?? true,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  SettingsModel _settings = SettingsModel();
  bool _isLoading = false;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  String get language => _settings.language;
  String get currency => _settings.currency;
  String get dateFormat => _settings.dateFormat;
  bool get darkMode => _settings.darkMode;
  bool get notifications => _settings.notifications;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = <String, dynamic>{};

      settingsMap['language'] = prefs.getString('language') ?? 'tr';
      settingsMap['currency'] = prefs.getString('currency') ?? 'TRY';
      settingsMap['dateFormat'] = prefs.getString('dateFormat') ?? 'dd/MM/yyyy';
      settingsMap['darkMode'] = prefs.getBool('darkMode') ?? false;
      settingsMap['notifications'] = prefs.getBool('notifications') ?? true;

      _settings = SettingsModel.fromMap(settingsMap);
    } catch (e) {
      if (kDebugMode) debugPrint('Settings load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    _settings = _settings.copyWith(currency: currency);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateDateFormat(String dateFormat) async {
    _settings = _settings.copyWith(dateFormat: dateFormat);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateDarkMode(bool darkMode) async {
    _settings = _settings.copyWith(darkMode: darkMode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateNotifications(bool notifications) async {
    _settings = _settings.copyWith(notifications: notifications);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> save() async {
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _settings.language);
      await prefs.setString('currency', _settings.currency);
      await prefs.setString('dateFormat', _settings.dateFormat);
      await prefs.setBool('darkMode', _settings.darkMode);
      await prefs.setBool('notifications', _settings.notifications);
    } catch (e) {
      if (kDebugMode) debugPrint('Settings save error: $e');
    }
  }
}
