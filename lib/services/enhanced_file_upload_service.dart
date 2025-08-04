import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'file_upload_service.dart';
import 'firestore_service.dart';

/// Enhanced file upload service with structured Cloud Storage paths and Firestore integration
class EnhancedFileUploadService {
  static final EnhancedFileUploadService _instance =
      EnhancedFileUploadService._internal();
  factory EnhancedFileUploadService() => _instance;
  EnhancedFileUploadService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Cloud Storage folder structure constants
  static const String _profilePhotosPath = 'users';
  static const String _appointmentDocumentsPath = 'appointments';
  static const String _customerDocumentsPath = 'customers';
  static const String _staffDocumentsPath = 'staff';
  static const String _serviceDocumentsPath = 'services';
  static const String _reportsPath = 'reports';
  static const String _generalDocumentsPath = 'documents';

  // File type configurations for different modules
  static const Map<String, List<String>> _moduleFileTypes = {
    'profile': ['jpg', 'jpeg', 'png'],
    'contract': ['pdf', 'doc', 'docx'],
    'appointment': ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    'customer': ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    'staff': ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    'service': ['jpg', 'jpeg', 'png', 'pdf'],
    'report': ['pdf', 'xlsx', 'xls', 'csv'],
    'general': [
      'pdf',
      'doc',
      'docx',
      'jpg',
      'jpeg',
      'png',
      'xlsx',
      'xls',
      'mp4',
      'mp3'
    ],
  };

  /// Upload profile photo for user
  Future<FileUploadResultExtended> uploadProfilePhoto({
    String? userId,
    Function(double)? onProgress,
  }) async {
    try {
      final uid = userId ?? _firestoreService.currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['profile'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final customPath =
          '$_profilePhotosPath/$uid/profile.${fileResult['fileExtension'] ?? 'jpg'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'profile',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'profile',
      );

      // Update user profile with new photo URL
      await _firestoreService.updateUserProfile({
        'photoURL': uploadedFile['fileUrl'] ?? '',
        'profileImageUrl': uploadedFile['fileUrl'] ?? '',
      });

      // Log the action
      await _firestoreService.logAction(
        action: 'profile_photo_uploaded',
        entityType: 'user',
        entityId: uid,
        details: {
          'fileName': uploadedFile['fileName'] ?? '',
          'fileSize': uploadedFile['fileSizeBytes'] ?? 0,
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        message: 'Profile photo uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure(
          'Failed to upload profile photo: $e');
    }
  }

  /// Upload appointment document
  Future<FileUploadResultExtended> uploadAppointmentDocument({
    required String appointmentId,
    required String
        documentType, // 'contract', 'invoice', 'medical_report', etc.
    String? title,
    String? description,
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['appointment'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_appointmentDocumentsPath/$userId/$appointmentId/${documentType}_$timestamp.${fileResult['fileExtension'] ?? 'pdf'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'document',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'appointment',
      );

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': documentType,
          'category': 'appointment',
          'title': title ?? (fileResult['originalName'] ?? 'Document'),
          'description': description ?? '',
          'fileName': uploadedFile['fileName'] ?? '',
          'originalFileName': uploadedFile['originalFileName'] ?? '',
          'fileUrl': uploadedFile['fileUrl'] ?? '',
          'fileExtension': uploadedFile['fileExtension'] ?? '',
          'fileSizeBytes': uploadedFile['fileSizeBytes'] ?? 0,
          'fileSizeMB': uploadedFile['fileSizeMB'] ?? 0,
          'storagePath': uploadedFile['storagePath'] ?? '',
          'relatedEntityType': 'appointment',
          'relatedEntityId': appointmentId,
          'tags': tags ?? [],
          'sector': '', // Will be populated from appointment data
        },
      );

      // Update appointment with document reference
      await _updateAppointmentDocuments(appointmentId, documentId);

      // Log the action
      await _firestoreService.logAction(
        action: 'appointment_document_uploaded',
        entityType: 'appointment',
        entityId: appointmentId,
        details: {
          'documentType': documentType,
          'documentId': documentId,
          'fileName': uploadedFile['fileName'] ?? '',
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Appointment document uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure(
          'Failed to upload appointment document: $e');
    }
  }

  /// Upload customer document
  Future<FileUploadResultExtended> uploadCustomerDocument({
    required String customerId,
    required String
        documentType, // 'id_card', 'contract', 'medical_history', etc.
    String? title,
    String? description,
    List<String>? tags,
    DateTime? expiryDate,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['customer'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_customerDocumentsPath/$userId/$customerId/${documentType}_$timestamp.${fileResult['fileExtension'] ?? 'pdf'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'document',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'customer',
      );

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': documentType,
          'category': 'customer',
          'title': title ?? (fileResult['originalName'] ?? 'Document'),
          'description': description ?? '',
          'fileName': uploadedFile['fileName'] ?? '',
          'originalFileName': uploadedFile['originalFileName'] ?? '',
          'fileUrl': uploadedFile['fileUrl'] ?? '',
          'fileExtension': uploadedFile['fileExtension'] ?? '',
          'fileSizeBytes': uploadedFile['fileSizeBytes'] ?? 0,
          'fileSizeMB': uploadedFile['fileSizeMB'] ?? 0,
          'storagePath': uploadedFile['storagePath'] ?? '',
          'relatedEntityType': 'customer',
          'relatedEntityId': customerId,
          'tags': tags ?? [],
          'expiryDate':
              expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        },
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'customer_document_uploaded',
        entityType: 'customer',
        entityId: customerId,
        details: {
          'documentType': documentType,
          'documentId': documentId,
          'fileName': uploadedFile['fileName'] ?? '',
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Customer document uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure(
          'Failed to upload customer document: $e');
    }
  }

  /// Upload staff document
  Future<FileUploadResultExtended> uploadStaffDocument({
    required String staffId,
    required String documentType, // 'contract', 'certificate', 'id_card', etc.
    String? title,
    String? description,
    List<String>? tags,
    DateTime? expiryDate,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['staff'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_staffDocumentsPath/$userId/$staffId/${documentType}_$timestamp.${fileResult['fileExtension'] ?? 'pdf'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'document',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'staff',
      );

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': documentType,
          'category': 'staff',
          'title': title ?? (fileResult['originalName'] ?? 'Document'),
          'description': description ?? '',
          'fileName': uploadedFile['fileName'] ?? '',
          'originalFileName': uploadedFile['originalFileName'] ?? '',
          'fileUrl': uploadedFile['fileUrl'] ?? '',
          'fileExtension': uploadedFile['fileExtension'] ?? '',
          'fileSizeBytes': uploadedFile['fileSizeBytes'] ?? 0,
          'fileSizeMB': uploadedFile['fileSizeMB'] ?? 0,
          'storagePath': uploadedFile['storagePath'] ?? '',
          'relatedEntityType': 'staff',
          'relatedEntityId': staffId,
          'tags': tags ?? [],
          'expiryDate':
              expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        },
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'staff_document_uploaded',
        entityType: 'staff',
        entityId: staffId,
        details: {
          'documentType': documentType,
          'documentId': documentId,
          'fileName': uploadedFile['fileName'] ?? '',
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Staff document uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure(
          'Failed to upload staff document: $e');
    }
  }

  /// Upload service image/document
  Future<FileUploadResultExtended> uploadServiceDocument({
    required String serviceId,
    required String documentType, // 'image', 'brochure', 'price_list', etc.
    String? title,
    String? description,
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['service'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_serviceDocumentsPath/$userId/$serviceId/${documentType}_$timestamp.${fileResult['fileExtension'] ?? 'pdf'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'document',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'service',
      );

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': documentType,
          'category': 'service',
          'title': title ?? (fileResult['originalName'] ?? 'Document'),
          'description': description ?? '',
          'fileName': uploadedFile['fileName'] ?? '',
          'originalFileName': uploadedFile['originalFileName'] ?? '',
          'fileUrl': uploadedFile['fileUrl'] ?? '',
          'fileExtension': uploadedFile['fileExtension'] ?? '',
          'fileSizeBytes': uploadedFile['fileSizeBytes'] ?? 0,
          'fileSizeMB': uploadedFile['fileSizeMB'] ?? 0,
          'storagePath': uploadedFile['storagePath'] ?? '',
          'relatedEntityType': 'service',
          'relatedEntityId': serviceId,
          'tags': tags ?? [],
        },
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'service_document_uploaded',
        entityType: 'service',
        entityId: serviceId,
        details: {
          'documentType': documentType,
          'documentId': documentId,
          'fileName': uploadedFile['fileName'] ?? '',
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Service document uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure(
          'Failed to upload service document: $e');
    }
  }

  /// Upload general document
  Future<FileUploadResultExtended> uploadGeneralDocument({
    required String documentType,
    String? category,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? expiryDate,
    bool isPublic = false,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final fileResult = await FileUploadService.pickFile(
        allowedExtensions: _moduleFileTypes['general'],
      );

      if (fileResult == null) {
        return FileUploadResultExtended.failure('No file selected');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_generalDocumentsPath/$userId/${category ?? 'general'}/${documentType}_$timestamp.${fileResult['fileExtension'] ?? 'pdf'}';

      final uploadedFile = await FileUploadService.uploadAndSaveDocument(
        fileName: fileResult['fileName'] ?? 'document',
        fileBytes: fileResult['fileBytes'],
        filePath: fileResult['filePath'],
        module: 'general',
      );

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': documentType,
          'category': category ?? 'general',
          'title': title ?? (fileResult['originalName'] ?? 'Document'),
          'description': description ?? '',
          'fileName': uploadedFile['fileName'] ?? '',
          'originalFileName': uploadedFile['originalFileName'] ?? '',
          'fileUrl': uploadedFile['fileUrl'] ?? '',
          'fileExtension': uploadedFile['fileExtension'] ?? '',
          'fileSizeBytes': uploadedFile['fileSizeBytes'] ?? 0,
          'fileSizeMB': uploadedFile['fileSizeMB'] ?? 0,
          'storagePath': uploadedFile['storagePath'] ?? '',
          'relatedEntityType': 'general',
          'relatedEntityId': null,
          'tags': tags ?? [],
          'isPublic': isPublic,
          'expiryDate':
              expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        },
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'general_document_uploaded',
        entityType: 'document',
        entityId: documentId,
        details: {
          'documentType': documentType,
          'category': category,
          'fileName': uploadedFile['fileName'] ?? '',
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Document uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure('Failed to upload document: $e');
    }
  }

  /// Generate report and upload to storage
  Future<FileUploadResultExtended> uploadReport({
    required String reportType,
    required List<int> reportData, // PDF or Excel bytes
    required String fileName,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customPath =
          '$_reportsPath/$userId/$reportType/${timestamp}_$fileName';

      // Upload directly from bytes
      final ref = FirebaseStorage.instance.ref().child(customPath);
      final uploadTask = ref.putData(Uint8List.fromList(reportData));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final uploadedFile = {
        'fileName': fileName,
        'originalFileName': fileName,
        'fileUrl': downloadUrl,
        'fileExtension': fileName.split('.').last.toLowerCase(),
        'fileSizeBytes': reportData.length,
        'fileSizeMB': reportData.length / (1024 * 1024),
        'uploadDate': DateTime.now(),
        'storagePath': customPath,
        'userId': userId,
        'module': 'report',
      };

      // Create document record in Firestore
      final documentId = await _firestoreService.createDocument(
        documentData: {
          'type': reportType,
          'category': 'report',
          'title': fileName,
          'description': description ?? '',
          'fileName': uploadedFile['fileName'],
          'originalFileName': uploadedFile['originalFileName'],
          'fileUrl': uploadedFile['fileUrl'],
          'fileExtension': uploadedFile['fileExtension'],
          'fileSizeBytes': uploadedFile['fileSizeBytes'],
          'fileSizeMB': uploadedFile['fileSizeMB'],
          'storagePath': uploadedFile['storagePath'],
          'relatedEntityType': 'report',
          'relatedEntityId': null,
          'metadata': metadata ?? {},
        },
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'report_uploaded',
        entityType: 'report',
        entityId: documentId,
        details: {
          'reportType': reportType,
          'fileName': fileName,
          'fileSize': uploadedFile['fileSizeMB'],
        },
      );

      return FileUploadResultExtended.success(
        uploadedFile: uploadedFile,
        documentId: documentId,
        message: 'Report uploaded successfully',
      );
    } catch (e) {
      return FileUploadResultExtended.failure('Failed to upload report: $e');
    }
  }

  /// Delete document from both Storage and Firestore
  Future<bool> deleteDocument(String documentId) async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get document data from Firestore
      final documentData = await _firestoreService.getGenericDocument(
        collection: FirestoreService.documentsCollection,
        docId: documentId,
      );

      if (documentData == null) {
        throw Exception('Document not found');
      }

      // Verify ownership
      if (documentData['userId'] != userId) {
        throw Exception('Unauthorized access');
      }

      // Delete from Storage
      final storagePath = documentData['storagePath'] as String? ?? '';
      if (storagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref().child(storagePath).delete();
        } catch (e) {
          // Try deleting by URL if path fails
          final fileUrl = documentData['fileUrl'] as String? ?? '';
          if (fileUrl.isNotEmpty) {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
          }
        }
      }

      // Delete from Firestore
      await _firestoreService.deleteGenericDocument(
        collection: FirestoreService.documentsCollection,
        docId: documentId,
      );

      // Log the action
      await _firestoreService.logAction(
        action: 'document_deleted',
        entityType: 'document',
        entityId: documentId,
        details: {
          'fileName': documentData['fileName'],
          'type': documentData['type'],
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) print('Delete document error: $e');
      return false;
    }
  }

  /// Get documents for an entity
  Future<List<Map<String, dynamic>>> getEntityDocuments({
    required String entityType,
    required String entityId,
    String? documentType,
  }) async {
    return await _firestoreService.getDocuments(
      relatedEntityType: entityType,
      relatedEntityId: entityId,
      type: documentType,
    );
  }

  /// Get all documents by type
  Future<List<Map<String, dynamic>>> getDocumentsByType({
    required String type,
    String? category,
    int limit = 50,
  }) async {
    return await _firestoreService.getDocuments(
      type: type,
      category: category,
      limit: limit,
    );
  }

  /// Update appointment documents list
  Future<void> _updateAppointmentDocuments(
      String appointmentId, String documentId) async {
    try {
      final appointmentData = await _firestoreService.getGenericDocument(
        collection: FirestoreService.appointmentsCollection,
        docId: appointmentId,
      );

      if (appointmentData != null) {
        final currentDocuments =
            List<String>.from(appointmentData['documents'] ?? []);
        if (!currentDocuments.contains(documentId)) {
          currentDocuments.add(documentId);

          await _firestoreService.updateGenericDocument(
            collection: FirestoreService.appointmentsCollection,
            docId: appointmentId,
            data: {'documents': currentDocuments},
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Update appointment documents error: $e');
    }
  }

  /// Get storage usage statistics
  Future<StorageUsageStats> getStorageUsage() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final documents = await _firestoreService.queryDocuments(
        collection: FirestoreService.documentsCollection,
        limit: 1000, // Get more documents for accurate stats
      );

      int totalFiles = documents.length;
      double totalSizeMB = 0;
      Map<String, int> fileTypeCount = {};
      Map<String, double> categorySize = {};

      for (final doc in documents) {
        final sizeMB = (doc['fileSizeMB'] as num?)?.toDouble() ?? 0;
        final type = doc['type'] as String? ?? 'unknown';
        final category = doc['category'] as String? ?? 'unknown';

        totalSizeMB += sizeMB;
        fileTypeCount[type] = (fileTypeCount[type] ?? 0) + 1;
        categorySize[category] = (categorySize[category] ?? 0) + sizeMB;
      }

      return StorageUsageStats(
        totalFiles: totalFiles,
        totalSizeMB: totalSizeMB,
        fileTypeCount: fileTypeCount,
        categorySize: categorySize,
      );
    } catch (e) {
      return StorageUsageStats(
        totalFiles: 0,
        totalSizeMB: 0,
        fileTypeCount: {},
        categorySize: {},
      );
    }
  }
}

/// Extended file upload result with additional metadata
class FileUploadResultExtended {
  final bool success;
  final dynamic uploadedFile; // Changed to dynamic to accept Map data
  final String? documentId;
  final String message;
  final String? error;

  FileUploadResultExtended._({
    required this.success,
    this.uploadedFile,
    this.documentId,
    required this.message,
    this.error,
  });

  factory FileUploadResultExtended.success({
    required dynamic uploadedFile, // Changed to dynamic
    String? documentId,
    required String message,
  }) {
    return FileUploadResultExtended._(
      success: true,
      uploadedFile: uploadedFile,
      documentId: documentId,
      message: message,
    );
  }

  factory FileUploadResultExtended.failure(String error) {
    return FileUploadResultExtended._(
      success: false,
      message: 'Upload failed',
      error: error,
    );
  }
}

/// Storage usage statistics
class StorageUsageStats {
  final int totalFiles;
  final double totalSizeMB;
  final Map<String, int> fileTypeCount;
  final Map<String, double> categorySize;

  StorageUsageStats({
    required this.totalFiles,
    required this.totalSizeMB,
    required this.fileTypeCount,
    required this.categorySize,
  });

  double get totalSizeGB => totalSizeMB / 1024;

  String get formattedTotalSize {
    if (totalSizeMB < 1024) {
      return '${totalSizeMB.toStringAsFixed(1)} MB';
    } else {
      return '${totalSizeGB.toStringAsFixed(2)} GB';
    }
  }
}
