import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'feedback_utils.dart';

class ErrorHandler {
  // Generic error handler for async operations
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation,
    BuildContext context, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = false,
    bool showSuccess = false,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      if (showLoading && loadingMessage != null) {
        // Loading dialog temporarily disabled
        // FeedbackUtils.showLoadingDialog(context, loadingMessage);
      }

      final result = await operation();

      if (showLoading && loadingMessage != null) {
        // Navigator.of(context).pop(); // Close loading dialog
      }

      if (showSuccess && successMessage != null) {
        FeedbackUtils.showSuccess(context, successMessage);
      }

      onSuccess?.call();
      return result;
    } catch (e) {
      if (showLoading && loadingMessage != null && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (context.mounted) {
        handleError(e, context);
      }

      onError?.call();
      return null;
    }
  }

  // Handle specific error types
  static void handleError(dynamic error, BuildContext context) {
    String message = _getErrorMessage(error);
    FeedbackUtils.showError(context, message);
  }

  // Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is Exception) {
      return _getGenericErrorMessage(error);
    } else {
      return 'Beklenmeyen bir hata oluştu: ${error.toString()}';
    }
  }

  // Firebase Auth error messages
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemi ile kayıtlı.';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen bir süre bekleyin.';
      case 'user-token-expired':
        return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
      default:
        return 'Kimlik doğrulama hatası: ${e.message ?? 'Bilinmeyen hata'}';
    }
  }

  // Firebase Firestore error messages
  static String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      case 'not-found':
        return 'İstenen veri bulunamadı.';
      case 'already-exists':
        return 'Bu veri zaten mevcut.';
      case 'failed-precondition':
        return 'İşlem için gerekli koşullar sağlanmamış.';
      case 'aborted':
        return 'İşlem iptal edildi. Lütfen tekrar deneyin.';
      case 'out-of-range':
        return 'Geçersiz veri aralığı.';
      case 'unimplemented':
        return 'Bu özellik henüz desteklenmiyor.';
      case 'internal':
        return 'İç sistem hatası oluştu.';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı.';
      case 'cancelled':
        return 'İşlem iptal edildi.';
      case 'resource-exhausted':
        return 'Sistem kaynakları tükendi. Lütfen daha sonra tekrar deneyin.';
      case 'invalid-argument':
        return 'Geçersiz parametre gönderildi.';
      default:
        return 'Veritabanı hatası: ${e.message ?? 'Bilinmeyen hata'}';
    }
  }

  // Generic error messages
  static String _getGenericErrorMessage(Exception e) {
    String message = e.toString();

    if (message.contains('SocketException')) {
      return 'İnternet bağlantısı hatası. Bağlantınızı kontrol edin.';
    } else if (message.contains('TimeoutException')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else if (message.contains('FormatException')) {
      return 'Geçersiz veri formatı.';
    } else if (message.contains('RangeError')) {
      return 'Veri aralığı hatası.';
    } else if (message.contains('StateError')) {
      return 'Uygulama durumu hatası.';
    } else if (message.contains('ArgumentError')) {
      return 'Geçersiz parametre hatası.';
    } else {
      return 'Bir hata oluştu: ${e.toString()}';
    }
  }

  // Network error checker
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || error.code == 'deadline-exceeded';
    }

    String message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('connection');
  }

  // Permission error checker
  static bool isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }

    if (error is FirebaseAuthException) {
      return error.code == 'operation-not-allowed' ||
          error.code == 'requires-recent-login';
    }

    return false;
  }

  // Authentication error checker
  static bool isAuthError(dynamic error) {
    return error is FirebaseAuthException;
  }

  // Show retry dialog for network errors
  static Future<bool> showRetryDialog(
    BuildContext context,
    String operation,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantı Hatası'),
        content: Text(
            'İnternet bağlantısı problemi nedeniyle $operation işlemi başarısız oldu. Tekrar denemek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static void logError(dynamic error, [String? operation]) {
    String logMessage =
        operation != null ? 'Error in $operation: $error' : 'Error: $error';

    if (kDebugMode) debugPrint('🚨 $logMessage');

    // Here you can add crash reporting (Firebase Crashlytics, etc.)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
