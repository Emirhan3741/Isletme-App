import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class PsychologyClient extends BaseModel implements StatusModel {
  final String ad;
  final String soyad;
  final String telefon;
  final String? email;
  final DateTime? dogumTarihi;
  final String? cinsiyet; // erkek, kadın, belirtmek_istemez
  final String? adres;
  final String? meslek;
  final String? egitimDurumu;
  final String? medeniDurum; // bekar, evli, bosanmis, dul
  final String danisanTipi; // bireysel, cift, cocuk, aile, grup
  final String? sevkEden; // başka uzman, kendi başvurusu, aile, vb.
  final String? sigorta; // sgk, özel_sigorta, yok
  final String? sigortaNo;
  final DateTime? ilkBasvuruTarihi;
  final String? yakiniAd;
  final String? yakiniTelefon;
  final String? yakiniIliski; // anne, baba, es, kardes, vb.
  @override
  final String status; // active, inactive, completed, paused
  final String? anamnez; // Geçmiş bilgiler
  final String? suanDurum; // Mevcut durum
  final String? tedaviAmaci; // Tedavi hedefleri
  final List<String>? tanilar; // Tanılar
  final List<String>? kullanilanIlaclar; // Kullandığı ilaçlar
  final List<String>? gecmisRahatsizliklar; // Önceki rahatsızlıklar
  final String? acilDurumTelefon;
  final String? notlar; // Genel notlar
  final Map<String, dynamic>? ekstraBilgiler;
  final DateTime? sonSeanstarihi;
  final int? toplamSeansSayisi;
  final String? oncelikDurumu; // normal, acil, takip

  const PsychologyClient({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.email,
    this.dogumTarihi,
    this.cinsiyet,
    this.adres,
    this.meslek,
    this.egitimDurumu,
    this.medeniDurum,
    this.danisanTipi = 'bireysel',
    this.sevkEden,
    this.sigorta,
    this.sigortaNo,
    this.ilkBasvuruTarihi,
    this.yakiniAd,
    this.yakiniTelefon,
    this.yakiniIliski,
    this.status = 'active',
    this.anamnez,
    this.suanDurum,
    this.tedaviAmaci,
    this.tanilar,
    this.kullanilanIlaclar,
    this.gecmisRahatsizliklar,
    this.acilDurumTelefon,
    this.notlar,
    this.ekstraBilgiler,
    this.sonSeanstarihi,
    this.toplamSeansSayisi,
    this.oncelikDurumu,
  });

  // StatusModel implementation
  @override
  bool get isActive => status == 'active';

  // Hesaplanan özellikler
  String get tamAd => '$ad $soyad';

  String get adSoyad => tamAd;

  String get telefronFormatli {
    if (telefon.length == 11) {
      return '${telefon.substring(0, 4)} ${telefon.substring(4, 7)} ${telefon.substring(7, 9)} ${telefon.substring(9)}';
    }
    return telefon;
  }

  int? get yas {
    if (dogumTarihi == null) return null;
    final now = DateTime.now();
    int age = now.year - dogumTarihi!.year;
    if (now.month < dogumTarihi!.month ||
        (now.month == dogumTarihi!.month && now.day < dogumTarihi!.day)) {
      age--;
    }
    return age;
  }

  String get yasMetni => yas != null ? '$yas yaş' : 'Yaş belirtilmemiş';

  String get cinsiyetEmoji {
    switch (cinsiyet) {
      case 'erkek':
        return '👨';
      case 'kadın':
        return '👩';
      case 'cocuk_erkek':
        return '👦';
      case 'cocuk_kadın':
        return '👧';
      default:
        return '👤';
    }
  }

  String get danisanTipiAciklama {
    switch (danisanTipi) {
      case 'bireysel':
        return 'Bireysel Terapi';
      case 'cift':
        return 'Çift Terapisi';
      case 'cocuk':
        return 'Çocuk Terapisi';
      case 'aile':
        return 'Aile Terapisi';
      case 'grup':
        return 'Grup Terapisi';
      default:
        return danisanTipi;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'active':
        return '🟢';
      case 'inactive':
        return '🔴';
      case 'completed':
        return '✅';
      case 'paused':
        return '⏸️';
      default:
        return '❓';
    }
  }

  String get statusAciklama {
    switch (status) {
      case 'active':
        return 'Aktif Tedavi';
      case 'inactive':
        return 'Pasif';
      case 'completed':
        return 'Tedavi Tamamlandı';
      case 'paused':
        return 'Tedavi Durduruldu';
      default:
        return 'Bilinmiyor';
    }
  }

  String get oncelikEmoji {
    switch (oncelikDurumu) {
      case 'acil':
        return '🚨';
      case 'takip':
        return '⚠️';
      default:
        return '📋';
    }
  }

  bool get acilDurum => oncelikDurumu == 'acil';

  // Son seans bilgisi
  String get sonSeansMetni {
    if (sonSeanstarihi == null) return 'Henüz seans yapılmamış';
    final gun = DateTime.now().difference(sonSeanstarihi!).inDays;
    if (gun == 0) return 'Bugün';
    if (gun == 1) return 'Dün';
    return '$gun gün önce';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'dogumTarihi':
          dogumTarihi != null ? Timestamp.fromDate(dogumTarihi!) : null,
      'cinsiyet': cinsiyet,
      'adres': adres,
      'meslek': meslek,
      'egitimDurumu': egitimDurumu,
      'medeniDurum': medeniDurum,
      'danisanTipi': danisanTipi,
      'sevkEden': sevkEden,
      'sigorta': sigorta,
      'sigortaNo': sigortaNo,
      'ilkBasvuruTarihi': ilkBasvuruTarihi != null
          ? Timestamp.fromDate(ilkBasvuruTarihi!)
          : null,
      'yakiniAd': yakiniAd,
      'yakiniTelefon': yakiniTelefon,
      'yakiniIliski': yakiniIliski,
      'status': status,
      'anamnez': anamnez,
      'suanDurum': suanDurum,
      'tedaviAmaci': tedaviAmaci,
      'tanilar': tanilar,
      'kullanilanIlaclar': kullanilanIlaclar,
      'gecmisRahatsizliklar': gecmisRahatsizliklar,
      'acilDurumTelefon': acilDurumTelefon,
      'notlar': notlar,
      'ekstraBilgiler': ekstraBilgiler,
      'sonSeanstarihi':
          sonSeanstarihi != null ? Timestamp.fromDate(sonSeanstarihi!) : null,
      'toplamSeansSayisi': toplamSeansSayisi,
      'oncelikDurumu': oncelikDurumu,
      'tamAd': tamAd, // Arama için
      'yas': yas, // Filtreleme için
    });
    return map;
  }

  static PsychologyClient fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return PsychologyClient(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      ad: map['ad'] as String? ?? '',
      soyad: map['soyad'] as String? ?? '',
      telefon: map['telefon'] as String? ?? '',
      email: map['email'] as String?,
      dogumTarihi: (map['dogumTarihi'] as Timestamp?)?.toDate(),
      cinsiyet: map['cinsiyet'] as String?,
      adres: map['adres'] as String?,
      meslek: map['meslek'] as String?,
      egitimDurumu: map['egitimDurumu'] as String?,
      medeniDurum: map['medeniDurum'] as String?,
      danisanTipi: map['danisanTipi'] as String? ?? 'bireysel',
      sevkEden: map['sevkEden'] as String?,
      sigorta: map['sigorta'] as String?,
      sigortaNo: map['sigortaNo'] as String?,
      ilkBasvuruTarihi: (map['ilkBasvuruTarihi'] as Timestamp?)?.toDate(),
      yakiniAd: map['yakiniAd'] as String?,
      yakiniTelefon: map['yakiniTelefon'] as String?,
      yakiniIliski: map['yakiniIliski'] as String?,
      status: map['status'] as String? ?? 'active',
      anamnez: map['anamnez'] as String?,
      suanDurum: map['suanDurum'] as String?,
      tedaviAmaci: map['tedaviAmaci'] as String?,
      tanilar:
          map['tanilar'] != null ? List<String>.from(map['tanilar']) : null,
      kullanilanIlaclar: map['kullanilanIlaclar'] != null
          ? List<String>.from(map['kullanilanIlaclar'])
          : null,
      gecmisRahatsizliklar: map['gecmisRahatsizliklar'] != null
          ? List<String>.from(map['gecmisRahatsizliklar'])
          : null,
      acilDurumTelefon: map['acilDurumTelefon'] as String?,
      notlar: map['notlar'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
      sonSeanstarihi: (map['sonSeanstarihi'] as Timestamp?)?.toDate(),
      toplamSeansSayisi: map['toplamSeansSayisi'] as int?,
      oncelikDurumu: map['oncelikDurumu'] as String?,
    );
  }

  PsychologyClient copyWith({
    String? ad,
    String? soyad,
    String? telefon,
    String? email,
    DateTime? dogumTarihi,
    String? cinsiyet,
    String? adres,
    String? meslek,
    String? egitimDurumu,
    String? medeniDurum,
    String? danisanTipi,
    String? sevkEden,
    String? sigorta,
    String? sigortaNo,
    DateTime? ilkBasvuruTarihi,
    String? yakiniAd,
    String? yakiniTelefon,
    String? yakiniIliski,
    String? status,
    String? anamnez,
    String? suanDurum,
    String? tedaviAmaci,
    List<String>? tanilar,
    List<String>? kullanilanIlaclar,
    List<String>? gecmisRahatsizliklar,
    String? acilDurumTelefon,
    String? notlar,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? sonSeansarihi,
    int? toplamSeansSayisi,
    String? oncelikDurumu,
    DateTime? updatedAt,
  }) {
    return PsychologyClient(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      adres: adres ?? this.adres,
      meslek: meslek ?? this.meslek,
      egitimDurumu: egitimDurumu ?? this.egitimDurumu,
      medeniDurum: medeniDurum ?? this.medeniDurum,
      danisanTipi: danisanTipi ?? this.danisanTipi,
      sevkEden: sevkEden ?? this.sevkEden,
      sigorta: sigorta ?? this.sigorta,
      sigortaNo: sigortaNo ?? this.sigortaNo,
      ilkBasvuruTarihi: ilkBasvuruTarihi ?? this.ilkBasvuruTarihi,
      yakiniAd: yakiniAd ?? this.yakiniAd,
      yakiniTelefon: yakiniTelefon ?? this.yakiniTelefon,
      yakiniIliski: yakiniIliski ?? this.yakiniIliski,
      status: status ?? this.status,
      anamnez: anamnez ?? this.anamnez,
      suanDurum: suanDurum ?? this.suanDurum,
      tedaviAmaci: tedaviAmaci ?? this.tedaviAmaci,
      tanilar: tanilar ?? this.tanilar,
      kullanilanIlaclar: kullanilanIlaclar ?? this.kullanilanIlaclar,
      gecmisRahatsizliklar: gecmisRahatsizliklar ?? this.gecmisRahatsizliklar,
      acilDurumTelefon: acilDurumTelefon ?? this.acilDurumTelefon,
      notlar: notlar ?? this.notlar,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
      sonSeanstarihi: sonSeanstarihi ?? this.sonSeanstarihi,
      toplamSeansSayisi: toplamSeansSayisi ?? this.toplamSeansSayisi,
      oncelikDurumu: oncelikDurumu ?? this.oncelikDurumu,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      ad.isNotEmpty &&
      soyad.isNotEmpty &&
      telefon.isNotEmpty &&
      danisanTipi.isNotEmpty;

  @override
  String toString() =>
      'PsychologyClient(id: $id, ad: $tamAd, tip: $danisanTipi, durum: $status)';
}
