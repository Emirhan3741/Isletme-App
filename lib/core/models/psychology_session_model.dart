import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class PsychologySession extends BaseModel implements StatusModel {
  final String danisanId;
  final String? hizmetId; // Hangi terapi hizmeti
  final String seansTuru; // bireysel, cift, aile, grup, online
  final DateTime seansTarihi;
  final String saatAraligi; // '14:00-15:00'
  final int sure; // dakika cinsinden
  final String? konum; // ofis, online, ev_ziyareti
  final double ucret;
  final String odemeDurumu; // odendi, bekliyor, ucretsiz
  @override
  final String status; // tamamlandi, iptal, gecikti, devam_ediyor
  final String? seansAmaci; // Bu seansın amacı
  final String? oncekiSeansOzeti; // Önceki seansın özeti
  final String? seansNotlari; // Seans sırasında alınan notlar
  final String? sonrakiPlan; // Bir sonraki seans için plan
  final String? odeyenKisi; // Danışan değilse kim ödedi
  final List<String>? uygulananteknikler; // Kullanılan terapi teknikleri
  final List<String>? konular; // Seansın konuları
  final String? duygusalDurum; // Danışanın seanstaki duygusal durumu
  final String? deerlendirme; // Seansın değerlendirmesi
  final int? seansNo; // Kaçıncı seans
  final String? katilimci; // Seansa katılanlar (aile terapisinde)
  final bool? evOdevi; // Ev ödevi verildi mi?
  final String? evOdeviDetay; // Ev ödevinin detayı
  final DateTime? sonrakiRandevu; // Bir sonraki randevu tarihi
  final String? aciliyet; // normal, acil, takip
  final Map<String, dynamic>? ekstraBilgiler;
  final String? recordId; // Kayıt dosyası ID'si (varsa)
  final bool gizlilik; // Gizlilik anlaşması imzalandı mı?

  const PsychologySession({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.danisanId,
    this.hizmetId,
    required this.seansTuru,
    required this.seansTarihi,
    required this.saatAraligi,
    this.sure = 50, // Standart 50 dakika
    this.konum,
    required this.ucret,
    this.odemeDurumu = 'bekliyor',
    this.status = 'tamamlandi',
    this.seansAmaci,
    this.oncekiSeansOzeti,
    this.seansNotlari,
    this.sonrakiPlan,
    this.odeyenKisi,
    this.uygulananteknikler,
    this.konular,
    this.duygusalDurum,
    this.deerlendirme,
    this.seansNo,
    this.katilimci,
    this.evOdevi,
    this.evOdeviDetay,
    this.sonrakiRandevu,
    this.aciliyet,
    this.ekstraBilgiler,
    this.recordId,
    this.gizlilik = true,
  });

  // StatusModel implementation
  @override
  bool get isActive => status == 'tamamlandi' || status == 'devam_ediyor';

  // Hesaplanan özellikler
  String get formatliTarih {
    return '${seansTarihi.day.toString().padLeft(2, '0')}/'
        '${seansTarihi.month.toString().padLeft(2, '0')}/'
        '${seansTarihi.year}';
  }

  String get formatliSaat => saatAraligi;

  String get formatliUcret => '₺${ucret.toStringAsFixed(2)}';

  String get seansTuruAciklama {
    switch (seansTuru) {
      case 'bireysel':
        return 'Bireysel Terapi';
      case 'cift':
        return 'Çift Terapisi';
      case 'aile':
        return 'Aile Terapisi';
      case 'grup':
        return 'Grup Terapisi';
      case 'online':
        return 'Online Seans';
      case 'telefon':
        return 'Telefon Danışmanlığı';
      default:
        return seansTuru;
    }
  }

  String get konumAciklama {
    switch (konum) {
      case 'ofis':
        return 'Ofiste';
      case 'online':
        return 'Online';
      case 'ev_ziyareti':
        return 'Ev Ziyareti';
      case 'hastane':
        return 'Hastanede';
      default:
        return konum ?? 'Belirtilmemiş';
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'tamamlandi':
        return '✅';
      case 'iptal':
        return '❌';
      case 'gecikti':
        return '⏰';
      case 'devam_ediyor':
        return '🔄';
      case 'planli':
        return '📅';
      default:
        return '❓';
    }
  }

  String get statusAciklama {
    switch (status) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'iptal':
        return 'İptal Edildi';
      case 'gecikti':
        return 'Gecikti';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'planli':
        return 'Planlandı';
      default:
        return 'Bilinmiyor';
    }
  }

  String get odemeDurumuEmoji {
    switch (odemeDurumu) {
      case 'odendi':
        return '💰';
      case 'bekliyor':
        return '⏳';
      case 'ucretsiz':
        return '🆓';
      default:
        return '❓';
    }
  }

  String get odemeDurumuAciklama {
    switch (odemeDurumu) {
      case 'odendi':
        return 'Ödendi';
      case 'bekliyor':
        return 'Bekliyor';
      case 'ucretsiz':
        return 'Ücretsiz';
      default:
        return 'Belirsiz';
    }
  }

  String get aciliyetEmoji {
    switch (aciliyet) {
      case 'acil':
        return '🚨';
      case 'takip':
        return '⚠️';
      default:
        return '📋';
    }
  }

  bool get odendi => odemeDurumu == 'odendi';
  bool get ucretsiz => odemeDurumu == 'ucretsiz';
  bool get gecikti => status == 'gecikti';
  bool get tamamlandi => status == 'tamamlandi';
  bool get iptalEdildi => status == 'iptal';

  // Tarih saat metni
  String get tarihSaatMetni {
    return '$formatliTarih $saatAraligi';
  }

  // Durum metni
  String get durumMetni {
    if (tamamlandi) return 'Tamamlandı';
    if (iptalEdildi) return 'İptal Edildi';
    if (gecikti) return 'Gecikti';
    if (seansTarihi.isAfter(DateTime.now())) return 'Yaklaşan';
    return 'Kaçırılan';
  }

  // Seansın süresi formatı
  String get sureFormatli {
    if (sure >= 60) {
      final saat = sure ~/ 60;
      final dakika = sure % 60;
      if (dakika == 0) {
        return '$saat saat';
      } else {
        return '$saat saat $dakika dk';
      }
    } else {
      return '$sure dakika';
    }
  }

  // Sonraki randevu bilgisi
  String get sonrakiRandevuMetni {
    if (sonrakiRandevu == null) return 'Planlanmamış';
    final gun = sonrakiRandevu!.difference(DateTime.now()).inDays;
    if (gun == 0) return 'Bugün';
    if (gun == 1) return 'Yarın';
    if (gun > 0) return '$gun gün sonra';
    return 'Geçmiş tarih';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'danisanId': danisanId,
      'hizmetId': hizmetId,
      'seansTuru': seansTuru,
      'seansTarihi': Timestamp.fromDate(seansTarihi),
      'saatAraligi': saatAraligi,
      'sure': sure,
      'konum': konum,
      'ucret': ucret,
      'odemeDurumu': odemeDurumu,
      'status': status,
      'seansAmaci': seansAmaci,
      'oncekiSeansOzeti': oncekiSeansOzeti,
      'seansNotlari': seansNotlari,
      'sonrakiPlan': sonrakiPlan,
      'odeyenKisi': odeyenKisi,
      'uygulananteknikler': uygulananteknikler,
      'konular': konular,
      'duygusalDurum': duygusalDurum,
      'deerlendirme': deerlendirme,
      'seansNo': seansNo,
      'katilimci': katilimci,
      'evOdevi': evOdevi,
      'evOdeviDetay': evOdeviDetay,
      'sonrakiRandevu':
          sonrakiRandevu != null ? Timestamp.fromDate(sonrakiRandevu!) : null,
      'aciliyet': aciliyet,
      'ekstraBilgiler': ekstraBilgiler,
      'recordId': recordId,
      'gizlilik': gizlilik,
      'formatliTarih': formatliTarih, // Arama için
      'seansTuruAciklama': seansTuruAciklama, // Filtreleme için
    });
    return map;
  }

  static PsychologySession fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return PsychologySession(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      danisanId: map['danisanId'] as String? ?? '',
      hizmetId: map['hizmetId'] as String?,
      seansTuru: map['seansTuru'] as String? ?? 'bireysel',
      seansTarihi:
          (map['seansTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      saatAraligi: map['saatAraligi'] as String? ?? '',
      sure: map['sure'] as int? ?? 50,
      konum: map['konum'] as String?,
      ucret: (map['ucret'] as num?)?.toDouble() ?? 0.0,
      odemeDurumu: map['odemeDurumu'] as String? ?? 'bekliyor',
      status: map['status'] as String? ?? 'tamamlandi',
      seansAmaci: map['seansAmaci'] as String?,
      oncekiSeansOzeti: map['oncekiSeansOzeti'] as String?,
      seansNotlari: map['seansNotlari'] as String?,
      sonrakiPlan: map['sonrakiPlan'] as String?,
      odeyenKisi: map['odeyenKisi'] as String?,
      uygulananteknikler: map['uygulananteknikler'] != null
          ? List<String>.from(map['uygulananteknikler'])
          : null,
      konular:
          map['konular'] != null ? List<String>.from(map['konular']) : null,
      duygusalDurum: map['duygusalDurum'] as String?,
      deerlendirme: map['deerlendirme'] as String?,
      seansNo: map['seansNo'] as int?,
      katilimci: map['katilimci'] as String?,
      evOdevi: map['evOdevi'] as bool?,
      evOdeviDetay: map['evOdeviDetay'] as String?,
      sonrakiRandevu: (map['sonrakiRandevu'] as Timestamp?)?.toDate(),
      aciliyet: map['aciliyet'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
      recordId: map['recordId'] as String?,
      gizlilik: map['gizlilik'] as bool? ?? true,
    );
  }

  PsychologySession copyWith({
    String? danisanId,
    String? hizmetId,
    String? seansTuru,
    DateTime? seansTarihi,
    String? saatAraligi,
    int? sure,
    String? konum,
    double? ucret,
    String? odemeDurumu,
    String? status,
    String? seansAmaci,
    String? oncekiSeansOzeti,
    String? seansNotlari,
    String? sonrakiPlan,
    String? odeyenKisi,
    List<String>? uygulananteknikler,
    List<String>? konular,
    String? duygusalDurum,
    String? deerlendirme,
    int? seansNo,
    String? katilimci,
    bool? evOdevi,
    String? evOdeviDetay,
    DateTime? sonrakiRandevu,
    String? aciliyet,
    Map<String, dynamic>? ekstraBilgiler,
    String? recordId,
    bool? gizlilik,
    DateTime? updatedAt,
  }) {
    return PsychologySession(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      danisanId: danisanId ?? this.danisanId,
      hizmetId: hizmetId ?? this.hizmetId,
      seansTuru: seansTuru ?? this.seansTuru,
      seansTarihi: seansTarihi ?? this.seansTarihi,
      saatAraligi: saatAraligi ?? this.saatAraligi,
      sure: sure ?? this.sure,
      konum: konum ?? this.konum,
      ucret: ucret ?? this.ucret,
      odemeDurumu: odemeDurumu ?? this.odemeDurumu,
      status: status ?? this.status,
      seansAmaci: seansAmaci ?? this.seansAmaci,
      oncekiSeansOzeti: oncekiSeansOzeti ?? this.oncekiSeansOzeti,
      seansNotlari: seansNotlari ?? this.seansNotlari,
      sonrakiPlan: sonrakiPlan ?? this.sonrakiPlan,
      odeyenKisi: odeyenKisi ?? this.odeyenKisi,
      uygulananteknikler: uygulananteknikler ?? this.uygulananteknikler,
      konular: konular ?? this.konular,
      duygusalDurum: duygusalDurum ?? this.duygusalDurum,
      deerlendirme: deerlendirme ?? this.deerlendirme,
      seansNo: seansNo ?? this.seansNo,
      katilimci: katilimci ?? this.katilimci,
      evOdevi: evOdevi ?? this.evOdevi,
      evOdeviDetay: evOdeviDetay ?? this.evOdeviDetay,
      sonrakiRandevu: sonrakiRandevu ?? this.sonrakiRandevu,
      aciliyet: aciliyet ?? this.aciliyet,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
      recordId: recordId ?? this.recordId,
      gizlilik: gizlilik ?? this.gizlilik,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      danisanId.isNotEmpty &&
      seansTuru.isNotEmpty &&
      saatAraligi.isNotEmpty &&
      ucret >= 0 &&
      sure > 0;

  @override
  String toString() =>
      'PsychologySession(id: $id, danisan: $danisanId, tarih: $formatliTarih, durum: $status)';
}
