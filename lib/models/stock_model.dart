class StockModel {
  final String id;
  final String userId;
  final String productName;
  final String brand;
  final String category;
  final int quantity;
  final int minQuantity;
  final double unitPrice;
  final double? purchasePrice;
  final DateTime? expiryDate;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StockModel({
    required this.id,
    required this.userId,
    required this.productName,
    required this.brand,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    required this.unitPrice,
    this.purchasePrice,
    this.expiryDate,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      productName: map['productName'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      minQuantity: map['minQuantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      purchasePrice: map['purchasePrice']?.toDouble(),
      expiryDate: map['expiryDate']?.toDate(),
      description: map['description'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productName': productName,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'expiryDate': expiryDate,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  // Backward compatibility getters (sadece çakışmayan olanlar)
  String get name => productName;
  int get currentStock => quantity;
  int get minStock => minQuantity;
  double get salePrice => unitPrice;
  bool get isLowStock => quantity <= minQuantity;
}

enum StockCategory {
  shampoo('Şampuan'),
  conditioner('Saç Kremi'),
  hairTreatment('Saç Bakım'),
  skincare('Cilt Bakım'),
  makeup('Makyaj'),
  nailPolish('Oje'),
  nailCare('Tırnak Bakım'),
  wax('Ağda'),
  tools('Aletler'),
  cleaning('Temizlik'),
  other('Diğer');

  const StockCategory(this.displayName);
  final String displayName;
}

extension StockCategoryExtension on StockCategory {
  static StockCategory fromString(String value) {
    return StockCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => StockCategory.other,
    );
  }
}
