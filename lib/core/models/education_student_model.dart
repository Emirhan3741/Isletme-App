import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class EducationStudent extends BaseModel implements StatusModel {
  final String ad;
  final String soyad;
  final String telefon;
  final String? email;
  final String? veliAdi;
  final String? veliTelefon;
  final DateTime dogumTarihi;
  final String? adres;
  final String sinif;
  final String seviye; // Örn: Başlangıç, Orta, İleri
  final List<String> kayitliDersler; // Course ID'leri
  @override
  final String status; // active, inactive, graduated, dropped
  final bool vipOgrenci;
  final bool bursluOgrenci;
  final double? indirimOrani;
  final String? ozelNotlar;
  final String? fotoUrl;
  final Map<String, dynamic>? ekstraBilgiler;
  final DateTime kayitTarihi;

  const EducationStudent({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.email,
    this.veliAdi,
    this.veliTelefon,
    required this.dogumTarihi,
    this.adres,
    required this.sinif,
    required this.seviye,
    required this.kayitliDersler,
    this.status = 'active',
    this.vipOgrenci = false,
    this.bursluOgrenci = false,
    this.indirimOrani,
    this.ozelNotlar,
    this.fotoUrl,
    this.ekstraBilgiler,
    required this.kayitTarihi,
  });

  // Tam isim
  String get tamIsim => '$ad $soyad';

  // Yaş hesaplama
  int get yas {
    final simdi = DateTime.now();
    int yas = simdi.year - dogumTarihi.year;
    if (simdi.month < dogumTarihi.month ||
        (simdi.month == dogumTarihi.month && simdi.day < dogumTarihi.day)) {
      yas--;
    }
    return yas;
  }

  // StatusModel implementation
  @override
  bool get isActive => status == 'active';

  // Öğrenci tipini döndür
  String get ogrenciTipi {
    if (vipOgrenci) return 'VIP';
    if (bursluOgrenci) return 'Burslu';
    return 'Normal';
  }

  // Emoji durumu
  String get statusEmoji {
    switch (status) {
      case 'active':
        return '✅';
      case 'inactive':
        return '⏸️';
      case 'graduated':
        return '🎓';
      case 'dropped':
        return '❌';
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
      case 'graduated':
        return 'Mezun';
      case 'dropped':
        return 'Ayrıldı';
      default:
        return 'Bilinmeyen';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'veliAdi': veliAdi,
      'veliTelefon': veliTelefon,
      'dogumTarihi': Timestamp.fromDate(dogumTarihi),
      'adres': adres,
      'sinif': sinif,
      'seviye': seviye,
      'kayitliDersler': kayitliDersler,
      'status': status,
      'vipOgrenci': vipOgrenci,
      'bursluOgrenci': bursluOgrenci,
      'indirimOrani': indirimOrani,
      'ozelNotlar': ozelNotlar,
      'fotoUrl': fotoUrl,
      'ekstraBilgiler': ekstraBilgiler,
      'kayitTarihi': Timestamp.fromDate(kayitTarihi),
      'tamIsim': tamIsim, // Arama için
      'yas': yas, // Filtreleme için
    });
    return map;
  }

  static EducationStudent fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationStudent(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      ad: map['ad'] as String? ?? '',
      soyad: map['soyad'] as String? ?? '',
      telefon: map['telefon'] as String? ?? '',
      email: map['email'] as String?,
      veliAdi: map['veliAdi'] as String?,
      veliTelefon: map['veliTelefon'] as String?,
      dogumTarihi:
          (map['dogumTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adres: map['adres'] as String?,
      sinif: map['sinif'] as String? ?? '',
      seviye: map['seviye'] as String? ?? 'Başlangıç',
      kayitliDersler: List<String>.from(map['kayitliDersler'] ?? []),
      status: map['status'] as String? ?? 'active',
      vipOgrenci: map['vipOgrenci'] as bool? ?? false,
      bursluOgrenci: map['bursluOgrenci'] as bool? ?? false,
      indirimOrani: (map['indirimOrani'] as num?)?.toDouble(),
      ozelNotlar: map['ozelNotlar'] as String?,
      fotoUrl: map['fotoUrl'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
      kayitTarihi:
          (map['kayitTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  EducationStudent copyWith({
    String? ad,
    String? soyad,
    String? telefon,
    String? email,
    String? veliAdi,
    String? veliTelefon,
    DateTime? dogumTarihi,
    String? adres,
    String? sinif,
    String? seviye,
    List<String>? kayitliDersler,
    String? status,
    bool? vipOgrenci,
    bool? bursluOgrenci,
    double? indirimOrani,
    String? ozelNotlar,
    String? fotoUrl,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? kayitTarihi,
    DateTime? updatedAt,
  }) {
    return EducationStudent(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      veliAdi: veliAdi ?? this.veliAdi,
      veliTelefon: veliTelefon ?? this.veliTelefon,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      adres: adres ?? this.adres,
      sinif: sinif ?? this.sinif,
      seviye: seviye ?? this.seviye,
      kayitliDersler: kayitliDersler ?? this.kayitliDersler,
      status: status ?? this.status,
      vipOgrenci: vipOgrenci ?? this.vipOgrenci,
      bursluOgrenci: bursluOgrenci ?? this.bursluOgrenci,
      indirimOrani: indirimOrani ?? this.indirimOrani,
      ozelNotlar: ozelNotlar ?? this.ozelNotlar,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      ad.isNotEmpty &&
      soyad.isNotEmpty &&
      telefon.isNotEmpty &&
      sinif.isNotEmpty;

  @override
  String toString() =>
      'EducationStudent(id: $id, tamIsim: $tamIsim, sinif: $sinif, status: $status)';
}
