// Refactored by Cursor: Only English, ASCII, and null-safe UserModel remains

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserRole { admin, owner, worker, manager, customer }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.owner:
        return 'İşletme Sahibi';
      case UserRole.worker:
        return 'Çalışan';
      case UserRole.manager:
        return 'Müdür';
      case UserRole.customer:
        return 'Müşteri';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isWorker => this == UserRole.worker;
  bool get isCustomer => this == UserRole.customer;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.worker,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'owner' veya 'worker'
  final String? companyId;
  final String sector; // 'güzellik_salon', 'psikolog', vb.
  final String? languageCode; // Yeni: Kullanıcının seçtiği dil
  final String? selectedPanel; // Yeni: Seçilen sektör paneli
  final DateTime? createdAt;

  // Adres bilgileri
  final String? country;
  final String? city;
  final String? district;
  final String? zipCode;
  final String? fullAddress;

  // Saat dilimi
  final String? timeZone;
  
  // Profile photo URL
  final String? photoURL;

  UserModel({
    required this.id,
    required this.name,
    this.email = '', // Optional with default
    required this.role,
    this.companyId,
    required this.sector,
    this.languageCode,
    this.selectedPanel,
    this.createdAt,
    this.country,
    this.city,
    this.district,
    this.zipCode,
    this.fullAddress,
    this.timeZone,
    this.photoURL,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Tarih dönüştürme helper
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.parse(dateValue);
      return null;
    }

    debugPrint('🔍 UserModel.fromMap - languageCode: ${map['languageCode']}');
    debugPrint('🔍 UserModel.fromMap - selectedPanel: ${map['selectedPanel']}');
    
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'worker',
      companyId: map['companyId'],
      sector: map['sector'] ?? 'güzellik_salon',
      languageCode: map['languageCode'],
      selectedPanel: map['selectedPanel'],
      createdAt: parseDate(map['createdAt']),
      // Adres bilgileri
      country: map['country'],
      city: map['city'],
      district: map['district'],
      zipCode: map['zipCode'],
      fullAddress: map['fullAddress'],
      // Saat dilimi
      timeZone: map['timeZone'],
      photoURL: map['photoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'companyId': companyId,
      'sector': sector,
      'languageCode': languageCode,
      'selectedPanel': selectedPanel,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      // Adres bilgileri
      'country': country,
      'city': city,
      'district': district,
      'zipCode': zipCode,
      'fullAddress': fullAddress,
      // Saat dilimi
      'timeZone': timeZone,
      'photoURL': photoURL,
    };
  }

  // Backward compatibility getters
  bool get isAdmin => role == 'owner';
  bool get isOwner => role == 'owner';
  bool get isWorker => role == 'worker';

  // Display name getter for compatibility
  String get displayName => name;

  // Sektör bilgisi için getter
  String get sectorDisplayName {
    switch (sector) {
      case 'güzellik_salon':
        return 'Güzellik Salonu / Kuaför';
      case 'psikolog':
        return 'Psikolog / Psikiyatrist';
      case 'diyetisyen':
        return 'Diyetisyen';
      case 'avukat':
        return 'Avukat / Hukuk Bürosu';
      case 'veteriner':
        return 'Veteriner Klinik';
      case 'spa':
        return 'Masaj Terapisti / SPA';
      case 'eğitmen':
        return 'Dil Eğitmeni / Özel Ders';
      case 'estetik':
        return 'Estetik Merkezi / Klinik';
      case 'koçluk':
        return 'Koçluk Hizmetleri';
      case 'kurs_merkezi':
        return 'Eğitim Kursları (Müzik, Spor, Resim)';
      default:
        return 'Diğer';
    }
  }

  // Adres bilgilerini tek string olarak döndüren getter
  String get fullAddressDisplay {
    List<String> addressParts = [];

    if (fullAddress?.isNotEmpty == true) addressParts.add(fullAddress!);
    if (district?.isNotEmpty == true) addressParts.add(district!);
    if (city?.isNotEmpty == true) addressParts.add(city!);
    if (zipCode?.isNotEmpty == true) addressParts.add(zipCode!);
    if (country?.isNotEmpty == true) addressParts.add(country!);

    return addressParts.join(', ');
  }

  // Saat dilimi bilgisi getter
  String get timeZoneDisplay {
    if (timeZone?.isNotEmpty == true) {
      return timeZone!;
    }
    return 'GMT+3 (Europe/Istanbul)'; // Varsayılan Türkiye
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? sector,
    DateTime? createdAt,
    String? country,
    String? city,
    String? district,
    String? zipCode,
    String? fullAddress,
    String? timeZone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      sector: sector ?? this.sector,
      createdAt: createdAt ?? this.createdAt,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      zipCode: zipCode ?? this.zipCode,
      fullAddress: fullAddress ?? this.fullAddress,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, sector: $sector, city: $city, timeZone: $timeZone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.sector == sector &&
        other.country == country &&
        other.city == city &&
        other.timeZone == timeZone;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode ^
        sector.hashCode ^
        country.hashCode ^
        city.hashCode ^
        timeZone.hashCode;
  }

  String getRoleText() {
    switch (UserRole.values.firstWhere((e) => e.name == role)) {
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.owner:
        return 'İşletme Sahibi';
      case UserRole.manager:
        return 'Müdür';
      case UserRole.worker:
        return 'Çalışan';
      case UserRole.customer:
        return 'Müşteri';
    }
  }

  Color getRoleColor() {
    switch (UserRole.values.firstWhere((e) => e.name == role)) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.owner:
        return Colors.deepPurple;
      case UserRole.manager:
        return Colors.purple;
      case UserRole.worker:
        return Colors.blue;
      case UserRole.customer:
        return Colors.green;
    }
  }

  IconData getRoleIcon() {
    switch (UserRole.values.firstWhere((e) => e.name == role)) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.owner:
        return Icons.business;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.worker:
        return Icons.work;
      case UserRole.customer:
        return Icons.person;
    }
  }

  bool get canManageUsers {
    switch (UserRole.values.firstWhere((e) => e.name == role)) {
      case UserRole.admin:
      case UserRole.owner:
      case UserRole.manager:
        return true;
      case UserRole.worker:
      case UserRole.customer:
        return false;
    }
  }
}

// Auto-cleaned and rebuilt by Cursor

// Fixed: Eksik getter'lar eklendi ve null-safe hale getirildi.
// Fixed for Web Compatibility by Cursor

// Rebuilt for Web by Cursor

// Fixed for Web Build by Cursor

// Cleaned for Web Build by Cursor
