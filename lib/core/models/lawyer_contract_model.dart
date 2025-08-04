import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

// Sözleşme Türleri
enum LawyerContractType {
  vekalet('vekalet', 'Vekalet Sözleşmesi'),
  danismanlik('danismanlik', 'Danışmanlık Sözleşmesi'),
  arabuluculuk('arabuluculuk', 'Arabuluculuk Sözleşmesi'),
  tahsilat('tahsilat', 'Tahsilat Sözleşmesi'),
  davaTakip('davaTakip', 'Dava Takip Sözleşmesi'),
  hukukiInceleme('hukukiInceleme', 'Hukuki İnceleme Sözleşmesi'),
  sozlesmeHazirlama('sozlesmeHazirlama', 'Sözleşme Hazırlama'),
  mirasTakibi('mirasTakibi', 'Miras Takibi'),
  icraTakibi('icraTakibi', 'İcra Takibi'),
  diger('diger', 'Diğer');

  const LawyerContractType(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Sözleşme Durumları
enum LawyerContractStatus {
  taslak('taslak', 'Taslak'),
  hazir('hazir', 'Hazır'),
  gonderildi('gonderildi', 'Gönderildi'),
  imzalandi('imzalandi', 'İmzalandı'),
  yururlukte('yururlukte', 'Yürürlükte'),
  tamamlandi('tamamlandi', 'Tamamlandı'),
  feshedildi('feshedildi', 'Feshedildi'),
  iptal('iptal', 'İptal');

  const LawyerContractStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Ücret Türleri
enum LawyerFeeType {
  sabit('sabit', 'Sabit Ücret'),
  saatlik('saatlik', 'Saatlik'),
  basari('basari', 'Başarı Payı'),
  karma('karma', 'Karma'),
  ucretsiz('ucretsiz', 'Ücretsiz');

  const LawyerFeeType(this.value, this.displayName);
  final String value;
  final String displayName;
}

class LawyerContractModel extends BaseModel {
  final String clientId;
  final String? caseId; // Bağlı olduğu dava (varsa)
  final String sozlesmeAdi;
  final String sozlesmeNo;
  final LawyerContractType sozlesmeTuru;
  final LawyerContractStatus sozlesmeDurumu;
  final DateTime sozlesmeTarihi;
  final DateTime? baslamaTarihi;
  final DateTime? bitisTarihi;
  final LawyerFeeType ucretTuru;
  final double ucretMiktari;
  final String? ucretAciklamasi;
  final double? basariPayiOrani; // % cinsinden
  final double? kapora;
  final double? odenenTutar;
  final String? odemeKosullari;
  final List<String> odemePlanimi;
  final String? hizmetKapsami;
  final String? sozlesmeMetni;
  final String? ozelSartlar;
  final String? fesihKosullari;
  final bool otomatikYenileme;
  final int? yenilenmeSuresi; // ay cinsinden
  final DateTime? hatirlatmaTarihi;
  final bool hatirlaticiAktif;
  final List<String> belgeler; // Ek belgeler
  final List<String> imzacilar; // İmzacı bilgileri
  final DateTime? imzaTarihi;
  final String? imzaYeri;
  final String? notlar;
  final Map<String, dynamic> ekBilgiler;
  final bool isActive;

  const LawyerContractModel({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? updatedAt,
    required this.clientId,
    this.caseId,
    required this.sozlesmeAdi,
    required this.sozlesmeNo,
    required this.sozlesmeTuru,
    this.sozlesmeDurumu = LawyerContractStatus.taslak,
    required this.sozlesmeTarihi,
    this.baslamaTarihi,
    this.bitisTarihi,
    this.ucretTuru = LawyerFeeType.sabit,
    this.ucretMiktari = 0.0,
    this.ucretAciklamasi,
    this.basariPayiOrani,
    this.kapora,
    this.odenenTutar,
    this.odemeKosullari,
    this.odemePlanimi = const [],
    this.hizmetKapsami,
    this.sozlesmeMetni,
    this.ozelSartlar,
    this.fesihKosullari,
    this.otomatikYenileme = false,
    this.yenilenmeSuresi,
    this.hatirlatmaTarihi,
    this.hatirlaticiAktif = false,
    this.belgeler = const [],
    this.imzacilar = const [],
    this.imzaTarihi,
    this.imzaYeri,
    this.notlar,
    this.ekBilgiler = const {},
    this.isActive = true,
  }) : super(
          id: id,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // Durum kontrolleri
  bool get taslak => sozlesmeDurumu == LawyerContractStatus.taslak;
  bool get hazir => sozlesmeDurumu == LawyerContractStatus.hazir;
  bool get imzalandi => sozlesmeDurumu == LawyerContractStatus.imzalandi;
  bool get yururlukte => sozlesmeDurumu == LawyerContractStatus.yururlukte;
  bool get tamamlandi => sozlesmeDurumu == LawyerContractStatus.tamamlandi;
  bool get feshedildi => sozlesmeDurumu == LawyerContractStatus.feshedildi;

  // Ücret hesaplamaları
  double get kalanTutar => ucretMiktari - (odenenTutar ?? 0);
  double get odemeOrani =>
      ucretMiktari > 0 ? ((odenenTutar ?? 0) / ucretMiktari) * 100 : 0;
  bool get tamOdendi => kalanTutar <= 0;

  // Zaman kontrolleri
  bool get suresiDoldu {
    if (bitisTarihi == null) return false;
    return DateTime.now().isAfter(bitisTarihi!);
  }

  bool get yakindaSona {
    if (bitisTarihi == null) return false;
    final kacGunKaldi = bitisTarihi!.difference(DateTime.now()).inDays;
    return kacGunKaldi <= 30 && kacGunKaldi > 0;
  }

  int get kalanGun {
    if (bitisTarihi == null) return -1;
    return bitisTarihi!.difference(DateTime.now()).inDays;
  }

  // Formatlanmış değerler
  String get formatliUcret {
    if (ucretMiktari >= 1000000) {
      return '${(ucretMiktari / 1000000).toStringAsFixed(1)} M ₺';
    } else if (ucretMiktari >= 1000) {
      return '${(ucretMiktari / 1000).toStringAsFixed(0)}K ₺';
    }
    return '${ucretMiktari.toStringAsFixed(0)} ₺';
  }

  String get formatliKalanTutar {
    final kalan = kalanTutar;
    if (kalan >= 1000000) {
      return '${(kalan / 1000000).toStringAsFixed(1)} M ₺';
    } else if (kalan >= 1000) {
      return '${(kalan / 1000).toStringAsFixed(0)}K ₺';
    }
    return '${kalan.toStringAsFixed(0)} ₺';
  }

  String get formatliTarih {
    return '${sozlesmeTarihi.day}/${sozlesmeTarihi.month}/${sozlesmeTarihi.year}';
  }

  String get formatliBaslamaTarihi {
    if (baslamaTarihi == null) return 'Belirtilmemiş';
    return '${baslamaTarihi!.day}/${baslamaTarihi!.month}/${baslamaTarihi!.year}';
  }

  String get formatliBitisTarihi {
    if (bitisTarihi == null) return 'Süresiz';
    return '${bitisTarihi!.day}/${bitisTarihi!.month}/${bitisTarihi!.year}';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'clientId': clientId,
      'caseId': caseId,
      'sozlesmeAdi': sozlesmeAdi,
      'sozlesmeNo': sozlesmeNo,
      'sozlesmeTuru': sozlesmeTuru.value,
      'sozlesmeDurumu': sozlesmeDurumu.value,
      'sozlesmeTarihi': Timestamp.fromDate(sozlesmeTarihi),
      'baslamaTarihi':
          baslamaTarihi != null ? Timestamp.fromDate(baslamaTarihi!) : null,
      'bitisTarihi':
          bitisTarihi != null ? Timestamp.fromDate(bitisTarihi!) : null,
      'ucretTuru': ucretTuru.value,
      'ucretMiktari': ucretMiktari,
      'ucretAciklamasi': ucretAciklamasi,
      'basariPayiOrani': basariPayiOrani,
      'kapora': kapora,
      'odenenTutar': odenenTutar,
      'odemeKosullari': odemeKosullari,
      'odemePlanimi': odemePlanimi,
      'hizmetKapsami': hizmetKapsami,
      'sozlesmeMetni': sozlesmeMetni,
      'ozelSartlar': ozelSartlar,
      'fesihKosullari': fesihKosullari,
      'otomatikYenileme': otomatikYenileme,
      'yenilenmeSuresi': yenilenmeSuresi,
      'hatirlatmaTarihi': hatirlatmaTarihi != null
          ? Timestamp.fromDate(hatirlatmaTarihi!)
          : null,
      'hatirlaticiAktif': hatirlaticiAktif,
      'belgeler': belgeler,
      'imzacilar': imzacilar,
      'imzaTarihi': imzaTarihi != null ? Timestamp.fromDate(imzaTarihi!) : null,
      'imzaYeri': imzaYeri,
      'notlar': notlar,
      'ekBilgiler': ekBilgiler,
      'isActive': isActive,
    });
    return map;
  }

  factory LawyerContractModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);

    return LawyerContractModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      clientId: map['clientId'] as String? ?? '',
      caseId: map['caseId'] as String?,
      sozlesmeAdi: map['sozlesmeAdi'] as String? ?? '',
      sozlesmeNo: map['sozlesmeNo'] as String? ?? '',
      sozlesmeTuru: LawyerContractType.values.firstWhere(
        (e) => e.value == map['sozlesmeTuru'],
        orElse: () => LawyerContractType.vekalet,
      ),
      sozlesmeDurumu: LawyerContractStatus.values.firstWhere(
        (e) => e.value == map['sozlesmeDurumu'],
        orElse: () => LawyerContractStatus.taslak,
      ),
      sozlesmeTarihi:
          (map['sozlesmeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      baslamaTarihi: (map['baslamaTarihi'] as Timestamp?)?.toDate(),
      bitisTarihi: (map['bitisTarihi'] as Timestamp?)?.toDate(),
      ucretTuru: LawyerFeeType.values.firstWhere(
        (e) => e.value == map['ucretTuru'],
        orElse: () => LawyerFeeType.sabit,
      ),
      ucretMiktari: (map['ucretMiktari'] as num?)?.toDouble() ?? 0.0,
      ucretAciklamasi: map['ucretAciklamasi'] as String?,
      basariPayiOrani: (map['basariPayiOrani'] as num?)?.toDouble(),
      kapora: (map['kapora'] as num?)?.toDouble(),
      odenenTutar: (map['odenenTutar'] as num?)?.toDouble(),
      odemeKosullari: map['odemeKosullari'] as String?,
      odemePlanimi: List<String>.from(map['odemePlanimi'] ?? []),
      hizmetKapsami: map['hizmetKapsami'] as String?,
      sozlesmeMetni: map['sozlesmeMetni'] as String?,
      ozelSartlar: map['ozelSartlar'] as String?,
      fesihKosullari: map['fesihKosullari'] as String?,
      otomatikYenileme: map['otomatikYenileme'] as bool? ?? false,
      yenilenmeSuresi: map['yenilenmeSuresi'] as int?,
      hatirlatmaTarihi: (map['hatirlatmaTarihi'] as Timestamp?)?.toDate(),
      hatirlaticiAktif: map['hatirlaticiAktif'] as bool? ?? false,
      belgeler: List<String>.from(map['belgeler'] ?? []),
      imzacilar: List<String>.from(map['imzacilar'] ?? []),
      imzaTarihi: (map['imzaTarihi'] as Timestamp?)?.toDate(),
      imzaYeri: map['imzaYeri'] as String?,
      notlar: map['notlar'] as String?,
      ekBilgiler: Map<String, dynamic>.from(map['ekBilgiler'] ?? {}),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory LawyerContractModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return LawyerContractModel.fromMap(data);
  }

  LawyerContractModel copyWith({
    String? clientId,
    String? caseId,
    String? sozlesmeAdi,
    String? sozlesmeNo,
    LawyerContractType? sozlesmeTuru,
    LawyerContractStatus? sozlesmeDurumu,
    DateTime? sozlesmeTarihi,
    DateTime? baslamaTarihi,
    DateTime? bitisTarihi,
    LawyerFeeType? ucretTuru,
    double? ucretMiktari,
    String? ucretAciklamasi,
    double? basariPayiOrani,
    double? kapora,
    double? odenenTutar,
    String? odemeKosullari,
    List<String>? odemePlanimi,
    String? hizmetKapsami,
    String? sozlesmeMetni,
    String? ozelSartlar,
    String? fesihKosullari,
    bool? otomatikYenileme,
    int? yenilenmeSuresi,
    DateTime? hatirlatmaTarihi,
    bool? hatirlaticiAktif,
    List<String>? belgeler,
    List<String>? imzacilar,
    DateTime? imzaTarihi,
    String? imzaYeri,
    String? notlar,
    Map<String, dynamic>? ekBilgiler,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return LawyerContractModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      clientId: clientId ?? this.clientId,
      caseId: caseId ?? this.caseId,
      sozlesmeAdi: sozlesmeAdi ?? this.sozlesmeAdi,
      sozlesmeNo: sozlesmeNo ?? this.sozlesmeNo,
      sozlesmeTuru: sozlesmeTuru ?? this.sozlesmeTuru,
      sozlesmeDurumu: sozlesmeDurumu ?? this.sozlesmeDurumu,
      sozlesmeTarihi: sozlesmeTarihi ?? this.sozlesmeTarihi,
      baslamaTarihi: baslamaTarihi ?? this.baslamaTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      ucretTuru: ucretTuru ?? this.ucretTuru,
      ucretMiktari: ucretMiktari ?? this.ucretMiktari,
      ucretAciklamasi: ucretAciklamasi ?? this.ucretAciklamasi,
      basariPayiOrani: basariPayiOrani ?? this.basariPayiOrani,
      kapora: kapora ?? this.kapora,
      odenenTutar: odenenTutar ?? this.odenenTutar,
      odemeKosullari: odemeKosullari ?? this.odemeKosullari,
      odemePlanimi: odemePlanimi ?? this.odemePlanimi,
      hizmetKapsami: hizmetKapsami ?? this.hizmetKapsami,
      sozlesmeMetni: sozlesmeMetni ?? this.sozlesmeMetni,
      ozelSartlar: ozelSartlar ?? this.ozelSartlar,
      fesihKosullari: fesihKosullari ?? this.fesihKosullari,
      otomatikYenileme: otomatikYenileme ?? this.otomatikYenileme,
      yenilenmeSuresi: yenilenmeSuresi ?? this.yenilenmeSuresi,
      hatirlatmaTarihi: hatirlatmaTarihi ?? this.hatirlatmaTarihi,
      hatirlaticiAktif: hatirlaticiAktif ?? this.hatirlaticiAktif,
      belgeler: belgeler ?? this.belgeler,
      imzacilar: imzacilar ?? this.imzacilar,
      imzaTarihi: imzaTarihi ?? this.imzaTarihi,
      imzaYeri: imzaYeri ?? this.imzaYeri,
      notlar: notlar ?? this.notlar,
      ekBilgiler: ekBilgiler ?? this.ekBilgiler,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'LawyerContractModel(id: $id, sozlesmeAdi: $sozlesmeAdi, sozlesmeDurumu: $sozlesmeDurumu)';
}

// Sözleşme şablonları
class LawyerContractTemplates {
  static const String vekaletSozlesmesi = '''
VEKALET SÖZLEŞMESİ

Müvekkil: [MÜVEKKİL_ADI]
Adres: [MÜVEKKİL_ADRES]
T.C. Kimlik No: [TC_NO]
Telefon: [TELEFON]

Vekil: [VEKİL_ADI]
Baro Sicil No: [SICIL_NO]
Adres: [VEKİL_ADRES]
Telefon: [VEKİL_TELEFON]

İşbu sözleşme ile müvekkil, aşağıda belirtilen konularda vekilini tam yetkili olarak yetkilendirmiştir:

[HİZMET_KAPSAMI]

Vekalet ücreti: [ÜCRET] TL
Ödeme koşulları: [ÖDEME_KOŞULLARI]

Tarih: [TARİH]

Müvekkil                    Vekil
[İMZA]                     [İMZA]
''';

  static const String danismanlikSozlesmesi = '''
HUKUKI DANIŞMANLIK SÖZLEŞMESİ

Müşteri: [MÜŞTERİ_ADI]
Adres: [MÜŞTERİ_ADRES]
Telefon: [TELEFON]

Danışman: [DANIŞMAN_ADI]
Baro Sicil No: [SICIL_NO]
Adres: [DANIŞMAN_ADRES]

Danışmanlık konusu: [KONU]
Süre: [SÜRE]
Ücret: [ÜCRET] TL

[ÖZEL_ŞARTLAR]

Tarih: [TARİH]

Müşteri                    Danışman
[İMZA]                     [İMZA]
''';

  static String getTemplate(LawyerContractType type) {
    switch (type) {
      case LawyerContractType.vekalet:
        return vekaletSozlesmesi;
      case LawyerContractType.danismanlik:
        return danismanlikSozlesmesi;
      default:
        return vekaletSozlesmesi;
    }
  }
}
