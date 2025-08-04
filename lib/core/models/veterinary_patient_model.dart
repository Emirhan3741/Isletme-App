import 'package:cloud_firestore/cloud_firestore.dart';

/// Veteriner kliniği hayvan hasta modeli
class VeterinaryPatient {
  final String id;
  final String kullaniciId; // Sahip kimliği
  final String hayvanAdi;
  final String hayvanTuru; // Kedi, Köpek, Kuş vb.
  final String hayvanCinsi; // Golden Retriever, Persian vb.
  final String? chipNumarasi;
  final DateTime? dogumTarihi;
  final String cinsiyet; // erkek, disi, kısırlaştırılmış
  final double agirlik; // kg
  final String renk;
  final String? ozelNotlar;

  // Sahip bilgileri
  final String sahipAdi;
  final String sahipSoyadi;
  final String sahipTelefon;
  final String? sahipEmail;
  final String? sahipAdres;

  // Tıbbi durum
  final String saglikDurumu; // sağlıklı, kronik_hasta, tedavi_altında
  final String? alerjiler;
  final String? kronikHastalik;
  final String? kullandigiIlaclar;
  final bool kisirlastirilmis;
  final DateTime? kisirlastirmaTarihi;

  // Kayıt bilgileri
  final DateTime kayitTarihi;
  final DateTime guncellemeTarihi;
  final bool aktif;
  final String? sonZiyaretTarihi;
  final String? veterinerNotu;

  const VeterinaryPatient({
    required this.id,
    required this.kullaniciId,
    required this.hayvanAdi,
    required this.hayvanTuru,
    required this.hayvanCinsi,
    this.chipNumarasi,
    this.dogumTarihi,
    required this.cinsiyet,
    required this.agirlik,
    required this.renk,
    this.ozelNotlar,
    required this.sahipAdi,
    required this.sahipSoyadi,
    required this.sahipTelefon,
    this.sahipEmail,
    this.sahipAdres,
    required this.saglikDurumu,
    this.alerjiler,
    this.kronikHastalik,
    this.kullandigiIlaclar,
    required this.kisirlastirilmis,
    this.kisirlastirmaTarihi,
    required this.kayitTarihi,
    required this.guncellemeTarihi,
    required this.aktif,
    this.sonZiyaretTarihi,
    this.veterinerNotu,
  });

  /// Firebase'den model oluştur
  factory VeterinaryPatient.fromMap(
      Map<String, dynamic> map, String documentId) {
    return VeterinaryPatient(
      id: documentId,
      kullaniciId: map['kullaniciId'] ?? '',
      hayvanAdi: map['hayvanAdi'] ?? '',
      hayvanTuru: map['hayvanTuru'] ?? '',
      hayvanCinsi: map['hayvanCinsi'] ?? '',
      chipNumarasi: map['chipNumarasi'],
      dogumTarihi: map['dogumTarihi'] != null
          ? (map['dogumTarihi'] as Timestamp).toDate()
          : null,
      cinsiyet: map['cinsiyet'] ?? '',
      agirlik: (map['agirlik'] ?? 0.0).toDouble(),
      renk: map['renk'] ?? '',
      ozelNotlar: map['ozelNotlar'],
      sahipAdi: map['sahipAdi'] ?? '',
      sahipSoyadi: map['sahipSoyadi'] ?? '',
      sahipTelefon: map['sahipTelefon'] ?? '',
      sahipEmail: map['sahipEmail'],
      sahipAdres: map['sahipAdres'],
      saglikDurumu: map['saglikDurumu'] ?? 'sağlıklı',
      alerjiler: map['alerjiler'],
      kronikHastalik: map['kronikHastalik'],
      kullandigiIlaclar: map['kullandigiIlaclar'],
      kisirlastirilmis: map['kisirlastirilmis'] ?? false,
      kisirlastirmaTarihi: map['kisirlastirmaTarihi'] != null
          ? (map['kisirlastirmaTarihi'] as Timestamp).toDate()
          : null,
      kayitTarihi: map['kayitTarihi'] != null
          ? (map['kayitTarihi'] as Timestamp).toDate()
          : DateTime.now(),
      guncellemeTarihi: map['guncellemeTarihi'] != null
          ? (map['guncellemeTarihi'] as Timestamp).toDate()
          : DateTime.now(),
      aktif: map['aktif'] ?? true,
      sonZiyaretTarihi: map['sonZiyaretTarihi'],
      veterinerNotu: map['veterinerNotu'],
    );
  }

  /// Firebase'e kaydetmek için map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'kullaniciId': kullaniciId,
      'hayvanAdi': hayvanAdi,
      'hayvanTuru': hayvanTuru,
      'hayvanCinsi': hayvanCinsi,
      'chipNumarasi': chipNumarasi,
      'dogumTarihi':
          dogumTarihi != null ? Timestamp.fromDate(dogumTarihi!) : null,
      'cinsiyet': cinsiyet,
      'agirlik': agirlik,
      'renk': renk,
      'ozelNotlar': ozelNotlar,
      'sahipAdi': sahipAdi,
      'sahipSoyadi': sahipSoyadi,
      'sahipTelefon': sahipTelefon,
      'sahipEmail': sahipEmail,
      'sahipAdres': sahipAdres,
      'saglikDurumu': saglikDurumu,
      'alerjiler': alerjiler,
      'kronikHastalik': kronikHastalik,
      'kullandigiIlaclar': kullandigiIlaclar,
      'kisirlastirilmis': kisirlastirilmis,
      'kisirlastirmaTarihi': kisirlastirmaTarihi != null
          ? Timestamp.fromDate(kisirlastirmaTarihi!)
          : null,
      'kayitTarihi': Timestamp.fromDate(kayitTarihi),
      'guncellemeTarihi': Timestamp.fromDate(guncellemeTarihi),
      'aktif': aktif,
      'sonZiyaretTarihi': sonZiyaretTarihi,
      'veterinerNotu': veterinerNotu,
    };
  }

  /// Kopyala ve güncelle
  VeterinaryPatient copyWith({
    String? id,
    String? kullaniciId,
    String? hayvanAdi,
    String? hayvanTuru,
    String? hayvanCinsi,
    String? chipNumarasi,
    DateTime? dogumTarihi,
    String? cinsiyet,
    double? agirlik,
    String? renk,
    String? ozelNotlar,
    String? sahipAdi,
    String? sahipSoyadi,
    String? sahipTelefon,
    String? sahipEmail,
    String? sahipAdres,
    String? saglikDurumu,
    String? alerjiler,
    String? kronikHastalik,
    String? kullandigiIlaclar,
    bool? kisirlastirilmis,
    DateTime? kisirlastirmaTarihi,
    DateTime? kayitTarihi,
    DateTime? guncellemeTarihi,
    bool? aktif,
    String? sonZiyaretTarihi,
    String? veterinerNotu,
  }) {
    return VeterinaryPatient(
      id: id ?? this.id,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      hayvanAdi: hayvanAdi ?? this.hayvanAdi,
      hayvanTuru: hayvanTuru ?? this.hayvanTuru,
      hayvanCinsi: hayvanCinsi ?? this.hayvanCinsi,
      chipNumarasi: chipNumarasi ?? this.chipNumarasi,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      agirlik: agirlik ?? this.agirlik,
      renk: renk ?? this.renk,
      ozelNotlar: ozelNotlar ?? this.ozelNotlar,
      sahipAdi: sahipAdi ?? this.sahipAdi,
      sahipSoyadi: sahipSoyadi ?? this.sahipSoyadi,
      sahipTelefon: sahipTelefon ?? this.sahipTelefon,
      sahipEmail: sahipEmail ?? this.sahipEmail,
      sahipAdres: sahipAdres ?? this.sahipAdres,
      saglikDurumu: saglikDurumu ?? this.saglikDurumu,
      alerjiler: alerjiler ?? this.alerjiler,
      kronikHastalik: kronikHastalik ?? this.kronikHastalik,
      kullandigiIlaclar: kullandigiIlaclar ?? this.kullandigiIlaclar,
      kisirlastirilmis: kisirlastirilmis ?? this.kisirlastirilmis,
      kisirlastirmaTarihi: kisirlastirmaTarihi ?? this.kisirlastirmaTarihi,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      aktif: aktif ?? this.aktif,
      sonZiyaretTarihi: sonZiyaretTarihi ?? this.sonZiyaretTarihi,
      veterinerNotu: veterinerNotu ?? this.veterinerNotu,
    );
  }

  /// Hayvanın yaşı
  int? get yas {
    if (dogumTarihi == null) return null;
    final now = DateTime.now();
    int yas = now.year - dogumTarihi!.year;
    if (now.month < dogumTarihi!.month ||
        (now.month == dogumTarihi!.month && now.day < dogumTarihi!.day)) {
      yas--;
    }
    return yas;
  }

  /// Yaş bilgisi string olarak
  String get yasMetni {
    if (yas == null) return 'Bilinmiyor';
    return '$yas yaşında';
  }

  /// Sahip tam adı
  String get sahipTamAdi => '$sahipAdi $sahipSoyadi';

  /// Hayvan tam bilgisi
  String get hayvanTamBilgi => '$hayvanAdi ($hayvanTuru - $hayvanCinsi)';

  /// Sağlık durumu emoji
  String get saglikDurumuEmoji {
    switch (saglikDurumu.toLowerCase()) {
      case 'sağlıklı':
        return '💚';
      case 'kronik_hasta':
        return '🟡';
      case 'tedavi_altında':
        return '🔴';
      default:
        return '📋';
    }
  }

  /// Sağlık durumu rengi
  String get saglikDurumuRenk {
    switch (saglikDurumu.toLowerCase()) {
      case 'sağlıklı':
        return '#10B981'; // Yeşil
      case 'kronik_hasta':
        return '#F59E0B'; // Sarı
      case 'tedavi_altında':
        return '#EF4444'; // Kırmızı
      default:
        return '#6B7280'; // Gri
    }
  }

  /// Chip numarası var mı?
  bool get chipliMi => chipNumarasi != null && chipNumarasi!.isNotEmpty;

  @override
  String toString() {
    return 'VeterinaryPatient(id: $id, hayvanAdi: $hayvanAdi, sahipAdi: $sahipTamAdi)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VeterinaryPatient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Hayvan türleri sabitleri
class AnimalTypes {
  static const String kopek = 'köpek';
  static const String kedi = 'kedi';
  static const String kus = 'kuş';
  static const String balik = 'balık';
  static const String hamster = 'hamster';
  static const String tavsan = 'tavşan';
  static const String kaplumbaga = 'kaplumbağa';
  static const String iguana = 'iguana';
  static const String yilan = 'yılan';
  static const String diger = 'diğer';

  static const List<String> tumuTurler = [
    kopek,
    kedi,
    kus,
    balik,
    hamster,
    tavsan,
    kaplumbaga,
    iguana,
    yilan,
    diger,
  ];

  static String getTurEmoji(String tur) {
    switch (tur.toLowerCase()) {
      case kopek:
        return '🐕';
      case kedi:
        return '🐱';
      case kus:
        return '🐦';
      case balik:
        return '🐠';
      case hamster:
        return '🐹';
      case tavsan:
        return '🐰';
      case kaplumbaga:
        return '🐢';
      case iguana:
        return '🦎';
      case yilan:
        return '🐍';
      default:
        return '🐾';
    }
  }
}

/// Hayvan cinsiyeti sabitleri
class AnimalGender {
  static const String erkek = 'erkek';
  static const String disi = 'dişi';
  static const String kisirlastirilmisErkek = 'kısırlaştırılmış erkek';
  static const String kisirlastirilmisDisi = 'kısırlaştırılmış dişi';

  static const List<String> tumuCinsiyetler = [
    erkek,
    disi,
    kisirlastirilmisErkek,
    kisirlastirilmisDisi,
  ];
}

/// Sağlık durumu sabitleri
class HealthStatus {
  static const String saglikli = 'sağlıklı';
  static const String kronikHasta = 'kronik_hasta';
  static const String tedaviAltinda = 'tedavi_altında';
  static const String kontrolAltinda = 'kontrol_altında';

  static const List<String> tumuDurumlar = [
    saglikli,
    kronikHasta,
    tedaviAltinda,
    kontrolAltinda,
  ];

  static String getDurumAdi(String durum) {
    switch (durum) {
      case saglikli:
        return 'Sağlıklı';
      case kronikHasta:
        return 'Kronik Hasta';
      case tedaviAltinda:
        return 'Tedavi Altında';
      case kontrolAltinda:
        return 'Kontrol Altında';
      default:
        return durum;
    }
  }
}
