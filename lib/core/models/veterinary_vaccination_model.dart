import 'package:cloud_firestore/cloud_firestore.dart';

/// Veteriner aşı modeli
class VeterinaryVaccination {
  final String id;
  final String kullaniciId;
  final String hastaId; // Hasta (hayvan) kimliği
  final String asiAdi;
  final String? asiMarkasi;
  final String? asiLotNumarasi;
  final DateTime uygulamaTarihi;
  final DateTime? tekrarTarihi;
  final String uygulananBolge; // boyun, arka bacak vb.
  final String? veterinerAdi;
  final String? asiNotu;
  final String durum; // uygulandi, planlandı, gecikti
  final double? asiUcreti;
  final String? yanEtkiler;

  // Aşı kartı bilgileri
  final String asiKartiNumarasi;
  final bool asiKartindaMi;
  final String? asiKartiNotu;

  // Kayıt bilgileri
  final DateTime kayitTarihi;
  final DateTime guncellemeTarihi;
  final bool aktif;

  const VeterinaryVaccination({
    required this.id,
    required this.kullaniciId,
    required this.hastaId,
    required this.asiAdi,
    this.asiMarkasi,
    this.asiLotNumarasi,
    required this.uygulamaTarihi,
    this.tekrarTarihi,
    required this.uygulananBolge,
    this.veterinerAdi,
    this.asiNotu,
    required this.durum,
    this.asiUcreti,
    this.yanEtkiler,
    required this.asiKartiNumarasi,
    required this.asiKartindaMi,
    this.asiKartiNotu,
    required this.kayitTarihi,
    required this.guncellemeTarihi,
    required this.aktif,
  });

  /// Firebase'den model oluştur
  factory VeterinaryVaccination.fromMap(
      Map<String, dynamic> map, String documentId) {
    return VeterinaryVaccination(
      id: documentId,
      kullaniciId: map['kullaniciId'] ?? '',
      hastaId: map['hastaId'] ?? '',
      asiAdi: map['asiAdi'] ?? '',
      asiMarkasi: map['asiMarkasi'],
      asiLotNumarasi: map['asiLotNumarasi'],
      uygulamaTarihi: map['uygulamaTarihi'] != null
          ? (map['uygulamaTarihi'] as Timestamp).toDate()
          : DateTime.now(),
      tekrarTarihi: map['tekrarTarihi'] != null
          ? (map['tekrarTarihi'] as Timestamp).toDate()
          : null,
      uygulananBolge: map['uygulananBolge'] ?? '',
      veterinerAdi: map['veterinerAdi'],
      asiNotu: map['asiNotu'],
      durum: map['durum'] ?? 'planlandı',
      asiUcreti: map['asiUcreti']?.toDouble(),
      yanEtkiler: map['yanEtkiler'],
      asiKartiNumarasi: map['asiKartiNumarasi'] ?? '',
      asiKartindaMi: map['asiKartindaMi'] ?? true,
      asiKartiNotu: map['asiKartiNotu'],
      kayitTarihi: map['kayitTarihi'] != null
          ? (map['kayitTarihi'] as Timestamp).toDate()
          : DateTime.now(),
      guncellemeTarihi: map['guncellemeTarihi'] != null
          ? (map['guncellemeTarihi'] as Timestamp).toDate()
          : DateTime.now(),
      aktif: map['aktif'] ?? true,
    );
  }

  /// Firebase'e kaydetmek için map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'kullaniciId': kullaniciId,
      'hastaId': hastaId,
      'asiAdi': asiAdi,
      'asiMarkasi': asiMarkasi,
      'asiLotNumarasi': asiLotNumarasi,
      'uygulamaTarihi': Timestamp.fromDate(uygulamaTarihi),
      'tekrarTarihi':
          tekrarTarihi != null ? Timestamp.fromDate(tekrarTarihi!) : null,
      'uygulananBolge': uygulananBolge,
      'veterinerAdi': veterinerAdi,
      'asiNotu': asiNotu,
      'durum': durum,
      'asiUcreti': asiUcreti,
      'yanEtkiler': yanEtkiler,
      'asiKartiNumarasi': asiKartiNumarasi,
      'asiKartindaMi': asiKartindaMi,
      'asiKartiNotu': asiKartiNotu,
      'kayitTarihi': Timestamp.fromDate(kayitTarihi),
      'guncellemeTarihi': Timestamp.fromDate(guncellemeTarihi),
      'aktif': aktif,
    };
  }

  /// Kopyala ve güncelle
  VeterinaryVaccination copyWith({
    String? id,
    String? kullaniciId,
    String? hastaId,
    String? asiAdi,
    String? asiMarkasi,
    String? asiLotNumarasi,
    DateTime? uygulamaTarihi,
    DateTime? tekrarTarihi,
    String? uygulananBolge,
    String? veterinerAdi,
    String? asiNotu,
    String? durum,
    double? asiUcreti,
    String? yanEtkiler,
    String? asiKartiNumarasi,
    bool? asiKartindaMi,
    String? asiKartiNotu,
    DateTime? kayitTarihi,
    DateTime? guncellemeTarihi,
    bool? aktif,
  }) {
    return VeterinaryVaccination(
      id: id ?? this.id,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      hastaId: hastaId ?? this.hastaId,
      asiAdi: asiAdi ?? this.asiAdi,
      asiMarkasi: asiMarkasi ?? this.asiMarkasi,
      asiLotNumarasi: asiLotNumarasi ?? this.asiLotNumarasi,
      uygulamaTarihi: uygulamaTarihi ?? this.uygulamaTarihi,
      tekrarTarihi: tekrarTarihi ?? this.tekrarTarihi,
      uygulananBolge: uygulananBolge ?? this.uygulananBolge,
      veterinerAdi: veterinerAdi ?? this.veterinerAdi,
      asiNotu: asiNotu ?? this.asiNotu,
      durum: durum ?? this.durum,
      asiUcreti: asiUcreti ?? this.asiUcreti,
      yanEtkiler: yanEtkiler ?? this.yanEtkiler,
      asiKartiNumarasi: asiKartiNumarasi ?? this.asiKartiNumarasi,
      asiKartindaMi: asiKartindaMi ?? this.asiKartindaMi,
      asiKartiNotu: asiKartiNotu ?? this.asiKartiNotu,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      aktif: aktif ?? this.aktif,
    );
  }

  /// Aşı tekrar tarihi geçti mi?
  bool get tekrarTarihiGectiMi {
    if (tekrarTarihi == null) return false;
    return DateTime.now().isAfter(tekrarTarihi!);
  }

  /// Tekrar tarihine kaç gün kaldı?
  int? get tekrarTarihineKalanGun {
    if (tekrarTarihi == null) return null;
    final gunFarki = tekrarTarihi!.difference(DateTime.now()).inDays;
    return gunFarki;
  }

  /// Aşı durumu emoji
  String get durumEmoji {
    switch (durum.toLowerCase()) {
      case 'uygulandi':
        return '✅';
      case 'planlandı':
        return '📅';
      case 'gecikti':
        return '⚠️';
      case 'iptal':
        return '❌';
      default:
        return '📋';
    }
  }

  /// Aşı durumu rengi
  String get durumRenk {
    switch (durum.toLowerCase()) {
      case 'uygulandi':
        return '#10B981'; // Yeşil
      case 'planlandı':
        return '#3B82F6'; // Mavi
      case 'gecikti':
        return '#F59E0B'; // Sarı
      case 'iptal':
        return '#EF4444'; // Kırmızı
      default:
        return '#6B7280'; // Gri
    }
  }

  /// Formatlanmış ücret
  String get formatliUcret {
    if (asiUcreti == null) return 'Ücretsiz';
    return '₺${asiUcreti!.toStringAsFixed(2)}';
  }

  /// Uygulama tarihi formatı
  String get formatliUygulamaTarihi {
    return '${uygulamaTarihi.day}/${uygulamaTarihi.month}/${uygulamaTarihi.year}';
  }

  /// Tekrar tarihi formatı
  String get formatliTekrarTarihi {
    if (tekrarTarihi == null) return 'Belirlenmedi';
    return '${tekrarTarihi!.day}/${tekrarTarihi!.month}/${tekrarTarihi!.year}';
  }

  @override
  String toString() {
    return 'VeterinaryVaccination(id: $id, asiAdi: $asiAdi, durum: $durum)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VeterinaryVaccination && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Aşı türleri sabitleri
class VaccineTypes {
  static const String rabies = 'Kuduz Aşısı';
  static const String dhpp = 'DHPP (Karma Aşı)';
  static const String feline = 'Kedi Üçlü Aşısı';
  static const String bordetella = 'Bordetella Aşısı';
  static const String lyme = 'Lyme Aşısı';
  static const String leukemia = 'Lösemi Aşısı';
  static const String canineInfluenza = 'Köpek Gribi Aşısı';
  static const String parvo = 'Parvo Aşısı';
  static const String hepatitis = 'Hepatit Aşısı';
  static const String distemper = 'Distemper Aşısı';

  static const List<String> tumuAsilar = [
    rabies,
    dhpp,
    feline,
    bordetella,
    lyme,
    leukemia,
    canineInfluenza,
    parvo,
    hepatitis,
    distemper,
  ];

  static String getAsiEmoji(String asiAdi) {
    if (asiAdi.toLowerCase().contains('kuduz')) return '🦠';
    if (asiAdi.toLowerCase().contains('dhpp')) return '💉';
    if (asiAdi.toLowerCase().contains('kedi')) return '🐱';
    if (asiAdi.toLowerCase().contains('köpek')) return '🐕';
    return '💉';
  }
}

/// Aşı durumu sabitleri
class VaccinationStatus {
  static const String uygulandi = 'uygulandi';
  static const String planlandi = 'planlandı';
  static const String gecikti = 'gecikti';
  static const String iptal = 'iptal';

  static const List<String> tumuDurumlar = [
    uygulandi,
    planlandi,
    gecikti,
    iptal,
  ];
}
