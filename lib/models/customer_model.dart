import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gender;
  final DateTime? birthDate;
  final String allergyInfo;
  final String preferredBrand;
  final String notes;
  final String customerTag;
  final double debtAmount;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final int totalVisits;
  final double totalSpent;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.userId,
    String? name,
    String? firstName,
    String? lastName,
    required this.phone,
    this.email = '',
    this.address = '',
    this.gender = '',
    this.birthDate,
    this.allergyInfo = '',
    this.preferredBrand = '',
    this.notes = '',
    this.customerTag = '',
    this.debtAmount = 0.0,
    required this.createdAt,
    this.lastVisit,
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.updatedAt,
  }) : name = name ?? '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gender: map['gender'] ?? '',
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] is Timestamp
              ? map['birthDate'].toDate()
              : DateTime.parse(map['birthDate']))
          : null,
      allergyInfo: map['allergyInfo'] ?? '',
      preferredBrand: map['preferredBrand'] ?? '',
      notes: map['notes'] ?? '',
      customerTag: map['customerTag'] ?? '',
      debtAmount: (map['debtAmount'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? map['createdAt'].toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      lastVisit: map['lastVisit'] != null
          ? (map['lastVisit'] is Timestamp
              ? map['lastVisit'].toDate()
              : DateTime.parse(map['lastVisit']))
          : null,
      totalVisits: map['totalVisits'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0).toDouble(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? map['updatedAt'].toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'allergyInfo': allergyInfo,
      'preferredBrand': preferredBrand,
      'notes': notes,
      'customerTag': customerTag,
      'debtAmount': debtAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
      'totalVisits': totalVisits,
      'totalSpent': totalSpent,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
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

  // Son ziyaret tarihinden itibaren geçen gün sayısı
  int? get daysSinceLastVisit {
    if (lastVisit == null) return null;
    return DateTime.now().difference(lastVisit!).inDays;
  }

  // Müşteri sadakat seviyesi
  String get loyaltyLevel {
    if (totalVisits >= 50) return 'Altın';
    if (totalVisits >= 25) return 'Gümüş';
    if (totalVisits >= 10) return 'Bronz';
    return 'Yeni';
  }

  // Ortalama harcama
  double get averageSpending {
    if (totalVisits == 0) return 0.0;
    return totalSpent / totalVisits;
  }

  // Kopyalama metodu
  CustomerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? gender,
    DateTime? birthDate,
    String? allergyInfo,
    String? preferredBrand,
    String? notes,
    String? customerTag,
    double? debtAmount,
    DateTime? createdAt,
    DateTime? lastVisit,
    int? totalVisits,
    double? totalSpent,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ??
          (firstName != null || lastName != null
              ? '${firstName ?? this.firstName} ${lastName ?? this.lastName}'
                  .trim()
              : this.name),
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      allergyInfo: allergyInfo ?? this.allergyInfo,
      preferredBrand: preferredBrand ?? this.preferredBrand,
      notes: notes ?? this.notes,
      customerTag: customerTag ?? this.customerTag,
      debtAmount: debtAmount ?? this.debtAmount,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, phone: $phone, email: $email, address: $address, gender: $gender, birthDate: $birthDate, allergyInfo: $allergyInfo, preferredBrand: $preferredBrand, notes: $notes, createdAt: $createdAt, lastVisit: $lastVisit, totalVisits: $totalVisits, totalSpent: $totalSpent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get content => notes;
  String get category => allergyInfo;

  // Backward compatibility getters
  String get firstName => name.split(' ').first;
  String get lastName =>
      name.split(' ').length > 1 ? name.split(' ').skip(1).join(' ') : '';
  String get tag => loyaltyLevel;
  String get note => notes;
  int get totalSessions => totalVisits;
  int get usedSessions => totalVisits;
  double get totalPayment => totalSpent;
  double get paidAmount => totalSpent;
  List<String> get documentUrls => <String>[];

  // Validation methods
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    // Türkiye ve uluslararası telefon numarası formatları
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // +1234567890 formatı (uluslararası)
    final RegExp intlPhoneRegex = RegExp(r'^\+\d{10,15}$');
    // 05321234567 formatı (Türkiye)
    final RegExp localPhoneRegex = RegExp(r'^0\d{10}$');
    
    return intlPhoneRegex.hasMatch(cleanPhone) || 
           localPhoneRegex.hasMatch(cleanPhone) ||
           (cleanPhone.length >= 10 && cleanPhone.length <= 15 && RegExp(r'^\d+$').hasMatch(cleanPhone));
  }
}

// Cleaned for Web Build by Cursor
