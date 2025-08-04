import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_customer_model.dart';
import '../constants/app_constants.dart';

class LawyerClientModel extends CommonCustomerModel {
  final String? tcNo;
  final String? pasaportNo;
  final String? dosyaNo;
  final String? davaYazisi;
  final String? mahkemeBilgisi;
  final String dosyaDurumu;
  final DateTime? davaBaslangicTarihi;
  final String? meslek;
  final String? dogumYeri;
  final String? babaAdi;
  final String? anneAdi;
  final String? medeniDurum;

  const LawyerClientModel({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? updatedAt,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
    String gender = 'other',
    DateTime? birthDate,
    bool isActive = true,
    String sector = 'lawyer',
    Map<String, dynamic> sectorSpecificData = const {},
    List<String> tags = const [],
    String? profileImageUrl,
    double totalSpent = 0.0,
    int visitCount = 0,
    DateTime? lastVisit,
    this.tcNo,
    this.pasaportNo,
    this.dosyaNo,
    this.davaYazisi,
    this.mahkemeBilgisi,
    this.dosyaDurumu = 'devam_ediyor',
    this.davaBaslangicTarihi,
    this.meslek,
    this.dogumYeri,
    this.babaAdi,
    this.anneAdi,
    this.medeniDurum,
  }) : super(
          id: id,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
          gender: gender,
          birthDate: birthDate,
          isActive: isActive,
          sector: sector,
          sectorSpecificData: sectorSpecificData,
          tags: tags,
          profileImageUrl: profileImageUrl,
          totalSpent: totalSpent,
          visitCount: visitCount,
          lastVisit: lastVisit,
        );

  // Dosya durumu kontrolleri
  bool get devamEdiyor => dosyaDurumu == 'devam_ediyor';
  bool get tamamlandi => dosyaDurumu == 'tamamlandi';
  bool get kapandi => dosyaDurumu == 'kapandi';

  // Kimlik numarası validasyonu
  bool get tcNoValid {
    if (tcNo == null || tcNo!.length != 11) return false;
    return RegExp(r'^[0-9]{11}$').hasMatch(tcNo!);
  }

  // Müvekkil tipi
  String get muvekkilTipi {
    return tcNo != null ? 'Türk Vatandaşı' : 'Yabancı Uyruklu';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'tcNo': tcNo,
      'pasaportNo': pasaportNo,
      'dosyaNo': dosyaNo,
      'davaYazisi': davaYazisi,
      'mahkemeBilgisi': mahkemeBilgisi,
      'dosyaDurumu': dosyaDurumu,
      'davaBaslangicTarihi': davaBaslangicTarihi != null
          ? Timestamp.fromDate(davaBaslangicTarihi!)
          : null,
      'meslek': meslek,
      'dogumYeri': dogumYeri,
      'babaAdi': babaAdi,
      'anneAdi': anneAdi,
      'medeniDurum': medeniDurum,
    });
    return map;
  }

  factory LawyerClientModel.fromMap(Map<String, dynamic> map) {
    final commonCustomer = CommonCustomerModel.fromMap(map);

    return LawyerClientModel(
      id: commonCustomer.id,
      userId: commonCustomer.userId,
      createdAt: commonCustomer.createdAt,
      updatedAt: commonCustomer.updatedAt,
      name: commonCustomer.name,
      phone: commonCustomer.phone,
      email: commonCustomer.email,
      address: commonCustomer.address,
      notes: commonCustomer.notes,
      gender: commonCustomer.gender,
      birthDate: commonCustomer.birthDate,
      isActive: commonCustomer.isActive,
      sector: commonCustomer.sector,
      sectorSpecificData: commonCustomer.sectorSpecificData,
      tags: commonCustomer.tags,
      profileImageUrl: commonCustomer.profileImageUrl,
      totalSpent: commonCustomer.totalSpent,
      visitCount: commonCustomer.visitCount,
      lastVisit: commonCustomer.lastVisit,
      tcNo: map['tcNo'] as String?,
      pasaportNo: map['pasaportNo'] as String?,
      dosyaNo: map['dosyaNo'] as String?,
      davaYazisi: map['davaYazisi'] as String?,
      mahkemeBilgisi: map['mahkemeBilgisi'] as String?,
      dosyaDurumu: map['dosyaDurumu'] as String? ?? 'devam_ediyor',
      davaBaslangicTarihi: (map['davaBaslangicTarihi'] as Timestamp?)?.toDate(),
      meslek: map['meslek'] as String?,
      dogumYeri: map['dogumYeri'] as String?,
      babaAdi: map['babaAdi'] as String?,
      anneAdi: map['anneAdi'] as String?,
      medeniDurum: map['medeniDurum'] as String?,
    );
  }

  factory LawyerClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return LawyerClientModel.fromMap(data);
  }

  @override
  LawyerClientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? gender,
    DateTime? birthDate,
    bool? isActive,
    String? sector,
    Map<String, dynamic>? sectorSpecificData,
    List<String>? tags,
    String? profileImageUrl,
    double? totalSpent,
    int? visitCount,
    DateTime? lastVisit,
    DateTime? updatedAt,
    String? tcNo,
    String? pasaportNo,
    String? dosyaNo,
    String? davaYazisi,
    String? mahkemeBilgisi,
    String? dosyaDurumu,
    DateTime? davaBaslangicTarihi,
    String? meslek,
    String? dogumYeri,
    String? babaAdi,
    String? anneAdi,
    String? medeniDurum,
  }) {
    return LawyerClientModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      sector: sector ?? this.sector,
      sectorSpecificData: sectorSpecificData ?? this.sectorSpecificData,
      tags: tags ?? this.tags,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      lastVisit: lastVisit ?? this.lastVisit,
      tcNo: tcNo ?? this.tcNo,
      pasaportNo: pasaportNo ?? this.pasaportNo,
      dosyaNo: dosyaNo ?? this.dosyaNo,
      davaYazisi: davaYazisi ?? this.davaYazisi,
      mahkemeBilgisi: mahkemeBilgisi ?? this.mahkemeBilgisi,
      dosyaDurumu: dosyaDurumu ?? this.dosyaDurumu,
      davaBaslangicTarihi: davaBaslangicTarihi ?? this.davaBaslangicTarihi,
      meslek: meslek ?? this.meslek,
      dogumYeri: dogumYeri ?? this.dogumYeri,
      babaAdi: babaAdi ?? this.babaAdi,
      anneAdi: anneAdi ?? this.anneAdi,
      medeniDurum: medeniDurum ?? this.medeniDurum,
    );
  }

  @override
  String toString() =>
      'LawyerClientModel(id: $id, name: $name, dosyaNo: $dosyaNo, dosyaDurumu: $dosyaDurumu)';
}

// Dosya durumu sabitleri
class DosyaDurumuConstants {
  static const String devamEdiyor = 'devam_ediyor';
  static const String tamamlandi = 'tamamlandi';
  static const String kapandi = 'kapandi';

  static const List<String> tumDurumlar = [
    devamEdiyor,
    tamamlandi,
    kapandi,
  ];

  static String getDurumDisplayName(String durum) {
    switch (durum) {
      case devamEdiyor:
        return 'Devam Ediyor';
      case tamamlandi:
        return 'Tamamlandı';
      case kapandi:
        return 'Kapandı';
      default:
        return durum;
    }
  }
}
