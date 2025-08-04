import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class EducationExam extends BaseModel implements StatusModel {
  final String sinavAdi;
  final String aciklama;
  final String dersId; // Course ID
  final String? ogretmenId; // Teacher ID
  final List<String> ogrenciListesi; // Sınava girecek öğrenci ID'leri
  final DateTime sinavTarihi;
  final DateTime sinavSaati;
  final int sure; // Sınav süresi (dakika)
  final String sinavTuru; // yazili, sozlu, quiz, proje, odev
  final String sinif; // Sınıf/oda bilgisi
  @override
  final String status; // planned, ongoing, completed, cancelled, graded
  final int toplamPuan; // Toplam puan
  final int gecmePuani; // Geçme puanı
  final Map<String, dynamic>? sinavSonuclari; // Student ID -> sonuç
  final Map<String, String>? ogrenciNotlari; // Student ID -> not
  final List<String> sorular; // Sınav soruları
  final String? sinavMalzemesi; // İhtiyaç duyulan malzemeler
  final bool onlineSlnav; // Online sınav mı?
  final String? sinavLinki; // Online sınav linki
  final bool acikKitap; // Açık kitap sınavı mı?
  final Map<String, dynamic>? istatistikler; // Sınav istatistikleri
  final String? degerlendirmeKriteri; // Değerlendirme kriterleri
  final DateTime? sonucAciklamaTarihi; // Sonuçların açıklanacağı tarih
  final bool sonuclarAciklandi; // Sonuçlar açıklandı mı?
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationExam({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.sinavAdi,
    required this.aciklama,
    required this.dersId,
    this.ogretmenId,
    required this.ogrenciListesi,
    required this.sinavTarihi,
    required this.sinavSaati,
    required this.sure,
    required this.sinavTuru,
    required this.sinif,
    this.status = 'planned',
    this.toplamPuan = 100,
    this.gecmePuani = 60,
    this.sinavSonuclari,
    this.ogrenciNotlari,
    this.sorular = const [],
    this.sinavMalzemesi,
    this.onlineSlnav = false,
    this.sinavLinki,
    this.acikKitap = false,
    this.istatistikler,
    this.degerlendirmeKriteri,
    this.sonucAciklamaTarihi,
    this.sonuclarAciklandi = false,
    this.ekstraBilgiler,
  });

  // StatusModel implementation
  @override
  bool get isActive => status != 'cancelled';

  // Sınav bitti mi?
  bool get bitti =>
      DateTime.now().isAfter(sinavSaati.add(Duration(minutes: sure)));

  // Sınav başladı mı?
  bool get basladi => DateTime.now().isAfter(sinavSaati);

  // Devam ediyor mu?
  bool get devamEdiyor => basladi && !bitti;

  // Katılımcı sayısı
  int get katilimciSayisi => ogrenciListesi.length;

  // Geçen öğrenci sayısı
  int get gecenOgrenciSayisi {
    if (sinavSonuclari == null) return 0;
    return sinavSonuclari!.values
        .where((sonuc) =>
            (sonuc['puan'] as num?) != null &&
            (sonuc['puan'] as num) >= gecmePuani)
        .length;
  }

  // Kalan öğrenci sayısı
  int get kalanOgrenciSayisi => katilimciSayisi - gecenOgrenciSayisi;

  // Ortalama puan
  double get ortalamaPuan {
    if (sinavSonuclari == null || sinavSonuclari!.isEmpty) return 0.0;

    double toplam = 0;
    int sayac = 0;

    for (var sonuc in sinavSonuclari!.values) {
      if (sonuc['puan'] != null) {
        toplam += (sonuc['puan'] as num).toDouble();
        sayac++;
      }
    }

    return sayac > 0 ? toplam / sayac : 0.0;
  }

  // Başarı oranı
  double get basariOrani {
    if (katilimciSayisi == 0) return 0.0;
    return (gecenOgrenciSayisi / katilimciSayisi) * 100;
  }

  // Formatlanmış süre
  String get formatliSure {
    if (sure < 60) {
      return '$sure dk';
    } else {
      int saat = sure ~/ 60;
      int dakika = sure % 60;
      return dakika > 0 ? '${saat}s ${dakika}dk' : '${saat}s';
    }
  }

  // Emoji durumu
  String get statusEmoji {
    switch (status) {
      case 'planned':
        return '📅';
      case 'ongoing':
        return '⏰';
      case 'completed':
        return '✅';
      case 'cancelled':
        return '❌';
      case 'graded':
        return '📊';
      default:
        return '❓';
    }
  }

  // Durum açıklaması
  String get statusAciklama {
    switch (status) {
      case 'planned':
        return 'Planlandı';
      case 'ongoing':
        return 'Devam Ediyor';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'graded':
        return 'Notlandırıldı';
      default:
        return 'Bilinmeyen';
    }
  }

  // Sınav türü emoji
  String get sinavTuruEmoji {
    switch (sinavTuru) {
      case 'yazili':
        return '📝';
      case 'sozlu':
        return '🗣️';
      case 'quiz':
        return '❓';
      case 'proje':
        return '💻';
      case 'odev':
        return '📚';
      default:
        return '📋';
    }
  }

  // Sınav türü açıklaması
  String get sinavTuruAciklama {
    switch (sinavTuru) {
      case 'yazili':
        return 'Yazılı Sınav';
      case 'sozlu':
        return 'Sözlü Sınav';
      case 'quiz':
        return 'Quiz';
      case 'proje':
        return 'Proje';
      case 'odev':
        return 'Ödev';
      default:
        return sinavTuru;
    }
  }

  // Kalan gün sayısı
  int get kalanGun {
    final now = DateTime.now();
    final examDate =
        DateTime(sinavTarihi.year, sinavTarihi.month, sinavTarihi.day);
    final today = DateTime(now.year, now.month, now.day);
    return examDate.difference(today).inDays;
  }

  // Kalan gün bilgisi
  String get kalanGunBilgisi {
    final days = kalanGun;
    if (days < 0) return 'Geçti';
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'sinavAdi': sinavAdi,
      'aciklama': aciklama,
      'dersId': dersId,
      'ogretmenId': ogretmenId,
      'ogrenciListesi': ogrenciListesi,
      'sinavTarihi': Timestamp.fromDate(sinavTarihi),
      'sinavSaati': Timestamp.fromDate(sinavSaati),
      'sure': sure,
      'sinavTuru': sinavTuru,
      'sinif': sinif,
      'status': status,
      'toplamPuan': toplamPuan,
      'gecmePuani': gecmePuani,
      'sinavSonuclari': sinavSonuclari,
      'ogrenciNotlari': ogrenciNotlari,
      'sorular': sorular,
      'sinavMalzemesi': sinavMalzemesi,
      'onlineSlnav': onlineSlnav,
      'sinavLinki': sinavLinki,
      'acikKitap': acikKitap,
      'istatistikler': istatistikler,
      'degerlendirmeKriteri': degerlendirmeKriteri,
      'sonucAciklamaTarihi': sonucAciklamaTarihi != null
          ? Timestamp.fromDate(sonucAciklamaTarihi!)
          : null,
      'sonuclarAciklandi': sonuclarAciklandi,
      'ekstraBilgiler': ekstraBilgiler,
      'ortalamaPuan': ortalamaPuan, // Hesaplanan değerler
      'basariOrani': basariOrani,
      'gecenOgrenciSayisi': gecenOgrenciSayisi,
      'kalanOgrenciSayisi': kalanOgrenciSayisi,
      'kalanGun': kalanGun,
    });
    return map;
  }

  static EducationExam fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationExam(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      sinavAdi: map['sinavAdi'] as String? ?? '',
      aciklama: map['aciklama'] as String? ?? '',
      dersId: map['dersId'] as String? ?? '',
      ogretmenId: map['ogretmenId'] as String?,
      ogrenciListesi: List<String>.from(map['ogrenciListesi'] ?? []),
      sinavTarihi:
          (map['sinavTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sinavSaati: (map['sinavSaati'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sure: map['sure'] as int? ?? 60,
      sinavTuru: map['sinavTuru'] as String? ?? 'yazili',
      sinif: map['sinif'] as String? ?? '',
      status: map['status'] as String? ?? 'planned',
      toplamPuan: map['toplamPuan'] as int? ?? 100,
      gecmePuani: map['gecmePuani'] as int? ?? 60,
      sinavSonuclari: map['sinavSonuclari'] as Map<String, dynamic>?,
      ogrenciNotlari: map['ogrenciNotlari'] != null
          ? Map<String, String>.from(map['ogrenciNotlari'])
          : null,
      sorular: List<String>.from(map['sorular'] ?? []),
      sinavMalzemesi: map['sinavMalzemesi'] as String?,
      onlineSlnav: map['onlineSlnav'] as bool? ?? false,
      sinavLinki: map['sinavLinki'] as String?,
      acikKitap: map['acikKitap'] as bool? ?? false,
      istatistikler: map['istatistikler'] as Map<String, dynamic>?,
      degerlendirmeKriteri: map['degerlendirmeKriteri'] as String?,
      sonucAciklamaTarihi: (map['sonucAciklamaTarihi'] as Timestamp?)?.toDate(),
      sonuclarAciklandi: map['sonuclarAciklandi'] as bool? ?? false,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationExam copyWith({
    String? sinavAdi,
    String? aciklama,
    String? dersId,
    String? ogretmenId,
    List<String>? ogrenciListesi,
    DateTime? sinavTarihi,
    DateTime? sinavSaati,
    int? sure,
    String? sinavTuru,
    String? sinif,
    String? status,
    int? toplamPuan,
    int? gecmePuani,
    Map<String, dynamic>? sinavSonuclari,
    Map<String, String>? ogrenciNotlari,
    List<String>? sorular,
    String? sinavMalzemesi,
    bool? onlineSlnav,
    String? sinavLinki,
    bool? acikKitap,
    Map<String, dynamic>? istatistikler,
    String? degerlendirmeKriteri,
    DateTime? sonucAciklamaTarihi,
    bool? sonuclarAciklandi,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationExam(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sinavAdi: sinavAdi ?? this.sinavAdi,
      aciklama: aciklama ?? this.aciklama,
      dersId: dersId ?? this.dersId,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      ogrenciListesi: ogrenciListesi ?? this.ogrenciListesi,
      sinavTarihi: sinavTarihi ?? this.sinavTarihi,
      sinavSaati: sinavSaati ?? this.sinavSaati,
      sure: sure ?? this.sure,
      sinavTuru: sinavTuru ?? this.sinavTuru,
      sinif: sinif ?? this.sinif,
      status: status ?? this.status,
      toplamPuan: toplamPuan ?? this.toplamPuan,
      gecmePuani: gecmePuani ?? this.gecmePuani,
      sinavSonuclari: sinavSonuclari ?? this.sinavSonuclari,
      ogrenciNotlari: ogrenciNotlari ?? this.ogrenciNotlari,
      sorular: sorular ?? this.sorular,
      sinavMalzemesi: sinavMalzemesi ?? this.sinavMalzemesi,
      onlineSlnav: onlineSlnav ?? this.onlineSlnav,
      sinavLinki: sinavLinki ?? this.sinavLinki,
      acikKitap: acikKitap ?? this.acikKitap,
      istatistikler: istatistikler ?? this.istatistikler,
      degerlendirmeKriteri: degerlendirmeKriteri ?? this.degerlendirmeKriteri,
      sonucAciklamaTarihi: sonucAciklamaTarihi ?? this.sonucAciklamaTarihi,
      sonuclarAciklandi: sonuclarAciklandi ?? this.sonuclarAciklandi,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      sinavAdi.isNotEmpty &&
      dersId.isNotEmpty &&
      ogrenciListesi.isNotEmpty &&
      sure > 0 &&
      toplamPuan > 0 &&
      gecmePuani >= 0 &&
      gecmePuani <= toplamPuan;

  @override
  String toString() =>
      'EducationExam(id: $id, sinavAdi: $sinavAdi, tarih: $sinavTarihi, durum: $status)';
}
