import 'dart:io';
import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../services/document_service.dart';

/// Belge yönetimi için Provider sınıfı
class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  // Getters
  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Hata mesajını temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Yükleme ilerlemesini sıfırla
  void resetProgress() {
    _uploadProgress = 0.0;
    notifyListeners();
  }

  /// Belge yükle
  Future<DocumentModel?> uploadDocument({
    required File file,
    required String panel,
    required String customerId,
    required String documentType,
    String? description,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _uploadProgress = 0.0;
      notifyListeners();

      final document = await _documentService.uploadDocument(
        file: file,
        panel: panel,
        customerId: customerId,
        documentType: documentType,
        description: description,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (document != null) {
        _documents.insert(0, document);
      }

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      return document;
    } catch (e) {
      _error = 'Belge yükleme hatası: ${e.toString()}';
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  /// Kullanıcının belgelerini yükle
  Future<void> loadDocuments({
    String? panel,
    String? customerId,
    String? documentType,
    String? status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _documents = await _documentService.getUserDocuments(
        panel: panel,
        customerId: customerId,
        documentType: documentType,
        status: status,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Belgeler yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Belgeyi sil
  Future<bool> deleteDocument(String documentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _documentService.deleteDocument(documentId);
      
      _documents.removeWhere((doc) => doc.id == documentId);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Belge silinemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Panel'e özel belge türlerini getir
  List<String> getDocumentTypesForPanel(String panel) {
    return _documentService.getDocumentTypesForPanel(panel);
  }

  /// Belge istatistiklerini getir
  Future<Map<String, int>> getDocumentStats(String? panel) async {
    try {
      return await _documentService.getDocumentStats(panel);
    } catch (e) {
      _error = 'İstatistikler yüklenemedi: ${e.toString()}';
      notifyListeners();
      return {};
    }
  }

  /// Panel değiştiğinde belgeleri yenile
  Future<void> refreshDocumentsForPanel(String panel) async {
    await loadDocuments(panel: panel);
  }

  /// Belge durumuna göre filtrele
  List<DocumentModel> getDocumentsByStatus(String status) {
    return _documents.where((doc) => doc.status == status).toList();
  }

  /// Belge türüne göre filtrele
  List<DocumentModel> getDocumentsByType(String documentType) {
    return _documents.where((doc) => doc.documentType == documentType).toList();
  }

  /// Panel'e göre filtrele
  List<DocumentModel> getDocumentsByPanel(String panel) {
    return _documents.where((doc) => doc.panel == panel).toList();
  }
}