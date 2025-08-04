import 'package:cloud_firestore/cloud_firestore.dart';

/// Spor salonu ödeme/gelir modeli
class SportsPayment {
  final String? id;
  final String userId;
  final String? memberId; // Üye ID'si
  final String? memberName; // Üye adı
  final String paymentType; // 'gelir', 'gider'
  final String category; // 'üyelik', 'PT', 'grup_dersi'
  final String description; // Açıklama
  final double amount; // Miktar
  final String paymentMethod; // 'nakit', 'kart', 'havale'
  final DateTime paymentDate; // Ödeme tarihi
  final String status; // 'ödendi', 'bekliyor', 'iptal'
  final String? notes; // Notlar
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  SportsPayment({
    this.id,
    required this.userId,
    this.memberId,
    this.memberName,
    required this.paymentType,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.status = 'bekliyor',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Firebase'den veri çekme
  factory SportsPayment.fromMap(Map<String, dynamic> map, String id) {
    return SportsPayment(
      id: id,
      userId: map['userId'] ?? '',
      memberId: map['memberId'],
      memberName: map['memberName'],
      paymentType: map['paymentType'] ?? 'gelir',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'nakit',
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'bekliyor',
      notes: map['notes'],
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
      'memberId': memberId,
      'memberName': memberName,
      'paymentType': paymentType,
      'category': category,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  // Formatlanmış tutar
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} ₺';
  }
}

/// Gider modeli (SportsPayment'in gider versiyonu)
class SportsExpense {
  final String? id;
  final String userId;
  final String category; // 'kira', 'maaş', 'ekipman', 'fatura', 'bakım'
  final String description;
  final double amount;
  final String paymentMethod;
  final DateTime expenseDate;
  final String status;
  final String? receiptNumber;
  final String? vendor; // Tedarikçi/firma
  final bool isRecurring;
  final String? recurringType;
  final DateTime? nextExpenseDate;
  final Map<String, dynamic>? recurringSettings;
  final String? notes;
  final List<String>? attachments;
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
    this.recurringSettings,
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
      recurringSettings: map['recurringSettings'],
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
      'recurringSettings': recurringSettings,
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
      default:
        return '💸';
    }
  }

  // Formatlanmış tutar
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} ₺';
  }
}
