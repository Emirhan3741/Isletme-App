import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadService {
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Desteklenen dosya uzantıları
  static List<String> get supportedExtensions => [
        'pdf',
        'doc',
        'docx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'gif',
        'mp4',
        'avi',
        'mov'
      ];

  // Maksimum dosya boyutu (MB)
  static double get maxFileSizeMB => 10.0;

  // Dosya seçimi (web uyumlu)
  static Future<Map<String, dynamic>?> pickFile({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    FileType fileType = FileType.any,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 FilePicker çağrılıyor...');
        print('📄 İzin verilen uzantılar: $allowedExtensions');
        print('🔢 Çoklu seçim: $allowMultiple');
      }

      // Web platformu için kIsWeb kontrolü
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        fileType = FileType.custom;
      }

      // FilePicker ile dosya seçimi
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true, // Web platformu için gerekli
      );

      if (result == null || result.files.isEmpty) {
        if (kDebugMode) print('❌ Dosya seçimi iptal edildi');
        return null;
      }

      final file = result.files.first;

      if (kDebugMode) {
        print('✅ Dosya seçildi: ${file.name}');
        print('📏 Boyut: ${file.size} bytes');
        print('🏷️ Uzantı: ${file.extension}');
      }

      // Dosya boyutu kontrolü
      if (file.size > (maxFileSizeMB * 1024 * 1024)) {
        throw Exception('Dosya boyutu ${maxFileSizeMB}MB\'dan büyük olamaz');
      }

      // Web/mobil platform kontrolü
      return {
        'fileName': file.name,
        'fileSize': file.size,
        'fileExtension': file.extension,
        'fileBytes': kIsWeb ? file.bytes : null,
        'filePath': !kIsWeb ? file.path : null,
        'isWeb': kIsWeb,
      };
    } catch (e) {
      if (kDebugMode) print('❌ FilePicker hatası: $e');
      rethrow;
    }
  }

  // Dosya seçimi ve yükleme (tek işlem)
  static Future<Map<String, dynamic>?> pickAndUploadFile({
    String? folderPath,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    String? userRole,
    String? userId,
  }) async {
    try {
      // Dosya seç
      final fileResult = await pickFile(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (fileResult == null) return null;

      // Dosyayı yükle
      return await uploadFile(
        fileResult: fileResult,
        folderPath: folderPath ?? 'documents',
        userRole: userRole,
        userId: userId,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Pick and upload hatası: $e');
      rethrow;
    }
  }

  // Dosya yükleme (web uyumlu)
  static Future<Map<String, dynamic>> uploadFile({
    required Map<String, dynamic> fileResult,
    String folderPath = 'documents',
    String? userRole,
    String? userId,
  }) async {
    try {
      final fileName = fileResult['fileName'] ?? 'document';

      // Web platformu kontrolü
      if (kIsWeb) {
        if (fileResult['fileBytes'] == null) {
          throw Exception('Web platformunda file bytes gerekli');
        }
        return await _uploadFromBytes(
          fileResult['fileBytes'],
          fileName,
          folderPath,
          userRole,
          userId,
        );
      } else {
        if (fileResult['filePath'] == null) {
          throw Exception('Mobil platformda file path gerekli');
        }
        return await _uploadFromPath(
          fileResult['filePath'],
          fileName,
          folderPath,
          userRole,
          userId,
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Upload hatası: $e');
      rethrow;
    }
  }

  // Web'den bytes ile yükleme
  static Future<Map<String, dynamic>> _uploadFromBytes(
    Uint8List bytes,
    String fileName,
    String folderPath,
    String? userRole,
    String? userId,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final uploadPath = '$folderPath/${user.uid}/${timestamp}_$fileName';

      if (kDebugMode) print('📤 Web upload başlıyor: $uploadPath');

      final ref = storage.ref().child(uploadPath);
      final uploadTask = ref.putData(bytes);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final fileDoc = {
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'filePath': uploadPath,
        'fileSize': bytes.length,
        'fileExtension': fileExtension,
        'uploadDate': FieldValue.serverTimestamp(),
        'uploadedBy': user.uid,
        'userRole': userRole,
        'userId': userId,
      };

      await firestore.collection('documents').add(fileDoc);

      if (kDebugMode) print('✅ Web upload tamamlandı: $downloadUrl');

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'fileSize': bytes.length,
        'message': 'Dosya başarıyla yüklendi',
      };
    } catch (e) {
      if (kDebugMode) print('❌ Web upload hatası: $e');
      rethrow;
    }
  }

  // Mobil'den path ile yükleme
  static Future<Map<String, dynamic>> _uploadFromPath(
    String filePath,
    String fileName,
    String folderPath,
    String? userRole,
    String? userId,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final uploadPath = '$folderPath/${user.uid}/${timestamp}_$fileName';

      if (kDebugMode) print('📤 Mobil upload başlıyor: $uploadPath');

      final ref = storage.ref().child(uploadPath);
      final uploadTask = ref.putFile(File(filePath));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final file = File(filePath);
      final fileSize = await file.length();

      final fileDoc = {
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'filePath': uploadPath,
        'fileSize': fileSize,
        'fileExtension': fileExtension,
        'uploadDate': FieldValue.serverTimestamp(),
        'uploadedBy': user.uid,
        'userRole': userRole,
        'userId': userId,
      };

      await firestore.collection('documents').add(fileDoc);

      if (kDebugMode) print('✅ Mobil upload tamamlandı: $downloadUrl');

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'message': 'Dosya başarıyla yüklendi',
      };
    } catch (e) {
      if (kDebugMode) print('❌ Mobil upload hatası: $e');
      rethrow;
    }
  }

  // Dosya ve belge kaydetme (backward compatibility)
  static Future<Map<String, dynamic>> uploadAndSaveDocument({
    required String fileName,
    required Uint8List? fileBytes,
    required String? filePath,
    required String module,
    String? customPath,
    Function(double)? onProgress,
  }) async {
    try {
      final fileResult = {
        'fileName': fileName,
        'fileBytes': fileBytes,
        'filePath': filePath,
      };

      return await uploadFile(
        fileResult: fileResult,
        folderPath: customPath ?? module,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Upload and save hatası: $e');
      rethrow;
    }
  }

  // Dosya silme
  static Future<bool> deleteFile(String storagePath) async {
    try {
      if (kDebugMode) print('🗑️ Dosya siliniyor: $storagePath');

      final ref = storage.ref().child(storagePath);
      await ref.delete();

      if (kDebugMode) print('✅ Dosya silindi: $storagePath');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Dosya silme hatası: $e');
      return false;
    }
  }

  // Dosya boyutu formatlama
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Dosya ikonu
  static String getFileIcon(String? extension) {
    if (extension == null) return '📄';

    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📋';
      case 'doc':
      case 'docx':
        return '📝';
      case 'txt':
        return '📄';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📄';
    }
  }

  // Storage path oluşturma
  static String getStoragePath(String module, String fileName) {
    final user = FirebaseAuth.instance.currentUser;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$module/${user?.uid}/${timestamp}_$fileName';
  }
}

// Backward compatibility için eski sınıflar
class FileUploadResult {
  final Map<String, dynamic> file;
  final String originalName;
  final String extension;
  final int sizeInBytes;
  final double sizeInMB;

  FileUploadResult({
    required this.file,
    required this.originalName,
    required this.extension,
    required this.sizeInBytes,
    required this.sizeInMB,
  });
}

class UploadedFileData {
  final String fileName;
  final String originalFileName;
  final String fileUrl;
  final String fileExtension;
  final int fileSizeBytes;
  final double fileSizeMB;
  final String storagePath;
  final DateTime uploadDate;

  UploadedFileData({
    required this.fileName,
    required this.originalFileName,
    required this.fileUrl,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.fileSizeMB,
    required this.storagePath,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'originalFileName': originalFileName,
      'downloadUrl': fileUrl,
      'fileExtension': fileExtension,
      'fileSize': fileSizeBytes,
      'fileSizeMB': fileSizeMB,
      'storagePath': storagePath,
      'uploadDate': uploadDate,
    };
  }
}

class UploadCompletionResult {
  final bool success;
  final UploadedFileData? fileData;
  final String message;

  UploadCompletionResult({
    required this.success,
    this.fileData,
    required this.message,
  });
}
