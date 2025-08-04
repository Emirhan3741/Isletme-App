import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class EducationAppointment extends BaseModel implements StatusModel {
  final String dersId; // Course ID
  final String? ogrenciId; // Özel ders için student ID
  final List<String> ogrenciListesi; // Grup dersi için student ID'leri
  final String? ogretmenId; // Teacher ID
  final DateTime baslangicZamani;
  final DateTime bitisZamani;
  final String baslik; // Ders başlığı
  final String? aciklama;
  final String tur; // ders, sinav, etkinlik, tatil
  @override
  final String status; // scheduled, confirmed, completed, cancelled, ongoing
  final bool tekrarli; // Tekrar eden ders mi?
  final String? tekrarSikligi; // gunluk, haftalik, aylik
  final List<int>?
      tekrarGunleri; // Haftalık tekrar için günler (1=Pazartesi, 7=Pazar)
  final DateTime? tekrarBitisTarihi; // Tekrarın bittiği tarih
  final String? sinif; // Sınıf/oda bilgisi
  final Map<String, bool>? katilimDurumu; // Student ID -> katıldı mı?
  final Map<String, String>? devamsizlikNedeni; // Student ID -> neden
  final String? odevler; // Verilen ödevler
  final String? notlar; // Ders notları
  final bool odevaVar; // Ödev verildi mi?
  final bool sinavVar; // Sınav var mı?
  final Map<String, dynamic>? sinavSonuclari; // Sınav sonuçları
  final String? materialListesi; // Kullanılan materyaller
  final double? devamOrani; // Katılım oranı
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationAppointment({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.dersId,
    this.ogrenciId,
    this.ogrenciListesi = const [],
    this.ogretmenId,
    required this.baslangicZamani,
    required this.bitisZamani,
    required this.baslik,
    this.aciklama,
    this.tur = 'ders',
    this.status = 'scheduled',
    this.tekrarli = false,
    this.tekrarSikligi,
    this.tekrarGunleri,
    this.tekrarBitisTarihi,
    this.sinif,
    this.katilimDurumu,
    this.devamsizlikNedeni,
    this.odevler,
    this.notlar,
    this.odevaVar = false,
    this.sinavVar = false,
    this.sinavSonuclari,
    this.materialListesi,
    this.devamOrani,
    this.ekstraBilgiler,
  });

  // StatusModel implementation
  @override
  bool get isActive => status != 'cancelled';

  // Ders süresi (dakika)
  int get sureDakika => bitisZamani.difference(baslangicZamani).inMinutes;

  // Formatlanmış süre
  String get formatliSure {
    if (sureDakika < 60) {
      return '$sureDakika dk';
    } else {
      int saat = sureDakika ~/ 60;
      int dakika = sureDakika % 60;
      return dakika > 0 ? '${saat}s ${dakika}dk' : '${saat}s';
    }
  }

  // Ders tipi (grup/özel)
  bool get grupDersi => ogrenciListesi.isNotEmpty;
  String get dersTipi => grupDersi ? 'Grup Dersi' : 'Özel Ders';

  // Katılımcı sayısı
  int get katilimciSayisi => grupDersi ? ogrenciListesi.length : 1;

  // Başlamış mı?
  bool get basladi => DateTime.now().isAfter(baslangicZamani);

  // Bitti mi?
  bool get bitti => DateTime.now().isAfter(bitisZamani);

  // Devam ediyor mu?
  bool get devamEdiyor => basladi && !bitti && status == 'ongoing';

  // Emoji durumu
  String get statusEmoji {
    switch (status) {
      case 'scheduled':
        return '📅';
      case 'confirmed':
        return '✅';
      case 'completed':
        return '🎓';
      case 'cancelled':
        return '❌';
      case 'ongoing':
        return '🔄';
      default:
        return '❓';
    }
  }

  // Durum açıklaması
  String get statusAciklama {
    switch (status) {
      case 'scheduled':
        return 'Planlandı';
      case 'confirmed':
        return 'Onaylandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'ongoing':
        return 'Devam Ediyor';
      default:
        return 'Bilinmeyen';
    }
  }

  // Tür emoji
  String get turEmoji {
    switch (tur) {
      case 'ders':
        return '📚';
      case 'sinav':
        return '📝';
      case 'etkinlik':
        return '🎉';
      case 'tatil':
        return '🏖️';
      default:
        return '📖';
    }
  }

  // Tür açıklaması
  String get turAciklama {
    switch (tur) {
      case 'ders':
        return 'Ders';
      case 'sinav':
        return 'Sınav';
      case 'etkinlik':
        return 'Etkinlik';
      case 'tatil':
        return 'Tatil';
      default:
        return tur;
    }
  }

  // Tekrar bilgisi
  String get tekrarBilgisi {
    if (!tekrarli) return 'Tek seferlik';

    String siklik = '';
    switch (tekrarSikligi) {
      case 'gunluk':
        siklik = 'Her gün';
        break;
      case 'haftalik':
        siklik = 'Her hafta';
        if (tekrarGunleri != null && tekrarGunleri!.isNotEmpty) {
          List<String> gunler = tekrarGunleri!.map((gun) {
            switch (gun) {
              case 1:
                return 'Pzt';
              case 2:
                return 'Sal';
              case 3:
                return 'Çar';
              case 4:
                return 'Per';
              case 5:
                return 'Cum';
              case 6:
                return 'Cmt';
              case 7:
                return 'Paz';
              default:
                return gun.toString();
            }
          }).toList();
          siklik += ' (${gunler.join(', ')})';
        }
        break;
      case 'aylik':
        siklik = 'Her ay';
        break;
      default:
        siklik = tekrarSikligi ?? '';
    }

    return siklik;
  }

  // Katılım oranı hesaplama
  double get hesaplananDevamOrani {
    if (katilimDurumu == null || katilimDurumu!.isEmpty) return 0.0;

    int toplamOgrenci = katilimDurumu!.length;
    int katilan = katilimDurumu!.values.where((katildi) => katildi).length;

    return (katilan / toplamOgrenci) * 100;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'dersId': dersId,
      'ogrenciId': ogrenciId,
      'ogrenciListesi': ogrenciListesi,
      'ogretmenId': ogretmenId,
      'baslangicZamani': Timestamp.fromDate(baslangicZamani),
      'bitisZamani': Timestamp.fromDate(bitisZamani),
      'baslik': baslik,
      'aciklama': aciklama,
      'tur': tur,
      'status': status,
      'tekrarli': tekrarli,
      'tekrarSikligi': tekrarSikligi,
      'tekrarGunleri': tekrarGunleri,
      'tekrarBitisTarihi': tekrarBitisTarihi != null
          ? Timestamp.fromDate(tekrarBitisTarihi!)
          : null,
      'sinif': sinif,
      'katilimDurumu': katilimDurumu,
      'devamsizlikNedeni': devamsizlikNedeni,
      'odevler': odevler,
      'notlar': notlar,
      'odevaVar': odevaVar,
      'sinavVar': sinavVar,
      'sinavSonuclari': sinavSonuclari,
      'materialListesi': materialListesi,
      'devamOrani': devamOrani ?? hesaplananDevamOrani,
      'ekstraBilgiler': ekstraBilgiler,
      'sureDakika': sureDakika, // Arama için
      'dersTipi': dersTipi, // Filtreleme için
      'tekrarBilgisi': tekrarBilgisi, // Görüntüleme için
    });
    return map;
  }

  static EducationAppointment fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationAppointment(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      dersId: map['dersId'] as String? ?? '',
      ogrenciId: map['ogrenciId'] as String?,
      ogrenciListesi: List<String>.from(map['ogrenciListesi'] ?? []),
      ogretmenId: map['ogretmenId'] as String?,
      baslangicZamani:
          (map['baslangicZamani'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bitisZamani: (map['bitisZamani'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 1)),
      baslik: map['baslik'] as String? ?? '',
      aciklama: map['aciklama'] as String?,
      tur: map['tur'] as String? ?? 'ders',
      status: map['status'] as String? ?? 'scheduled',
      tekrarli: map['tekrarli'] as bool? ?? false,
      tekrarSikligi: map['tekrarSikligi'] as String?,
      tekrarGunleri: map['tekrarGunleri'] != null
          ? List<int>.from(map['tekrarGunleri'])
          : null,
      tekrarBitisTarihi: (map['tekrarBitisTarihi'] as Timestamp?)?.toDate(),
      sinif: map['sinif'] as String?,
      katilimDurumu: map['katilimDurumu'] != null
          ? Map<String, bool>.from(map['katilimDurumu'])
          : null,
      devamsizlikNedeni: map['devamsizlikNedeni'] != null
          ? Map<String, String>.from(map['devamsizlikNedeni'])
          : null,
      odevler: map['odevler'] as String?,
      notlar: map['notlar'] as String?,
      odevaVar: map['odevaVar'] as bool? ?? false,
      sinavVar: map['sinavVar'] as bool? ?? false,
      sinavSonuclari: map['sinavSonuclari'] as Map<String, dynamic>?,
      materialListesi: map['materialListesi'] as String?,
      devamOrani: (map['devamOrani'] as num?)?.toDouble(),
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationAppointment copyWith({
    String? dersId,
    String? ogrenciId,
    List<String>? ogrenciListesi,
    String? ogretmenId,
    DateTime? baslangicZamani,
    DateTime? bitisZamani,
    String? baslik,
    String? aciklama,
    String? tur,
    String? status,
    bool? tekrarli,
    String? tekrarSikligi,
    List<int>? tekrarGunleri,
    DateTime? tekrarBitisTarihi,
    String? sinif,
    Map<String, bool>? katilimDurumu,
    Map<String, String>? devamsizlikNedeni,
    String? odevler,
    String? notlar,
    bool? odevaVar,
    bool? sinavVar,
    Map<String, dynamic>? sinavSonuclari,
    String? materialListesi,
    double? devamOrani,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationAppointment(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dersId: dersId ?? this.dersId,
      ogrenciId: ogrenciId ?? this.ogrenciId,
      ogrenciListesi: ogrenciListesi ?? this.ogrenciListesi,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      baslangicZamani: baslangicZamani ?? this.baslangicZamani,
      bitisZamani: bitisZamani ?? this.bitisZamani,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      tur: tur ?? this.tur,
      status: status ?? this.status,
      tekrarli: tekrarli ?? this.tekrarli,
      tekrarSikligi: tekrarSikligi ?? this.tekrarSikligi,
      tekrarGunleri: tekrarGunleri ?? this.tekrarGunleri,
      tekrarBitisTarihi: tekrarBitisTarihi ?? this.tekrarBitisTarihi,
      sinif: sinif ?? this.sinif,
      katilimDurumu: katilimDurumu ?? this.katilimDurumu,
      devamsizlikNedeni: devamsizlikNedeni ?? this.devamsizlikNedeni,
      odevler: odevler ?? this.odevler,
      notlar: notlar ?? this.notlar,
      odevaVar: odevaVar ?? this.odevaVar,
      sinavVar: sinavVar ?? this.sinavVar,
      sinavSonuclari: sinavSonuclari ?? this.sinavSonuclari,
      materialListesi: materialListesi ?? this.materialListesi,
      devamOrani: devamOrani ?? this.devamOrani,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      dersId.isNotEmpty &&
      baslik.isNotEmpty &&
      baslangicZamani.isBefore(bitisZamani) &&
      (ogrenciId != null || ogrenciListesi.isNotEmpty);

  @override
  String toString() =>
      'EducationAppointment(id: $id, baslik: $baslik, baslangic: $baslangicZamani, durum: $status)';
}
