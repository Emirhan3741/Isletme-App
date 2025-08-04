import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final BeautyServiceCategory category;
  final double price;
  final int durationMinutes;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double commissionRate;
  final List<String> requiredMaterials;
  final List<String> compatibleSpecialties;
  final String? imageUrl;
  final bool isPopular;
  final int? preparationTimeMinutes;
  final String? afterCareInstructions;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.commissionRate = 0.0,
    this.requiredMaterials = const [],
    this.compatibleSpecialties = const [],
    this.imageUrl,
    this.isPopular = false,
    this.preparationTimeMinutes,
    this.afterCareInstructions,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category:
          BeautyServiceCategoryExtension.fromString(map['category'] ?? 'other'),
      price: (map['price'] ?? 0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 30,
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      requiredMaterials: List<String>.from(map['requiredMaterials'] ?? []),
      compatibleSpecialties:
          List<String>.from(map['compatibleSpecialties'] ?? []),
      imageUrl: map['imageUrl'],
      isPopular: map['isPopular'] ?? false,
      preparationTimeMinutes: map['preparationTimeMinutes'],
      afterCareInstructions: map['afterCareInstructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'commissionRate': commissionRate,
      'requiredMaterials': requiredMaterials,
      'compatibleSpecialties': compatibleSpecialties,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'preparationTimeMinutes': preparationTimeMinutes,
      'afterCareInstructions': afterCareInstructions,
    };
  }

  ServiceModel copyWith({
    String? name,
    BeautyServiceCategory? category,
    double? price,
    int? durationMinutes,
    String? description,
    bool? isActive,
    DateTime? updatedAt,
    double? commissionRate,
    List<String>? requiredMaterials,
    List<String>? compatibleSpecialties,
    String? imageUrl,
    bool? isPopular,
    int? preparationTimeMinutes,
    String? afterCareInstructions,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      commissionRate: commissionRate ?? this.commissionRate,
      requiredMaterials: requiredMaterials ?? this.requiredMaterials,
      compatibleSpecialties:
          compatibleSpecialties ?? this.compatibleSpecialties,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      afterCareInstructions:
          afterCareInstructions ?? this.afterCareInstructions,
    );
  }

  String get formattedPrice => '₺${price.toStringAsFixed(0)}';
  String get formattedDuration => '${durationMinutes} dk';

  @override
  String toString() =>
      'ServiceModel(id: $id, name: $name, category: ${category.displayName})';
}

enum BeautyServiceCategory {
  // Genel Kategoriler
  hairCare('Saç Bakımı', '💇‍♀️', Icons.content_cut, Colors.brown,
      'Saç bakım hizmetleri'),
  skinCare('Cilt Bakımı', '✨', Icons.face, Colors.lightGreen,
      'Cilt bakım hizmetleri'),
  nailCare('Tırnak Bakımı', '💅', Icons.back_hand, Colors.pink,
      'Tırnak bakım hizmetleri'),
  massage('Masaj', '💆‍♀️', Icons.healing, Colors.green, 'Masaj hizmetleri'),
  waxing('Ağda', '🦵', Icons.clean_hands, Colors.teal, 'Ağda hizmetleri'),
  makeup('Makyaj', '💄', Icons.face, Colors.pink, 'Makyaj hizmetleri'),
  facialTreatments('Yüz Bakımı', '😊', Icons.face_retouching_natural,
      Colors.green, 'Yüz bakım tedavileri'),
  bodyTreatments(
      'Vücut Bakımı', '🛁', Icons.spa, Colors.blue, 'Vücut bakım tedavileri'),
  specialTreatments(
      'Özel Tedaviler', '⭐', Icons.star, Colors.amber, 'Özel bakım tedavileri'),

  // Saç Hizmetleri
  hairCut('Saç Kesimi', '💇‍♀️', Icons.content_cut, Colors.brown,
      'Kadın ve erkek saç kesimi hizmetleri'),
  hairWash('Saç Yıkama', '🧴', Icons.local_car_wash, Colors.blue,
      'Şampuan ve bakım ürünleri ile saç yıkama'),
  hairDrying(
      'Fön', '💨', Icons.air, Colors.cyan, 'Profesyonel fön çekme hizmeti'),
  hairColoring('Saç Boyama', '🎨', Icons.palette, Colors.purple,
      'Saç renk değişimi ve boyama'),
  hairHighlights('Röfle/Balyaj', '✨', Icons.auto_fix_high, Colors.amber,
      'Saç renklendirme teknikleri'),
  hairTreatment('Saç Bakımı', '💆‍♀️', Icons.spa, Colors.green,
      'Keratin, botoks ve bakım maskeleri'),

  // Tırnak Hizmetleri
  manicure(
      'Manikür', '💅', Icons.back_hand, Colors.pink, 'El ve tırnak bakımı'),
  pedicure('Pedikür', '🦶', Icons.spa, Colors.teal, 'Ayak ve tırnak bakımı'),
  nailArt('Nail Art', '🎨', Icons.brush, Colors.deepPurple,
      'Tırnak süsleme ve sanat'),
  gelNails('Kalıcı Oje', '💎', Icons.diamond, Colors.red,
      'Kalıcı oje ve jel tırnak'),

  // Cilt Bakımı
  facialCleaning('Cilt Temizliği', '✨', Icons.face, Colors.lightGreen,
      'Derin cilt temizliği'),
  facialMask('Yüz Maskesi', '🧴', Icons.face_retouching_natural, Colors.green,
      'Besleyici ve nemlendirici maskeler'),
  antiAging('Anti-Aging', '⏰', Icons.refresh, Colors.orange,
      'Yaşlanma karşıtı bakım'),
  acneTreatment('Akne Tedavisi', '🔬', Icons.healing, Colors.red,
      'Akne ve sivilce tedavisi'),

  // Makyaj
  dailyMakeup('Günlük Makyaj', '💄', Icons.face, Colors.pink,
      'Günlük kullanım makyajı'),
  eventMakeup('Özel Gün Makyajı', '👰', Icons.celebration, Colors.amber,
      'Düğün, nişan ve özel günler'),
  eyeMakeup('Göz Makyajı', '👁️', Icons.visibility, Colors.indigo,
      'Göz çevresi makyajı'),

  // Kaş ve Kirpik
  eyebrowShaping('Kaş Şekillendirme', '👁️', Icons.visibility, Colors.brown,
      'Kaş alma ve şekillendirme'),
  eyebrowTinting(
      'Kaş Boyama', '🎨', Icons.brush, Colors.deepOrange, 'Kaş renklendirme'),
  eyelashExtension('Kirpik Uzatma', '👁️', Icons.remove_red_eye, Colors.black,
      'Takma kirpik uygulaması'),
  eyelashLifting('Kirpik Lifting', '⬆️', Icons.keyboard_arrow_up, Colors.grey,
      'Kirpik kaldırma ve kıvırma'),

  // Ağda ve Epilasyon
  waxingLegs('Bacak Ağdası', '🦵', Icons.clean_hands, Colors.teal,
      'Bacak bölgesi ağda'),
  waxingArms(
      'Kol Ağdası', '💪', Icons.clean_hands, Colors.blue, 'Kol bölgesi ağda'),
  waxingFace('Yüz Ağdası', '😊', Icons.face, Colors.pink, 'Yüz bölgesi ağda'),
  waxingBikini('Bikini Ağdası', '👙', Icons.clean_hands, Colors.purple,
      'Bikini bölgesi ağda'),

  // Masaj
  relaxingMassage('Rahatlatıcı Masaj', '💆‍♀️', Icons.healing, Colors.green,
      'Stres giderici masaj'),
  aromatherapy('Aromaterapi', '🌸', Icons.local_florist, Colors.purple,
      'Aromaterapi masajı'),
  hotStone('Sıcak Taş Masajı', '🔥', Icons.spa, Colors.orange,
      'Sıcak taş ile masaj'),

  // Diğer
  other('Diğer', '📋', Icons.more_horiz, Colors.grey, 'Diğer hizmetler');

  const BeautyServiceCategory(
    this.displayName,
    this.emoji,
    this.icon,
    this.color,
    this.description,
  );

  final String displayName;
  final String emoji;
  final IconData icon;
  final Color color;
  final String description;
}

extension BeautyServiceCategoryExtension on BeautyServiceCategory {
  static BeautyServiceCategory fromString(String value) {
    return BeautyServiceCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => BeautyServiceCategory.other,
    );
  }
}

// Önceden tanımlı popüler hizmetler
class BeautyServiceTemplates {
  static List<ServiceModel> getDefaultServices() {
    final now = DateTime.now();
    return [
      // Saç Hizmetleri
      ServiceModel(
        id: 'hair_cut_women',
        name: 'Kadın Saç Kesimi',
        category: BeautyServiceCategory.hairCut,
        price: 150,
        durationMinutes: 45,
        description: 'Profesyonel kadın saç kesimi ve şekillendirme',
        createdAt: now,
        commissionRate: 0.3,
        requiredMaterials: ['Makas', 'Tarak', 'Saç Spreyi'],
        compatibleSpecialties: ['hairstylist'],
        isPopular: true,
      ),
      ServiceModel(
        id: 'hair_coloring',
        name: 'Saç Boyama',
        category: BeautyServiceCategory.hairColoring,
        price: 300,
        durationMinutes: 120,
        description: 'Saç renk değişimi ve boyama işlemi',
        createdAt: now,
        commissionRate: 0.25,
        requiredMaterials: ['Saç Boyası', 'Oksidan', 'Eldiven', 'Fırça'],
        compatibleSpecialties: ['colorist', 'hairstylist'],
        preparationTimeMinutes: 15,
        afterCareInstructions: 'İlk 48 saat saçı yıkamayın',
      ),
      ServiceModel(
        id: 'hair_drying',
        name: 'Fön',
        category: BeautyServiceCategory.hairDrying,
        price: 80,
        durationMinutes: 30,
        description: 'Profesyonel fön çekme',
        createdAt: now,
        commissionRate: 0.4,
        requiredMaterials: ['Fön Makinesi', 'Fırça', 'Saç Spreyi'],
        compatibleSpecialties: ['hairstylist'],
        isPopular: true,
      ),

      // Tırnak Hizmetleri
      ServiceModel(
        id: 'manicure_classic',
        name: 'Klasik Manikür',
        category: BeautyServiceCategory.manicure,
        price: 120,
        durationMinutes: 60,
        description: 'El bakımı ve klasik manikür',
        createdAt: now,
        commissionRate: 0.35,
        requiredMaterials: ['Tırnak Makası', 'Törpü', 'Oje', 'El Kremi'],
        compatibleSpecialties: ['nailTechnician'],
        isPopular: true,
      ),
      ServiceModel(
        id: 'gel_nails',
        name: 'Kalıcı Oje',
        category: BeautyServiceCategory.gelNails,
        price: 180,
        durationMinutes: 90,
        description: 'UV jel ile kalıcı oje uygulaması',
        createdAt: now,
        commissionRate: 0.3,
        requiredMaterials: ['Jel Oje', 'UV Lamba', 'Base Coat', 'Top Coat'],
        compatibleSpecialties: ['nailTechnician'],
        afterCareInstructions:
            '2-3 hafta dayanır, su ile temas ettikten sonra kurulayın',
      ),

      // Cilt Bakımı
      ServiceModel(
        id: 'facial_cleaning',
        name: 'Cilt Temizliği',
        category: BeautyServiceCategory.facialCleaning,
        price: 200,
        durationMinutes: 75,
        description: 'Derin cilt temizliği ve bakım',
        createdAt: now,
        commissionRate: 0.25,
        requiredMaterials: ['Temizlik Kremi', 'Tonik', 'Maske', 'Nemlendirici'],
        compatibleSpecialties: ['esthetician'],
        preparationTimeMinutes: 10,
        afterCareInstructions: '24 saat güneşe çıkmayın, bol su için',
      ),

      // Kaş Hizmetleri
      ServiceModel(
        id: 'eyebrow_shaping',
        name: 'Kaş Şekillendirme',
        category: BeautyServiceCategory.eyebrowShaping,
        price: 100,
        durationMinutes: 30,
        description: 'İplik yöntemi ile kaş alma',
        createdAt: now,
        commissionRate: 0.4,
        requiredMaterials: ['İplik', 'Kaş Makası', 'Kaş Fırçası'],
        compatibleSpecialties: ['eyebrowSpecialist', 'esthetician'],
        isPopular: true,
      ),
    ];
  }
}
