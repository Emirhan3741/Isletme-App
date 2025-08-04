import 'package:flutter/material.dart';

class LoyaltyModel {
  final String id;
  final String customerId;
  final String customerName;
  final int points;
  final LoyaltyTier tier;
  final List<LoyaltyTransaction> transactions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  LoyaltyModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.points = 0,
    this.tier = LoyaltyTier.bronze,
    this.transactions = const [],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory LoyaltyModel.fromMap(Map<String, dynamic> map) {
    return LoyaltyModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      points: map['points'] ?? 0,
      tier: LoyaltyTierExtension.fromString(map['tier'] ?? 'bronze'),
      transactions: (map['transactions'] as List<dynamic>?)
              ?.map((e) => LoyaltyTransaction.fromMap(e))
              .toList() ??
          [],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'points': points,
      'tier': tier.name,
      'transactions': transactions.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'isActive': isActive,
    };
  }

  LoyaltyModel copyWith({
    int? points,
    LoyaltyTier? tier,
    List<LoyaltyTransaction>? transactions,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return LoyaltyModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Puan ekleme
  LoyaltyModel addPoints(int pointsToAdd, String reason, String serviceId) {
    final newPoints = points + pointsToAdd;
    final newTier = LoyaltyTierExtension.getTierByPoints(newPoints);
    final newTransaction = LoyaltyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LoyaltyTransactionType.earned,
      points: pointsToAdd,
      reason: reason,
      serviceId: serviceId,
      createdAt: DateTime.now(),
    );

    return copyWith(
      points: newPoints,
      tier: newTier,
      transactions: [...transactions, newTransaction],
      updatedAt: DateTime.now(),
    );
  }

  // Puan kullanma
  LoyaltyModel usePoints(int pointsToUse, String reason) {
    if (pointsToUse > points) {
      throw Exception(
          'Yetersiz puan! Mevcut: $points, Kullanmak istenen: $pointsToUse');
    }

    final newPoints = points - pointsToUse;
    final newTier = LoyaltyTierExtension.getTierByPoints(newPoints);
    final newTransaction = LoyaltyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LoyaltyTransactionType.redeemed,
      points: -pointsToUse,
      reason: reason,
      createdAt: DateTime.now(),
    );

    return copyWith(
      points: newPoints,
      tier: newTier,
      transactions: [...transactions, newTransaction],
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'LoyaltyModel(customerId: $customerId, points: $points, tier: ${tier.displayName})';
}

class LoyaltyTransaction {
  final String id;
  final LoyaltyTransactionType type;
  final int points;
  final String reason;
  final String? serviceId;
  final String? campaignId;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.reason,
    this.serviceId,
    this.campaignId,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      id: map['id'] ?? '',
      type: LoyaltyTransactionTypeExtension.fromString(map['type'] ?? 'earned'),
      points: map['points'] ?? 0,
      reason: map['reason'] ?? '',
      serviceId: map['serviceId'],
      campaignId: map['campaignId'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'points': points,
      'reason': reason,
      'serviceId': serviceId,
      'campaignId': campaignId,
      'createdAt': createdAt,
    };
  }
}

enum LoyaltyTier {
  bronze('Bronz', 0, Colors.brown, Icons.workspace_premium, 1.0),
  silver('Gümüş', 500, Colors.grey, Icons.star, 1.1),
  gold('Altın', 1500, Colors.amber, Icons.star_border, 1.2),
  platinum('Platin', 3000, Colors.purple, Icons.diamond, 1.3),
  vip('VIP', 5000, Colors.red, Icons.stars,
      1.5); // Changed from Icons.crown to Icons.stars

  const LoyaltyTier(this.displayName, this.requiredPoints, this.color,
      this.icon, this.discountMultiplier);

  final String displayName;
  final int requiredPoints;
  final Color color;
  final IconData icon;
  final double discountMultiplier; // İndirim çarpanı
}

extension LoyaltyTierExtension on LoyaltyTier {
  static LoyaltyTier fromString(String value) {
    return LoyaltyTier.values.firstWhere(
      (tier) => tier.name == value,
      orElse: () => LoyaltyTier.bronze,
    );
  }

  static LoyaltyTier getTierByPoints(int points) {
    if (points >= LoyaltyTier.vip.requiredPoints) {
      return LoyaltyTier.vip;
    }
    if (points >= LoyaltyTier.platinum.requiredPoints) {
      return LoyaltyTier.platinum;
    }
    if (points >= LoyaltyTier.gold.requiredPoints) {
      return LoyaltyTier.gold;
    }
    if (points >= LoyaltyTier.silver.requiredPoints) {
      return LoyaltyTier.silver;
    }
    return LoyaltyTier.bronze;
  }

  // Bir sonraki seviyeye kadar gereken puan
  int pointsToNextTier(int currentPoints) {
    const tiers = LoyaltyTier.values;
    final currentIndex = tiers.indexOf(this);
    if (currentIndex == tiers.length - 1) return 0; // Zaten en üst seviye

    final nextTier = tiers[currentIndex + 1];
    return nextTier.requiredPoints - currentPoints;
  }
}

enum LoyaltyTransactionType {
  earned('Kazanılan', Icons.add, Colors.green),
  redeemed('Kullanılan', Icons.remove, Colors.red),
  expired('Süresi Dolmuş', Icons.access_time, Colors.orange),
  bonus('Bonus', Icons.card_giftcard, Colors.purple);

  const LoyaltyTransactionType(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;
}

extension LoyaltyTransactionTypeExtension on LoyaltyTransactionType {
  static LoyaltyTransactionType fromString(String value) {
    return LoyaltyTransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LoyaltyTransactionType.earned,
    );
  }
}

// Sadakat kampanyaları
class LoyaltyCampaign {
  final String id;
  final String title;
  final String description;
  final CampaignType type;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> rewards;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  LoyaltyCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.conditions,
    required this.rewards,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory LoyaltyCampaign.fromMap(Map<String, dynamic> map) {
    return LoyaltyCampaign(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: CampaignTypeExtension.fromString(map['type'] ?? 'pointMultiplier'),
      conditions: Map<String, dynamic>.from(map['conditions'] ?? {}),
      rewards: Map<String, dynamic>.from(map['rewards'] ?? {}),
      startDate: map['startDate']?.toDate() ?? DateTime.now(),
      endDate: map['endDate']?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'conditions': conditions,
      'rewards': rewards,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

enum CampaignType {
  pointMultiplier(
      'Puan Çarpanı', Icons.close, 'Belirli hizmetlerde ekstra puan'),
  freeService('Bedava Hizmet', Icons.card_giftcard, 'X hizmet al, 1 bedava'),
  discount('İndirim', Icons.percent, 'Belirli hizmetlerde indirim'),
  birthdayBonus('Doğum Günü Bonusu', Icons.cake, 'Doğum günü özel indirimi'),
  referralBonus('Arkadaş Getir', Icons.group_add, 'Arkadaş getirme bonusu');

  const CampaignType(this.displayName, this.icon, this.description);

  final String displayName;
  final IconData icon;
  final String description;
}

extension CampaignTypeExtension on CampaignType {
  static CampaignType fromString(String value) {
    return CampaignType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CampaignType.pointMultiplier,
    );
  }
}

// Önceden tanımlı kampanyalar
class LoyaltyCampaignTemplates {
  static List<LoyaltyCampaign> getDefaultCampaigns() {
    final now = DateTime.now();
    return [
      LoyaltyCampaign(
        id: 'welcome_bonus',
        title: 'Hoş Geldin Bonusu',
        description: 'İlk randevunuzda 100 bonus puan!',
        type: CampaignType.pointMultiplier,
        conditions: {'minVisits': 1, 'maxVisits': 1},
        rewards: {'bonusPoints': 100},
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        createdAt: now,
      ),
      LoyaltyCampaign(
        id: 'hair_service_5plus1',
        title: '5 Al 1 Bedava - Saç Hizmetleri',
        description: '5 saç hizmeti aldığınızda 6.sı bedava!',
        type: CampaignType.freeService,
        conditions: {'serviceCategory': 'hairCare', 'requiredCount': 5},
        rewards: {'freeServiceCategory': 'hairCare'},
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        createdAt: now,
      ),
      LoyaltyCampaign(
        id: 'birthday_discount',
        title: 'Doğum Günü İndirimi',
        description: 'Doğum gününüzde tüm hizmetlerde %20 indirim!',
        type: CampaignType.birthdayBonus,
        conditions: {'birthdayMonth': true},
        rewards: {'discountPercent': 20},
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        createdAt: now,
      ),
      LoyaltyCampaign(
        id: 'referral_bonus',
        title: 'Arkadaş Getir Bonusu',
        description: 'Arkadaşınızı getirin, her ikiniz de 150 puan kazanın!',
        type: CampaignType.referralBonus,
        conditions: {'newCustomerRequired': true},
        rewards: {'bonusPointsReferrer': 150, 'bonusPointsReferred': 150},
        startDate: now,
        endDate: now.add(const Duration(days: 180)),
        createdAt: now,
      ),
    ];
  }
}
