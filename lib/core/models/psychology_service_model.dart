import 'base_model.dart';

class PsychologyService extends BaseModel implements StatusModel {
  final String hizmetAdi;
  final String? aciklama;
  final String kategori; // bireysel, cift, aile, grup, test, online
  final double ucret;
  final int varsayilanSure; // dakika cinsinden
  final String? hedefKitle; // yetiskin, cocuk, ergen, tumu
  final List<String>? uygulamaAlanlari; // depresyon, anksiyete, travma, vs.
  @override
  final String status; // active, inactive
  final String? uzmanlikGereksinimi; // klinik_psikolog, danisman, terapist
  final bool onlineUygun; // Online olarak verilebilir mi?
  final String? malzemeler; // Gerekli malzemeler
  final String? onkosullar; // On kosullar
  final double? indirimliUcret; // Indirimli ucret varsa
  final String? indirimKosulu; // Indirim kosulu
  final List<String>? etiketler; // Arama icin etiketler
  final Map<String, dynamic>? ekstraBilgiler;
  final int? minSeansSayisi; // Minimum seans sayisi
  final int? maxSeansSayisi; // Maksimum seans sayisi
  final String? terapiTuru; // CBT, DBT, EMDR, psikanaliz, vs.

  const PsychologyService({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.hizmetAdi,
    this.aciklama,
    required this.kategori,
    required this.ucret,
    this.varsayilanSure = 50,
    this.hedefKitle,
    this.uygulamaAlanlari,
    this.status = 'active',
    this.uzmanlikGereksinimi,
    this.onlineUygun = true,
    this.malzemeler,
    this.onkosullar,
    this.indirimliUcret,
    this.indirimKosulu,
    this.etiketler,
    this.ekstraBilgiler,
    this.minSeansSayisi,
    this.maxSeansSayisi,
    this.terapiTuru,
  });

  // StatusModel implementation
  @override
  bool get isActive => status == 'active';

  // Hesaplanan özellikler
  String get formatliUcret => '₺${ucret.toStringAsFixed(2)}';

  String get formatliIndirimliUcret => indirimliUcret != null
      ? '₺${indirimliUcret!.toStringAsFixed(2)}'
      : formatliUcret;

  String get kategoriAciklama {
    switch (kategori) {
      case 'bireysel':
        return 'Bireysel Terapi';
      case 'cift':
        return 'Çift Terapisi';
      case 'aile':
        return 'Aile Terapisi';
      case 'grup':
        return 'Grup Terapisi';
      case 'test':
        return 'Psikolojik Test';
      case 'online':
        return 'Online Danışmanlık';
      case 'telefon':
        return 'Telefon Danışmanlığı';
      default:
        return kategori;
    }
  }

  String get hedefKitleAciklama {
    switch (hedefKitle) {
      case 'yetiskin':
        return 'Yetişkin';
      case 'cocuk':
        return 'Çocuk';
      case 'ergen':
        return 'Ergen';
      case 'tumu':
        return 'Tüm Yaş Grupları';
      default:
        return hedefKitle ?? 'Belirtilmemiş';
    }
  }

  String get uzmanlikGereksinimAciklama {
    switch (uzmanlikGereksinimi) {
      case 'klinik_psikolog':
        return 'Klinik Psikolog';
      case 'danişman':
        return 'Psikolojik Danışman';
      case 'terapist':
        return 'Terapist';
      case 'psikiyatrist':
        return 'Psikiyatrist';
      default:
        return uzmanlikGereksinimi ?? 'Belirtilmemiş';
    }
  }

  String get sureFormatli {
    if (varsayilanSure >= 60) {
      final saat = varsayilanSure ~/ 60;
      final dakika = varsayilanSure % 60;
      if (dakika == 0) {
        return '$saat saat';
      } else {
        return '$saat saat $dakika dk';
      }
    } else {
      return '$varsayilanSure dakika';
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'active':
        return '✅';
      case 'inactive':
        return '❌';
      default:
        return '❓';
    }
  }

  String get statusAciklama {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Pasif';
      default:
        return 'Bilinmiyor';
    }
  }

  String get kategoriEmoji {
    switch (kategori) {
      case 'bireysel':
        return '👤';
      case 'cift':
        return '👫';
      case 'aile':
        return '👨‍👩‍👧‍👦';
      case 'grup':
        return '👥';
      case 'test':
        return '📋';
      case 'online':
        return '💻';
      default:
        return '🧠';
    }
  }

  bool get indirimVar => indirimliUcret != null && indirimliUcret! < ucret;

  double get indirimpOrani {
    if (!indirimVar) return 0;
    return ((ucret - indirimliUcret!) / ucret) * 100;
  }

  String get indirimBilgisi {
    if (!indirimVar) return '';
    return '%${indirimpOrani.toStringAsFixed(0)} indirim';
  }

  // Uygun seans sayısı aralığı
  String get seansSayisiAraligi {
    if (minSeansSayisi == null && maxSeansSayisi == null) {
      return 'Sınırsız';
    }
    if (minSeansSayisi != null && maxSeansSayisi != null) {
      return '$minSeansSayisi-$maxSeansSayisi seans';
    }
    if (minSeansSayisi != null) {
      return 'Min $minSeansSayisi seans';
    }
    if (maxSeansSayisi != null) {
      return 'Max $maxSeansSayisi seans';
    }
    return 'Belirtilmemiş';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'hizmetAdi': hizmetAdi,
      'aciklama': aciklama,
      'kategori': kategori,
      'ucret': ucret,
      'varsayilanSure': varsayilanSure,
      'hedefKitle': hedefKitle,
      'uygulamaAlanlari': uygulamaAlanlari,
      'status': status,
      'uzmanlikGereksinimi': uzmanlikGereksinimi,
      'onlineUygun': onlineUygun,
      'malzemeler': malzemeler,
      'onkosullar': onkosullar,
      'indirimliUcret': indirimliUcret,
      'indirimKosulu': indirimKosulu,
      'etiketler': etiketler,
      'ekstraBilgiler': ekstraBilgiler,
      'minSeansSayisi': minSeansSayisi,
      'maxSeansSayisi': maxSeansSayisi,
      'terapiTuru': terapiTuru,
      'kategoriAciklama': kategoriAciklama, // Arama için
      'formatliUcret': formatliUcret, // Filtreleme için
      'indirimVar': indirimVar, // Filtreleme için
    });
    return map;
  }

  static PsychologyService fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return PsychologyService(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      hizmetAdi: map['hizmetAdi'] as String? ?? '',
      aciklama: map['aciklama'] as String?,
      kategori: map['kategori'] as String? ?? 'bireysel',
      ucret: (map['ucret'] as num?)?.toDouble() ?? 0.0,
      varsayilanSure: map['varsayilanSure'] as int? ?? 50,
      hedefKitle: map['hedefKitle'] as String?,
      uygulamaAlanlari: map['uygulamaAlanlari'] != null
          ? List<String>.from(map['uygulamaAlanlari'])
          : null,
      status: map['status'] as String? ?? 'active',
      uzmanlikGereksinimi: map['uzmanlikGereksinimi'] as String?,
      onlineUygun: map['onlineUygun'] as bool? ?? true,
      malzemeler: map['malzemeler'] as String?,
      onkosullar: map['onkosullar'] as String?,
      indirimliUcret: (map['indirimliUcret'] as num?)?.toDouble(),
      indirimKosulu: map['indirimKosulu'] as String?,
      etiketler:
          map['etiketler'] != null ? List<String>.from(map['etiketler']) : null,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
      minSeansSayisi: map['minSeansSayisi'] as int?,
      maxSeansSayisi: map['maxSeansSayisi'] as int?,
      terapiTuru: map['terapiTuru'] as String?,
    );
  }

  PsychologyService copyWith({
    String? hizmetAdi,
    String? aciklama,
    String? kategori,
    double? ucret,
    int? varsayilanSure,
    String? hedefKitle,
    List<String>? uygulamaAlanlari,
    String? status,
    String? uzmanlikGereksinimi,
    bool? onlineUygun,
    String? malzemeler,
    String? onkosullar,
    double? indirimliUcret,
    String? indirimKosulu,
    List<String>? etiketler,
    Map<String, dynamic>? ekstraBilgiler,
    int? minSeansSayisi,
    int? maxSeansSayisi,
    String? terapiTuru,
    DateTime? updatedAt,
  }) {
    return PsychologyService(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      hizmetAdi: hizmetAdi ?? this.hizmetAdi,
      aciklama: aciklama ?? this.aciklama,
      kategori: kategori ?? this.kategori,
      ucret: ucret ?? this.ucret,
      varsayilanSure: varsayilanSure ?? this.varsayilanSure,
      hedefKitle: hedefKitle ?? this.hedefKitle,
      uygulamaAlanlari: uygulamaAlanlari ?? this.uygulamaAlanlari,
      status: status ?? this.status,
      uzmanlikGereksinimi: uzmanlikGereksinimi ?? this.uzmanlikGereksinimi,
      onlineUygun: onlineUygun ?? this.onlineUygun,
      malzemeler: malzemeler ?? this.malzemeler,
      onkosullar: onkosullar ?? this.onkosullar,
      indirimliUcret: indirimliUcret ?? this.indirimliUcret,
      indirimKosulu: indirimKosulu ?? this.indirimKosulu,
      etiketler: etiketler ?? this.etiketler,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
      minSeansSayisi: minSeansSayisi ?? this.minSeansSayisi,
      maxSeansSayisi: maxSeansSayisi ?? this.maxSeansSayisi,
      terapiTuru: terapiTuru ?? this.terapiTuru,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      hizmetAdi.isNotEmpty &&
      kategori.isNotEmpty &&
      ucret >= 0 &&
      varsayilanSure > 0;

  @override
  String toString() =>
      'PsychologyService(id: $id, ad: $hizmetAdi, kategori: $kategori, ucret: $formatliUcret)';
}
