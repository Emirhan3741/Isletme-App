import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  rent,
  electricity,
  water,
  naturalGas,
  phone,
  internet,
  salary,
  material,
  cleaning,
  advertising,
  tax,
  insurance,
  fuel,
  food,
  education,
  maintenance,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get name => toString().split('.').last;
  String get displayName {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.water:
        return 'Water';
      case ExpenseCategory.naturalGas:
        return 'Natural Gas';
      case ExpenseCategory.phone:
        return 'Phone';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.material:
        return 'Material';
      case ExpenseCategory.cleaning:
        return 'Cleaning';
      case ExpenseCategory.advertising:
        return 'Advertising';
      case ExpenseCategory.tax:
        return 'Tax';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

ExpenseCategory expenseCategoryFromString(String value) {
  return ExpenseCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ExpenseCategory.other,
  );
}

enum PaymentMethod {
  cash,
  credit,
  transfer,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.transfer:
        return 'Transfer';
    }
  }
}

class ExpenseModel {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      }
      return 0.0;
    }
    return ExpenseModel(
      id: id,
      amount: parseAmount(map['amount']),
      category: map['category'] is String
          ? expenseCategoryFromString(map['category'])
          : ExpenseCategory.other,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category.name,
      'createdAt': createdAt,
    };
  }

  ExpenseModel copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Cleaned for Web Build by Cursor