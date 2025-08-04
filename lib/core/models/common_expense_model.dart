import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

// Gider Kategorileri
enum ExpenseCategory {
  rent('rent', 'Kira'),
  utilities('utilities', 'Faturalar'),
  supplies('supplies', 'Malzemeler'),
  marketing('marketing', 'Pazarlama'),
  equipment('equipment', 'Ekipman'),
  salary('salary', 'Maaş'),
  maintenance('maintenance', 'Bakım'),
  other('other', 'Diğer');

  const ExpenseCategory(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Gider Durumları
enum ExpenseStatus {
  pending('pending', 'Beklemede'),
  paid('paid', 'Ödendi'),
  overdue('overdue', 'Gecikmiş'),
  cancelled('cancelled', 'İptal Edildi');

  const ExpenseStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Tekrarlama Türleri
enum RecurringType {
  none('none', 'Tekrarlanmaz'),
  daily('daily', 'Günlük'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık'),
  yearly('yearly', 'Yıllık');

  const RecurringType(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Ortak Gider Modeli
class CommonExpenseModel extends BaseModel
    implements StatusModel, CategoryModel, SectorModel {
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory expenseCategory;
  final ExpenseStatus expenseStatus;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isRecurring;
  final RecurringType recurringType;
  final DateTime? recurringEndDate;
  final String? receiptUrl;
  final String? vendor;
  final String notes;
  @override
  final Map<String, dynamic> sectorSpecificData;

  const CommonExpenseModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.title,
    this.description = '',
    required this.amount,
    required this.expenseCategory,
    this.expenseStatus = ExpenseStatus.pending,
    required this.dueDate,
    this.paidDate,
    this.isRecurring = false,
    this.recurringType = RecurringType.none,
    this.recurringEndDate,
    this.receiptUrl,
    this.vendor,
    this.notes = '',
    this.sectorSpecificData = const {},
  });

  factory CommonExpenseModel.fromMap(Map<String, dynamic> map) {
    final baseFields = BaseModel.getBaseFields(map);
    return CommonExpenseModel(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      expenseCategory: ExpenseCategory.values.firstWhere(
        (category) => category.value == (map['expenseCategory'] ?? 'other'),
        orElse: () => ExpenseCategory.other,
      ),
      expenseStatus: ExpenseStatus.values.firstWhere(
        (status) => status.value == (map['expenseStatus'] ?? 'pending'),
        orElse: () => ExpenseStatus.pending,
      ),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (map['paidDate'] as Timestamp?)?.toDate(),
      isRecurring: map['isRecurring'] ?? false,
      recurringType: RecurringType.values.firstWhere(
        (type) => type.value == (map['recurringType'] ?? 'none'),
        orElse: () => RecurringType.none,
      ),
      recurringEndDate: (map['recurringEndDate'] as Timestamp?)?.toDate(),
      receiptUrl: map['receiptUrl'],
      vendor: map['vendor'],
      notes: map['notes'] ?? '',
      sectorSpecificData:
          Map<String, dynamic>.from(map['sectorSpecificData'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'title': title,
      'description': description,
      'amount': amount,
      'expenseCategory': expenseCategory.value,
      'expenseStatus': expenseStatus.value,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'isRecurring': isRecurring,
      'recurringType': recurringType.value,
      'recurringEndDate': recurringEndDate != null
          ? Timestamp.fromDate(recurringEndDate!)
          : null,
      'receiptUrl': receiptUrl,
      'vendor': vendor,
      'notes': notes,
      'sectorSpecificData': sectorSpecificData,
    });
    return map;
  }

  // StatusModel implementation
  @override
  String get status => expenseStatus.value;

  @override
  bool get isActive => expenseStatus != ExpenseStatus.cancelled;

  // CategoryModel implementation
  @override
  String get category => expenseCategory.value;

  @override
  String get categoryDisplayName => expenseCategory.displayName;

  // SectorModel implementation
  @override
  String get sector => sectorSpecificData['sector'] ?? '';

  // Utility methods
  bool get isPaid => expenseStatus == ExpenseStatus.paid;

  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  bool get isDueSoon {
    if (isPaid) return false;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  // Next recurring date calculation
  DateTime? get nextRecurringDate {
    if (!isRecurring || recurringType == RecurringType.none) return null;
    if (recurringEndDate != null && DateTime.now().isAfter(recurringEndDate!)) {
      return null;
    }

    DateTime nextDate = dueDate;
    final now = DateTime.now();

    while (nextDate.isBefore(now)) {
      switch (recurringType) {
        case RecurringType.daily:
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case RecurringType.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case RecurringType.monthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case RecurringType.yearly:
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        case RecurringType.none:
          return null;
      }
    }

    return nextDate;
  }

  CommonExpenseModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? expenseCategory,
    ExpenseStatus? expenseStatus,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isRecurring,
    RecurringType? recurringType,
    DateTime? recurringEndDate,
    String? receiptUrl,
    String? vendor,
    String? notes,
    Map<String, dynamic>? sectorSpecificData,
  }) {
    return CommonExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      expenseStatus: expenseStatus ?? this.expenseStatus,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      vendor: vendor ?? this.vendor,
      notes: notes ?? this.notes,
      sectorSpecificData: sectorSpecificData ?? this.sectorSpecificData,
    );
  }
}
