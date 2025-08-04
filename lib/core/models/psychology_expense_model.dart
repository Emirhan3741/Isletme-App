import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class PsychologyExpense extends BaseModel implements StatusModel {
  final String giderTuru; // kira, malzeme, platform_ucreti, reklam, egitim
  final String baslik;
  final String? aciklama;
  final double tutar;
  final DateTime tarih;
  final String? kategori; // sabit, degisken
  final bool tekrarEden; // Aylık kira gibi tekrar eden gider mi?
  final String? tekrarPeriyodu; // aylik, haftalik, yillik
  final String? satici; // Giderin yapıldığı yer/kişi
  final String? fisNo;
  final String? odemeYontemi; // nakit, kart, havale
  @override
  final String status; // paid, pending, cancelled
  final Map<String, dynamic>? ekstraBilgiler;

  const PsychologyExpense({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.giderTuru,
    required this.baslik,
    this.aciklama,
    required this.tutar,
    required this.tarih,
    this.kategori,
    this.tekrarEden = false,
    this.tekrarPeriyodu,
    this.satici,
    this.fisNo,
    this.odemeYontemi,
    this.status = 'paid',
    this.ekstraBilgiler,
  });

  @override
  bool get isActive => status == 'paid';

  String get formatliTutar => '₺${tutar.toStringAsFixed(2)}';

  String get giderTuruAciklama {
    switch (giderTuru) {
      case 'kira':
        return 'Kira';
      case 'malzeme':
        return 'Malzeme';
      case 'platform_ucreti':
        return 'Platform Ücreti';
      case 'reklam':
        return 'Reklam';
      case 'egitim':
        return 'Eğitim';
      case 'uretim':
        return 'Üretim';
      case 'yakit':
        return 'Yakıt';
      default:
        return giderTuru;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'paid':
        return '✅';
      case 'pending':
        return '⏳';
      case 'cancelled':
        return '❌';
      default:
        return '❓';
    }
  }

  String get kategoriAciklama {
    switch (kategori) {
      case 'sabit':
        return 'Sabit Gider';
      case 'degisken':
        return 'Değişken Gider';
      default:
        return kategori ?? 'Belirtilmemiş';
    }
  }

  String get tekrarPeriyoduAciklama {
    if (!tekrarEden) return 'Tek seferlik';
    switch (tekrarPeriyodu) {
      case 'haftalik':
        return 'Haftalık';
      case 'aylik':
        return 'Aylık';
      case 'yillik':
        return 'Yıllık';
      default:
        return tekrarPeriyodu ?? 'Belirsiz';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'giderTuru': giderTuru,
      'baslik': baslik,
      'aciklama': aciklama,
      'tutar': tutar,
      'tarih': Timestamp.fromDate(tarih),
      'kategori': kategori,
      'tekrarEden': tekrarEden,
      'tekrarPeriyodu': tekrarPeriyodu,
      'satici': satici,
      'fisNo': fisNo,
      'odemeYontemi': odemeYontemi,
      'status': status,
      'ekstraBilgiler': ekstraBilgiler,
    });
    return map;
  }

  static PsychologyExpense fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return PsychologyExpense(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      giderTuru: map['giderTuru'] as String? ?? '',
      baslik: map['baslik'] as String? ?? '',
      aciklama: map['aciklama'] as String?,
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      tarih: (map['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      kategori: map['kategori'] as String?,
      tekrarEden: map['tekrarEden'] as bool? ?? false,
      tekrarPeriyodu: map['tekrarPeriyodu'] as String?,
      satici: map['satici'] as String?,
      fisNo: map['fisNo'] as String?,
      odemeYontemi: map['odemeYontemi'] as String?,
      status: map['status'] as String? ?? 'paid',
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  @override
  bool get isValid =>
      super.isValid && giderTuru.isNotEmpty && baslik.isNotEmpty && tutar > 0;

  @override
  String toString() =>
      'PsychologyExpense(id: $id, baslik: $baslik, tutar: $formatliTutar)';
}
