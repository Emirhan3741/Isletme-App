import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpenseModel {
  String? id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isRecurring;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  bool isPaid;
  DateTime? paymentDate;
  String priority;

  ExpenseModel({
    this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.isRecurring = false,
    this.description = '',
    required this.createdAt,
    this.updatedAt,
    this.isPaid = false,
    this.paymentDate,
    this.priority = 'medium',
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Diğer',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date']),
      isRecurring: map['isRecurring'] ?? false,
      description: map['description'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isPaid: map['isPaid'] ?? false,
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] is Timestamp
              ? (map['paymentDate'] as Timestamp).toDate()
              : DateTime.parse(map['paymentDate']))
          : null,
      priority: map['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPaid': isPaid,
      'paymentDate':
          paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'priority': priority,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    bool? isRecurring,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPaid,
    DateTime? paymentDate,
    String? priority,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      priority: priority ?? this.priority,
    );
  }

  // Kategori rengi
  Color getCategoryColor() {
    switch (category) {
      case 'Kira':
        return Colors.purple;
      case 'Maaş':
        return Colors.blue;
      case 'Malzeme':
        return Colors.orange;
      case 'Pazarlama':
        return Colors.green;
      case 'Faturalar':
        return Colors.red;
      case 'Bakım':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Kategori ikonu
  IconData getCategoryIcon() {
    switch (category) {
      case 'Kira':
        return Icons.home_outlined;
      case 'Maaş':
        return Icons.people_outlined;
      case 'Malzeme':
        return Icons.inventory_outlined;
      case 'Pazarlama':
        return Icons.campaign_outlined;
      case 'Faturalar':
        return Icons.receipt_long_outlined;
      case 'Bakım':
        return Icons.build_outlined;
      default:
        return Icons.money_off_outlined;
    }
  }

  @override
  String toString() {
    return 'ExpenseModel{id: $id, title: $title, category: $category, amount: $amount, isRecurring: $isRecurring}';
  }
}

// Refactored by Cursor
