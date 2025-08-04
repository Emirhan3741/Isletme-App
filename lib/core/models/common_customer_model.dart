import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';
import '../constants/app_constants.dart';
import '../constants/sector_constants.dart';

class CommonCustomerModel extends BaseModel
    implements StatusModel, SectorModel {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final String gender;
  final DateTime? birthDate;
  @override
  final bool isActive;
  @override
  final String sector;
  @override
  final Map<String, dynamic> sectorSpecificData;
  final List<String> tags;
  final String? profileImageUrl;
  final double totalSpent;
  final int visitCount;
  final DateTime? lastVisit;

  const CommonCustomerModel({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? updatedAt,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
    this.gender = 'other',
    this.birthDate,
    this.isActive = true,
    required this.sector,
    this.sectorSpecificData = const {},
    this.tags = const [],
    this.profileImageUrl,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    this.lastVisit,
  }) : super(
          id: id,
          userId: userId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  @override
  String get status => isActive ? 'active' : 'inactive';

  // Müşteri değeri hesaplama
  String get customerValue {
    if (totalSpent >= 5000) return 'VIP';
    if (totalSpent >= 2000) return 'Premium';
    if (totalSpent >= 500) return 'Regular';
    return 'New';
  }

  // Yaş hesaplama
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Doğum günü yakın mı?
  bool get isBirthdayThisMonth {
    if (birthDate == null) return false;
    final now = DateTime.now();
    return birthDate!.month == now.month;
  }

  // Uzun süredir gelmemiş mi?
  bool get isInactive {
    if (lastVisit == null) return visitCount == 0;
    return DateTime.now().difference(lastVisit!).inDays > 90;
  }

  // Sektörel özelleştirmeler
  String? get preferredService => sectorSpecificData['preferredService'];
  String? get allergies => sectorSpecificData['allergies'];
  String? get medicalHistory => sectorSpecificData['medicalHistory'];
  Map<String, dynamic> get customFields =>
      sectorSpecificData['customFields'] ?? {};

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'isActive': isActive,
      'sector': sector,
      'sectorSpecificData': sectorSpecificData,
      'tags': tags,
      'profileImageUrl': profileImageUrl,
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
    });
    return map;
  }

  factory CommonCustomerModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);

    return CommonCustomerModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      gender: map['gender'] as String? ?? 'other',
      birthDate: (map['birthDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] as bool? ?? true,
      sector: map['sector'] as String? ?? SectorConstants.beauty,
      sectorSpecificData:
          Map<String, dynamic>.from(map['sectorSpecificData'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      profileImageUrl: map['profileImageUrl'] as String?,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      visitCount: map['visitCount'] as int? ?? 0,
      lastVisit: (map['lastVisit'] as Timestamp?)?.toDate(),
    );
  }

  CommonCustomerModel copyWith({
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
  }) {
    return CommonCustomerModel(
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
    );
  }

  // Tag ekleme
  CommonCustomerModel addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  // Tag çıkarma
  CommonCustomerModel removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  // Ziyaret güncelleme
  CommonCustomerModel updateVisit(double spentAmount) {
    return copyWith(
      totalSpent: totalSpent + spentAmount,
      visitCount: visitCount + 1,
      lastVisit: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Sektörel validasyon
  bool get isValidForSector {
    switch (sector) {
      case SectorConstants.beauty:
        return name.isNotEmpty && phone.isNotEmpty;
      case SectorConstants.psychology:
        return name.isNotEmpty && phone.isNotEmpty;
      case SectorConstants.diet:
        return name.isNotEmpty && phone.isNotEmpty;
      case SectorConstants.veterinary:
        return name.isNotEmpty && phone.isNotEmpty; // Pet owner info
      default:
        return name.isNotEmpty && phone.isNotEmpty;
    }
  }

  // Formatlanmış telefon
  String get formattedPhone {
    if (phone.length == 11 && phone.startsWith('0')) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 9)} ${phone.substring(9)}';
    }
    return phone;
  }

  // Tam isim
  String get fullName => name;

  @override
  String toString() =>
      'CommonCustomerModel(id: $id, name: $name, phone: $phone, customerValue: $customerValue)';
}
