import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String ad;
  final String soyad;
  final String telefon;
  final String? eposta;
  final String? not;
  final DateTime olusturulmaTarihi;
  final String ekleyenKullaniciId;

  CustomerModel({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.eposta,
    this.not,
    required this.olusturulmaTarihi,
    required this.ekleyenKullaniciId,
  });

  // Firestore'dan CustomerModel oluştur
  factory CustomerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerModel(
      id: documentId,
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      telefon: map['telefon'] ?? '',
      eposta: map['eposta'],
      not: map['not'],
      olusturulmaTarihi: (map['olusturulmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ekleyenKullaniciId: map['ekleyenKullaniciId'] ?? '',
    );
  }

  // Firestore DocumentSnapshot'tan oluştur
  factory CustomerModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return CustomerModel.fromMap(data, snapshot.id);
  }

  // Firestore için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'eposta': eposta,
      'not': not,
      'olusturulmaTarihi': Timestamp.fromDate(olusturulmaTarihi),
      'ekleyenKullaniciId': ekleyenKullaniciId,
    };
  }

  // Müşteri bilgilerini güncelle
  CustomerModel copyWith({
    String? id,
    String? ad,
    String? soyad,
    String? telefon,
    String? eposta,
    String? not,
    DateTime? olusturulmaTarihi,
    String? ekleyenKullaniciId,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      eposta: eposta ?? this.eposta,
      not: not ?? this.not,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      ekleyenKullaniciId: ekleyenKullaniciId ?? this.ekleyenKullaniciId,
    );
  }

  // Tam ad döndür
  String get tamAd => '$ad $soyad';

  // Arama için kullanılacak text
  String get aramaMetni => '$ad $soyad $telefon ${eposta ?? ''}'.toLowerCase();

  // Telefon formatla
  String get formatliTelefon {
    if (telefon.length == 10) {
      return '(${telefon.substring(0, 3)}) ${telefon.substring(3, 6)} ${telefon.substring(6)}';
    } else if (telefon.length == 11 && telefon.startsWith('0')) {
      return '+90 (${telefon.substring(1, 4)}) ${telefon.substring(4, 7)} ${telefon.substring(7)}';
    }
    return telefon;
  }

  // Müşteri bilgilerinin geçerli olup olmadığını kontrol et
  bool get isValid {
    return ad.isNotEmpty && 
           soyad.isNotEmpty && 
           telefon.isNotEmpty &&
           telefon.length >= 10;
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, ad: $ad, soyad: $soyad, telefon: $telefon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
} 