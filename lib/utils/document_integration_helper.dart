import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../models/document_model.dart';
import '../widgets/document_upload_widget.dart';

/// Her panel için belge entegrasyonunu kolaylaştıran yardımcı sınıf
class DocumentIntegrationHelper {
  
  /// Herhangi bir sayfaya belge yükleme özelliği eklemek için kullanılır
  static Widget buildDocumentSection({
    required BuildContext context,
    required String panel,
    String? panelContextId,
    List<String>? allowedTypes,
    Function(DocumentModel)? onDocumentUploaded,
    bool showUploadOnly = false,
  }) {
    if (showUploadOnly) {
      return DocumentUploadWidget(
        customerId: '',
        panel: panel,
        allowedTypes: allowedTypes,
        onDocumentUploaded: onDocumentUploaded,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.cloud_upload), text: 'Yükle'),
              Tab(icon: Icon(Icons.list), text: 'Belgeler'),
            ],
          ),
          Container(
            height: 400,
            child: TabBarView(
              children: [
                                DocumentUploadWidget(
                  customerId: '',
                  panel: panel,
                  allowedTypes: allowedTypes,
                  onDocumentUploaded: onDocumentUploaded,
                ),
                // Buraya DocumentListWidget eklenebilir
                Center(child: Text('Belge listesi')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hızlı belge yükleme fonksiyonu - herhangi bir yerden çağrılabilir
  static Future<DocumentModel?> quickUpload({
    required BuildContext context,
    required String panel,
    required File file,
    required String documentType,
    String? description,
    String? panelContextId,
    String? customerId,
  }) async {
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    
    return await documentProvider.uploadDocument(
      customerId: customerId ?? '',
      file: file,
      panel: panel,
      documentType: documentType,
      description: description,

    );
  }

  /// Veteriner paneli için özel entegrasyon
  static Widget buildVeterinaryDocumentSection(
    BuildContext context, {
    String? animalId,
    String? appointmentId,
  }) {
    return buildDocumentSection(
      context: context,
      panel: 'veterinary',
      panelContextId: animalId ?? appointmentId,
      allowedTypes: [
        'kimlik',
        'hayvan_kimlik',
        'aşı_kartı',
        'reçete',
        'kan_tahlili',
        'röntgen',
        'muayene_raporu',
      ],
    );
  }

  /// Eğitim paneli için özel entegrasyon
  static Widget buildEducationDocumentSection(
    BuildContext context, {
    String? courseId,
    String? studentId,
  }) {
    return buildDocumentSection(
      context: context,
      panel: 'education',
      panelContextId: courseId ?? studentId,
      allowedTypes: [
        'kimlik',
        'diploma',
        'sertifika',
        'cv',
        'referans_mektubu',
        'transkript',
      ],
    );
  }

  /// Spor paneli için özel entegrasyon
  static Widget buildSportsDocumentSection(
    BuildContext context, {
    String? memberId,
    String? programId,
  }) {
    return buildDocumentSection(
      context: context,
      panel: 'sports',
      panelContextId: memberId ?? programId,
      allowedTypes: [
        'kimlik',
        'sağlık_raporu',
        'spor_lisansı',
        'antrenman_programı',
        'beslenme_planı',
      ],
    );
  }

  /// Danışmanlık paneli için özel entegrasyon
  static Widget buildConsultingDocumentSection(
    BuildContext context, {
    String? projectId,
    String? clientId,
  }) {
    return buildDocumentSection(
      context: context,
      panel: 'consulting',
      panelContextId: projectId ?? clientId,
      allowedTypes: [
        'kimlik',
        'şirket_evrakı',
        'mali_tablo',
        'sözleşme',
        'proje_dosyası',
      ],
    );
  }

  /// Emlak paneli için özel entegrasyon
  static Widget buildRealEstateDocumentSection(
    BuildContext context, {
    String? propertyId,
    String? saleId,
  }) {
    return buildDocumentSection(
      context: context,
      panel: 'real_estate',
      panelContextId: propertyId ?? saleId,
      allowedTypes: [
        'kimlik',
        'tapu',
        'yapı_ruhsatı',
        'iskan_ruhsatı',
        'emlak_ekspertiz',
        'mülk_fotoğrafları',
      ],
    );
  }

  /// Belge yükleme dialog'u göster
  static Future<DocumentModel?> showUploadDialog({
    required BuildContext context,
    required String panel,
    String? panelContextId,
    List<String>? allowedTypes,
  }) async {
    DocumentModel? uploadedDocument;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: DocumentUploadWidget(
            customerId: '',
            panel: panel,
            allowedTypes: allowedTypes,
            onDocumentUploaded: (document) {
              uploadedDocument = document;
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );

    return uploadedDocument;
  }

  /// Panel için belge türlerini getir
  static List<String> getDocumentTypesForPanel(String panel) {
    switch (panel) {
      case 'lawyer':
        return ['kimlik', 'ikametgah', 'dava_evrakı', 'sözleşme', 'mahkeme_kararı', 'vekaletname'];
      case 'beauty':
        return ['kimlik', 'sağlık_raporu', 'öncesi_fotoğraf', 'sonrası_fotoğraf', 'onay_formu'];
      case 'veterinary':
        return ['kimlik', 'hayvan_kimlik', 'aşı_kartı', 'reçete', 'kan_tahlili', 'röntgen', 'muayene_raporu'];
      case 'education':
        return ['kimlik', 'diploma', 'sertifika', 'cv', 'referans_mektubu', 'transkript'];
      case 'sports':
        return ['kimlik', 'sağlık_raporu', 'spor_lisansı', 'antrenman_programı', 'beslenme_planı'];
      case 'consulting':
        return ['kimlik', 'şirket_evrakı', 'mali_tablo', 'sözleşme', 'proje_dosyası'];
      case 'real_estate':
        return ['kimlik', 'tapu', 'yapı_ruhsatı', 'iskan_ruhsatı', 'emlak_ekspertiz', 'mülk_fotoğrafları'];
      default:
        return ['kimlik', 'diğer'];
    }
  }

  /// Belge türü ismini formatla
  static String formatDocumentType(String type) {
    return type.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Panel ismini formatla
  static String formatPanelName(String panel) {
    switch (panel) {
      case 'lawyer':
        return 'Avukat';
      case 'beauty':
        return 'Güzellik';
      case 'veterinary':
        return 'Veteriner';
      case 'education':
        return 'Eğitim';
      case 'sports':
        return 'Spor';
      case 'consulting':
        return 'Danışmanlık';
      case 'real_estate':
        return 'Emlak';
      default:
        return panel;
    }
  }
}