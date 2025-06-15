import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String musteriId;
  final String randevuId;
  final String islemAdi;
  final double tutar;
  final String odemeDurumu; // Ödendi / Borç
  final String odemeTipi; // Nakit / Kredi / Havale
  final String not;
  final DateTime tarih;
  final Timestamp olusturulmaTarihi;
  final String ekleyenKullaniciId;

  TransactionModel({
    required this.id,
    required this.musteriId,
    required this.randevuId,
    required this.islemAdi,
    required this.tutar,
    required this.odemeDurumu,
    required this.odemeTipi,
    required this.not,
    required this.tarih,
    required this.olusturulmaTarihi,
    required this.ekleyenKullaniciId,
  });

  // Firestore'dan gelen verileri modele dönüştürme
  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      musteriId: map['musteriId'] ?? '',
      randevuId: map['randevuId'] ?? '',
      islemAdi: map['islemAdi'] ?? '',
      tutar: (map['tutar'] ?? 0.0).toDouble(),
      odemeDurumu: map['odemeDurumu'] ?? 'Borç',
      odemeTipi: map['odemeTipi'] ?? 'Nakit',
      not: map['not'] ?? '',
      tarih: (map['tarih'] as Timestamp).toDate(),
      olusturulmaTarihi: map['olusturulmaTarihi'] ?? Timestamp.now(),
      ekleyenKullaniciId: map['ekleyenKullaniciId'] ?? '',
    );
  }

  // Model verisini Firestore formatına dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'musteriId': musteriId,
      'randevuId': randevuId,
      'islemAdi': islemAdi,
      'tutar': tutar,
      'odemeDurumu': odemeDurumu,
      'odemeTipi': odemeTipi,
      'not': not,
      'tarih': Timestamp.fromDate(tarih),
      'olusturulmaTarihi': olusturulmaTarihi,
      'ekleyenKullaniciId': ekleyenKullaniciId,
    };
  }

  // Model kopyalama fonksiyonu
  TransactionModel copyWith({
    String? id,
    String? musteriId,
    String? randevuId,
    String? islemAdi,
    double? tutar,
    String? odemeDurumu,
    String? odemeTipi,
    String? not,
    DateTime? tarih,
    Timestamp? olusturulmaTarihi,
    String? ekleyenKullaniciId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      musteriId: musteriId ?? this.musteriId,
      randevuId: randevuId ?? this.randevuId,
      islemAdi: islemAdi ?? this.islemAdi,
      tutar: tutar ?? this.tutar,
      odemeDurumu: odemeDurumu ?? this.odemeDurumu,
      odemeTipi: odemeTipi ?? this.odemeTipi,
      not: not ?? this.not,
      tarih: tarih ?? this.tarih,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      ekleyenKullaniciId: ekleyenKullaniciId ?? this.ekleyenKullaniciId,
    );
  }

  @override
  String toString() {
    return 'TransactionModel{id: $id, musteriId: $musteriId, islemAdi: $islemAdi, tutar: $tutar, odemeDurumu: $odemeDurumu}';
  }
}

// Ödeme durumu sabit değerleri
class OdemeDurumu {
  static const String odendi = 'Ödendi';
  static const String borc = 'Borç';
  
  static List<String> get tumDurumlar => [odendi, borc];
}

// Ödeme tipi sabit değerleri
class OdemeTipi {
  static const String nakit = 'Nakit';
  static const String kredi = 'Kredi';
  static const String havale = 'Havale';
  
  static List<String> get tumTipler => [nakit, kredi, havale];
} 