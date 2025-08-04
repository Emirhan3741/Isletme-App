import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'base_model.dart';

// Öğretmen Durumu
enum TeacherStatus {
  active('active', 'Aktif'),
  inactive('inactive', 'Pasif'),
  onLeave('on_leave', 'İzinli'),
  terminated('terminated', 'Ayrıldı');

  const TeacherStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

extension TeacherStatusExtension on TeacherStatus {
  String get emoji {
    switch (this) {
      case TeacherStatus.active:
        return '✅';
      case TeacherStatus.inactive:
        return '⏸️';
      case TeacherStatus.onLeave:
        return '🏖️';
      case TeacherStatus.terminated:
        return '❌';
    }
  }

  Color get color {
    switch (this) {
      case TeacherStatus.active:
        return const Color(0xFF10B981);
      case TeacherStatus.inactive:
        return const Color(0xFF6B7280);
      case TeacherStatus.onLeave:
        return const Color(0xFFF59E0B);
      case TeacherStatus.terminated:
        return const Color(0xFFEF4444);
    }
  }
}

class EducationTeacher extends BaseModel {
  final String ad;
  final String soyad;
  final String telefon;
  final String? email;
  final List<String> uzmanlikAlanlari;
  final String egitimDurumu; // Lisans, Yüksek Lisans, Doktora
  final String mezunOkul;
  final int deneyimYili;
  final String status; // active, inactive, on_leave, terminated
  final double? saatlikUcret;
  final DateTime iseBaslamaTarihi;
  final DateTime? istenAyrilisTarihi;
  final bool tamZamanli;
  final List<String> calismaGunleri; // ['Pazartesi', 'Salı', ...]
  final String? calismaBaslangicSaati; // "09:00"
  final String? calismaBitisSaati; // "17:00"
  final String? adres;
  final String? notlar;
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
  final String? tcKimlikNo;
  final String? iban;
  final String? sozlesmeNo;
  final String? sgkNo;

  EducationTeacher({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.ad,
    required this.soyad,
    required this.telefon,
    this.email,
    required this.uzmanlikAlanlari,
    required this.egitimDurumu,
    required this.mezunOkul,
    required this.deneyimYili,
    required this.status,
    this.saatlikUcret,
    required this.iseBaslamaTarihi,
    this.istenAyrilisTarihi,
    required this.tamZamanli,
    required this.calismaGunleri,
    this.calismaBaslangicSaati,
    this.calismaBitisSaati,
    this.adres,
    this.notlar,
    this.acilDurumKisi,
    this.acilDurumTelefon,
    this.tcKimlikNo,
    this.iban,
    this.sozlesmeNo,
    this.sgkNo,
  });

  factory EducationTeacher.fromMap(
      Map<String, dynamic> map, String documentId) {
    return EducationTeacher(
      id: documentId,
      userId: map['userId'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      telefon: map['telefon'] ?? '',
      email: map['email'],
      uzmanlikAlanlari: List<String>.from(map['uzmanlikAlanlari'] ?? []),
      egitimDurumu: map['egitimDurumu'] ?? '',
      mezunOkul: map['mezunOkul'] ?? '',
      deneyimYili: map['deneyimYili'] ?? 0,
      status: map['status'] ?? 'active',
      saatlikUcret: map['saatlikUcret']?.toDouble(),
      iseBaslamaTarihi: (map['iseBaslamaTarihi'] as Timestamp).toDate(),
      istenAyrilisTarihi: map['istenAyrilisTarihi'] != null
          ? (map['istenAyrilisTarihi'] as Timestamp).toDate()
          : null,
      tamZamanli: map['tamZamanli'] ?? true,
      calismaGunleri: List<String>.from(map['calismaGunleri'] ?? []),
      calismaBaslangicSaati: map['calismaBaslangicSaati'],
      calismaBitisSaati: map['calismaBitisSaati'],
      adres: map['adres'],
      notlar: map['notlar'],
      acilDurumKisi: map['acilDurumKisi'],
      acilDurumTelefon: map['acilDurumTelefon'],
      tcKimlikNo: map['tcKimlikNo'],
      iban: map['iban'],
      sozlesmeNo: map['sozlesmeNo'],
      sgkNo: map['sgkNo'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'uzmanlikAlanlari': uzmanlikAlanlari,
      'egitimDurumu': egitimDurumu,
      'mezunOkul': mezunOkul,
      'deneyimYili': deneyimYili,
      'status': status,
      'saatlikUcret': saatlikUcret,
      'iseBaslamaTarihi': Timestamp.fromDate(iseBaslamaTarihi),
      'istenAyrilisTarihi': istenAyrilisTarihi != null
          ? Timestamp.fromDate(istenAyrilisTarihi!)
          : null,
      'tamZamanli': tamZamanli,
      'calismaGunleri': calismaGunleri,
      'calismaBaslangicSaati': calismaBaslangicSaati,
      'calismaBitisSaati': calismaBitisSaati,
      'adres': adres,
      'notlar': notlar,
      'acilDurumKisi': acilDurumKisi,
      'acilDurumTelefon': acilDurumTelefon,
      'tcKimlikNo': tcKimlikNo,
      'iban': iban,
      'sozlesmeNo': sozlesmeNo,
      'sgkNo': sgkNo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  EducationTeacher copyWith({
    String? id,
    String? userId,
    String? ad,
    String? soyad,
    String? telefon,
    String? email,
    List<String>? uzmanlikAlanlari,
    String? egitimDurumu,
    String? mezunOkul,
    int? deneyimYili,
    String? status,
    double? saatlikUcret,
    DateTime? iseBaslamaTarihi,
    DateTime? istenAyrilisTarihi,
    bool? tamZamanli,
    List<String>? calismaGunleri,
    String? calismaBaslangicSaati,
    String? calismaBitisSaati,
    String? adres,
    String? notlar,
    String? acilDurumKisi,
    String? acilDurumTelefon,
    String? tcKimlikNo,
    String? iban,
    String? sozlesmeNo,
    String? sgkNo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationTeacher(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      uzmanlikAlanlari: uzmanlikAlanlari ?? this.uzmanlikAlanlari,
      egitimDurumu: egitimDurumu ?? this.egitimDurumu,
      mezunOkul: mezunOkul ?? this.mezunOkul,
      deneyimYili: deneyimYili ?? this.deneyimYili,
      status: status ?? this.status,
      saatlikUcret: saatlikUcret ?? this.saatlikUcret,
      iseBaslamaTarihi: iseBaslamaTarihi ?? this.iseBaslamaTarihi,
      istenAyrilisTarihi: istenAyrilisTarihi ?? this.istenAyrilisTarihi,
      tamZamanli: tamZamanli ?? this.tamZamanli,
      calismaGunleri: calismaGunleri ?? this.calismaGunleri,
      calismaBaslangicSaati:
          calismaBaslangicSaati ?? this.calismaBaslangicSaati,
      calismaBitisSaati: calismaBitisSaati ?? this.calismaBitisSaati,
      adres: adres ?? this.adres,
      notlar: notlar ?? this.notlar,
      acilDurumKisi: acilDurumKisi ?? this.acilDurumKisi,
      acilDurumTelefon: acilDurumTelefon ?? this.acilDurumTelefon,
      tcKimlikNo: tcKimlikNo ?? this.tcKimlikNo,
      iban: iban ?? this.iban,
      sozlesmeNo: sozlesmeNo ?? this.sozlesmeNo,
      sgkNo: sgkNo ?? this.sgkNo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  String get tamIsim => '$ad $soyad';

  String get uzmanlikAlanlariStr => uzmanlikAlanlari.join(', ');

  String get calismaGunleriStr => calismaGunleri.join(', ');

  String get deneyimAciklama =>
      deneyimYili == 0 ? 'Yeni başlayan' : '$deneyimYili yıl deneyim';

  String get calismaTipi => tamZamanli ? 'Tam zamanlı' : 'Yarı zamanlı';

  TeacherStatus get statusEnum => TeacherStatus.values.firstWhere(
        (e) => e.value == status,
        orElse: () => TeacherStatus.inactive,
      );

  String get statusText => statusEnum.displayName;

  String get statusEmoji => statusEnum.emoji;

  Color get statusColor => statusEnum.color;

  bool get aktif => status == 'active';

  String get calismaDetayi {
    if (calismaBaslangicSaati != null && calismaBitisSaati != null) {
      return '$calismaBaslangicSaati - $calismaBitisSaati';
    }
    return calismaTipi;
  }

  // İstatistikler
  int get toplamCalismaSuresi {
    if (istenAyrilisTarihi != null) {
      return istenAyrilisTarihi!.difference(iseBaslamaTarihi).inDays;
    }
    return DateTime.now().difference(iseBaslamaTarihi).inDays;
  }

  String get calismaGecmisi => '${(toplamCalismaSuresi / 30).floor()} ay';

  // Validasyon
  bool get bilgiTamMi {
    return ad.isNotEmpty &&
        soyad.isNotEmpty &&
        telefon.isNotEmpty &&
        uzmanlikAlanlari.isNotEmpty &&
        egitimDurumu.isNotEmpty;
  }

  Map<String, String> get eksikBilgiler {
    final eksikler = <String, String>{};

    if (ad.isEmpty) eksikler['ad'] = 'Ad zorunlu';
    if (soyad.isEmpty) eksikler['soyad'] = 'Soyad zorunlu';
    if (telefon.isEmpty) eksikler['telefon'] = 'Telefon zorunlu';
    if (uzmanlikAlanlari.isEmpty) {
      eksikler['uzmanlik'] = 'En az bir uzmanlık alanı seçin';
    }
    if (egitimDurumu.isEmpty) eksikler['egitim'] = 'Eğitim durumu zorunlu';

    return eksikler;
  }

  @override
  String toString() =>
      'EducationTeacher(id: $id, tamIsim: $tamIsim, status: $status)';
}
