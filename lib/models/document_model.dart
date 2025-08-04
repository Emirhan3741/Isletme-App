import 'package:cloud_firestore/cloud_firestore.dart';

/// Belge modeli - Firestore'da saklanan belge bilgileri
class DocumentModel {
  final String? id;
  final String userId;
  final String panel;
  final String customerId; // Müşteri ID'si (zorunlu)
  final String documentType;
  final String filePath;
  final DateTime uploadedAt;
  final String status;
  final String description;
  final String? approvedBy;
  final String? adminComment; // Admin sadece yorum ekleyebilir
  final String? panelContextId; // Bağlantılı işlem/randevu ID'si (opsiyonel)

  DocumentModel({
    this.id,
    required this.userId,
    required this.panel,
    required this.customerId,
    required this.documentType,
    required this.filePath,
    required this.uploadedAt,
    this.status = 'waiting',
    this.description = '',
    this.approvedBy,
    this.adminComment,
    this.panelContextId,
  });

  /// Firestore'dan veri oluştururken kullanılır
  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return DocumentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      panel: data['panel'] ?? '',
      customerId: data['customerId'] ?? '',
      documentType: data['documentType'] ?? '',
      filePath: data['filePath'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'waiting',
      description: data['description'] ?? '',
      approvedBy: data['approvedBy'],
      adminComment: data['adminComment'],
      panelContextId: data['panelContextId'],
    );
  }

  /// Firestore'a kaydetmek için map'e çevirir
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'panel': panel,
      'customerId': customerId,
      'documentType': documentType,
      'filePath': filePath,
      'uploadedAt': uploadedAt,
      'status': status,
      'description': description,
      'approvedBy': approvedBy,
      'adminComment': adminComment,
      'panelContextId': panelContextId,
    };
  }

  /// Kopya oluşturur (güncellemeler için)
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? panel,
    String? customerId,
    String? documentType,
    String? filePath,
    DateTime? uploadedAt,
    String? status,
    String? description,
    String? approvedBy,
    String? adminComment,
    String? panelContextId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      panel: panel ?? this.panel,
      customerId: customerId ?? this.customerId,
      documentType: documentType ?? this.documentType,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      description: description ?? this.description,
      approvedBy: approvedBy ?? this.approvedBy,
      adminComment: adminComment ?? this.adminComment,
      panelContextId: panelContextId ?? this.panelContextId,
    );
  }
}

/// Panel türleri enum'u
enum PanelType {
  lawyer('lawyer', 'Avukat'),
  beauty('beauty', 'Güzellik'),
  veterinary('veterinary', 'Veteriner'),
  education('education', 'Eğitim'),
  sports('sports', 'Spor'),
  consulting('consulting', 'Danışmanlık'),
  realEstate('real_estate', 'Emlak');

  const PanelType(this.code, this.displayName);
  final String code;
  final String displayName;
}

/// Belge durumları enum'u
enum DocumentStatus {
  waiting('waiting', 'Onay Bekliyor'),
  approved('approved', 'Onaylandı'),
  rejected('rejected', 'Reddedildi'),
  underReview('under_review', 'İnceleniyor');

  const DocumentStatus(this.code, this.displayName);
  final String code;
  final String displayName;
}