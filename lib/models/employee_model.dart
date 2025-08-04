import 'package:flutter/material.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final BeautySpecialty specialty;
  final List<String> workingDays;
  final String workingHoursStart;
  final String workingHoursEnd;
  final double commissionRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;
  final String? notes;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.specialty = BeautySpecialty.general,
    this.workingDays = const [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma'
    ],
    this.workingHoursStart = '09:00',
    this.workingHoursEnd = '18:00',
    this.commissionRate = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    this.notes,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String id) {
    return EmployeeModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      specialty:
          BeautySpecialtyExtension.fromString(map['specialty'] ?? 'general'),
      workingDays: List<String>.from(map['workingDays'] ??
          ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma']),
      workingHoursStart: map['workingHoursStart'] ?? '09:00',
      workingHoursEnd: map['workingHoursEnd'] ?? '18:00',
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      profileImageUrl: map['profileImageUrl'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'specialty': specialty.name,
      'workingDays': workingDays,
      'workingHoursStart': workingHoursStart,
      'workingHoursEnd': workingHoursEnd,
      'commissionRate': commissionRate,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'profileImageUrl': profileImageUrl,
      'notes': notes,
    };
  }

  EmployeeModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    BeautySpecialty? specialty,
    List<String>? workingDays,
    String? workingHoursStart,
    String? workingHoursEnd,
    double? commissionRate,
    bool? isActive,
    DateTime? updatedAt,
    String? profileImageUrl,
    String? notes,
  }) {
    return EmployeeModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      workingDays: workingDays ?? this.workingDays,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'EmployeeModel(id: $id, name: $name, specialty: ${specialty.displayName})';
}

enum BeautySpecialty {
  general('Genel', Icons.person, Colors.grey),
  hairstylist('Kuaför', Icons.content_cut, Colors.brown),
  colorist('Boyacı', Icons.palette, Colors.purple),
  nailTechnician('Manikürist', Icons.back_hand, Colors.pink),
  esthetician('Estetisyen', Icons.spa, Colors.green),
  makeupArtist('Makyöz', Icons.brush, Colors.orange),
  massageTherapist('Masöz', Icons.healing, Colors.blue),
  eyebrowSpecialist('Kaş Uzmanı', Icons.visibility, Colors.indigo),
  waxingSpecialist('Ağda Uzmanı', Icons.clean_hands, Colors.teal);

  const BeautySpecialty(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

extension BeautySpecialtyExtension on BeautySpecialty {
  static BeautySpecialty fromString(String value) {
    return BeautySpecialty.values.firstWhere(
      (specialty) => specialty.name == value,
      orElse: () => BeautySpecialty.general,
    );
  }
}

enum EmployeeRole {
  admin('Yönetici', Icons.admin_panel_settings, Colors.red),
  manager('Müdür', Icons.supervisor_account, Colors.orange),
  senior('Kıdemli Çalışan', Icons.star, Colors.amber),
  junior('Çalışan', Icons.person, Colors.blue),
  beautician('Güzellik Uzmanı', Icons.spa, Colors.purple),
  intern('Stajyer', Icons.school, Colors.green);

  const EmployeeRole(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

extension EmployeeRoleExtension on EmployeeRole {
  static EmployeeRole fromString(String value) {
    return EmployeeRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => EmployeeRole.junior,
    );
  }
}
