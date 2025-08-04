import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType {
  satilik,
  kiralik,
}

enum PropertyCategory {
  ev,
  apart,
  villa,
  arsaDukkaniOfis,
  isyeri,
  arsa,
}

enum PropertyStatus {
  aktif,
  rezerve,
  satildi,
  kiralandi,
  pasif,
}

class Property {
  final String id;
  final String userId;
  final String baslik;
  final String aciklama;
  final PropertyType tip;
  final PropertyCategory kategori;
  final PropertyStatus durum;
  final double fiyat;
  final String parabirimi;
  final double metrekare;
  final int odaSayisi;
  final int salonSayisi;
  final int banyoSayisi;
  final int balkonSayisi;
  final int kat;
  final int binaYasi;
  final bool asansorVar;
  final bool otoparkVar;
  final bool bahceVar;
  final bool esyaliMi;
  final String sehir;
  final String ilce;
  final String mahalle;
  final String sokak;
  final String adres;
  final double? enlem;
  final double? boylam;
  final List<String> resimler;
  final List<String> ozellikler;
  final String? temsilciId;
  final String? temsilciAdi;
  final String? temsilciTelefon;
  final DateTime olusturmaTarihi;
  final DateTime guncellenmeTarihi;
  final bool isActive;
  final int goruntulemeSayisi;
  final List<String> ilgilenenMusteriler;

  Property({
    required this.id,
    required this.userId,
    required this.baslik,
    required this.aciklama,
    required this.tip,
    required this.kategori,
    required this.durum,
    required this.fiyat,
    this.parabirimi = 'TL',
    required this.metrekare,
    this.odaSayisi = 0,
    this.salonSayisi = 0,
    this.banyoSayisi = 0,
    this.balkonSayisi = 0,
    this.kat = 0,
    this.binaYasi = 0,
    this.asansorVar = false,
    this.otoparkVar = false,
    this.bahceVar = false,
    this.esyaliMi = false,
    required this.sehir,
    required this.ilce,
    required this.mahalle,
    this.sokak = '',
    required this.adres,
    this.enlem,
    this.boylam,
    this.resimler = const [],
    this.ozellikler = const [],
    this.temsilciId,
    this.temsilciAdi,
    this.temsilciTelefon,
    required this.olusturmaTarihi,
    required this.guncellenmeTarihi,
    this.isActive = true,
    this.goruntulemeSayisi = 0,
    this.ilgilenenMusteriler = const [],
  });

  factory Property.fromMap(Map<String, dynamic> map, String id) {
    return Property(
      id: id,
      userId: map['userId'] ?? '',
      baslik: map['baslik'] ?? '',
      aciklama: map['aciklama'] ?? '',
      tip: PropertyType.values.firstWhere(
        (e) => e.toString().split('.').last == map['tip'],
        orElse: () => PropertyType.satilik,
      ),
      kategori: PropertyCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['kategori'],
        orElse: () => PropertyCategory.ev,
      ),
      durum: PropertyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['durum'],
        orElse: () => PropertyStatus.aktif,
      ),
      fiyat: (map['fiyat'] ?? 0).toDouble(),
      parabirimi: map['parabirimi'] ?? 'TL',
      metrekare: (map['metrekare'] ?? 0).toDouble(),
      odaSayisi: map['odaSayisi'] ?? 0,
      salonSayisi: map['salonSayisi'] ?? 0,
      banyoSayisi: map['banyoSayisi'] ?? 0,
      balkonSayisi: map['balkonSayisi'] ?? 0,
      kat: map['kat'] ?? 0,
      binaYasi: map['binaYasi'] ?? 0,
      asansorVar: map['asansorVar'] ?? false,
      otoparkVar: map['otoparkVar'] ?? false,
      bahceVar: map['bahceVar'] ?? false,
      esyaliMi: map['esyaliMi'] ?? false,
      sehir: map['sehir'] ?? '',
      ilce: map['ilce'] ?? '',
      mahalle: map['mahalle'] ?? '',
      sokak: map['sokak'] ?? '',
      adres: map['adres'] ?? '',
      enlem: map['enlem']?.toDouble(),
      boylam: map['boylam']?.toDouble(),
      resimler: List<String>.from(map['resimler'] ?? []),
      ozellikler: List<String>.from(map['ozellikler'] ?? []),
      temsilciId: map['temsilciId'],
      temsilciAdi: map['temsilciAdi'],
      temsilciTelefon: map['temsilciTelefon'],
      olusturmaTarihi:
          (map['olusturmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guncellenmeTarihi:
          (map['guncellenmeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      goruntulemeSayisi: map['goruntulemeSayisi'] ?? 0,
      ilgilenenMusteriler: List<String>.from(map['ilgilenenMusteriler'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'baslik': baslik,
      'aciklama': aciklama,
      'tip': tip.toString().split('.').last,
      'kategori': kategori.toString().split('.').last,
      'durum': durum.toString().split('.').last,
      'fiyat': fiyat,
      'parabirimi': parabirimi,
      'metrekare': metrekare,
      'odaSayisi': odaSayisi,
      'salonSayisi': salonSayisi,
      'banyoSayisi': banyoSayisi,
      'balkonSayisi': balkonSayisi,
      'kat': kat,
      'binaYasi': binaYasi,
      'asansorVar': asansorVar,
      'otoparkVar': otoparkVar,
      'bahceVar': bahceVar,
      'esyaliMi': esyaliMi,
      'sehir': sehir,
      'ilce': ilce,
      'mahalle': mahalle,
      'sokak': sokak,
      'adres': adres,
      'enlem': enlem,
      'boylam': boylam,
      'resimler': resimler,
      'ozellikler': ozellikler,
      'temsilciId': temsilciId,
      'temsilciAdi': temsilciAdi,
      'temsilciTelefon': temsilciTelefon,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'guncellenmeTarihi': Timestamp.fromDate(guncellenmeTarihi),
      'isActive': isActive,
      'goruntulemeSayisi': goruntulemeSayisi,
      'ilgilenenMusteriler': ilgilenenMusteriler,
    };
  }

  String get tipText {
    switch (tip) {
      case PropertyType.satilik:
        return 'Satılık';
      case PropertyType.kiralik:
        return 'Kiralık';
    }
  }

  String get kategoriText {
    switch (kategori) {
      case PropertyCategory.ev:
        return 'Ev';
      case PropertyCategory.apart:
        return 'Apart';
      case PropertyCategory.villa:
        return 'Villa';
      case PropertyCategory.arsaDukkaniOfis:
        return 'Arsa/Dükkan/Ofis';
      case PropertyCategory.isyeri:
        return 'İşyeri';
      case PropertyCategory.arsa:
        return 'Arsa';
    }
  }

  String get durumText {
    switch (durum) {
      case PropertyStatus.aktif:
        return 'Aktif';
      case PropertyStatus.rezerve:
        return 'Rezerve';
      case PropertyStatus.satildi:
        return 'Satıldı';
      case PropertyStatus.kiralandi:
        return 'Kiralandı';
      case PropertyStatus.pasif:
        return 'Pasif';
    }
  }

  String get formatliAdres {
    return '$mahalle, $ilce / $sehir';
  }

  String get formatliOdaBilgisi {
    if (odaSayisi == 0 && salonSayisi == 0) return 'Belirtilmemiş';
    return '${salonSayisi > 0 ? '$salonSayisi+' : ''}${odaSayisi > 0 ? odaSayisi : ''}';
  }

  String get formatliMetrekare {
    return '${metrekare.toInt()} m²';
  }

  String get formatliFiyat {
    if (fiyat >= 1000000) {
      return '${(fiyat / 1000000).toStringAsFixed(1)} M $parabirimi';
    } else if (fiyat >= 1000) {
      return '${(fiyat / 1000).toStringAsFixed(0)}K $parabirimi';
    }
    return '${fiyat.toStringAsFixed(0)} $parabirimi';
  }

  Property copyWith({
    String? id,
    String? userId,
    String? baslik,
    String? aciklama,
    PropertyType? tip,
    PropertyCategory? kategori,
    PropertyStatus? durum,
    double? fiyat,
    String? parabirimi,
    double? metrekare,
    int? odaSayisi,
    int? salonSayisi,
    int? banyoSayisi,
    int? balkonSayisi,
    int? kat,
    int? binaYasi,
    bool? asansorVar,
    bool? otoparkVar,
    bool? bahceVar,
    bool? esyaliMi,
    String? sehir,
    String? ilce,
    String? mahalle,
    String? sokak,
    String? adres,
    double? enlem,
    double? boylam,
    List<String>? resimler,
    List<String>? ozellikler,
    String? temsilciId,
    String? temsilciAdi,
    String? temsilciTelefon,
    DateTime? olusturmaTarihi,
    DateTime? guncellenmeTarihi,
    bool? isActive,
    int? goruntulemeSayisi,
    List<String>? ilgilenenMusteriler,
  }) {
    return Property(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      tip: tip ?? this.tip,
      kategori: kategori ?? this.kategori,
      durum: durum ?? this.durum,
      fiyat: fiyat ?? this.fiyat,
      parabirimi: parabirimi ?? this.parabirimi,
      metrekare: metrekare ?? this.metrekare,
      odaSayisi: odaSayisi ?? this.odaSayisi,
      salonSayisi: salonSayisi ?? this.salonSayisi,
      banyoSayisi: banyoSayisi ?? this.banyoSayisi,
      balkonSayisi: balkonSayisi ?? this.balkonSayisi,
      kat: kat ?? this.kat,
      binaYasi: binaYasi ?? this.binaYasi,
      asansorVar: asansorVar ?? this.asansorVar,
      otoparkVar: otoparkVar ?? this.otoparkVar,
      bahceVar: bahceVar ?? this.bahceVar,
      esyaliMi: esyaliMi ?? this.esyaliMi,
      sehir: sehir ?? this.sehir,
      ilce: ilce ?? this.ilce,
      mahalle: mahalle ?? this.mahalle,
      sokak: sokak ?? this.sokak,
      adres: adres ?? this.adres,
      enlem: enlem ?? this.enlem,
      boylam: boylam ?? this.boylam,
      resimler: resimler ?? this.resimler,
      ozellikler: ozellikler ?? this.ozellikler,
      temsilciId: temsilciId ?? this.temsilciId,
      temsilciAdi: temsilciAdi ?? this.temsilciAdi,
      temsilciTelefon: temsilciTelefon ?? this.temsilciTelefon,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      isActive: isActive ?? this.isActive,
      goruntulemeSayisi: goruntulemeSayisi ?? this.goruntulemeSayisi,
      ilgilenenMusteriler: ilgilenenMusteriler ?? this.ilgilenenMusteriler,
    );
  }
}
