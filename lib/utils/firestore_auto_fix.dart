import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore sorunlarını otomatik tespit edip çözüm öneren yardımcı sınıf
class FirestoreAutoFix {
  static final FirestoreAutoFix _instance = FirestoreAutoFix._internal();
  factory FirestoreAutoFix() => _instance;
  FirestoreAutoFix._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Index sorunları tespiti için map
  final Map<String, String> _indexUrls = {
    'notes_userId_createdAt': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=Clxwcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbm90ZXMvaW5kZXhlcy9fEAEaDAoIdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg',
    'appointments_userId_dateTime': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=Cl5wcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYXBwb2ludG1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGgwKCGRhdGVUaW1lEAIaDgoKX19uYW1lX18QAg',
    'appointments_userId_employeeId_dateTime': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=CmFwcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYXBwb2ludG1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGg8KC2VtcGxveWVlSWQQARoMCghkYXRlVGltZRACGg4KCl9fbmFtZV9fEAI',
    'appointments_userId_customerId_dateTime': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=CmBwcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYXBwb2ludG1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGg4KCmN1c3RvbWVySWQQARoMCghkYXRlVGltZRACGg4KCl9fbmFtZV9fEAI',
    'appointments_userId_status_dateTime': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYXBwb2ludG1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGgkKBXN0YXR1cxABGgwKCGRhdGVUaW1lEAIaDgoKX19uYW1lX18QAg',
    'documents_userId_uploadedAt': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=Cl1wcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZG9jdW1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGg0KCXVwbG9hZGVkQXQQAhoDCgEqEAI',
    'documents_userId_panel_uploadedAt': 'https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=CmBwcm9qZWN0cy9yYW5kZXZ1LXRha2lwLWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZG9jdW1lbnRzL2luZGV4ZXMvXxABGgwKCHVzZXJJZBABGgoKBnBhbmVsEAEaDQoJdXBsb2FkZWRBdBACGgMKASoQAg',
  };

  /// Firestore'da kritik sorguları test et
  Future<Map<String, dynamic>> runDiagnostics() async {
    if (kDebugMode) debugPrint('\n🔧 Firestore tanılama başlatılıyor...');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _auth.currentUser?.uid,
      'indexTests': <String, bool>{},
      'errorTests': <String, String>{},
      'recommendations': <String>[],
    };

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      results['error'] = 'Kullanıcı giriş yapmamış';
      return results;
    }

    // Test senaryoları
    final tests = [
      {
        'name': 'notes_userId_createdAt',
        'description': 'Notes collection - userId + createdAt ordering',
        'test': () => _firestore
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get(),
      },
      {
        'name': 'appointments_userId_dateTime',
        'description': 'Appointments collection - userId + dateTime ordering',
        'test': () => _firestore
            .collection('appointments')
            .where('userId', isEqualTo: userId)
            .orderBy('dateTime', descending: true)
            .limit(1)
            .get(),
      },
      {
        'name': 'documents_userId_uploadedAt',
        'description': 'Documents collection - userId + uploadedAt ordering',
        'test': () => _firestore
            .collection('documents')
            .where('userId', isEqualTo: userId)
            .orderBy('uploadedAt', descending: true)
            .limit(1)
            .get(),
      },
    ];

    for (final test in tests) {
      final testName = test['name'] as String;
      final testDesc = test['description'] as String;
      final testFunc = test['test'] as Future<QuerySnapshot> Function();

      try {
        await testFunc();
        results['indexTests'][testName] = true;
        if (kDebugMode) debugPrint('✅ $testDesc - OK');
      } catch (e) {
        results['indexTests'][testName] = false;
        results['errorTests'][testName] = e.toString();
        
        if (e is FirebaseException && e.code == 'failed-precondition') {
          if (kDebugMode) debugPrint('❌ $testDesc - INDEX EKSİK');
          final indexUrl = _indexUrls[testName];
          if (indexUrl != null) {
            results['recommendations'].add('$testDesc için index oluşturun: $indexUrl');
          }
        } else {
          if (kDebugMode) debugPrint('❌ $testDesc - HATA: $e');
        }
      }
    }

    return results;
  }

  /// Tüm index'leri hızlıca oluşturmak için URL listesi döndür
  List<String> getAllIndexUrls() {
    return _indexUrls.values.toList();
  }

  /// Index hatası yakalandığında otomatik çözüm öner
  String getIndexSolution(String errorMessage) {
    if (!errorMessage.contains('failed-precondition') && 
        !errorMessage.contains('requires an index')) {
      return 'Bu bir index hatası değil: $errorMessage';
    }

    final buffer = StringBuffer();
    buffer.writeln('🔍 FIRESTORE INDEX HATASI TESPİT EDİLDİ!');
    buffer.writeln('');
    buffer.writeln('📋 HIZLI ÇÖZÜM:');
    buffer.writeln('1. Aşağıdaki URL\'leri sırayla açın');
    buffer.writeln('2. Her birinde "Create Index" butonuna tıklayın');
    buffer.writeln('3. 2-3 dakika bekleyin');
    buffer.writeln('4. Uygulamayı yeniden başlatın');
    buffer.writeln('');
    
    int i = 1;
    for (final entry in _indexUrls.entries) {
      buffer.writeln('${i++}. ${entry.key}:');
      buffer.writeln('   ${entry.value}');
      buffer.writeln('');
    }
    
    buffer.writeln('🎯 Alternatif: firebase_deploy.bat çalıştırın');
    
    return buffer.toString();
  }

  /// Console'a detaylı rapor yazdır
  void printDetailedReport(Map<String, dynamic> diagnostics) {
    if (!kDebugMode) return;

    debugPrint('\n' + '═' * 60);
    debugPrint('🔥 FIRESTORE TANİLAMA RAPORU');
    debugPrint('═' * 60);
    debugPrint('⏰ Zaman: ${diagnostics['timestamp']}');
    debugPrint('👤 Kullanıcı: ${diagnostics['userId'] ?? 'N/A'}');
    debugPrint('');

    final indexTests = diagnostics['indexTests'] as Map<String, bool>;
    final errorTests = diagnostics['errorTests'] as Map<String, String>;
    final recommendations = diagnostics['recommendations'] as List<String>;

    // Başarılı testler
    final successfulTests = indexTests.entries.where((e) => e.value).toList();
    if (successfulTests.isNotEmpty) {
      debugPrint('✅ BAŞARILI TESTLER (${successfulTests.length}):');
      for (final test in successfulTests) {
        debugPrint('   • ${test.key}');
      }
      debugPrint('');
    }

    // Başarısız testler
    final failedTests = indexTests.entries.where((e) => !e.value).toList();
    if (failedTests.isNotEmpty) {
      debugPrint('❌ BAŞARISIZ TESTLER (${failedTests.length}):');
      for (final test in failedTests) {
        debugPrint('   • ${test.key}');
        final error = errorTests[test.key];
        if (error != null) {
          debugPrint('     Hata: ${error.substring(0, error.length > 100 ? 100 : error.length)}...');
        }
      }
      debugPrint('');
    }

    // Öneriler
    if (recommendations.isNotEmpty) {
      debugPrint('💡 ÖNERİLER:');
      for (final rec in recommendations) {
        debugPrint('   • $rec');
      }
      debugPrint('');
    }

    // Özet
    final totalTests = indexTests.length;
    final passedTests = successfulTests.length;
    final failedTestsCount = failedTests.length;

    debugPrint('📊 ÖZET:');
    debugPrint('   Toplam Test: $totalTests');
    debugPrint('   Başarılı: $passedTests');
    debugPrint('   Başarısız: $failedTestsCount');
    debugPrint('   Başarı Oranı: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%');
    debugPrint('');

    if (failedTestsCount > 0) {
      debugPrint('🚨 HAREKETE GEÇİN:');
      debugPrint('   1. FIRESTORE_INDEX_URLS.md dosyasını açın');
      debugPrint('   2. URL\'leri tarayıcıda açıp index oluşturun');
      debugPrint('   3. firebase_deploy.bat çalıştırın');
      debugPrint('   4. 2-3 dakika bekleyip uygulamayı yeniden başlatın');
    } else {
      debugPrint('🎉 TÜM TESTLER BAŞARILI!');
      debugPrint('   Firestore index\'leriniz hazır.');
    }

    debugPrint('═' * 60);
  }

  /// Widget'larda kullanım için basit index durumu kontrol et
  Future<bool> isIndexReady(String indexName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      switch (indexName) {
        case 'notes':
          await _firestore
              .collection('notes')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          return true;
        case 'appointments':
          await _firestore
              .collection('appointments')
              .where('userId', isEqualTo: userId)
              .orderBy('dateTime', descending: true)
              .limit(1)
              .get();
          return true;
        case 'documents':
          await _firestore
              .collection('documents')
              .where('userId', isEqualTo: userId)
              .orderBy('uploadedAt', descending: true)
              .limit(1)
              .get();
          return true;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
}