import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor salonu/stüdyo üye modeli
class SportsMember {
  final String? id;
  final String userId; // Spor salonu sahibinin ID'si
  final String ad;
  final String soyad;
  final String telefon;
  final String email;
  final DateTime? dogumTarihi;
  final String cinsiyet;
  final String uyelikTipi; // 'aylık', 'yıllık', 'paket', 'günlük'
  final DateTime uyelikBaslangici;
  final DateTime? uyelikBitisi;
  final String durum; // 'aktif', 'pasif', 'donduruldu'
  final bool isVip;
  final String? hedef; // 'kilo_verme', 'kas_gelistirme', 'kardiyovaskuler'
  final double? boy; // cm
  final double? kilo; // kg
  final String? saglikDurumu;
  final String? antrenmanSeviyesi; // 'başlangıç', 'orta', 'ileri'
  final Map<String, dynamic>? programBilgisi; // Mevcut program
  final List<String>? alerjiListesi;
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
  final String? not;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  SportsMember({
    this.id,
    required this.userId,
    required this.ad,
    required this.soyad,
    required this.telefon,
    required this.email,
    this.dogumTarihi,
    required this.cinsiyet,
    required this.uyelikTipi,
    required this.uyelikBaslangici,
    this.uyelikBitisi,
    this.durum = 'aktif',
    this.isVip = false,
    this.hedef,
    this.boy,
    this.kilo,
    this.saglikDurumu,
    this.antrenmanSeviyesi,
    this.programBilgisi,
    this.alerjiListesi,
    this.acilDurumKisi,
    this.acilDurumTelefon,
    this.not,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Firebase'den veri çekme
  factory SportsMember.fromMap(Map<String, dynamic> map, String id) {
    return SportsMember(
      id: id,
      userId: map['userId'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      telefon: map['telefon'] ?? '',
      email: map['email'] ?? '',
      dogumTarihi: map['dogumTarihi'] != null
          ? (map['dogumTarihi'] as Timestamp).toDate()
          : null,
      cinsiyet: map['cinsiyet'] ?? '',
      uyelikTipi: map['uyelikTipi'] ?? 'aylık',
      uyelikBaslangici: (map['uyelikBaslangici'] as Timestamp).toDate(),
      uyelikBitisi: map['uyelikBitisi'] != null
          ? (map['uyelikBitisi'] as Timestamp).toDate()
          : null,
      durum: map['durum'] ?? 'aktif',
      isVip: map['isVip'] ?? false,
      hedef: map['hedef'],
      boy: map['boy']?.toDouble(),
      kilo: map['kilo']?.toDouble(),
      saglikDurumu: map['saglikDurumu'],
      antrenmanSeviyesi: map['antrenmanSeviyesi'],
      programBilgisi: map['programBilgisi'],
      alerjiListesi: map['alerjiListesi'] != null
          ? List<String>.from(map['alerjiListesi'])
          : null,
      acilDurumKisi: map['acilDurumKisi'],
      acilDurumTelefon: map['acilDurumTelefon'],
      not: map['not'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'dogumTarihi':
          dogumTarihi != null ? Timestamp.fromDate(dogumTarihi!) : null,
      'cinsiyet': cinsiyet,
      'uyelikTipi': uyelikTipi,
      'uyelikBaslangici': Timestamp.fromDate(uyelikBaslangici),
      'uyelikBitisi':
          uyelikBitisi != null ? Timestamp.fromDate(uyelikBitisi!) : null,
      'durum': durum,
      'isVip': isVip,
      'hedef': hedef,
      'boy': boy,
      'kilo': kilo,
      'saglikDurumu': saglikDurumu,
      'antrenmanSeviyesi': antrenmanSeviyesi,
      'programBilgisi': programBilgisi,
      'alerjiListesi': alerjiListesi,
      'acilDurumKisi': acilDurumKisi,
      'acilDurumTelefon': acilDurumTelefon,
      'not': not,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  // Copy with method
  SportsMember copyWith({
    String? id,
    String? userId,
    String? ad,
    String? soyad,
    String? telefon,
    String? email,
    DateTime? dogumTarihi,
    String? cinsiyet,
    String? uyelikTipi,
    DateTime? uyelikBaslangici,
    DateTime? uyelikBitisi,
    String? durum,
    bool? isVip,
    String? hedef,
    double? boy,
    double? kilo,
    String? saglikDurumu,
    String? antrenmanSeviyesi,
    Map<String, dynamic>? programBilgisi,
    List<String>? alerjiListesi,
    String? acilDurumKisi,
    String? acilDurumTelefon,
    String? not,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SportsMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      uyelikTipi: uyelikTipi ?? this.uyelikTipi,
      uyelikBaslangici: uyelikBaslangici ?? this.uyelikBaslangici,
      uyelikBitisi: uyelikBitisi ?? this.uyelikBitisi,
      durum: durum ?? this.durum,
      isVip: isVip ?? this.isVip,
      hedef: hedef ?? this.hedef,
      boy: boy ?? this.boy,
      kilo: kilo ?? this.kilo,
      saglikDurumu: saglikDurumu ?? this.saglikDurumu,
      antrenmanSeviyesi: antrenmanSeviyesi ?? this.antrenmanSeviyesi,
      programBilgisi: programBilgisi ?? this.programBilgisi,
      alerjiListesi: alerjiListesi ?? this.alerjiListesi,
      acilDurumKisi: acilDurumKisi ?? this.acilDurumKisi,
      acilDurumTelefon: acilDurumTelefon ?? this.acilDurumTelefon,
      not: not ?? this.not,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Tam ad
  String get tamAd => '$ad $soyad';

  // Yaş hesaplama
  int? get yas {
    if (dogumTarihi == null) return null;
    final today = DateTime.now();
    int age = today.year - dogumTarihi!.year;
    if (today.month < dogumTarihi!.month ||
        (today.month == dogumTarihi!.month && today.day < dogumTarihi!.day)) {
      age--;
    }
    return age;
  }

  // BMI hesaplama
  double? get bmi {
    if (boy == null || kilo == null || boy == 0) return null;
    return kilo! / ((boy! / 100) * (boy! / 100));
  }

  // Üyelik durumu kontrolü
  bool get uyelikAktifMi {
    if (uyelikBitisi == null) return true;
    return DateTime.now().isBefore(uyelikBitisi!);
  }
}
