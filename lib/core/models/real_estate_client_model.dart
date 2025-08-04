import 'package:cloud_firestore/cloud_firestore.dart';

enum ClientType {
  alici,
  satici,
  kiralayan,
  kiralayici,
}

enum ClientStatus {
  potansiyel,
  aktif,
  sozlesme,
  tamamlandi,
  iptal,
}

class RealEstateClient {
  final String id;
  final String userId;
  final String ad;
  final String soyad;
  final String telefon;
  final String? email;
  final String? adres;
  final ClientType tip;
  final ClientStatus durum;
  final double? butce;
  final String? istenenSehir;
  final String? istenenIlce;
  final String? istenenMahalle;
  final List<String> ilgilenenIlanlar;
  final List<String> randevuGecmisi;
  final List<String> teklifier;
  final String? notlar;
  final DateTime olusturmaTarihi;
  final DateTime guncellenmeTarihi;
  final bool isActive;

  RealEstateClient({
    required this.id,
    required this.userId,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.email,
    this.adres,
    required this.tip,
    this.durum = ClientStatus.potansiyel,
    this.butce,
    this.istenenSehir,
    this.istenenIlce,
    this.istenenMahalle,
    this.ilgilenenIlanlar = const [],
    this.randevuGecmisi = const [],
    this.teklifier = const [],
    this.notlar,
    required this.olusturmaTarihi,
    required this.guncellenmeTarihi,
    this.isActive = true,
  });

  factory RealEstateClient.fromMap(Map<String, dynamic> map, String id) {
    return RealEstateClient(
      id: id,
      userId: map['userId'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      telefon: map['telefon'] ?? '',
      email: map['email'],
      adres: map['adres'],
      tip: ClientType.values.firstWhere(
        (e) => e.toString().split('.').last == map['tip'],
        orElse: () => ClientType.alici,
      ),
      durum: ClientStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['durum'],
        orElse: () => ClientStatus.potansiyel,
      ),
      butce: map['butce']?.toDouble(),
      istenenSehir: map['istenenSehir'],
      istenenIlce: map['istenenIlce'],
      istenenMahalle: map['istenenMahalle'],
      ilgilenenIlanlar: List<String>.from(map['ilgilenenIlanlar'] ?? []),
      randevuGecmisi: List<String>.from(map['randevuGecmisi'] ?? []),
      teklifier: List<String>.from(map['teklifier'] ?? []),
      notlar: map['notlar'],
      olusturmaTarihi:
          (map['olusturmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guncellenmeTarihi:
          (map['guncellenmeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'adres': adres,
      'tip': tip.toString().split('.').last,
      'durum': durum.toString().split('.').last,
      'butce': butce,
      'istenenSehir': istenenSehir,
      'istenenIlce': istenenIlce,
      'istenenMahalle': istenenMahalle,
      'ilgilenenIlanlar': ilgilenenIlanlar,
      'randevuGecmisi': randevuGecmisi,
      'teklifier': teklifier,
      'notlar': notlar,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'guncellenmeTarihi': Timestamp.fromDate(guncellenmeTarihi),
      'isActive': isActive,
    };
  }

  String get tamAdi => '$ad $soyad';

  String get tipText {
    switch (tip) {
      case ClientType.alici:
        return 'Alıcı';
      case ClientType.satici:
        return 'Satıcı';
      case ClientType.kiralayan:
        return 'Kiralayan';
      case ClientType.kiralayici:
        return 'Kiralayıcı';
    }
  }

  String get durumText {
    switch (durum) {
      case ClientStatus.potansiyel:
        return 'Potansiyel';
      case ClientStatus.aktif:
        return 'Aktif';
      case ClientStatus.sozlesme:
        return 'Sözleşme';
      case ClientStatus.tamamlandi:
        return 'Tamamlandı';
      case ClientStatus.iptal:
        return 'İptal';
    }
  }

  String get formattedButce {
    if (butce == null) return 'Belirtilmemiş';
    if (butce! >= 1000000) {
      return '${(butce! / 1000000).toStringAsFixed(1)} M TL';
    } else if (butce! >= 1000) {
      return '${(butce! / 1000).toStringAsFixed(0)}K TL';
    }
    return '${butce!.toStringAsFixed(0)} TL';
  }

  String get istenenBolge {
    if (istenenMahalle != null && istenenIlce != null && istenenSehir != null) {
      return '$istenenMahalle, $istenenIlce / $istenenSehir';
    } else if (istenenIlce != null && istenenSehir != null) {
      return '$istenenIlce / $istenenSehir';
    } else if (istenenSehir != null) {
      return istenenSehir!;
    }
    return 'Belirtilmemiş';
  }

  RealEstateClient copyWith({
    String? id,
    String? userId,
    String? ad,
    String? soyad,
    String? telefon,
    String? email,
    String? adres,
    ClientType? tip,
    ClientStatus? durum,
    double? butce,
    String? istenenSehir,
    String? istenenIlce,
    String? istenenMahalle,
    List<String>? ilgilenenIlanlar,
    List<String>? randevuGecmisi,
    List<String>? teklifier,
    String? notlar,
    DateTime? olusturmaTarihi,
    DateTime? guncellenmeTarihi,
    bool? isActive,
  }) {
    return RealEstateClient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      adres: adres ?? this.adres,
      tip: tip ?? this.tip,
      durum: durum ?? this.durum,
      butce: butce ?? this.butce,
      istenenSehir: istenenSehir ?? this.istenenSehir,
      istenenIlce: istenenIlce ?? this.istenenIlce,
      istenenMahalle: istenenMahalle ?? this.istenenMahalle,
      ilgilenenIlanlar: ilgilenenIlanlar ?? this.ilgilenenIlanlar,
      randevuGecmisi: randevuGecmisi ?? this.randevuGecmisi,
      teklifier: teklifier ?? this.teklifier,
      notlar: notlar ?? this.notlar,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      isActive: isActive ?? this.isActive,
    );
  }
}
