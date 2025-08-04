import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'base_model.dart';

class CourtDateModel extends BaseModel {
  final String caseId;
  final String clientId;
  final String baslik;
  final DateTime durusmaTarihi;
  final TimeOfDay durusmaSaati;
  final String mahkemeAdi;
  final String salonNo;
  final String durusmaTuru;
  final String durusmaDurumu;
  final String? hakim;
  final String? savci;
  final String? kararNotu;
  final String? sonrakiIslem;
  final DateTime? sonrakiDurusma;
  final String? hazirlikNotlari;
  final String? durusmaNotlari;
  final String? sonucNotlari;
  final bool hatirlaticiAktif;
  final int hatirlaticiSuresi; // dakika cinsinden
  final List<String> belgeler;
  final List<String> katilimcilar;
  final bool isActive;

  const CourtDateModel({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? updatedAt,
    required this.caseId,
    required this.clientId,
    required this.baslik,
    required this.durusmaTarihi,
    required this.durusmaSaati,
    required this.mahkemeAdi,
    this.salonNo = '',
    required this.durusmaTuru,
    this.durusmaDurumu = 'bekliyor',
    this.hakim,
    this.savci,
    this.kararNotu,
    this.sonrakiIslem,
    this.sonrakiDurusma,
    this.hazirlikNotlari,
    this.durusmaNotlari,
    this.sonucNotlari,
    this.hatirlaticiAktif = true,
    this.hatirlaticiSuresi = 60, // 1 saat önceden
    this.belgeler = const [],
    this.katilimcilar = const [],
    this.isActive = true,
  }) : super(
          id: id,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // Duruşma durumu kontrolleri
  bool get bekliyor => durusmaDurumu == 'bekliyor';
  bool get tamamlandi => durusmaDurumu == 'tamamlandi';
  bool get ertelendi => durusmaDurumu == 'ertelendi';
  bool get iptal => durusmaDurumu == 'iptal';

  // Duruşma türü kontrolleri
  bool get ilkInceleme => durusmaTuru == 'ilk_inceleme';
  bool get hazirlik => durusmaTuru == 'hazirlik';
  bool get esasInceleme => durusmaTuru == 'esas_inceleme';
  bool get karar => durusmaTuru == 'karar';

  // Zaman kontrolleri
  DateTime get durusmaDateTime {
    return DateTime(
      durusmaTarihi.year,
      durusmaTarihi.month,
      durusmaTarihi.day,
      durusmaSaati.hour,
      durusmaSaati.minute,
    );
  }

  bool get gecmisDurusma {
    return durusmaDateTime.isBefore(DateTime.now());
  }

  bool get bugunDurusma {
    final bugun = DateTime.now();
    return durusmaTarihi.year == bugun.year &&
        durusmaTarihi.month == bugun.month &&
        durusmaTarihi.day == bugun.day;
  }

  bool get yarinDurusma {
    final yarin = DateTime.now().add(const Duration(days: 1));
    return durusmaTarihi.year == yarin.year &&
        durusmaTarihi.month == yarin.month &&
        durusmaTarihi.day == yarin.day;
  }

  bool get haftaIcindeKiDurusma {
    final kacGunKaldi = durusmaTarihi.difference(DateTime.now()).inDays;
    return kacGunKaldi >= 0 && kacGunKaldi <= 7;
  }

  int get kalanGun {
    return durusmaTarihi.difference(DateTime.now()).inDays;
  }

  // Hatırlatıcı zamanı
  DateTime get hatirlaticiZamani {
    return durusmaDateTime.subtract(Duration(minutes: hatirlaticiSuresi));
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'caseId': caseId,
      'clientId': clientId,
      'baslik': baslik,
      'durusmaTarihi': Timestamp.fromDate(durusmaTarihi),
      'durusmaSaati': {
        'hour': durusmaSaati.hour,
        'minute': durusmaSaati.minute,
      },
      'mahkemeAdi': mahkemeAdi,
      'salonNo': salonNo,
      'durusmaTuru': durusmaTuru,
      'durusmaDurumu': durusmaDurumu,
      'hakim': hakim,
      'savci': savci,
      'kararNotu': kararNotu,
      'sonrakiIslem': sonrakiIslem,
      'sonrakiDurusma':
          sonrakiDurusma != null ? Timestamp.fromDate(sonrakiDurusma!) : null,
      'hazirlikNotlari': hazirlikNotlari,
      'durusmaNotlari': durusmaNotlari,
      'sonucNotlari': sonucNotlari,
      'hatirlaticiAktif': hatirlaticiAktif,
      'hatirlaticiSuresi': hatirlaticiSuresi,
      'belgeler': belgeler,
      'katilimcilar': katilimcilar,
      'isActive': isActive,
    });
    return map;
  }

  factory CourtDateModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);
    final saatMap = map['durusmaSaati'] as Map<String, dynamic>? ?? {};

    return CourtDateModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      caseId: map['caseId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      baslik: map['baslik'] as String? ?? '',
      durusmaTarihi:
          (map['durusmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durusmaSaati: TimeOfDay(
        hour: saatMap['hour'] as int? ?? 9,
        minute: saatMap['minute'] as int? ?? 0,
      ),
      mahkemeAdi: map['mahkemeAdi'] as String? ?? '',
      salonNo: map['salonNo'] as String? ?? '',
      durusmaTuru: map['durusmaTuru'] as String? ?? 'hazirlik',
      durusmaDurumu: map['durusmaDurumu'] as String? ?? 'bekliyor',
      hakim: map['hakim'] as String?,
      savci: map['savci'] as String?,
      kararNotu: map['kararNotu'] as String?,
      sonrakiIslem: map['sonrakiIslem'] as String?,
      sonrakiDurusma: (map['sonrakiDurusma'] as Timestamp?)?.toDate(),
      hazirlikNotlari: map['hazirlikNotlari'] as String?,
      durusmaNotlari: map['durusmaNotlari'] as String?,
      sonucNotlari: map['sonucNotlari'] as String?,
      hatirlaticiAktif: map['hatirlaticiAktif'] as bool? ?? true,
      hatirlaticiSuresi: map['hatirlaticiSuresi'] as int? ?? 60,
      belgeler: List<String>.from(map['belgeler'] ?? []),
      katilimcilar: List<String>.from(map['katilimcilar'] ?? []),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  CourtDateModel copyWith({
    String? caseId,
    String? clientId,
    String? baslik,
    DateTime? durusmaTarihi,
    TimeOfDay? durusmaSaati,
    String? mahkemeAdi,
    String? salonNo,
    String? durusmaTuru,
    String? durusmaDurumu,
    String? hakim,
    String? savci,
    String? kararNotu,
    String? sonrakiIslem,
    DateTime? sonrakiDurusma,
    String? hazirlikNotlari,
    String? durusmaNotlari,
    String? sonucNotlari,
    bool? hatirlaticiAktif,
    int? hatirlaticiSuresi,
    List<String>? belgeler,
    List<String>? katilimcilar,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return CourtDateModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      caseId: caseId ?? this.caseId,
      clientId: clientId ?? this.clientId,
      baslik: baslik ?? this.baslik,
      durusmaTarihi: durusmaTarihi ?? this.durusmaTarihi,
      durusmaSaati: durusmaSaati ?? this.durusmaSaati,
      mahkemeAdi: mahkemeAdi ?? this.mahkemeAdi,
      salonNo: salonNo ?? this.salonNo,
      durusmaTuru: durusmaTuru ?? this.durusmaTuru,
      durusmaDurumu: durusmaDurumu ?? this.durusmaDurumu,
      hakim: hakim ?? this.hakim,
      savci: savci ?? this.savci,
      kararNotu: kararNotu ?? this.kararNotu,
      sonrakiIslem: sonrakiIslem ?? this.sonrakiIslem,
      sonrakiDurusma: sonrakiDurusma ?? this.sonrakiDurusma,
      hazirlikNotlari: hazirlikNotlari ?? this.hazirlikNotlari,
      durusmaNotlari: durusmaNotlari ?? this.durusmaNotlari,
      sonucNotlari: sonucNotlari ?? this.sonucNotlari,
      hatirlaticiAktif: hatirlaticiAktif ?? this.hatirlaticiAktif,
      hatirlaticiSuresi: hatirlaticiSuresi ?? this.hatirlaticiSuresi,
      belgeler: belgeler ?? this.belgeler,
      katilimcilar: katilimcilar ?? this.katilimcilar,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'CourtDateModel(id: $id, baslik: $baslik, durusmaTarihi: $durusmaTarihi)';
}

// Duruşma türü sabitleri
class DurusmaTuruConstants {
  static const String ilkInceleme = 'ilk_inceleme';
  static const String hazirlik = 'hazirlik';
  static const String esasInceleme = 'esas_inceleme';
  static const String karar = 'karar';
  static const String temyiz = 'temyiz';
  static const String icra = 'icra';

  static const List<String> tumTurler = [
    ilkInceleme,
    hazirlik,
    esasInceleme,
    karar,
    temyiz,
    icra,
  ];

  static String getTurDisplayName(String tur) {
    switch (tur) {
      case ilkInceleme:
        return 'İlk İnceleme';
      case hazirlik:
        return 'Hazırlık';
      case esasInceleme:
        return 'Esas İnceleme';
      case karar:
        return 'Karar';
      case temyiz:
        return 'Temyiz';
      case icra:
        return 'İcra';
      default:
        return tur;
    }
  }
}

// Duruşma durumu sabitleri
class DurusmaDurumuConstants {
  static const String bekliyor = 'bekliyor';
  static const String tamamlandi = 'tamamlandi';
  static const String ertelendi = 'ertelendi';
  static const String iptal = 'iptal';

  static const List<String> tumDurumlar = [
    bekliyor,
    tamamlandi,
    ertelendi,
    iptal,
  ];

  static String getDurumDisplayName(String durum) {
    switch (durum) {
      case bekliyor:
        return 'Bekliyor';
      case tamamlandi:
        return 'Tamamlandı';
      case ertelendi:
        return 'Ertelendi';
      case iptal:
        return 'İptal';
      default:
        return durum;
    }
  }
}
