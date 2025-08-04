import 'package:flutter/foundation.dart';

enum Environment {
  development,
  beta,
  production,
}

class AppConfig {
  static const Environment currentEnvironment = kDebugMode
      ? Environment.development
      : Environment.beta; // Beta için değiştirilebilir

  // Firebase Configuration
  static const Map<Environment, Map<String, String>> firebaseConfig = {
    Environment.development: {
      'projectId': 'randevu-erp-dev',
      'apiKey': 'your-dev-api-key',
      'appId': 'your-dev-app-id',
    },
    Environment.beta: {
      'projectId': 'randevu-erp-beta',
      'apiKey': 'your-beta-api-key',
      'appId': 'your-beta-app-id',
    },
    Environment.production: {
      'projectId': 'randevu-erp-prod',
      'apiKey': 'your-prod-api-key',
      'appId': 'your-prod-app-id',
    },
  };

  // App Configuration
  static const Map<Environment, Map<String, dynamic>> appSettings = {
    Environment.development: {
      'appName': 'Randevu ERP (Dev)',
      'baseUrl': 'http://localhost:8080',
      'enableDebugTools': true,
      'enableAnalytics': false,
      'enableCrashlytics': false,
      'maxCacheSize': 100, // MB
      'enableBetaFeatures': true,
    },
    Environment.beta: {
      'appName': 'Randevu ERP (Beta)',
      'baseUrl': 'https://randevu-erp-beta.web.app',
      'enableDebugTools': false,
      'enableAnalytics': true,
      'enableCrashlytics': true,
      'maxCacheSize': 50, // MB
      'enableBetaFeatures': true,
    },
    Environment.production: {
      'appName': 'Randevu ERP',
      'baseUrl': 'https://randevu-erp.web.app',
      'enableDebugTools': false,
      'enableAnalytics': true,
      'enableCrashlytics': true,
      'maxCacheSize': 50, // MB
      'enableBetaFeatures': false,
    },
  };

  // Beta Test Configuration
  static const Map<String, dynamic> betaConfig = {
    'maxTestUsers': 50,
    'testDataExpiry': 30, // days
    'enableTestDataGeneration': true,
    'betaFeedbackEmail': 'beta@randevu-erp.com',
    'supportEmail': 'support@randevu-erp.com',
    'testAccountCredentials': [
      {
        'email': 'test.beauty@randevuerp.com',
        'password': 'TestBeauty123!',
        'role': 'beauty_salon_owner',
        'businessType': 'beauty',
      },
      {
        'email': 'test.clinic@randevuerp.com',
        'password': 'TestClinic123!',
        'role': 'clinic_doctor',
        'businessType': 'clinic',
      },
      {
        'email': 'test.sports@randevuerp.com',
        'password': 'TestSports123!',
        'role': 'sports_coach',
        'businessType': 'sports',
      },
    ],
  };

  // Getters for current environment
  static String get currentProjectId =>
      firebaseConfig[currentEnvironment]!['projectId']!;

  static String get currentApiKey =>
      firebaseConfig[currentEnvironment]!['apiKey']!;

  static String get currentAppId =>
      firebaseConfig[currentEnvironment]!['appId']!;

  static String get appName => appSettings[currentEnvironment]!['appName'];

  static String get baseUrl => appSettings[currentEnvironment]!['baseUrl'];

  static bool get enableDebugTools =>
      appSettings[currentEnvironment]!['enableDebugTools'];

  static bool get enableAnalytics =>
      appSettings[currentEnvironment]!['enableAnalytics'];

  static bool get enableCrashlytics =>
      appSettings[currentEnvironment]!['enableCrashlytics'];

  static bool get enableBetaFeatures =>
      appSettings[currentEnvironment]!['enableBetaFeatures'];

  static int get maxCacheSize =>
      appSettings[currentEnvironment]!['maxCacheSize'];

  // Beta specific getters
  static bool get isBeta => currentEnvironment == Environment.beta;
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;
  static bool get isProduction => currentEnvironment == Environment.production;

  static int get maxTestUsers => betaConfig['maxTestUsers'];
  static int get testDataExpiry => betaConfig['testDataExpiry'];
  static bool get enableTestDataGeneration =>
      betaConfig['enableTestDataGeneration'];
  static String get betaFeedbackEmail => betaConfig['betaFeedbackEmail'];
  static String get supportEmail => betaConfig['supportEmail'];
  static List<Map<String, dynamic>> get testAccountCredentials =>
      List<Map<String, dynamic>>.from(betaConfig['testAccountCredentials']);

  // App Version
  static const String appVersion = '1.0.0-beta.1';
  static const int buildNumber = 1;
  static const String minimumSupportedVersion = '1.0.0';

  // Feature Flags
  static const Map<String, bool> featureFlags = {
    'newDashboard': true,
    'advancedReports': true,
    'multiLanguage': false,
    'darkMode': false,
    'offlineMode': false,
    'voiceNotes': false,
    'aiAssistant': false,
    'videoCall': false,
  };

  // Beta Testing URLs
  static const Map<String, String> betaLinks = {
    'androidTestLink': 'https://play.google.com/apps/test/com.randevuerp.beta',
    'iosTestFlight': 'https://testflight.apple.com/join/RandomCode',
    'webBeta': 'https://randevu-erp-beta.web.app',
    'feedbackForm': 'https://forms.google.com/randevu-erp-beta-feedback',
    'bugReport': 'https://github.com/randevu-erp/issues',
  };

  // Performance Limits for Beta
  static const Map<String, int> betaLimits = {
    'maxCustomers': 100,
    'maxAppointments': 500,
    'maxTransactions': 1000,
    'maxNotes': 200,
    'maxServices': 50,
    'maxEmployees': 10,
    'maxFileUploadMB': 10,
    'maxDailyApiCalls': 5000,
  };

  // Check if feature is enabled
  static bool isFeatureEnabled(String featureName) {
    return featureFlags[featureName] ?? false;
  }

  // Check if within beta limits
  static bool isWithinBetaLimit(String limitType, int currentCount) {
    if (!isBeta) return true;
    final limit = betaLimits[limitType];
    if (limit == null) return true;
    return currentCount < limit;
  }

  // Get environment display info
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': currentEnvironment.name,
      'appName': appName,
      'version': appVersion,
      'buildNumber': buildNumber,
      'isBeta': isBeta,
      'enableDebugTools': enableDebugTools,
      'firebaseProject': currentProjectId,
    };
  }
}
