import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class CaseModel extends BaseModel {
  final String clientId;
  final String davaAdi;
  final String davaKodu;
  final String davaTuru;
  final String mahkemeAdi;
  final String esasNo;
  final String karanNo;
  final DateTime? davaBaslangicTarihi;
  final DateTime? davaBitisTarihi;
  final String davaDurumu;
  final String? davacilar;
  final String? davalilar;
  final String? davaKonusu;
  final String? davaciVekili;
  final String? davaliVekili;
  final String? hakim;
  final String? savci;
  final String? davaSerhi;
  final String? sonuc;
  final String? notlar;
  final double? davaUcreti;
  final double? odenecekHarc;
  final double? odenenHarc;
  final double? vekaleUcreti;
  final double? odenenVekaleUcreti;
  final bool isActive;
  final List<String> belgeler;
  final List<String> etiketler;

  const CaseModel({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? updatedAt,
    required this.clientId,
    required this.davaAdi,
    required this.davaKodu,
    required this.davaTuru,
    required this.mahkemeAdi,
    this.esasNo = '',
    this.karanNo = '',
    this.davaBaslangicTarihi,
    this.davaBitisTarihi,
    this.davaDurumu = 'hazirlik',
    this.davacilar,
    this.davalilar,
    this.davaKonusu,
    this.davaciVekili,
    this.davaliVekili,
    this.hakim,
    this.savci,
    this.davaSerhi,
    this.sonuc,
    this.notlar,
    this.davaUcreti,
    this.odenecekHarc,
    this.odenenHarc,
    this.vekaleUcreti,
    this.odenenVekaleUcreti,
    this.isActive = true,
    this.belgeler = const [],
    this.etiketler = const [],
  }) : super(
          id: id,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // Dava durumu kontrolleri
  bool get hazirlik => davaDurumu == 'hazirlik';
  bool get devamEdiyor => davaDurumu == 'devam_ediyor';
  bool get tamamlandi => davaDurumu == 'tamamlandi';
  bool get temyiz => davaDurumu == 'temyiz';
  bool get icra => davaDurumu == 'icra';
  bool get iptal => davaDurumu == 'iptal';

  // Süre hesaplamaları
  int? get davaGunu {
    if (davaBaslangicTarihi == null) return null;
    final now = DateTime.now();
    return now.difference(davaBaslangicTarihi!).inDays;
  }

  // Mali durum kontrolleri
  bool get vekaleUcretiTamamOdendi {
    if (vekaleUcreti == null || odenenVekaleUcreti == null) return false;
    return odenenVekaleUcreti! >= vekaleUcreti!;
  }

  bool get harcTamamOdendi {
    if (odenecekHarc == null || odenenHarc == null) return false;
    return odenenHarc! >= odenecekHarc!;
  }

  double get kalanVekaleUcreti {
    if (vekaleUcreti == null) return 0.0;
    return vekaleUcreti! - (odenenVekaleUcreti ?? 0.0);
  }

  double get kalanHarc {
    if (odenecekHarc == null) return 0.0;
    return odenecekHarc! - (odenenHarc ?? 0.0);
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'clientId': clientId,
      'davaAdi': davaAdi,
      'davaKodu': davaKodu,
      'davaTuru': davaTuru,
      'mahkemeAdi': mahkemeAdi,
      'esasNo': esasNo,
      'karanNo': karanNo,
      'davaBaslangicTarihi': davaBaslangicTarihi != null
          ? Timestamp.fromDate(davaBaslangicTarihi!)
          : null,
      'davaBitisTarihi':
          davaBitisTarihi != null ? Timestamp.fromDate(davaBitisTarihi!) : null,
      'davaDurumu': davaDurumu,
      'davacilar': davacilar,
      'davalilar': davalilar,
      'davaKonusu': davaKonusu,
      'davaciVekili': davaciVekili,
      'davaliVekili': davaliVekili,
      'hakim': hakim,
      'savci': savci,
      'davaSerhi': davaSerhi,
      'sonuc': sonuc,
      'notlar': notlar,
      'davaUcreti': davaUcreti,
      'odenecekHarc': odenecekHarc,
      'odenenHarc': odenenHarc,
      'vekaleUcreti': vekaleUcreti,
      'odenenVekaleUcreti': odenenVekaleUcreti,
      'isActive': isActive,
      'belgeler': belgeler,
      'etiketler': etiketler,
    });
    return map;
  }

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);

    return CaseModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      clientId: map['clientId'] as String? ?? '',
      davaAdi: map['davaAdi'] as String? ?? '',
      davaKodu: map['davaKodu'] as String? ?? '',
      davaTuru: map['davaTuru'] as String? ?? '',
      mahkemeAdi: map['mahkemeAdi'] as String? ?? '',
      esasNo: map['esasNo'] as String? ?? '',
      karanNo: map['karanNo'] as String? ?? '',
      davaBaslangicTarihi: (map['davaBaslangicTarihi'] as Timestamp?)?.toDate(),
      davaBitisTarihi: (map['davaBitisTarihi'] as Timestamp?)?.toDate(),
      davaDurumu: map['davaDurumu'] as String? ?? 'hazirlik',
      davacilar: map['davacilar'] as String?,
      davalilar: map['davalilar'] as String?,
      davaKonusu: map['davaKonusu'] as String?,
      davaciVekili: map['davaciVekili'] as String?,
      davaliVekili: map['davaliVekili'] as String?,
      hakim: map['hakim'] as String?,
      savci: map['savci'] as String?,
      davaSerhi: map['davaSerhi'] as String?,
      sonuc: map['sonuc'] as String?,
      notlar: map['notlar'] as String?,
      davaUcreti: (map['davaUcreti'] as num?)?.toDouble(),
      odenecekHarc: (map['odenecekHarc'] as num?)?.toDouble(),
      odenenHarc: (map['odenenHarc'] as num?)?.toDouble(),
      vekaleUcreti: (map['vekaleUcreti'] as num?)?.toDouble(),
      odenenVekaleUcreti: (map['odenenVekaleUcreti'] as num?)?.toDouble(),
      isActive: map['isActive'] as bool? ?? true,
      belgeler: List<String>.from(map['belgeler'] ?? []),
      etiketler: List<String>.from(map['etiketler'] ?? []),
    );
  }

  factory CaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return CaseModel.fromMap(data);
  }

  // İngilizce compatibility getter'lar için UI'da kullanım
  String get title => davaAdi;
  String get status => davaDurumu;
  String get caseType => davaTuru;
  String get courtName => mahkemeAdi;
  String get description => davaKonusu ?? '';

  CaseModel copyWith({
    String? clientId,
    String? davaAdi,
    String? davaKodu,
    String? davaTuru,
    String? mahkemeAdi,
    String? esasNo,
    String? karanNo,
    DateTime? davaBaslangicTarihi,
    DateTime? davaBitisTarihi,
    String? davaDurumu,
    String? davacilar,
    String? davalilar,
    String? davaKonusu,
    String? davaciVekili,
    String? davaliVekili,
    String? hakim,
    String? savci,
    String? davaSerhi,
    String? sonuc,
    String? notlar,
    double? davaUcreti,
    double? odenecekHarc,
    double? odenenHarc,
    double? vekaleUcreti,
    double? odenenVekaleUcreti,
    bool? isActive,
    List<String>? belgeler,
    List<String>? etiketler,
    DateTime? updatedAt,
  }) {
    return CaseModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      clientId: clientId ?? this.clientId,
      davaAdi: davaAdi ?? this.davaAdi,
      davaKodu: davaKodu ?? this.davaKodu,
      davaTuru: davaTuru ?? this.davaTuru,
      mahkemeAdi: mahkemeAdi ?? this.mahkemeAdi,
      esasNo: esasNo ?? this.esasNo,
      karanNo: karanNo ?? this.karanNo,
      davaBaslangicTarihi: davaBaslangicTarihi ?? this.davaBaslangicTarihi,
      davaBitisTarihi: davaBitisTarihi ?? this.davaBitisTarihi,
      davaDurumu: davaDurumu ?? this.davaDurumu,
      davacilar: davacilar ?? this.davacilar,
      davalilar: davalilar ?? this.davalilar,
      davaKonusu: davaKonusu ?? this.davaKonusu,
      davaciVekili: davaciVekili ?? this.davaciVekili,
      davaliVekili: davaliVekili ?? this.davaliVekili,
      hakim: hakim ?? this.hakim,
      savci: savci ?? this.savci,
      davaSerhi: davaSerhi ?? this.davaSerhi,
      sonuc: sonuc ?? this.sonuc,
      notlar: notlar ?? this.notlar,
      davaUcreti: davaUcreti ?? this.davaUcreti,
      odenecekHarc: odenecekHarc ?? this.odenecekHarc,
      odenenHarc: odenenHarc ?? this.odenenHarc,
      vekaleUcreti: vekaleUcreti ?? this.vekaleUcreti,
      odenenVekaleUcreti: odenenVekaleUcreti ?? this.odenenVekaleUcreti,
      isActive: isActive ?? this.isActive,
      belgeler: belgeler ?? this.belgeler,
      etiketler: etiketler ?? this.etiketler,
    );
  }

  @override
  String toString() =>
      'CaseModel(id: $id, davaAdi: $davaAdi, davaDurumu: $davaDurumu)';
}

// Dava türü sabitleri
class DavaTuruConstants {
  static const String hukuk = 'hukuk';
  static const String ceza = 'ceza';
  static const String icra = 'icra';
  static const String aile = 'aile';
  static const String ticaret = 'ticaret';
  static const String isHukuku = 'is_hukuku';
  static const String idare = 'idare';
  static const String vergi = 'vergi';
  static const String sgk = 'sgk';
  static const String gayrimenkul = 'gayrimenkul';

  static const List<String> tumTurler = [
    hukuk,
    ceza,
    icra,
    aile,
    ticaret,
    isHukuku,
    idare,
    vergi,
    sgk,
    gayrimenkul,
  ];

  static String getTurDisplayName(String tur) {
    switch (tur) {
      case hukuk:
        return 'Hukuk';
      case ceza:
        return 'Ceza';
      case icra:
        return 'İcra';
      case aile:
        return 'Aile';
      case ticaret:
        return 'Ticaret';
      case isHukuku:
        return 'İş';
      case idare:
        return 'İdare';
      case vergi:
        return 'Vergi';
      case sgk:
        return 'SGK';
      case gayrimenkul:
        return 'Gayrimenkul';
      default:
        return tur;
    }
  }
}

// Dava durumu sabitleri
class DavaDurumuConstants {
  static const String hazirlik = 'hazirlik';
  static const String devamEdiyor = 'devam_ediyor';
  static const String tamamlandi = 'tamamlandi';
  static const String temyiz = 'temyiz';
  static const String icra = 'icra';
  static const String iptal = 'iptal';

  static const List<String> tumDurumlar = [
    hazirlik,
    devamEdiyor,
    tamamlandi,
    temyiz,
    icra,
    iptal,
  ];

  static String getDurumDisplayName(String durum) {
    switch (durum) {
      case hazirlik:
        return 'Hazırlık';
      case devamEdiyor:
        return 'Devam Ediyor';
      case tamamlandi:
        return 'Tamamlandı';
      case temyiz:
        return 'Temyiz';
      case icra:
        return 'İcra';
      case iptal:
        return 'İptal';
      default:
        return durum;
    }
  }
}
