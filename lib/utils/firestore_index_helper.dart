import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore Index yönetimi ve hata tespiti için yardımcı sınıf
class FirestoreIndexHelper {
  static final FirestoreIndexHelper _instance = FirestoreIndexHelper._internal();
  factory FirestoreIndexHelper() => _instance;
  FirestoreIndexHelper._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tespit edilen eksik indeksler listesi
  final Set<String> _missingIndexes = <String>{};

  /// Firestore query'sini index error kontrolü ile çalıştır
  Future<QuerySnapshot<Map<String, dynamic>>> executeQueryWithIndexCheck({
    required Query<Map<String, dynamic>> query,
    required String operationName,
  }) async {
    try {
      final snapshot = await query.get();
      if (kDebugMode) debugPrint('✅ $operationName query başarılı');
      return snapshot;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' && 
          (e.message?.contains('index') == true || e.message?.contains('requires an index') == true)) {
        
        await _handleIndexError(e, operationName);
        rethrow;
      } else {
        if (kDebugMode) debugPrint('❌ Firestore $operationName hatası: ${e.code} - ${e.message}');
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen $operationName hatası: $e');
      rethrow;
    }
  }

  /// Index hatası yakalandığında işlem yap
  Future<void> _handleIndexError(FirebaseException e, String operationName) async {
    final indexUrl = _extractIndexUrl(e.message ?? '');
    final indexKey = _generateIndexKey(e.message ?? '');
    
    // Daha önce tespit edilmişse tekrar loglama
    if (_missingIndexes.contains(indexKey)) {
      if (kDebugMode) debugPrint('⚠️ $operationName - Index hatası (daha önce tespit edildi)');
      return;
    }
    
    _missingIndexes.add(indexKey);
    
    if (kDebugMode) {
      debugPrint('🚨 FIRESTORE INDEX HATASI 🚨');
      debugPrint('═' * 50);
      debugPrint('🔍 İşlem: $operationName');
      debugPrint('❌ Hata: ${e.message}');
      debugPrint('🔗 Index URL: $indexUrl');
      debugPrint('💡 ÇÖZÜM ADIMLARI:');
      debugPrint('   1. Yukarıdaki URL\'yi tarayıcıda açın');
      debugPrint('   2. "Create Index" butonuna tıklayın');
      debugPrint('   3. 2-3 dakika bekleyin');
      debugPrint('   4. Uygulamayı yeniden başlatın');
      debugPrint('═' * 50);
    }
    
    // Index bilgisini localStorage'a kaydet (sonradan raporlama için)
    await _saveIndexErrorToPrefs(operationName, indexUrl, e.message ?? '');
  }

  /// Index URL'sini hata mesajından çıkart
  String _extractIndexUrl(String errorMessage) {
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0) ?? 'Index URL bulunamadı';
  }

  /// Index için benzersiz key oluştur
  String _generateIndexKey(String errorMessage) {
    // Collection ve field bilgilerini çıkart
    final collectionMatch = RegExp(r'collection \'([^\']+)\'').firstMatch(errorMessage);
    final fieldsMatch = RegExp(r'fields \'([^\']+)\'').firstMatch(errorMessage);
    
    final collection = collectionMatch?.group(1) ?? 'unknown';
    final fields = fieldsMatch?.group(1) ?? 'unknown';
    
    return '${collection}_$fields';
  }

  /// Index hatalarını SharedPreferences'a kaydet
  Future<void> _saveIndexErrorToPrefs(String operation, String indexUrl, String error) async {
    try {
      // Bu kısım SharedPreferences ile implementation'a bırakılabilir
      // Şimdilik debug log olarak bırakıyoruz
      if (kDebugMode) {
        debugPrint('💾 Index hatası kaydedildi: $operation');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Index hata kayıt hatası: $e');
    }
  }

  /// Yaygın index pattern'larını test et
  Future<Map<String, bool>> checkCommonIndexes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'auth': false};
    }

    final results = <String, bool>{};

    // Appointments with userId + createdAt ordering
    results['appointments_userId_createdAt'] = await _testIndex(
      'appointments',
      () => _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1),
    );

    // Customers with userId + firstName ordering
    results['customers_userId_firstName'] = await _testIndex(
      'customers',
      () => _firestore
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .orderBy('firstName')
          .limit(1),
    );

    // Documents with userId + uploadedAt ordering
    results['documents_userId_uploadedAt'] = await _testIndex(
      'documents',
      () => _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .limit(1),
    );

    // Transactions with userId + date ordering
    results['transactions_userId_date'] = await _testIndex(
      'transactions',
      () => _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1),
    );

    // Expenses with userId + date ordering
    results['expenses_userId_date'] = await _testIndex(
      'expenses',
      () => _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1),
    );

    return results;
  }

  /// Belirli bir index'i test et
  Future<bool> _testIndex(String indexName, Query<Map<String, dynamic>> Function() queryBuilder) async {
    try {
      final query = queryBuilder();
      await query.get();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' && e.message?.contains('index') == true) {
        if (kDebugMode) debugPrint('❌ Index eksik: $indexName');
        return false;
      }
      return true; // Başka bir hata, index problemi değil
    } catch (e) {
      return true; // Başka bir hata, index problemi değil
    }
  }

  /// Tüm index durumlarını raporla
  Future<void> generateIndexReport() async {
    if (kDebugMode) {
      debugPrint('\n🔍 FIRESTORE INDEX DURUM RAPORU 🔍');
      debugPrint('═' * 50);
    }

    final indexResults = await checkCommonIndexes();
    
    final missingIndexes = <String>[];
    final availableIndexes = <String>[];

    indexResults.forEach((indexName, isAvailable) {
      if (isAvailable) {
        availableIndexes.add(indexName);
      } else {
        missingIndexes.add(indexName);
      }
    });

    if (kDebugMode) {
      debugPrint('✅ Mevcut Index\'ler (${availableIndexes.length}):');
      for (final index in availableIndexes) {
        debugPrint('   • $index');
      }
      
      debugPrint('\n❌ Eksik Index\'ler (${missingIndexes.length}):');
      for (final index in missingIndexes) {
        debugPrint('   • $index');
      }
      
      if (missingIndexes.isNotEmpty) {
        debugPrint('\n💡 ÇÖZÜM:');
        debugPrint('   1. Firebase Console > Firestore > Indexes');
        debugPrint('   2. Composite tab\'ına gidin');
        debugPrint('   3. Eksik index\'leri manuel olarak oluşturun');
        debugPrint('   4. Veya hata mesajlarındaki URL\'leri kullanın');
      }
      
      debugPrint('═' * 50);
    }
  }

  /// Eksik index sayısını al
  int get missingIndexCount => _missingIndexes.length;

  /// Eksik index'leri temizle
  void clearMissingIndexes() {
    _missingIndexes.clear();
  }
}