import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class PsychologyPayment extends BaseModel implements StatusModel {
  final String danisanId;
  final String? seansId;
  final String? hizmetId;
  final String odemeTuru; // seans_ucreti, test_ucreti, danismanlik_ucreti
  final double tutar;
  final DateTime odemeTarihi;
  final String odemeTipi; // nakit, kart, havale, online
  @override
  final String status; // paid, pending, overdue, cancelled
  final String? aciklama;
  final String? makbuzNo;
  final String? odeyenKisi;
  final DateTime? vadeTarihi;
  final Map<String, dynamic>? ekstraBilgiler;

  const PsychologyPayment({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.danisanId,
    this.seansId,
    this.hizmetId,
    required this.odemeTuru,
    required this.tutar,
    required this.odemeTarihi,
    required this.odemeTipi,
    this.status = 'paid',
    this.aciklama,
    this.makbuzNo,
    this.odeyenKisi,
    this.vadeTarihi,
    this.ekstraBilgiler,
  });

  @override
  bool get isActive => status == 'paid';

  String get formatliTutar => '₺${tutar.toStringAsFixed(2)}';

  String get odemeTuruAciklama {
    switch (odemeTuru) {
      case 'seans_ucreti':
        return 'Seans Ücreti';
      case 'test_ucreti':
        return 'Test Ücreti';
      case 'danismanlik_ucreti':
        return 'Danışmanlık Ücreti';
      default:
        return odemeTuru;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'paid':
        return '✅';
      case 'pending':
        return '⏳';
      case 'overdue':
        return '❌';
      case 'cancelled':
        return '🚫';
      default:
        return '❓';
    }
  }

  bool get vadesiGecti {
    if (vadeTarihi == null || status == 'paid') return false;
    return DateTime.now().isAfter(vadeTarihi!);
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'danisanId': danisanId,
      'seansId': seansId,
      'hizmetId': hizmetId,
      'odemeTuru': odemeTuru,
      'tutar': tutar,
      'odemeTarihi': Timestamp.fromDate(odemeTarihi),
      'odemeTipi': odemeTipi,
      'status': status,
      'aciklama': aciklama,
      'makbuzNo': makbuzNo,
      'odeyenKisi': odeyenKisi,
      'vadeTarihi': vadeTarihi != null ? Timestamp.fromDate(vadeTarihi!) : null,
      'ekstraBilgiler': ekstraBilgiler,
    });
    return map;
  }

  static PsychologyPayment fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return PsychologyPayment(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      danisanId: map['danisanId'] as String? ?? '',
      seansId: map['seansId'] as String?,
      hizmetId: map['hizmetId'] as String?,
      odemeTuru: map['odemeTuru'] as String? ?? '',
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      odemeTarihi:
          (map['odemeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      odemeTipi: map['odemeTipi'] as String? ?? '',
      status: map['status'] as String? ?? 'paid',
      aciklama: map['aciklama'] as String?,
      makbuzNo: map['makbuzNo'] as String?,
      odeyenKisi: map['odeyenKisi'] as String?,
      vadeTarihi: (map['vadeTarihi'] as Timestamp?)?.toDate(),
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      danisanId.isNotEmpty &&
      odemeTuru.isNotEmpty &&
      tutar > 0 &&
      odemeTipi.isNotEmpty;

  @override
  String toString() =>
      'PsychologyPayment(id: $id, danisan: $danisanId, tutar: $formatliTutar)';
}
