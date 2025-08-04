import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/document_model.dart';

/// Belge yükleme ve yönetim servisi
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Ana belge yükleme fonksiyonu
  /// File'ı Storage'a yükler ve Firestore'a index kaydeder
  Future<DocumentModel?> uploadDocument({
    required File file,
    required String panel,
    required String customerId,
    required String documentType,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Dosya adı ve yol oluştur
      final fileName = _generateFileName(file, documentType);
      final filePath = 'client_documents/${user.uid}/$fileName';

      // Storage'a yükle
      final storageRef = _storage.ref().child(filePath);
      final uploadTask = storageRef.putFile(file);

      // Progress takibi
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Upload tamamlanmasını bekle
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'a kaydet
      final document = await saveDocumentToFirestore(
        panel: panel,
        customerId: customerId,
        documentType: documentType,
        filePath: filePath,
        downloadUrl: downloadUrl,
        description: description,
      );

      return document;
    } catch (e) {
      debugPrint('Belge yükleme hatası: $e');
      rethrow;
    }
  }

  /// Firestore'a belge index'i kaydetme fonksiyonu
  Future<DocumentModel> saveDocumentToFirestore({
    required String panel,
    required String customerId,
    required String documentType,
    required String filePath,
    required String downloadUrl,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      if (kDebugMode) debugPrint('🔄 Belge Firestore\'a kaydediliyor...');
      
      // Null kontrolleri
      if (panel.trim().isEmpty) {
        throw Exception('Panel bilgisi boş olamaz');
      }
      if (documentType.trim().isEmpty) {
        throw Exception('Belge türü boş olamaz');
      }
      if (downloadUrl.trim().isEmpty) {
        throw Exception('Download URL boş olamaz');
      }

      final documentData = DocumentModel(
        userId: user.uid,
        panel: panel,
        customerId: customerId,
        documentType: documentType,
        filePath: filePath,
        uploadedAt: DateTime.now(),
        status: 'waiting',
        description: description ?? '',
      );

      // Firestore'a kaydet
      final docRef = await _firestore
          .collection('documents')
          .add(documentData.toFirestore());

      final savedDocument = documentData.copyWith(id: docRef.id);
      
      if (kDebugMode) debugPrint('✅ Belge başarıyla kaydedildi: ${docRef.id}');
      return savedDocument;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase belge kaydetme hatası: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'failed-precondition':
          if (e.message?.contains('index') == true) {
            final indexUrl = _extractIndexUrl(e.message ?? '');
            debugPrint('🔍 Index gerekli - URL: $indexUrl');
            throw Exception('Veritabanı index\'i eksik.\n\n📋 ÇÖZÜM:\n1. FIRESTORE_INDEX_URLS.md dosyasını açın\n2. Documents Collection bölümündeki URL\'leri açın\n3. "Create Index" butonlarına tıklayın\n4. 2-3 dakika bekleyin');
          }
          throw Exception('Veritabanı koşulları sağlanmamış: ${e.message}');
        case 'permission-denied':
          throw Exception('Bu işlem için yetkiniz yok. Giriş yapınız.');
        case 'unavailable':
          throw Exception('Veritabanı servis kullanılamıyor. İnternet bağlantınızı kontrol edin.');
        default:
          throw Exception('Belge kaydedilemedi: ${e.message ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen belge kaydetme hatası: $e');
      throw Exception('Belge kaydedilemedi: $e');
    }
  }
  
  String _extractIndexUrl(String errorMessage) {
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0) ?? 'FIRESTORE_INDEX_URLS.md dosyasına bakın';
  }

  /// Kullanıcının belgelerini getir
  Future<List<DocumentModel>> getUserDocuments({
    String? panel,
    String? customerId,
    String? documentType,
    String? status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    Query query = _firestore
        .collection('documents')
        .where('userId', isEqualTo: user.uid)
        .orderBy('uploadedAt', descending: true);

    // Filtreler
    if (panel != null && panel.isNotEmpty) {
      query = query.where('panel', isEqualTo: panel);
    }
    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (documentType != null && documentType.isNotEmpty) {
      query = query.where('documentType', isEqualTo: documentType);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => DocumentModel.fromFirestore(doc))
        .toList();
  }

  /// Admin yorum ekleme (Admin sadece yorum ekleyebilir, silemez)
  Future<void> addAdminComment({
    required String documentId,
    required String comment,
    String? status,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Admin giriş yapmamış');
    }

    final updateData = <String, dynamic>{
      'adminComment': comment,
      'approvedBy': currentUser.uid,
      'updatedAt': DateTime.now(),
    };

    if (status != null) {
      updateData['status'] = status;
    }

    await _firestore.collection('documents').doc(documentId).update(updateData);
  }

  /// Belgeyi sil (Sadece dosyayı yükleyen kullanıcı silebilir)
  Future<void> deleteDocument(String documentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Önce belge bilgisini al ve yetki kontrol et
      final doc = await _firestore
          .collection('documents')
          .doc(documentId)
          .get();

      if (doc.exists) {
        final documentModel = DocumentModel.fromFirestore(doc);
        
        // Sadece dosyayı yükleyen kullanıcı silebilir
        if (documentModel.userId != user.uid) {
          throw Exception('Bu belgeyi silme yetkiniz yok. Sadece kendi belgelerinizi silebilirsiniz.');
        }
        
        // Storage'dan dosyayı sil
        await _storage.ref().child(documentModel.filePath).delete();
        
        // Firestore'dan kaydı sil
        await _firestore.collection('documents').doc(documentId).delete();
      } else {
        throw Exception('Belge bulunamadı');
      }
    } catch (e) {
      debugPrint('Belge silme hatası: $e');
      rethrow;
    }
  }

  /// Panel'e özel belge türlerini getir
  List<String> getDocumentTypesForPanel(String panel) {
    switch (panel) {
      case 'lawyer':
        return [
          'kimlik',
          'ikametgah',
          'dava_evrakı',
          'sözleşme',
          'mahkeme_kararı',
          'vekaletname'
        ];
      case 'beauty':
        return [
          'kimlik',
          'sağlık_raporu',
          'öncesi_fotoğraf',
          'sonrası_fotoğraf',
          'onay_formu'
        ];
      case 'veterinary':
        return [
          'kimlik',
          'hayvan_kimlik',
          'aşı_kartı',
          'reçete',
          'kan_tahlili',
          'röntgen',
          'muayene_raporu'
        ];
      case 'education':
        return [
          'kimlik',
          'diploma',
          'sertifika',
          'cv',
          'referans_mektubu',
          'transkript'
        ];
      case 'sports':
        return [
          'kimlik',
          'sağlık_raporu',
          'spor_lisansı',
          'antrenman_programı',
          'beslenme_planı'
        ];
      case 'consulting':
        return [
          'kimlik',
          'şirket_evrakı',
          'mali_tablo',
          'sözleşme',
          'proje_dosyası'
        ];
      case 'real_estate':
        return [
          'kimlik',
          'tapu',
          'yapı_ruhsatı',
          'iskan_ruhsatı',
          'emlak_ekspertiz',
          'mülk_fotoğrafları'
        ];
      default:
        return ['kimlik', 'diğer'];
    }
  }

  /// Benzersiz dosya adı oluştur
  String _generateFileName(File file, String documentType) {
    final extension = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${documentType}.$extension';
  }

  /// Belge istatistiklerini getir
  Future<Map<String, int>> getDocumentStats(String? panel) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    Query query = _firestore
        .collection('documents')
        .where('userId', isEqualTo: user.uid);

    if (panel != null && panel.isNotEmpty) {
      query = query.where('panel', isEqualTo: panel);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs
        .map((doc) => DocumentModel.fromFirestore(doc))
        .toList();

    return {
      'toplam': docs.length,
      'onay_bekleyen': docs.where((d) => d.status == 'waiting').length,
      'onaylanan': docs.where((d) => d.status == 'approved').length,
      'reddedilen': docs.where((d) => d.status == 'rejected').length,
    };
  }
}