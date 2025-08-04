import 'package:cloud_firestore/cloud_firestore.dart';

enum ContractType {
  satis,
  kira,
}

enum ContractStatus {
  taslak,
  hazir,
  imzalandi,
  tamamlandi,
  iptal,
}

class RealEstateContract {
  final String id;
  final String userId;
  final String ilanId;
  final String musteriId;
  final ContractType tip;
  final ContractStatus durum;
  final double tutar;
  final String parabirimi;
  final double? kapora;
  final double komisyonOrani;
  final double komisyonTutari;
  final DateTime sozlesmeTarihi;
  final DateTime? teslimTarihi;
  final DateTime? bitisTarihi; // Kira sözleşmeleri için
  final int? kiraSuresi; // Ay cinsinden
  final double? aidat;
  final List<String> odemePlanimi;
  final String? notlar;
  final List<String> ekBelgeler;
  final String? saticiId;
  final String? saticiAdi;
  final String? aliciId;
  final String? aliciAdi;
  final DateTime olusturmaTarihi;
  final DateTime guncellenmeTarihi;
  final bool isActive;

  RealEstateContract({
    required this.id,
    required this.userId,
    required this.ilanId,
    required this.musteriId,
    required this.tip,
    this.durum = ContractStatus.taslak,
    required this.tutar,
    this.parabirimi = 'TL',
    this.kapora,
    this.komisyonOrani = 3.0,
    required this.komisyonTutari,
    required this.sozlesmeTarihi,
    this.teslimTarihi,
    this.bitisTarihi,
    this.kiraSuresi,
    this.aidat,
    this.odemePlanimi = const [],
    this.notlar,
    this.ekBelgeler = const [],
    this.saticiId,
    this.saticiAdi,
    this.aliciId,
    this.aliciAdi,
    required this.olusturmaTarihi,
    required this.guncellenmeTarihi,
    this.isActive = true,
  });

  factory RealEstateContract.fromMap(Map<String, dynamic> map, String id) {
    return RealEstateContract(
      id: id,
      userId: map['userId'] ?? '',
      ilanId: map['ilanId'] ?? '',
      musteriId: map['musteriId'] ?? '',
      tip: ContractType.values.firstWhere(
        (e) => e.toString().split('.').last == map['tip'],
        orElse: () => ContractType.satis,
      ),
      durum: ContractStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['durum'],
        orElse: () => ContractStatus.taslak,
      ),
      tutar: (map['tutar'] ?? 0).toDouble(),
      parabirimi: map['parabirimi'] ?? 'TL',
      kapora: map['kapora']?.toDouble(),
      komisyonOrani: (map['komisyonOrani'] ?? 3.0).toDouble(),
      komisyonTutari: (map['komisyonTutari'] ?? 0).toDouble(),
      sozlesmeTarihi:
          (map['sozlesmeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      teslimTarihi: (map['teslimTarihi'] as Timestamp?)?.toDate(),
      bitisTarihi: (map['bitisTarihi'] as Timestamp?)?.toDate(),
      kiraSuresi: map['kiraSuresi'],
      aidat: map['aidat']?.toDouble(),
      odemePlanimi: List<String>.from(map['odemePlanimi'] ?? []),
      notlar: map['notlar'],
      ekBelgeler: List<String>.from(map['ekBelgeler'] ?? []),
      saticiId: map['saticiId'],
      saticiAdi: map['saticiAdi'],
      aliciId: map['aliciId'],
      aliciAdi: map['aliciAdi'],
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
      'ilanId': ilanId,
      'musteriId': musteriId,
      'tip': tip.toString().split('.').last,
      'durum': durum.toString().split('.').last,
      'tutar': tutar,
      'parabirimi': parabirimi,
      'kapora': kapora,
      'komisyonOrani': komisyonOrani,
      'komisyonTutari': komisyonTutari,
      'sozlesmeTarihi': Timestamp.fromDate(sozlesmeTarihi),
      'teslimTarihi':
          teslimTarihi != null ? Timestamp.fromDate(teslimTarihi!) : null,
      'bitisTarihi':
          bitisTarihi != null ? Timestamp.fromDate(bitisTarihi!) : null,
      'kiraSuresi': kiraSuresi,
      'aidat': aidat,
      'odemePlanimi': odemePlanimi,
      'notlar': notlar,
      'ekBelgeler': ekBelgeler,
      'saticiId': saticiId,
      'saticiAdi': saticiAdi,
      'aliciId': aliciId,
      'aliciAdi': aliciAdi,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'guncellenmeTarihi': Timestamp.fromDate(guncellenmeTarihi),
      'isActive': isActive,
    };
  }

  String get tipText {
    switch (tip) {
      case ContractType.satis:
        return 'Satış';
      case ContractType.kira:
        return 'Kira';
    }
  }

  String get durumText {
    switch (durum) {
      case ContractStatus.taslak:
        return 'Taslak';
      case ContractStatus.hazir:
        return 'Hazır';
      case ContractStatus.imzalandi:
        return 'İmzalandı';
      case ContractStatus.tamamlandi:
        return 'Tamamlandı';
      case ContractStatus.iptal:
        return 'İptal';
    }
  }

  String get formattedTutar {
    if (tutar >= 1000000) {
      return '${(tutar / 1000000).toStringAsFixed(1)} M $parabirimi';
    } else if (tutar >= 1000) {
      return '${(tutar / 1000).toStringAsFixed(0)}K $parabirimi';
    }
    return '${tutar.toStringAsFixed(0)} $parabirimi';
  }

  String get formattedKomisyon {
    if (komisyonTutari >= 1000000) {
      return '${(komisyonTutari / 1000000).toStringAsFixed(1)} M $parabirimi';
    } else if (komisyonTutari >= 1000) {
      return '${(komisyonTutari / 1000).toStringAsFixed(0)}K $parabirimi';
    }
    return '${komisyonTutari.toStringAsFixed(0)} $parabirimi';
  }

  String get formattedKapora {
    if (kapora == null) return 'Yok';
    if (kapora! >= 1000000) {
      return '${(kapora! / 1000000).toStringAsFixed(1)} M $parabirimi';
    } else if (kapora! >= 1000) {
      return '${(kapora! / 1000).toStringAsFixed(0)}K $parabirimi';
    }
    return '${kapora!.toStringAsFixed(0)} $parabirimi';
  }

  RealEstateContract copyWith({
    String? id,
    String? userId,
    String? ilanId,
    String? musteriId,
    ContractType? tip,
    ContractStatus? durum,
    double? tutar,
    String? parabirimi,
    double? kapora,
    double? komisyonOrani,
    double? komisyonTutari,
    DateTime? sozlesmeTarihi,
    DateTime? teslimTarihi,
    DateTime? bitisTarihi,
    int? kiraSuresi,
    double? aidat,
    List<String>? odemePlanimi,
    String? notlar,
    List<String>? ekBelgeler,
    String? saticiId,
    String? saticiAdi,
    String? aliciId,
    String? aliciAdi,
    DateTime? olusturmaTarihi,
    DateTime? guncellenmeTarihi,
    bool? isActive,
  }) {
    return RealEstateContract(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ilanId: ilanId ?? this.ilanId,
      musteriId: musteriId ?? this.musteriId,
      tip: tip ?? this.tip,
      durum: durum ?? this.durum,
      tutar: tutar ?? this.tutar,
      parabirimi: parabirimi ?? this.parabirimi,
      kapora: kapora ?? this.kapora,
      komisyonOrani: komisyonOrani ?? this.komisyonOrani,
      komisyonTutari: komisyonTutari ?? this.komisyonTutari,
      sozlesmeTarihi: sozlesmeTarihi ?? this.sozlesmeTarihi,
      teslimTarihi: teslimTarihi ?? this.teslimTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      kiraSuresi: kiraSuresi ?? this.kiraSuresi,
      aidat: aidat ?? this.aidat,
      odemePlanimi: odemePlanimi ?? this.odemePlanimi,
      notlar: notlar ?? this.notlar,
      ekBelgeler: ekBelgeler ?? this.ekBelgeler,
      saticiId: saticiId ?? this.saticiId,
      saticiAdi: saticiAdi ?? this.saticiAdi,
      aliciId: aliciId ?? this.aliciId,
      aliciAdi: aliciAdi ?? this.aliciAdi,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      isActive: isActive ?? this.isActive,
    );
  }
}
