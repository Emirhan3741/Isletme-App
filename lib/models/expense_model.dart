import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String kategori;
  final double tutar;
  final DateTime tarih;
  final String not;
  final Timestamp olusturulmaTarihi;
  final String ekleyenKullaniciId;

  ExpenseModel({
    required this.id,
    required this.kategori,
    required this.tutar,
    required this.tarih,
    required this.not,
    required this.olusturulmaTarihi,
    required this.ekleyenKullaniciId,
  });

  // Firestore'dan gelen verileri modele dönüştürme
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      kategori: map['kategori'] ?? '',
      tutar: (map['tutar'] ?? 0.0).toDouble(),
      not: map['not'] ?? '',
      tarih: (map['tarih'] as Timestamp).toDate(),
      olusturulmaTarihi: map['olusturulmaTarihi'] ?? Timestamp.now(),
      ekleyenKullaniciId: map['ekleyenKullaniciId'] ?? '',
    );
  }

  // Model verisini Firestore formatına dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'kategori': kategori,
      'tutar': tutar,
      'not': not,
      'tarih': Timestamp.fromDate(tarih),
      'olusturulmaTarihi': olusturulmaTarihi,
      'ekleyenKullaniciId': ekleyenKullaniciId,
    };
  }

  // Model kopyalama fonksiyonu
  ExpenseModel copyWith({
    String? id,
    String? kategori,
    double? tutar,
    DateTime? tarih,
    String? not,
    Timestamp? olusturulmaTarihi,
    String? ekleyenKullaniciId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      kategori: kategori ?? this.kategori,
      tutar: tutar ?? this.tutar,
      tarih: tarih ?? this.tarih,
      not: not ?? this.not,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      ekleyenKullaniciId: ekleyenKullaniciId ?? this.ekleyenKullaniciId,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel{id: $id, kategori: $kategori, tutar: $tutar, tarih: $tarih}';
  }
}

// Gider kategorileri sabit değerleri
class ExpenseCategory {
  static const String kira = 'Kira';
  static const String elektrik = 'Elektrik';
  static const String su = 'Su';
  static const String dogalgaz = 'Doğalgaz';
  static const String telefon = 'Telefon';
  static const String internet = 'İnternet';
  static const String maas = 'Maaş';
  static const String malzeme = 'Malzeme';
  static const String temizlik = 'Temizlik';
  static const String reklam = 'Reklam';
  static const String vergi = 'Vergi';
  static const String sigorta = 'Sigorta';
  static const String yakıt = 'Yakıt';
  static const String yemek = 'Yemek';
  static const String egitim = 'Eğitim';
  static const String bakim = 'Bakım';
  static const String diger = 'Diğer';

  static List<String> get tumKategoriler => [
        kira,
        elektrik,
        su,
        dogalgaz,
        telefon,
        internet,
        maas,
        malzeme,
        temizlik,
        reklam,
        vergi,
        sigorta,
        yakıt,
        yemek,
        egitim,
        bakim,
        diger,
      ];

  // Kategori ikonları
  static Map<String, String> get kategoriIkonlari => {
        kira: '🏠',
        elektrik: '⚡',
        su: '💧',
        dogalgaz: '🔥',
        telefon: '📞',
        internet: '📶',
        maas: '💰',
        malzeme: '📦',
        temizlik: '🧹',
        reklam: '📢',
        vergi: '📋',
        sigorta: '🛡️',
        yakıt: '⛽',
        yemek: '🍽️',
        egitim: '📚',
        bakim: '🔧',
        diger: '💼',
      };
}