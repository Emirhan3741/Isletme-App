import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SportsTrainer {
  final String? id;
  final String userId;
  final String fullName;
  final String speciality;
  final String phone;
  final String email;
  final List<String> workingHours; // ["09:00-12:00", "14:00-18:00"]
  final List<String> workingDays; // ["Pazartesi", "Salı", "Çarşamba"]
  final int experience; // yıl
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SportsTrainer({
    this.id,
    required this.userId,
    required this.fullName,
    required this.speciality,
    required this.phone,
    required this.email,
    required this.workingHours,
    required this.workingDays,
    required this.experience,
    this.profileImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SportsTrainer.fromMap(Map<String, dynamic> map, String documentId) {
    return SportsTrainer(
      id: documentId,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      speciality: map['speciality'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      workingHours: List<String>.from(map['workingHours'] ?? []),
      workingDays: List<String>.from(map['workingDays'] ?? []),
      experience: map['experience'] ?? 0,
      profileImage: map['profileImage'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'speciality': speciality,
      'phone': phone,
      'email': email,
      'workingHours': workingHours,
      'workingDays': workingDays,
      'experience': experience,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SportsTrainer copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? speciality,
    String? phone,
    String? email,
    List<String>? workingHours,
    List<String>? workingDays,
    int? experience,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportsTrainer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      speciality: speciality ?? this.speciality,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      workingHours: workingHours ?? this.workingHours,
      workingDays: workingDays ?? this.workingDays,
      experience: experience ?? this.experience,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get workingHoursDisplay => workingHours.join(', ');
  String get workingDaysDisplay => workingDays.join(', ');

  String get statusText => isActive ? 'Aktif' : 'Pasif';
  Color get statusColor =>
      isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
}
