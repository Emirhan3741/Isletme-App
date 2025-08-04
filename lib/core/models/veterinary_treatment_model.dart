import 'package:cloud_firestore/cloud_firestore.dart';

/// Veterinary treatment record model
class VeterinaryTreatment {
  final String id;
  final String kullaniciId;
  final String hastaId;
  final DateTime tedaviTarihi;
  final String tedaviTipi;
  final String tani; // Diagnosis
  final String? tedaviDetayi;
  final String? receteler; // Prescriptions
  final String? notlar;
  final double? ucret;
  final String veterinerAdi;
  final String durum; // completed, ongoing, cancelled
  final List<String>? kullanilanIlaclar;
  final String? kontrolTarihi;
  final int? seansNo;
  final String? yanEtkiler;
  final bool? tedaviBasarili;
  final String? iyilesmeOrani;
  final String? takipNotlari;
  final List<String>? tedaviYontemleri;
  final String? komplikasyonlar;
  final String? tabarcuTarihi;
  final String? yatisGereksinimi;
  final String? laboratuvarSonuclari;
  final String? goruntulemeRaporlari;
  final String? ameliyatNotlari;
  final String? anesteziTipi;

  // Record information
  final DateTime kayitTarihi;
  final DateTime guncellemeTarihi;
  final bool aktif;

  const VeterinaryTreatment({
    required this.id,
    required this.kullaniciId,
    required this.hastaId,
    required this.tedaviTarihi,
    required this.tedaviTipi,
    required this.tani,
    required this.veterinerAdi,
    required this.durum,
    required this.kayitTarihi,
    required this.guncellemeTarihi,
    this.tedaviDetayi,
    this.receteler,
    this.notlar,
    this.ucret,
    this.kullanilanIlaclar,
    this.kontrolTarihi,
    this.seansNo,
    this.yanEtkiler,
    this.tedaviBasarili,
    this.iyilesmeOrani,
    this.takipNotlari,
    this.tedaviYontemleri,
    this.komplikasyonlar,
    this.tabarcuTarihi,
    this.yatisGereksinimi,
    this.laboratuvarSonuclari,
    this.goruntulemeRaporlari,
    this.ameliyatNotlari,
    this.anesteziTipi,
    this.aktif = true,
  });

  /// Create model from Firebase
  factory VeterinaryTreatment.fromMap(Map<String, dynamic> map,
      [String? docId]) {
    return VeterinaryTreatment(
      id: docId ?? map['id'] ?? '',
      kullaniciId: map['kullaniciId'] ?? '',
      hastaId: map['hastaId'] ?? '',
      tedaviTarihi: map['tedaviTarihi']?.toDate() ?? DateTime.now(),
      tedaviTipi: map['tedaviTipi'] ?? '',
      tani: map['tani'] ?? '',
      veterinerAdi: map['veterinerAdi'] ?? '',
      durum: map['durum'] ?? 'ongoing',
      kayitTarihi: map['kayitTarihi']?.toDate() ?? DateTime.now(),
      guncellemeTarihi: map['guncellemeTarihi']?.toDate() ?? DateTime.now(),
      tedaviDetayi: map['tedaviDetayi'],
      receteler: map['receteler'],
      notlar: map['notlar'],
      ucret: map['ucret']?.toDouble(),
      kullanilanIlaclar: List<String>.from(map['kullanilanIlaclar'] ?? []),
      kontrolTarihi: map['kontrolTarihi'],
      seansNo: map['seansNo']?.toInt(),
      yanEtkiler: map['yanEtkiler'],
      tedaviBasarili: map['tedaviBasarili'],
      iyilesmeOrani: map['iyilesmeOrani'],
      takipNotlari: map['takipNotlari'],
      tedaviYontemleri: List<String>.from(map['tedaviYontemleri'] ?? []),
      komplikasyonlar: map['komplikasyonlar'],
      tabarcuTarihi: map['tabarcuTarihi'],
      yatisGereksinimi: map['yatisGereksinimi'],
      laboratuvarSonuclari: map['laboratuvarSonuclari'],
      goruntulemeRaporlari: map['goruntulemeRaporlari'],
      ameliyatNotlari: map['ameliyatNotlari'],
      anesteziTipi: map['anesteziTipi'],
      aktif: map['aktif'] ?? true,
    );
  }

  /// Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kullaniciId': kullaniciId,
      'hastaId': hastaId,
      'tedaviTarihi': Timestamp.fromDate(tedaviTarihi),
      'tedaviTipi': tedaviTipi,
      'tani': tani,
      'veterinerAdi': veterinerAdi,
      'durum': durum,
      'kayitTarihi': Timestamp.fromDate(kayitTarihi),
      'guncellemeTarihi': Timestamp.fromDate(guncellemeTarihi),
      'tedaviDetayi': tedaviDetayi,
      'receteler': receteler,
      'notlar': notlar,
      'ucret': ucret,
      'kullanilanIlaclar': kullanilanIlaclar,
      'kontrolTarihi': kontrolTarihi,
      'seansNo': seansNo,
      'yanEtkiler': yanEtkiler,
      'tedaviBasarili': tedaviBasarili,
      'iyilesmeOrani': iyilesmeOrani,
      'takipNotlari': takipNotlari,
      'tedaviYontemleri': tedaviYontemleri,
      'komplikasyonlar': komplikasyonlar,
      'tabarcuTarihi': tabarcuTarihi,
      'yatisGereksinimi': yatisGereksinimi,
      'laboratuvarSonuclari': laboratuvarSonuclari,
      'goruntulemeRaporlari': goruntulemeRaporlari,
      'ameliyatNotlari': ameliyatNotlari,
      'anesteziTipi': anesteziTipi,
      'aktif': aktif,
    };
  }

  /// Copy and update
  VeterinaryTreatment copyWith({
    String? id,
    String? kullaniciId,
    String? hastaId,
    DateTime? tedaviTarihi,
    String? tedaviTipi,
    String? tani,
    String? veterinerAdi,
    String? durum,
    DateTime? kayitTarihi,
    DateTime? guncellemeTarihi,
    String? tedaviDetayi,
    String? receteler,
    String? notlar,
    double? ucret,
    List<String>? kullanilanIlaclar,
    String? kontrolTarihi,
    int? seansNo,
    String? yanEtkiler,
    bool? tedaviBasarili,
    String? iyilesmeOrani,
    String? takipNotlari,
    List<String>? tedaviYontemleri,
    String? komplikasyonlar,
    String? tabarcuTarihi,
    String? yatisGereksinimi,
    String? laboratuvarSonuclari,
    String? goruntulemeRaporlari,
    String? ameliyatNotlari,
    String? anesteziTipi,
    bool? aktif,
  }) {
    return VeterinaryTreatment(
      id: id ?? this.id,
      kullaniciId: kullaniciId ?? this.kullaniciId,
      hastaId: hastaId ?? this.hastaId,
      tedaviTarihi: tedaviTarihi ?? this.tedaviTarihi,
      tedaviTipi: tedaviTipi ?? this.tedaviTipi,
      tani: tani ?? this.tani,
      veterinerAdi: veterinerAdi ?? this.veterinerAdi,
      durum: durum ?? this.durum,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      tedaviDetayi: tedaviDetayi ?? this.tedaviDetayi,
      receteler: receteler ?? this.receteler,
      notlar: notlar ?? this.notlar,
      ucret: ucret ?? this.ucret,
      kullanilanIlaclar: kullanilanIlaclar ?? this.kullanilanIlaclar,
      kontrolTarihi: kontrolTarihi ?? this.kontrolTarihi,
      seansNo: seansNo ?? this.seansNo,
      yanEtkiler: yanEtkiler ?? this.yanEtkiler,
      tedaviBasarili: tedaviBasarili ?? this.tedaviBasarili,
      iyilesmeOrani: iyilesmeOrani ?? this.iyilesmeOrani,
      takipNotlari: takipNotlari ?? this.takipNotlari,
      tedaviYontemleri: tedaviYontemleri ?? this.tedaviYontemleri,
      komplikasyonlar: komplikasyonlar ?? this.komplikasyonlar,
      tabarcuTarihi: tabarcuTarihi ?? this.tabarcuTarihi,
      yatisGereksinimi: yatisGereksinimi ?? this.yatisGereksinimi,
      laboratuvarSonuclari: laboratuvarSonuclari ?? this.laboratuvarSonuclari,
      goruntulemeRaporlari: goruntulemeRaporlari ?? this.goruntulemeRaporlari,
      ameliyatNotlari: ameliyatNotlari ?? this.ameliyatNotlari,
      anesteziTipi: anesteziTipi ?? this.anesteziTipi,
      aktif: aktif ?? this.aktif,
    );
  }

  // Status color
  String get durumRengi {
    switch (durum) {
      case 'completed':
        return '#10B981'; // Green
      case 'ongoing':
        return '#F59E0B'; // Yellow
      case 'cancelled':
        return '#EF4444'; // Red
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Formatted price
  String get formatliUcret =>
      ucret != null ? '₺${ucret!.toStringAsFixed(0)}' : 'Not specified';

  /// Treatment date format
  String get formatliTarih =>
      '${tedaviTarihi.day}/${tedaviTarihi.month}/${tedaviTarihi.year}';

  /// Duration format
  String get formatliSure {
    return 'Duration not specified';
  }

  /// Check if control is needed
  bool get kontrolGerekli {
    if (kontrolTarihi == null) return false;
    try {
      final kontrolDate = DateTime.parse(kontrolTarihi!);
      return kontrolDate.isBefore(DateTime.now().add(const Duration(days: 7)));
    } catch (e) {
      return false;
    }
  }

  /// Treatment types constants
  static const Map<String, String> tedaviTurleri = {
    'genel_muayene': 'General Examination',
    'asi': 'Vaccination',
    'kisirlastirma': 'Sterilization',
    'disTemizligi': 'Dental Cleaning',
    'ameliyat': 'Surgery',
    'xray': 'X-Ray',
    'laboratuvar': 'Laboratory',
    'tedavi': 'Treatment',
    'bakim': 'Care & Grooming',
  };

  /// Treatment type emoji
  String get tedaviEmojiSi {
    switch (tedaviTipi.toLowerCase()) {
      case 'general examination':
        return '🔍';
      case 'vaccination':
        return '💉';
      case 'sterilization':
        return '✂️';
      case 'dental cleaning':
        return '🦷';
      case 'surgery':
        return '🏥';
      case 'x-ray':
        return '📸';
      case 'laboratory':
        return '🧪';
      case 'treatment':
        return '💊';
      case 'care':
        return '🛁';
      default:
        return '🏥';
    }
  }

  /// Status display name
  String get durumGoruntuAdi {
    switch (durum) {
      case 'completed':
        return 'Completed';
      case 'ongoing':
        return 'Ongoing';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
