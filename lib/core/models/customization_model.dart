import 'package:cloud_firestore/cloud_firestore.dart';

class CustomizationSettings {
  final String id;
  final String userId;
  final String specialization;
  final Map<String, String> terminology; // Terminoloji özelleştirmeleri
  final Map<String, dynamic> colors; // Renk ayarları
  final List<String> serviceCategories; // Hizmet kategorileri
  final Map<String, String> statusLabels; // Durum etiketleri
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomizationSettings({
    required this.id,
    required this.userId,
    required this.specialization,
    required this.terminology,
    required this.colors,
    required this.serviceCategories,
    required this.statusLabels,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomizationSettings.fromMap(
      Map<String, dynamic> map, String documentId) {
    return CustomizationSettings(
      id: documentId,
      userId: map['userId'] ?? '',
      specialization: map['specialization'] ?? '',
      terminology: Map<String, String>.from(map['terminology'] ?? {}),
      colors: Map<String, dynamic>.from(map['colors'] ?? {}),
      serviceCategories: List<String>.from(map['serviceCategories'] ?? []),
      statusLabels: Map<String, String>.from(map['statusLabels'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialization': specialization,
      'terminology': terminology,
      'colors': colors,
      'serviceCategories': serviceCategories,
      'statusLabels': statusLabels,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CustomizationSettings copyWith({
    String? id,
    String? userId,
    String? specialization,
    Map<String, String>? terminology,
    Map<String, dynamic>? colors,
    List<String>? serviceCategories,
    Map<String, String>? statusLabels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomizationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialization: specialization ?? this.specialization,
      terminology: terminology ?? this.terminology,
      colors: colors ?? this.colors,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      statusLabels: statusLabels ?? this.statusLabels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Varsayılan özelleştirme ayarları
  factory CustomizationSettings.defaultForSpecialization(
      String userId, String specialization) {
    final terminology = _getDefaultTerminology(specialization);
    final colors = _getDefaultColors(specialization);
    final serviceCategories = _getDefaultServiceCategories(specialization);
    final statusLabels = _getDefaultStatusLabels(specialization);

    return CustomizationSettings(
      id: '',
      userId: userId,
      specialization: specialization,
      terminology: terminology,
      colors: colors,
      serviceCategories: serviceCategories,
      statusLabels: statusLabels,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Map<String, String> _getDefaultTerminology(String specialization) {
    switch (specialization) {
      case 'Diş Hekimi':
        return {
          'patient': 'Hasta',
          'appointment': 'Randevu',
          'treatment': 'Tedavi',
          'service': 'İşlem',
          'document': 'Belge',
          'payment': 'Ödeme',
          'note': 'Not',
          'dashboard': 'Panel',
          'clients': 'Hastalar',
          'calendar': 'Takvim',
          'treatments': 'Tedaviler',
          'services': 'İşlemler',
          'documents': 'Belgeler',
          'notes': 'Notlar',
          'employees': 'Çalışanlar',
          'reports': 'Raporlar',
          'expenses': 'Giderler',
          'revenue': 'Gelir',
        };
      case 'Psikolog':
        return {
          'patient': 'Danışan',
          'appointment': 'Seans',
          'treatment': 'Terapi',
          'service': 'Hizmet',
          'document': 'Dosya',
          'payment': 'Ödeme',
          'note': 'Not',
          'dashboard': 'Panel',
          'clients': 'Danışanlar',
          'calendar': 'Seans Takvimi',
          'treatments': 'Terapi Seansları',
          'services': 'Hizmetler',
          'documents': 'Dosyalar',
          'notes': 'Notlar',
          'employees': 'Çalışanlar',
          'reports': 'Raporlar',
          'expenses': 'Giderler',
          'revenue': 'Gelir',
        };
      case 'Fizyoterapist':
        return {
          'patient': 'Hasta',
          'appointment': 'Randevu',
          'treatment': 'Fizyoterapi',
          'service': 'Tedavi',
          'document': 'Rapor',
          'payment': 'Ödeme',
          'note': 'Not',
          'dashboard': 'Panel',
          'clients': 'Hastalar',
          'calendar': 'Randevu Takvimi',
          'treatments': 'Fizyoterapi Seansları',
          'services': 'Tedaviler',
          'documents': 'Raporlar',
          'notes': 'Notlar',
          'employees': 'Çalışanlar',
          'reports': 'Raporlar',
          'expenses': 'Giderler',
          'revenue': 'Gelir',
        };
      case 'Diyetisyen':
        return {
          'patient': 'Danışan',
          'appointment': 'Konsültasyon',
          'treatment': 'Diyet Planı',
          'service': 'Danışmanlık',
          'document': 'Plan',
          'payment': 'Ödeme',
          'note': 'Not',
          'dashboard': 'Panel',
          'clients': 'Danışanlar',
          'calendar': 'Konsültasyon Takvimi',
          'treatments': 'Diyet Planları',
          'services': 'Danışmanlık Hizmetleri',
          'documents': 'Planlar',
          'notes': 'Notlar',
          'employees': 'Çalışanlar',
          'reports': 'Raporlar',
          'expenses': 'Giderler',
          'revenue': 'Gelir',
        };
      default:
        return {
          'patient': 'Hasta',
          'appointment': 'Randevu',
          'treatment': 'Tedavi',
          'service': 'Hizmet',
          'document': 'Belge',
          'payment': 'Ödeme',
          'note': 'Not',
          'dashboard': 'Panel',
          'clients': 'Hastalar',
          'calendar': 'Takvim',
          'treatments': 'Tedaviler',
          'services': 'Hizmetler',
          'documents': 'Belgeler',
          'notes': 'Notlar',
          'employees': 'Çalışanlar',
          'reports': 'Raporlar',
          'expenses': 'Giderler',
          'revenue': 'Gelir',
        };
    }
  }

  static Map<String, dynamic> _getDefaultColors(String specialization) {
    switch (specialization) {
      case 'Diş Hekimi':
        return {
          'primary': '#2563EB', // Mavi
          'secondary': '#E5E7EB',
          'accent': '#10B981',
          'text': '#111827',
        };
      case 'Psikolog':
        return {
          'primary': '#7C3AED', // Mor
          'secondary': '#E5E7EB',
          'accent': '#F59E0B',
          'text': '#111827',
        };
      case 'Fizyoterapist':
        return {
          'primary': '#059669', // Yeşil
          'secondary': '#E5E7EB',
          'accent': '#DC2626',
          'text': '#111827',
        };
      case 'Diyetisyen':
        return {
          'primary': '#EA580C', // Turuncu
          'secondary': '#E5E7EB',
          'accent': '#16A34A',
          'text': '#111827',
        };
      default:
        return {
          'primary': '#0D9488', // Teal
          'secondary': '#E5E7EB',
          'accent': '#3B82F6',
          'text': '#111827',
        };
    }
  }

  static List<String> _getDefaultServiceCategories(String specialization) {
    switch (specialization) {
      case 'Diş Hekimi':
        return [
          'Muayene',
          'Dolgu',
          'Çekim',
          'Kanal Tedavisi',
          'İmplant',
          'Protez',
          'Temizlik',
          'Beyazlatma',
          'Ortodonti',
          'Diğer',
        ];
      case 'Psikolog':
        return [
          'Bireysel Terapi',
          'Çift Terapisi',
          'Aile Terapisi',
          'Grup Terapisi',
          'Psikolojik Test',
          'Danışmanlık',
          'Travma Terapisi',
          'Çocuk Terapisi',
          'Diğer',
        ];
      case 'Fizyoterapist':
        return [
          'Egzersiz Terapisi',
          'Manuel Terapi',
          'Elektroterapi',
          'Hidroterapi',
          'Solunum Fizyoterapisi',
          'Nörolojik Rehabilitasyon',
          'Ortopedik Rehabilitasyon',
          'Spor Fizyoterapisi',
          'Diğer',
        ];
      case 'Diyetisyen':
        return [
          'Beslenme Danışmanlığı',
          'Kilo Yönetimi',
          'Spor Beslenmesi',
          'Medikal Beslenme',
          'Çocuk Beslenmesi',
          'Geriatrik Beslenme',
          'Diyet Planı',
          'Takip Konsültasyonu',
          'Diğer',
        ];
      default:
        return [
          'Muayene',
          'Tedavi',
          'Konsültasyon',
          'Kontrol',
          'Test',
          'Rapor',
          'Danışmanlık',
          'Takip',
          'Diğer',
        ];
    }
  }

  static Map<String, String> _getDefaultStatusLabels(String specialization) {
    switch (specialization) {
      case 'Psikolog':
        return {
          'pending': 'Bekliyor',
          'confirmed': 'Onaylandı',
          'completed': 'Tamamlandı',
          'cancelled': 'İptal',
          'no_show': 'Gelmedi',
          'rescheduled': 'Ertelendi',
        };
      default:
        return {
          'pending': 'Bekliyor',
          'confirmed': 'Onaylandı',
          'completed': 'Tamamlandı',
          'cancelled': 'İptal',
          'no_show': 'Gelmedi',
          'rescheduled': 'Ertelendi',
        };
    }
  }
}
