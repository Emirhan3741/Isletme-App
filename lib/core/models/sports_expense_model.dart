import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor salonu gider modeli
class SportsExpense {
  final String? id;
  final String userId;
  final String
      category; // 'kira', 'maaş', 'ekipman', 'fatura', 'bakım', 'malzeme'
  final String description;
  final double amount;
  final String paymentMethod; // 'nakit', 'kart', 'havale', 'çek'
  final DateTime expenseDate;
  final String status; // 'ödendi', 'bekliyor', 'iptal'
  final String? receiptNumber; // Fiş/fatura numarası
  final String? vendor; // Tedarikçi/firma
  final bool isRecurring; // Tekrarlayan gider mi?
  final String? recurringType; // 'haftalık', 'aylık', 'yıllık'
  final DateTime? nextExpenseDate; // Sonraki gider tarihi
  final String? notes; // Notlar
  final List<String>? attachments; // Ek belgeler
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  SportsExpense({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.expenseDate,
    this.status = 'ödendi',
    this.receiptNumber,
    this.vendor,
    this.isRecurring = false,
    this.recurringType,
    this.nextExpenseDate,
    this.notes,
    this.attachments,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Firebase'den veri çekme
  factory SportsExpense.fromMap(Map<String, dynamic> map, String id) {
    return SportsExpense(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'nakit',
      expenseDate: (map['expenseDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'ödendi',
      receiptNumber: map['receiptNumber'],
      vendor: map['vendor'],
      isRecurring: map['isRecurring'] ?? false,
      recurringType: map['recurringType'],
      nextExpenseDate: map['nextExpenseDate'] != null
          ? (map['nextExpenseDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Firebase'e veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'status': status,
      'receiptNumber': receiptNumber,
      'vendor': vendor,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'nextExpenseDate':
          nextExpenseDate != null ? Timestamp.fromDate(nextExpenseDate!) : null,
      'notes': notes,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  // Kategori emojisi
  String get categoryEmoji {
    switch (category) {
      case 'kira':
        return '🏢';
      case 'maaş':
        return '👥';
      case 'ekipman':
        return '🏋️';
      case 'fatura':
        return '📄';
      case 'bakım':
        return '🔧';
      case 'malzeme':
        return '📦';
      default:
        return '💸';
    }
  }

  // Durum emojisi
  String get statusEmoji {
    switch (status) {
      case 'ödendi':
        return '✅';
      case 'bekliyor':
        return '⏳';
      case 'iptal':
        return '❌';
      default:
        return '⏳';
    }
  }

  // Ödeme yöntemi emojisi
  String get paymentMethodEmoji {
    switch (paymentMethod) {
      case 'nakit':
        return '💵';
      case 'kart':
        return '💳';
      case 'havale':
        return '🏦';
      case 'çek':
        return '📄';
      default:
        return '💳';
    }
  }

  // Formatlanmış tutar
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} ₺';
  }
}
