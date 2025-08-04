import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:locapo/core/constants/app_constants.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'appointment_model.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  // Gelir
  sale,
  serviceFee,
  productSale,
  appointment,
  // Gider
  rent,
  salary,
  material,
  marketing,
  bills,
  maintenance,
  other
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final String category; // Storing category key as string
  final String title;
  final String description;
  final double amount;
  final DateTime createdAt;
  final List<String> fileUrls;
  final String? customerName;
  final String? status;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.amount,
    required this.createdAt,
    required this.fileUrls,
    this.customerName,
    this.status,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.parse(dateValue);
      return DateTime.now();
    }

    return TransactionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => TransactionType.income,
      ),
      category: map['category'] as String? ?? 'other',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(map['createdAt'] ?? map['date']),
      fileUrls: List<String>.from(map['fileUrls'] ?? []),
      customerName: map['customerName'] as String?,
      status: map['status'] as String?,
    );
  }

  factory TransactionModel.fromAppointment(AppointmentModel appointment) {
    return TransactionModel(
      id: UniqueKey().toString(),
      userId: appointment.userId,
      type: TransactionType.income,
      category: 'appointment',
      title: 'Randevu Geliri - ${appointment.customerName ?? 'Müşteri'}',
      description: appointment.notes ?? '',
      amount: appointment.price ?? 0.0,
      createdAt: appointment.createdAt,
      fileUrls: [],
      customerName: appointment.customerName,
      status: appointment.status?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category,
      'title': title,
      'description': description,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'fileUrls': fileUrls,
      'customerName': customerName,
      'status': status,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    String? category,
    String? title,
    String? description,
    double? amount,
    DateTime? createdAt,
    List<String>? fileUrls,
    String? customerName,
    String? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      fileUrls: fileUrls ?? this.fileUrls,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, type: $type, category: $category, title: $title, userId: $userId)';
  }

  String getTypeText(dynamic localizations) {
    switch (type) {
      case TransactionType.income:
        return localizations.income;
      case TransactionType.expense:
        return localizations.expense;
    }
  }

  String getCategoryText(dynamic localizations) {
    switch (category) {
      case 'sale':
        return localizations.categorySale;
      case 'serviceFee':
        return localizations.categoryServiceFee;
      case 'productSale':
        return localizations.categoryProductSale;
      case 'appointment':
        return localizations.categoryAppointment;
      case 'rent':
        return localizations.categoryRent;
      case 'salary':
        return localizations.categorySalary;
      case 'material':
        return localizations.categoryMaterial;
      case 'marketing':
        return localizations.categoryMarketing;
      case 'bills':
        return localizations.categoryBills;
      case 'maintenance':
        return localizations.categoryMaintenance;
      case 'other':
        return localizations.categoryOther;
      default:
        return localizations.categoryOther;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'sale':
      case 'serviceFee':
      case 'productSale':
      case 'appointment':
        return AppConstants.successColor;
      case 'rent':
        return Colors.orange;
      case 'salary':
        return Colors.blue;
      case 'material':
        return Colors.purple;
      case 'marketing':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'maintenance':
        return Colors.teal;
      case 'other':
      default:
        return AppConstants.textSecondary;
    }
  }

  // Method wrapper for compatibility
  Color getCategoryColor() {
    return categoryColor;
  }
}

extension TransactionTypeExtension on TransactionType {
  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.income,
    );
  }
}

extension TransactionCategoryExtension on TransactionCategory {
  static TransactionCategory fromString(String value) {
    return TransactionCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionCategory.other,
    );
  }
}
