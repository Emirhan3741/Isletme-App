import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ensure user is authenticated before Storage operations
  Future<void> _ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      // Sign in anonymously for Storage access
      try {
        await _auth.signInAnonymously();
        if (kDebugMode) debugPrint('✅ Anonymous auth for Storage access');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Anonymous auth failed: $e');
        throw Exception('Firebase Authentication required for Storage access');
      }
    }
  }

  /// Upload file to Firebase Storage with automatic authentication
  Future<String> uploadFile({
    required String path,
    required List<int> fileBytes,
    required String fileName,
    String? contentType,
  }) async {
    // Null ve boş değer kontrolleri
    if (path.trim().isEmpty) {
      throw Exception('Dosya yolu boş olamaz');
    }
    if (fileName.trim().isEmpty) {
      throw Exception('Dosya adı boş olamaz');
    }
    if (fileBytes.isEmpty) {
      throw Exception('Dosya içeriği boş olamaz');
    }
    
    // Dosya boyutu kontrolü (max 50MB)
    if (fileBytes.length > 50 * 1024 * 1024) {
      throw Exception('Dosya boyutu 50MB\'dan büyük olamaz');
    }

    await _ensureAuthenticated();

    try {
      final ref = _storage.ref().child('$path/$fileName');
      
      final metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': fileName,
          'fileSize': fileBytes.length.toString(),
        },
      );

      if (kDebugMode) debugPrint('🚀 Dosya yükleniyor: $fileName (${fileBytes.length} bytes)');
      
      final uploadTask = ref.putData(Uint8List.fromList(fileBytes), metadata);
      
      // Upload progress izleme
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          if (kDebugMode) debugPrint('📊 Upload progress: ${progress.toStringAsFixed(1)}%');
        },
        onError: (error) {
          if (kDebugMode) debugPrint('❌ Upload progress error: $error');
        },
      );
      
      final snapshot = await uploadTask;
      
      // Upload durumu kontrolü
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload tamamlanamadı. Durum: ${snapshot.state}');
      }
      
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      // URL kontrolü
      if (downloadURL.isEmpty) {
        throw Exception('Download URL alınamadı');
      }

      if (kDebugMode) debugPrint('✅ Dosya başarıyla yüklendi: $downloadURL');
      if (kDebugMode) debugPrint('📈 Yüklenen boyut: ${snapshot.totalBytes} bytes');
      
      return downloadURL;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase Storage hatası: ${e.code} - ${e.message}');
      
      // Özel hata mesajları
      switch (e.code) {
        case 'storage/unauthorized':
          throw Exception('Dosya yükleme yetkiniz yok. Giriş yapınız.');
        case 'storage/canceled':
          throw Exception('Dosya yükleme iptal edildi.');
        case 'storage/quota-exceeded':
          throw Exception('Depolama alanı kotası aşıldı.');
        case 'storage/unauthenticated':
          throw Exception('Kimlik doğrulama gerekli.');
        case 'storage/retry-limit-exceeded':
          throw Exception('Yükleme deneme limiti aşıldı.');
        case 'storage/invalid-format':
          throw Exception('Geçersiz dosya formatı.');
        case 'storage/no-default-bucket':
          throw Exception('Varsayılan depolama bucket\'ı tanımlanmamış.');
        default:
          throw Exception('Dosya yüklenemedi: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen dosya yükleme hatası: $e');
      throw Exception('Dosya yüklenemedi: $e');
    }
  }

  /// Download file from Firebase Storage with automatic authentication
  Future<List<int>> downloadFile(String url) async {
    await _ensureAuthenticated();

    try {
      final ref = _storage.refFromURL(url);
      final data = await ref.getData();
      
      if (data == null) {
        throw Exception('Dosya bulunamadı');
      }

      if (kDebugMode) debugPrint('✅ File downloaded: ${data.length} bytes');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Storage download error: $e');
      throw Exception('Dosya indirilemedi: $e');
    }
  }

  /// Delete file from Firebase Storage with automatic authentication
  Future<void> deleteFile(String url) async {
    await _ensureAuthenticated();

    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      
      if (kDebugMode) debugPrint('✅ File deleted: $url');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Storage delete error: $e');
      throw Exception('Dosya silinemedi: $e');
    }
  }

  /// Get download URL with automatic authentication
  Future<String> getDownloadUrl(String path) async {
    await _ensureAuthenticated();

    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();
      
      if (kDebugMode) debugPrint('✅ Download URL: $url');
      return url;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Get URL error: $e');
      throw Exception('URL alınamadı: $e');
    }
  }

  /// List files in directory with automatic authentication
  Future<List<Reference>> listFiles(String path) async {
    await _ensureAuthenticated();

    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      
      if (kDebugMode) debugPrint('✅ Listed ${result.items.length} files in $path');
      return result.items;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ List files error: $e');
      throw Exception('Dosyalar listelenemedi: $e');
    }
  }
}