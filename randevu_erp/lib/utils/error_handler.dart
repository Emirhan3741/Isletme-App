import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  static String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      default:
        return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }

  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'not-found':
        return 'İstenen veri bulunamadı.';
      case 'already-exists':
        return 'Bu veri zaten mevcut.';
      case 'unavailable':
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı.';
      case 'invalid-argument':
        return 'Geçersiz veri girdiniz.';
      case 'resource-exhausted':
        return 'Kaynak limiti aşıldı.';
      case 'aborted':
        return 'İşlem iptal edildi.';
      case 'internal':
        return 'Sunucu hatası oluştu.';
      default:
        return e.message ?? 'Veri işlemi sırasında hata oluştu.';
    }
  }

  static String getNetworkErrorMessage() {
    return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
  }

  static String getGenericErrorMessage() {
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Kapat',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600]),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  static String handleError(dynamic error) {
    if (error is FirebaseAuthException) {
      return getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error.toString().contains('network') || 
               error.toString().contains('connection')) {
      return getNetworkErrorMessage();
    } else {
      return getGenericErrorMessage();
    }
  }

  static void logError(dynamic error, {String? context}) {
    // Production'da sadece kritik hatalar loglanır
    if (context != null) {
      // Logger.error('Error in $context: $error', context: context, error: error);
    }
    
    // Gelişmiş loglamak için Firebase Crashlytics kullanılabilir
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

class NetworkHelper {
  static Future<bool> hasInternetConnection() async {
    try {
      // Basit bir network kontrolü
      // Gerçek uygulamada connectivity_plus paketi kullanılabilir
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<T?> executeWithNetworkCheck<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        ErrorHandler.showErrorSnackBar(
          context,
          'İnternet bağlantınızı kontrol edin.',
        );
        return null;
      }

      return await operation();
    } catch (error) {
      ErrorHandler.logError(error, context: 'NetworkHelper');
      ErrorHandler.showErrorSnackBar(
        context,
        errorMessage ?? ErrorHandler.handleError(error),
      );
      return null;
    }
  }
} 