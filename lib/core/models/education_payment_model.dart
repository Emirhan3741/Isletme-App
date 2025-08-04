import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class EducationPayment extends BaseModel implements StatusModel {
  final String ogrenciId;
  final String? dersId;
  final String
      odemeTuru; // ders_ucreti, kayit_ucreti, sinav_ucreti, sertifika_ucreti
  final double tutar;
  final double odenecekTutar; // İndirim sonrası ödenmesi gereken tutar
  final double? indirimMiktari;
  final double? indirimOrani;
  final String? indirimNedeni;
  final DateTime odemeTarihi;
  final DateTime? vadeseTarihi;
  final String odemeTipi; // nakit, kart, havale, pos, online
  @override
  final String status; // paid, pending, partial, overdue, cancelled
  final String? aciklama;
  final String? makbuzNo;
  final String? fisNo;
  final Map<String, dynamic>? odemeDetaylari;
  final List<String>? taksitler; // Taksite böldüyse taksitin payment ID'leri
  final String? parentPaymentId; // Ana ödeme ID'si (taksitlerde)
  final bool taksitliOdeme;
  final int? taksitSayisi;
  final int? hanciTaksit;
  final String? bankaBilgisi;
  final DateTime? odemeTanitTarihi; // Ödemenin tanıtıldığı tarih
  final String? odeyenKisi; // Öğrenci dışında biri ödediyse
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationPayment({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.ogrenciId,
    this.dersId,
    required this.odemeTuru,
    required this.tutar,
    required this.odenecekTutar,
    this.indirimMiktari,
    this.indirimOrani,
    this.indirimNedeni,
    required this.odemeTarihi,
    this.vadeseTarihi,
    required this.odemeTipi,
    this.status = 'pending',
    this.aciklama,
    this.makbuzNo,
    this.fisNo,
    this.odemeDetaylari,
    this.taksitler,
    this.parentPaymentId,
    this.taksitliOdeme = false,
    this.taksitSayisi,
    this.hanciTaksit,
    this.bankaBilgisi,
    this.odemeTanitTarihi,
    this.odeyenKisi,
    this.ekstraBilgiler,
  });

  // StatusModel implementation
  @override
  bool get isActive => status == 'paid' || status == 'partial';

  // Ödeme durumu kontrolü
  bool get odendi => status == 'paid';
  bool get bekliyor => status == 'pending';
  bool get gecikmis => status == 'overdue';
  bool get kismiOdeme => status == 'partial';
  bool get iptalEdildi => status == 'cancelled';

  // Formatlanmış tutarlar
  String get formatliTutar => '₺${tutar.toStringAsFixed(2)}';
  String get formatliOdenecekTutar => '₺${odenecekTutar.toStringAsFixed(2)}';
  String get formatliIndirim => indirimMiktari != null
      ? '₺${indirimMiktari!.toStringAsFixed(2)}'
      : '₺0,00';

  // İndirim durumu
  bool get indirimVar => indirimMiktari != null && indirimMiktari! > 0;

  // Vade durumu
  bool get vadesiGecti {
    if (vadeseTarihi == null) return false;
    return DateTime.now().isAfter(vadeseTarihi!) && !odendi;
  }

  // Kalan gün sayısı
  int? get kalanGun {
    if (vadeseTarihi == null || odendi) return null;
    return vadeseTarihi!.difference(DateTime.now()).inDays;
  }

  // Ödeme türü açıklaması
  String get odemeTuruAciklama {
    switch (odemeTuru) {
      case 'ders_ucreti':
        return 'Ders Ücreti';
      case 'kayit_ucreti':
        return 'Kayıt Ücreti';
      case 'sinav_ucreti':
        return 'Sınav Ücreti';
      case 'sertifika_ucreti':
        return 'Sertifika Ücreti';
      case 'materyal_ucreti':
        return 'Materyal Ücreti';
      case 'diger':
        return 'Diğer';
      default:
        return odemeTuru;
    }
  }

  // Ödeme tipi açıklaması
  String get odemeTipiAciklama {
    switch (odemeTipi) {
      case 'nakit':
        return 'Nakit';
      case 'kart':
        return 'Kredi/Banka Kartı';
      case 'havale':
        return 'Havale/EFT';
      case 'pos':
        return 'POS';
      case 'online':
        return 'Online Ödeme';
      default:
        return odemeTipi;
    }
  }

  // Emoji durumu
  String get statusEmoji {
    switch (status) {
      case 'paid':
        return '✅';
      case 'pending':
        return '⏳';
      case 'partial':
        return '⚠️';
      case 'overdue':
        return '❌';
      case 'cancelled':
        return '🚫';
      default:
        return '❓';
    }
  }

  // Durum açıklaması
  String get statusAciklama {
    switch (status) {
      case 'paid':
        return 'Ödendi';
      case 'pending':
        return 'Bekliyor';
      case 'partial':
        return 'Kısmi Ödeme';
      case 'overdue':
        return 'Vadesi Geçti';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen';
    }
  }

  // Taksit bilgisi
  String get taksitBilgisi {
    if (!taksitliOdeme) return 'Tek seferde';
    if (hanciTaksit != null && taksitSayisi != null) {
      return '$hanciTaksit/$taksitSayisi. Taksit';
    }
    return 'Taksitli';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'ogrenciId': ogrenciId,
      'dersId': dersId,
      'odemeTuru': odemeTuru,
      'tutar': tutar,
      'odenecekTutar': odenecekTutar,
      'indirimMiktari': indirimMiktari,
      'indirimOrani': indirimOrani,
      'indirimNedeni': indirimNedeni,
      'odemeTarihi': Timestamp.fromDate(odemeTarihi),
      'vadeseTarihi':
          vadeseTarihi != null ? Timestamp.fromDate(vadeseTarihi!) : null,
      'odemeTipi': odemeTipi,
      'status': status,
      'aciklama': aciklama,
      'makbuzNo': makbuzNo,
      'fisNo': fisNo,
      'odemeDetaylari': odemeDetaylari,
      'taksitler': taksitler,
      'parentPaymentId': parentPaymentId,
      'taksitliOdeme': taksitliOdeme,
      'taksitSayisi': taksitSayisi,
      'hanciTaksit': hanciTaksit,
      'bankaBilgisi': bankaBilgisi,
      'odemeTanitTarihi': odemeTanitTarihi != null
          ? Timestamp.fromDate(odemeTanitTarihi!)
          : null,
      'odeyenKisi': odeyenKisi,
      'ekstraBilgiler': ekstraBilgiler,
      'odemeTuruAciklama': odemeTuruAciklama, // Arama için
      'vadesiGecti': vadesiGecti, // Filtreleme için
    });
    return map;
  }

  static EducationPayment fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationPayment(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      ogrenciId: map['ogrenciId'] as String? ?? '',
      dersId: map['dersId'] as String?,
      odemeTuru: map['odemeTuru'] as String? ?? '',
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      odenecekTutar: (map['odenecekTutar'] as num?)?.toDouble() ?? 0.0,
      indirimMiktari: (map['indirimMiktari'] as num?)?.toDouble(),
      indirimOrani: (map['indirimOrani'] as num?)?.toDouble(),
      indirimNedeni: map['indirimNedeni'] as String?,
      odemeTarihi:
          (map['odemeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vadeseTarihi: (map['vadeseTarihi'] as Timestamp?)?.toDate(),
      odemeTipi: map['odemeTipi'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      aciklama: map['aciklama'] as String?,
      makbuzNo: map['makbuzNo'] as String?,
      fisNo: map['fisNo'] as String?,
      odemeDetaylari: map['odemeDetaylari'] as Map<String, dynamic>?,
      taksitler:
          map['taksitler'] != null ? List<String>.from(map['taksitler']) : null,
      parentPaymentId: map['parentPaymentId'] as String?,
      taksitliOdeme: map['taksitliOdeme'] as bool? ?? false,
      taksitSayisi: map['taksitSayisi'] as int?,
      hanciTaksit: map['hanciTaksit'] as int?,
      bankaBilgisi: map['bankaBilgisi'] as String?,
      odemeTanitTarihi: (map['odemeTanitTarihi'] as Timestamp?)?.toDate(),
      odeyenKisi: map['odeyenKisi'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationPayment copyWith({
    String? ogrenciId,
    String? dersId,
    String? odemeTuru,
    double? tutar,
    double? odenecekTutar,
    double? indirimMiktari,
    double? indirimOrani,
    String? indirimNedeni,
    DateTime? odemeTarihi,
    DateTime? vadeseTarihi,
    String? odemeTipi,
    String? status,
    String? aciklama,
    String? makbuzNo,
    String? fisNo,
    Map<String, dynamic>? odemeDetaylari,
    List<String>? taksitler,
    String? parentPaymentId,
    bool? taksitliOdeme,
    int? taksitSayisi,
    int? hanciTaksit,
    String? bankaBilgisi,
    DateTime? odemeTanitTarihi,
    String? odeyenKisi,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationPayment(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      ogrenciId: ogrenciId ?? this.ogrenciId,
      dersId: dersId ?? this.dersId,
      odemeTuru: odemeTuru ?? this.odemeTuru,
      tutar: tutar ?? this.tutar,
      odenecekTutar: odenecekTutar ?? this.odenecekTutar,
      indirimMiktari: indirimMiktari ?? this.indirimMiktari,
      indirimOrani: indirimOrani ?? this.indirimOrani,
      indirimNedeni: indirimNedeni ?? this.indirimNedeni,
      odemeTarihi: odemeTarihi ?? this.odemeTarihi,
      vadeseTarihi: vadeseTarihi ?? this.vadeseTarihi,
      odemeTipi: odemeTipi ?? this.odemeTipi,
      status: status ?? this.status,
      aciklama: aciklama ?? this.aciklama,
      makbuzNo: makbuzNo ?? this.makbuzNo,
      fisNo: fisNo ?? this.fisNo,
      odemeDetaylari: odemeDetaylari ?? this.odemeDetaylari,
      taksitler: taksitler ?? this.taksitler,
      parentPaymentId: parentPaymentId ?? this.parentPaymentId,
      taksitliOdeme: taksitliOdeme ?? this.taksitliOdeme,
      taksitSayisi: taksitSayisi ?? this.taksitSayisi,
      hanciTaksit: hanciTaksit ?? this.hanciTaksit,
      bankaBilgisi: bankaBilgisi ?? this.bankaBilgisi,
      odemeTanitTarihi: odemeTanitTarihi ?? this.odemeTanitTarihi,
      odeyenKisi: odeyenKisi ?? this.odeyenKisi,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      ogrenciId.isNotEmpty &&
      odemeTuru.isNotEmpty &&
      tutar > 0 &&
      odenecekTutar >= 0 &&
      odemeTipi.isNotEmpty;

  @override
  String toString() =>
      'EducationPayment(id: $id, ogrenci: $ogrenciId, tutar: $formatliOdenecekTutar, durum: $status)';
}
