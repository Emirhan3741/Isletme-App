import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'base_model.dart';

// Gider Türleri
enum EducationExpenseType {
  rent('rent', 'Kira'),
  utilities('utilities', 'Faturalar'),
  supplies('supplies', 'Malzemeler'),
  books('books', 'Kitaplar'),
  equipment('equipment', 'Ekipman'),
  salary('salary', 'Maaş'),
  marketing('marketing', 'Pazarlama'),
  maintenance('maintenance', 'Bakım'),
  insurance('insurance', 'Sigorta'),
  license('license', 'Lisans'),
  training('training', 'Eğitim'),
  transport('transport', 'Ulaşım'),
  stationery('stationery', 'Kırtasiye'),
  software('software', 'Yazılım'),
  other('other', 'Diğer');

  const EducationExpenseType(this.value, this.displayName);
  final String value;
  final String displayName;
}

extension EducationExpenseTypeExtension on EducationExpenseType {
  IconData get icon {
    switch (this) {
      case EducationExpenseType.rent:
        return Icons.home;
      case EducationExpenseType.utilities:
        return Icons.electrical_services;
      case EducationExpenseType.supplies:
        return Icons.inventory_2;
      case EducationExpenseType.books:
        return Icons.menu_book;
      case EducationExpenseType.equipment:
        return Icons.devices;
      case EducationExpenseType.salary:
        return Icons.payments;
      case EducationExpenseType.marketing:
        return Icons.campaign;
      case EducationExpenseType.maintenance:
        return Icons.build;
      case EducationExpenseType.insurance:
        return Icons.security;
      case EducationExpenseType.license:
        return Icons.verified;
      case EducationExpenseType.training:
        return Icons.school;
      case EducationExpenseType.transport:
        return Icons.directions_car;
      case EducationExpenseType.stationery:
        return Icons.edit;
      case EducationExpenseType.software:
        return Icons.computer;
      case EducationExpenseType.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case EducationExpenseType.rent:
        return const Color(0xFF3B82F6);
      case EducationExpenseType.utilities:
        return const Color(0xFFF59E0B);
      case EducationExpenseType.supplies:
        return const Color(0xFF10B981);
      case EducationExpenseType.books:
        return const Color(0xFF8B5CF6);
      case EducationExpenseType.equipment:
        return const Color(0xFF06B6D4);
      case EducationExpenseType.salary:
        return const Color(0xFFEF4444);
      case EducationExpenseType.marketing:
        return const Color(0xFFEC4899);
      case EducationExpenseType.maintenance:
        return const Color(0xFF84CC16);
      case EducationExpenseType.insurance:
        return const Color(0xFF6366F1);
      case EducationExpenseType.license:
        return const Color(0xFF14B8A6);
      case EducationExpenseType.training:
        return const Color(0xFFF97316);
      case EducationExpenseType.transport:
        return const Color(0xFF8B5CF6);
      case EducationExpenseType.stationery:
        return const Color(0xFF06B6D4);
      case EducationExpenseType.software:
        return const Color(0xFF10B981);
      case EducationExpenseType.other:
        return const Color(0xFF6B7280);
    }
  }
}

// Gider Durumları
enum ExpenseStatus {
  paid('paid', 'Ödendi'),
  pending('pending', 'Beklemede'),
  overdue('overdue', 'Gecikmiş'),
  cancelled('cancelled', 'İptal Edildi'),
  partiallyPaid('partiallyPaid', 'Kısmi Ödendi');

  const ExpenseStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

class EducationExpense extends BaseModel implements StatusModel {
  final String baslik; // Gider başlığı
  final String aciklama; // Açıklama
  final EducationExpenseType giderTuru; // Gider türü
  final double tutar; // Gider tutarı
  final DateTime giderTarihi; // Giderin oluştuğu tarih
  final DateTime? odemeTarihi; // Ödemenin yapıldığı tarih
  final DateTime? vadeseTarihi; // Ödeme vadesi
  final ExpenseStatus durum; // Gider durumu
  final String? tedarikci; // Tedarikci/satıcı
  final String? kategori; // Kategori (sabit/değişken/yatırım)
  final bool tekrarEden; // Tekrar eden gider mi?
  final String? tekrarPeriyodu; // aylık, yıllık vs.
  final String? odemeYontemi; // nakit, kart, havale, çek
  final String? fisNo; // Fiş/fatura numarası
  final String? makbuzNo; // Makbuz numarası
  final String? vergiDairesi; // Vergi dairesi
  final String? vergiNo; // Vergi numarası
  final double? kdvOrani; // KDV oranı
  final double? kdvTutari; // KDV tutarı
  final String? dersId; // Hangi derse ait (opsiyonel)
  final String? ogretmenId; // Hangi öğretmene ait (opsiyonel)
  final List<String>? etiketler; // Gider etiketleri
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationExpense({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.baslik,
    this.aciklama = '',
    required this.giderTuru,
    required this.tutar,
    required this.giderTarihi,
    this.odemeTarihi,
    this.vadeseTarihi,
    this.durum = ExpenseStatus.pending,
    this.tedarikci,
    this.kategori,
    this.tekrarEden = false,
    this.tekrarPeriyodu,
    this.odemeYontemi,
    this.fisNo,
    this.makbuzNo,
    this.vergiDairesi,
    this.vergiNo,
    this.kdvOrani,
    this.kdvTutari,
    this.dersId,
    this.ogretmenId,
    this.etiketler,
    this.ekstraBilgiler,
  });

  // StatusModel implementation
  @override
  bool get isActive => durum != ExpenseStatus.cancelled;

  // Formatlanmış tutar
  String get formatliTutar => '₺${tutar.toStringAsFixed(2)}';

  // KDV dahil tutar
  double get kdvDahilTutar => tutar + (kdvTutari ?? 0);
  String get formatliKdvDahilTutar => '₺${kdvDahilTutar.toStringAsFixed(2)}';

  // Ödeme durumu kontrolları
  bool get odendi => durum == ExpenseStatus.paid;
  bool get bekliyor => durum == ExpenseStatus.pending;
  bool get geciken => durum == ExpenseStatus.overdue;
  bool get kismiOdeme => durum == ExpenseStatus.partiallyPaid;
  bool get iptalEdildi => durum == ExpenseStatus.cancelled;

  // Vade durumu
  bool get vadesiGecti {
    if (vadeseTarihi == null || odendi) return false;
    return DateTime.now().isAfter(vadeseTarihi!);
  }

  // Kalan gün sayısı
  int? get kalanGun {
    if (vadeseTarihi == null || odendi) return null;
    final diff = vadeseTarihi!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : null;
  }

  // Durum rengi
  Color get durumRengi {
    switch (durum) {
      case ExpenseStatus.paid:
        return const Color(0xFF10B981);
      case ExpenseStatus.pending:
        return const Color(0xFFF59E0B);
      case ExpenseStatus.overdue:
        return const Color(0xFFEF4444);
      case ExpenseStatus.cancelled:
        return const Color(0xFF6B7280);
      case ExpenseStatus.partiallyPaid:
        return const Color(0xFF3B82F6);
    }
  }

  // Etiketler string formatı
  String get etiketlerStr => etiketler?.join(', ') ?? '';

  // StatusModel implementation
  @override
  String get status => durum.toString();

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'baslik': baslik,
      'aciklama': aciklama,
      'giderTuru': giderTuru.value,
      'tutar': tutar,
      'giderTarihi': Timestamp.fromDate(giderTarihi),
      'odemeTarihi':
          odemeTarihi != null ? Timestamp.fromDate(odemeTarihi!) : null,
      'vadeseTarihi':
          vadeseTarihi != null ? Timestamp.fromDate(vadeseTarihi!) : null,
      'durum': durum.value,
      'tedarikci': tedarikci,
      'kategori': kategori,
      'tekrarEden': tekrarEden,
      'tekrarPeriyodu': tekrarPeriyodu,
      'odemeYontemi': odemeYontemi,
      'fisNo': fisNo,
      'makbuzNo': makbuzNo,
      'vergiDairesi': vergiDairesi,
      'vergiNo': vergiNo,
      'kdvOrani': kdvOrani,
      'kdvTutari': kdvTutari,
      'dersId': dersId,
      'ogretmenId': ogretmenId,
      'etiketler': etiketler,
      'ekstraBilgiler': ekstraBilgiler,
      'kdvDahilTutar': kdvDahilTutar, // Hesaplanan değerler
      'vadesiGecti': vadesiGecti,
      'kalanGun': kalanGun,
    });
    return map;
  }

  static EducationExpense fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationExpense(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      baslik: map['baslik'] as String? ?? '',
      aciklama: map['aciklama'] as String? ?? '',
      giderTuru: EducationExpenseType.values.firstWhere(
        (type) => type.value == map['giderTuru'],
        orElse: () => EducationExpenseType.other,
      ),
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      giderTarihi:
          (map['giderTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      odemeTarihi: (map['odemeTarihi'] as Timestamp?)?.toDate(),
      vadeseTarihi: (map['vadeseTarihi'] as Timestamp?)?.toDate(),
      durum: ExpenseStatus.values.firstWhere(
        (status) => status.value == map['durum'],
        orElse: () => ExpenseStatus.pending,
      ),
      tedarikci: map['tedarikci'] as String?,
      kategori: map['kategori'] as String?,
      tekrarEden: map['tekrarEden'] as bool? ?? false,
      tekrarPeriyodu: map['tekrarPeriyodu'] as String?,
      odemeYontemi: map['odemeYontemi'] as String?,
      fisNo: map['fisNo'] as String?,
      makbuzNo: map['makbuzNo'] as String?,
      vergiDairesi: map['vergiDairesi'] as String?,
      vergiNo: map['vergiNo'] as String?,
      kdvOrani: (map['kdvOrani'] as num?)?.toDouble(),
      kdvTutari: (map['kdvTutari'] as num?)?.toDouble(),
      dersId: map['dersId'] as String?,
      ogretmenId: map['ogretmenId'] as String?,
      etiketler:
          map['etiketler'] != null ? List<String>.from(map['etiketler']) : null,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationExpense copyWith({
    String? baslik,
    String? aciklama,
    EducationExpenseType? giderTuru,
    double? tutar,
    DateTime? giderTarihi,
    DateTime? odemeTarihi,
    DateTime? vadeseTarihi,
    ExpenseStatus? durum,
    String? tedarikci,
    String? kategori,
    bool? tekrarEden,
    String? tekrarPeriyodu,
    String? odemeYontemi,
    String? fisNo,
    String? makbuzNo,
    String? vergiDairesi,
    String? vergiNo,
    double? kdvOrani,
    double? kdvTutari,
    String? dersId,
    String? ogretmenId,
    List<String>? etiketler,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationExpense(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      giderTuru: giderTuru ?? this.giderTuru,
      tutar: tutar ?? this.tutar,
      giderTarihi: giderTarihi ?? this.giderTarihi,
      odemeTarihi: odemeTarihi ?? this.odemeTarihi,
      vadeseTarihi: vadeseTarihi ?? this.vadeseTarihi,
      durum: durum ?? this.durum,
      tedarikci: tedarikci ?? this.tedarikci,
      kategori: kategori ?? this.kategori,
      tekrarEden: tekrarEden ?? this.tekrarEden,
      tekrarPeriyodu: tekrarPeriyodu ?? this.tekrarPeriyodu,
      odemeYontemi: odemeYontemi ?? this.odemeYontemi,
      fisNo: fisNo ?? this.fisNo,
      makbuzNo: makbuzNo ?? this.makbuzNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      vergiNo: vergiNo ?? this.vergiNo,
      kdvOrani: kdvOrani ?? this.kdvOrani,
      kdvTutari: kdvTutari ?? this.kdvTutari,
      dersId: dersId ?? this.dersId,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      etiketler: etiketler ?? this.etiketler,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid => super.isValid && baslik.isNotEmpty && tutar > 0;

  @override
  String toString() =>
      'EducationExpense(id: $id, baslik: $baslik, tutar: $formatliTutar, durum: ${durum.displayName})';
}
