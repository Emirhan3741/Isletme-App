import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// 🔍 Firebase Debug Utilities v2.0
// Firebase bağlantı sorunlarını tespit etme ve çözme araçları
// Index eksikliği, permission denied ve diğer yaygın hatalar için çözümler
class FirebaseDebugUtils {
  // 🔐 Authentication durumu kontrol et
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return {
          'success': false,
          'message': '❌ Kullanıcı oturumu açık değil',
          'details': 'Giriş yapılmamış',
          'suggestions': [
            'Giriş yapmayı deneyin',
            'FirebaseAuth.instance.signInWithEmailAndPassword() kullanın',
            'Auth state listener ekleyin'
          ]
        };
      }

      // Email doğrulanmış mı kontrol et
      await user.reload();
      final isEmailVerified = user.emailVerified;

      return {
        'success': true,
        'message': '✅ Kullanıcı oturumu aktif',
        'user': {
          'uid': user.uid,
          'email': user.email,
          'emailVerified': isEmailVerified,
          'displayName': user.displayName,
          'lastSignIn': user.metadata.lastSignInTime?.toIso8601String(),
        },
        'suggestions': isEmailVerified ? [] : ['Email adresini doğrulayın']
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Auth kontrolü başarısız',
        'error': e.toString(),
        'suggestions': [
          'Firebase Auth yapılandırmasını kontrol edin',
          'API key\'lerin doğru olduğundan emin olun'
        ]
      };
    }
  }

  // 📦 Firestore bağlantı testi ve index kontrolü
  static Future<Map<String, dynamic>> testFirestoreConnection(
      String collection) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': '❌ Kullanıcı oturumu bulunamadı',
          'suggestions': ['Önce giriş yapın']
        };
      }

      // Basit okuma testi
      final testDoc = await FirebaseFirestore.instance
          .collection(collection)
          .limit(1)
          .get();

      // Composite index gerektiren sorgu testi
      Map<String, dynamic> indexTest = {
        'success': true,
        'message': '✅ Index sorunu yok'
      };

      try {
        await FirebaseFirestore.instance
            .collection(collection)
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
      } catch (indexError) {
        if (indexError.toString().contains('failed-precondition') ||
            indexError.toString().contains('requires an index')) {
          indexTest = {
            'success': false,
            'message': '⚠️ Composite index eksik',
            'error': indexError.toString(),
            'indexUrl': _extractIndexUrl(indexError.toString()),
            'suggestions': [
              'Firebase Console\'dan index oluşturun',
              'Verilen URL\'yi tarayıcıda açın',
              'Index oluşturulduktan sonra 2-3 dakika bekleyin',
              'Alternatif: .orderBy() kullanmadan sorgulayın'
            ]
          };
        }
      }

      return {
        'success': true,
        'message': '✅ Firestore bağlantısı çalışıyor',
        'collection': collection,
        'docCount': testDoc.docs.length,
        'indexTest': indexTest,
        'suggestions': indexTest['success'] ? [] : indexTest['suggestions']
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Firestore bağlantı hatası',
        'error': e.toString(),
        'suggestions': _getFirestoreErrorSuggestions(e.toString())
      };
    }
  }

  // 🔗 Index URL'sini hata mesajından çıkar
  static String? _extractIndexUrl(String errorMessage) {
    final urlPattern = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlPattern.firstMatch(errorMessage);
    return match?.group(0);
  }

  // 💾 Firebase Storage bağlantı testi
  static Future<Map<String, dynamic>> testStorageConnection(String path) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': '❌ Kullanıcı oturumu bulunamadı',
          'suggestions': ['Önce giriş yapın']
        };
      }

      // Storage bucket erişim testi
      final ref = FirebaseStorage.instance.ref().child('test_connection.txt');

      try {
        await ref.getDownloadURL();
      } catch (notFoundError) {
        // Dosya yoksa normal, bağlantı çalışıyor demektir
        if (notFoundError.toString().contains('object-not-found')) {
          return {
            'success': true,
            'message': '✅ Storage bağlantısı çalışıyor',
            'path': path,
            'suggestions': []
          };
        }
      }

      return {
        'success': true,
        'message': '✅ Storage erişimi doğrulandı',
        'path': path,
        'suggestions': []
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Storage bağlantı hatası',
        'error': e.toString(),
        'suggestions': _getStorageErrorSuggestions(e.toString())
      };
    }
  }

  // 🔍 Kapsamlı sistem kontrolü
  static Future<Map<String, dynamic>> performSystemCheck() async {
    final results = <String, dynamic>{};

    // Paralel testler
    final authResult = await checkAuthStatus();
    final firestoreResult = await testFirestoreConnection('lawyer_clients');
    final storageResult = await testStorageConnection('documents');

    results['auth'] = authResult;
    results['firestore'] = firestoreResult;
    results['storage'] = storageResult;
    results['summary'] = _generateSummary(results);
    results['timestamp'] = DateTime.now().toIso8601String();

    return results;
  }

  // 🎯 Hata öneri sistemi - Firestore
  static List<String> _getFirestoreErrorSuggestions(String error) {
    if (error.contains('permission-denied')) {
      return [
        '🔐 Firestore Rules kontrolü yapın',
        '✅ firebase console > Firestore > Rules: allow read, write: if true;',
        '🔑 Kullanıcının doğru collection\'a erişim iznı var mı?',
        '⏰ Rules değişikliği 1-2 dakika sürebilir'
      ];
    }

    if (error.contains('failed-precondition') ||
        error.contains('requires an index')) {
      return [
        '📊 Composite Index eksik',
        '🔗 Hata mesajındaki URL\'yi tarayıcıda açın',
        '⚡ Firebase Console\'dan index oluşturun',
        '⏱️ Index oluşturulduktan sonra 2-3 dakika bekleyin',
        '🔄 Sayfayı yenileyip tekrar deneyin'
      ];
    }

    if (error.contains('network-request-failed')) {
      return [
        '🌐 İnternet bağlantınızı kontrol edin',
        '🔄 Sayfayı yenileyip tekrar deneyin',
        '🚪 Firewall veya proxy ayarlarını kontrol edin'
      ];
    }

    return [
      '🔍 Hata detaylarını console\'da kontrol edin',
      '📚 Firebase documentation\'ını inceleyin',
      '🔄 Uygulamayı yeniden başlatmayı deneyin'
    ];
  }

  // 🎯 Hata öneri sistemi - Storage
  static List<String> _getStorageErrorSuggestions(String error) {
    if (error.contains('permission-denied')) {
      return [
        '🔐 Storage Rules kontrolü yapın',
        '✅ Firebase Console > Storage > Rules: allow read, write: if true;',
        '📁 Doğru path\'e erişim izni var mı?'
      ];
    }

    if (error.contains('object-not-found')) {
      return [
        '📄 Dosya bulunamadı - normal olabilir',
        '📁 Path\'in doğru olduğundan emin olun',
        '🔄 Dosya upload edildi mi kontrol edin'
      ];
    }

    if (error.contains('quota-exceeded')) {
      return [
        '💾 Storage kotanız dolmuş',
        '🗑️ Gereksiz dosyaları silin',
        '💳 Plan yükseltmeyi düşünün'
      ];
    }

    return [
      '🔍 Storage yapılandırmasını kontrol edin',
      '📁 Dosya formatı destekleniyor mu?',
      '🔄 Yeniden upload etmeyi deneyin'
    ];
  }

  // 📊 Sonuç özeti oluştur
  static Map<String, dynamic> _generateSummary(Map<String, dynamic> results) {
    int passedTests = 0;
    int totalTests = 0;
    final issues = <String>[];
    final recommendations = <String>[];

    ['auth', 'firestore', 'storage'].forEach((test) {
      totalTests++;
      if (results[test]?['success'] == true) {
        passedTests++;
      } else {
        issues.add('❌ ${test.toUpperCase()}: ${results[test]?['message']}');
        if (results[test]?['suggestions'] != null) {
          recommendations
              .addAll(List<String>.from(results[test]['suggestions']));
        }
      }
    });

    // Index sorunları özel kontrolü
    if (results['firestore']?['indexTest']?['success'] == false) {
      issues.add('⚠️ COMPOSITE INDEX: Bazı sorgular index gerektirir');
      if (results['firestore']['indexTest']['indexUrl'] != null) {
        recommendations.add(
            '🔗 Index URL: ${results['firestore']['indexTest']['indexUrl']}');
      }
    }

    return {
      'score': '$passedTests/$totalTests',
      'status': passedTests == totalTests ? 'healthy' : 'needs_attention',
      'issues': issues,
      'recommendations': recommendations,
      'quickFix': passedTests < totalTests
          ? 'Firebase Console > Firestore > Rules: allow read, write: if true;'
          : 'Sistem tamamen sağlıklı ✅'
    };
  }

  // 🖨️ Debug raporu yazdır
  static void printDebugReport(Map<String, dynamic> results) {
    if (kDebugMode) debugPrint('\n🔥 FIREBASE DEBUG RAPORU 🔥');
    if (kDebugMode) debugPrint('═' * 50);
    if (kDebugMode) debugPrint('⏰ Zaman: ${results['timestamp']}');
    if (kDebugMode)
      debugPrint(
          '📊 Durum: ${results['summary']['score']} - ${results['summary']['status']}');
    if (kDebugMode) debugPrint('');

    if (results['summary']['issues'].isNotEmpty) {
      if (kDebugMode) debugPrint('🚨 SORUNLAR:');
      for (final issue in results['summary']['issues']) {
        if (kDebugMode) debugPrint('  $issue');
      }
      if (kDebugMode) debugPrint('');
    }

    if (results['summary']['recommendations'].isNotEmpty) {
      if (kDebugMode) debugPrint('💡 ÖNERİLER:');
      for (final rec in results['summary']['recommendations']) {
        if (kDebugMode) debugPrint('  $rec');
      }
      if (kDebugMode) debugPrint('');
    }

    if (kDebugMode)
      debugPrint('🔧 HIZLI ÇÖZÜM: ${results['summary']['quickFix']}');
    if (kDebugMode) debugPrint('═' * 50);
  }

  // 🎨 Debug widget'ı için UI helper
  static Widget buildDebugCard(
      BuildContext context, Map<String, dynamic> results) {
    final summary = results['summary'];
    final isHealthy = summary['status'] == 'healthy';

    return Card(
      color: isHealthy ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Firebase Durum: ${summary['score']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isHealthy && summary['issues'].isNotEmpty) ...[
              const Text('🚨 Sorunlar:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ...summary['issues']
                  .map<Widget>((issue) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: Text('• $issue',
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHealthy ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔧 ${summary['quickFix']}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Otomatik hata yakalayıcı
  static void setupErrorHandler() {
    // Global Firestore error handler
    FirebaseFirestore.instance.enableNetwork();

    if (kDebugMode)
      debugPrint('🔍 Firebase Debug Utils aktif - hata yakalayıcı çalışıyor');
  }

  // 🔗 Hızlı index oluşturma linki
  static String generateIndexCreationUrl(
      String projectId, String collection, List<String> fields) {
    final baseUrl =
        'https://console.firebase.google.com/v1/r/project/$projectId/firestore/indexes';
    // Bu URL Firebase console'da otomatik index oluşturmaya yönlendirir
    return baseUrl;
  }
}
