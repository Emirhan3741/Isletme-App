import 'base_model.dart';

class EducationCourse extends BaseModel implements StatusModel, CategoryModel {
  final String dersAdi;
  final String aciklama;
  final String kategori; // Matematik, İngilizce, Müzik, Spor vs.
  final String seviye; // Başlangıç, Orta, İleri, A1, A2, B1, B2, C1, C2
  final String sinifDuzeyi; // 1.sınıf, 2.sınıf, 4.sınıf, Lise vs.
  final int sure; // Dakika cinsinden ders süresi
  final double ucret; // Ders ücreti
  final String ucretTipi; // saatlik, derlik, aylik, donemlik
  final bool grupDersi; // true: grup dersi, false: özel ders
  final int? maxOgrenciSayisi; // Grup dersi için max öğrenci sayısı
  @override
  final String status; // active, inactive, suspended, archived
  final String? ogretmenId; // Varsayılan öğretmen ID
  final List<String> gereksanimler; // Gerekli malzemeler/kitaplar
  final Map<String, dynamic>? dersMufredat; // Ders müfredat bilgileri
  final String? dersKodu; // Ders kodu (MAT101, ENG201 vs.)
  final int? kreditSayisi; // Kredi/puan
  final bool sertifikaVarMi; // Kurs bitiminde sertifika verilir mi
  final String? onKosul; // Ön koşul dersleri
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationCourse({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.dersAdi,
    required this.aciklama,
    required this.kategori,
    required this.seviye,
    required this.sinifDuzeyi,
    required this.sure,
    required this.ucret,
    this.ucretTipi = 'derlik',
    this.grupDersi = true,
    this.maxOgrenciSayisi,
    this.status = 'active',
    this.ogretmenId,
    this.gereksanimler = const [],
    this.dersMufredat,
    this.dersKodu,
    this.kreditSayisi,
    this.sertifikaVarMi = false,
    this.onKosul,
    this.ekstraBilgiler,
  });

  // StatusModel implementation
  @override
  bool get isActive => status == 'active';

  // CategoryModel implementation
  @override
  String get category => kategori;

  @override
  String get categoryDisplayName => _getCategoryDisplayName(kategori);

  // Formatlanmış ücret
  String get formatliUcret => '₺${ucret.toStringAsFixed(0)} / $ucretTipi';

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

  // Ders tipi
  String get dersTipi => grupDersi ? 'Grup Dersi' : 'Özel Ders';

  // Emoji durumu
  String get statusEmoji {
    switch (status) {
      case 'active':
        return '✅';
      case 'inactive':
        return '⏸️';
      case 'suspended':
        return '⚠️';
      case 'archived':
        return '📦';
      default:
        return '❓';
    }
  }

  // Durum açıklaması
  String get statusAciklama {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Pasif';
      case 'suspended':
        return 'Askıda';
      case 'archived':
        return 'Arşivlenmiş';
      default:
        return 'Bilinmeyen';
    }
  }

  // Kategori emoji
  String get kategoriEmoji {
    switch (kategori.toLowerCase()) {
      case 'matematik':
        return '🔢';
      case 'ingilizce':
      case 'dil':
        return '🗣️';
      case 'müzik':
        return '🎵';
      case 'spor':
        return '⚽';
      case 'resim':
      case 'sanat':
        return '🎨';
      case 'bilgisayar':
      case 'programlama':
        return '💻';
      case 'fen':
      case 'fizik':
      case 'kimya':
        return '🔬';
      case 'edebiyat':
      case 'türkçe':
        return '📚';
      case 'tarih':
        return '🏛️';
      case 'coğrafya':
        return '🌍';
      default:
        return '📖';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'dersAdi': dersAdi,
      'aciklama': aciklama,
      'kategori': kategori,
      'seviye': seviye,
      'sinifDuzeyi': sinifDuzeyi,
      'sure': sure,
      'ucret': ucret,
      'ucretTipi': ucretTipi,
      'grupDersi': grupDersi,
      'maxOgrenciSayisi': maxOgrenciSayisi,
      'status': status,
      'ogretmenId': ogretmenId,
      'gereksanimler': gereksanimler,
      'dersMufredat': dersMufredat,
      'dersKodu': dersKodu,
      'kreditSayisi': kreditSayisi,
      'sertifikaVarMi': sertifikaVarMi,
      'onKosul': onKosul,
      'ekstraBilgiler': ekstraBilgiler,
      'formatliUcret': formatliUcret, // Arama için
      'dersTipi': dersTipi, // Filtreleme için
    });
    return map;
  }

  static EducationCourse fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationCourse(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      dersAdi: map['dersAdi'] as String? ?? '',
      aciklama: map['aciklama'] as String? ?? '',
      kategori: map['kategori'] as String? ?? '',
      seviye: map['seviye'] as String? ?? 'Başlangıç',
      sinifDuzeyi: map['sinifDuzeyi'] as String? ?? '',
      sure: map['sure'] as int? ?? 60,
      ucret: (map['ucret'] as num?)?.toDouble() ?? 0.0,
      ucretTipi: map['ucretTipi'] as String? ?? 'derlik',
      grupDersi: map['grupDersi'] as bool? ?? true,
      maxOgrenciSayisi: map['maxOgrenciSayisi'] as int?,
      status: map['status'] as String? ?? 'active',
      ogretmenId: map['ogretmenId'] as String?,
      gereksanimler: List<String>.from(map['gereksanimler'] ?? []),
      dersMufredat: map['dersMufredat'] as Map<String, dynamic>?,
      dersKodu: map['dersKodu'] as String?,
      kreditSayisi: map['kreditSayisi'] as int?,
      sertifikaVarMi: map['sertifikaVarMi'] as bool? ?? false,
      onKosul: map['onKosul'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationCourse copyWith({
    String? dersAdi,
    String? aciklama,
    String? kategori,
    String? seviye,
    String? sinifDuzeyi,
    int? sure,
    double? ucret,
    String? ucretTipi,
    bool? grupDersi,
    int? maxOgrenciSayisi,
    String? status,
    String? ogretmenId,
    List<String>? gereksanimler,
    Map<String, dynamic>? dersMufredat,
    String? dersKodu,
    int? kreditSayisi,
    bool? sertifikaVarMi,
    String? onKosul,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationCourse(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dersAdi: dersAdi ?? this.dersAdi,
      aciklama: aciklama ?? this.aciklama,
      kategori: kategori ?? this.kategori,
      seviye: seviye ?? this.seviye,
      sinifDuzeyi: sinifDuzeyi ?? this.sinifDuzeyi,
      sure: sure ?? this.sure,
      ucret: ucret ?? this.ucret,
      ucretTipi: ucretTipi ?? this.ucretTipi,
      grupDersi: grupDersi ?? this.grupDersi,
      maxOgrenciSayisi: maxOgrenciSayisi ?? this.maxOgrenciSayisi,
      status: status ?? this.status,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      gereksanimler: gereksanimler ?? this.gereksanimler,
      dersMufredat: dersMufredat ?? this.dersMufredat,
      dersKodu: dersKodu ?? this.dersKodu,
      kreditSayisi: kreditSayisi ?? this.kreditSayisi,
      sertifikaVarMi: sertifikaVarMi ?? this.sertifikaVarMi,
      onKosul: onKosul ?? this.onKosul,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'matematik':
        return 'Matematik';
      case 'ingilizce':
        return 'İngilizce';
      case 'dil':
        return 'Dil Dersleri';
      case 'müzik':
        return 'Müzik';
      case 'spor':
        return 'Spor';
      case 'resim':
        return 'Resim';
      case 'sanat':
        return 'Sanat';
      case 'bilgisayar':
        return 'Bilgisayar';
      case 'programlama':
        return 'Programlama';
      case 'fen':
        return 'Fen Bilimleri';
      case 'fizik':
        return 'Fizik';
      case 'kimya':
        return 'Kimya';
      case 'edebiyat':
        return 'Edebiyat';
      case 'türkçe':
        return 'Türkçe';
      case 'tarih':
        return 'Tarih';
      case 'coğrafya':
        return 'Coğrafya';
      default:
        return category;
    }
  }

  @override
  bool get isValid =>
      super.isValid &&
      dersAdi.isNotEmpty &&
      kategori.isNotEmpty &&
      seviye.isNotEmpty &&
      sinifDuzeyi.isNotEmpty &&
      sure > 0 &&
      ucret >= 0;

  @override
  String toString() =>
      'EducationCourse(id: $id, dersAdi: $dersAdi, kategori: $kategori, ucret: $formatliUcret)';
}
