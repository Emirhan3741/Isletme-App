import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'base_model.dart';

// Not Türleri
enum GradeType {
  exam('exam', 'Sınav'),
  quiz('quiz', 'Quiz'),
  homework('homework', 'Ödev'),
  project('project', 'Proje'),
  participation('participation', 'Katılım'),
  midterm('midterm', 'Ara Sınav'),
  finalExam('final', 'Final'),
  other('other', 'Diğer');

  const GradeType(this.value, this.displayName);
  final String value;
  final String displayName;
}

extension GradeTypeExtension on GradeType {
  IconData get icon {
    switch (this) {
      case GradeType.exam:
        return Icons.quiz;
      case GradeType.quiz:
        return Icons.help_outline;
      case GradeType.homework:
        return Icons.assignment;
      case GradeType.project:
        return Icons.work;
      case GradeType.participation:
        return Icons.people;
      case GradeType.midterm:
        return Icons.school;
      case GradeType.finalExam:
        return Icons.grade;
      case GradeType.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case GradeType.exam:
        return const Color(0xFF3B82F6);
      case GradeType.quiz:
        return const Color(0xFF8B5CF6);
      case GradeType.homework:
        return const Color(0xFF10B981);
      case GradeType.project:
        return const Color(0xFFF59E0B);
      case GradeType.participation:
        return const Color(0xFFEF4444);
      case GradeType.midterm:
        return const Color(0xFF06B6D4);
      case GradeType.finalExam:
        return const Color(0xFF84CC16);
      case GradeType.other:
        return const Color(0xFF6B7280);
    }
  }
}

class EducationGrade extends BaseModel {
  final String ogrenciId; // Student ID
  final String dersId; // Course ID
  final String? sinavId; // Exam ID (opsiyonel)
  final String baslik; // Not başlığı
  final String aciklama; // Açıklama
  final GradeType notTuru; // Not türü
  final double alinanPuan; // Alınan puan
  final double toplamPuan; // Toplam puan
  final DateTime notTarihi; // Notun verildiği tarih
  final DateTime? sinavTarihi; // Sınavın yapıldığı tarih
  final String? ogretmenId; // Notu veren öğretmen
  final String? ogretmenNotu; // Öğretmen notu/yorumu
  final bool gectiMi; // Geçti mi?
  final double? agirlik; // Notun ağırlığı (genel ortalamada)
  final String? seviye; // Öğrencinin seviyesi o tarihteki
  final Map<String, dynamic>?
      detaylar; // Detaylı puanlar (sözlü, yazılı, pratik vs)
  final bool aktif; // Aktif not mu (iptal edilmiş olabilir)
  final String? iptalNedeni; // İptal nedeni
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationGrade({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.ogrenciId,
    required this.dersId,
    this.sinavId,
    required this.baslik,
    this.aciklama = '',
    required this.notTuru,
    required this.alinanPuan,
    required this.toplamPuan,
    required this.notTarihi,
    this.sinavTarihi,
    this.ogretmenId,
    this.ogretmenNotu,
    this.gectiMi = false,
    this.agirlik = 1.0,
    this.seviye,
    this.detaylar,
    this.aktif = true,
    this.iptalNedeni,
    this.ekstraBilgiler,
  });

  // Yüzde hesaplama
  double get yuzde => toplamPuan > 0 ? (alinanPuan / toplamPuan) * 100 : 0.0;

  // Formatlanmış yüzde
  String get formatliYuzde => '${yuzde.toStringAsFixed(1)}%';

  // Formatlanmış puan
  String get formatliPuan =>
      '${alinanPuan.toStringAsFixed(1)}/${toplamPuan.toStringAsFixed(1)}';

  // Harf notu
  String get harfNotu {
    if (yuzde >= 90) return 'AA';
    if (yuzde >= 85) return 'BA';
    if (yuzde >= 80) return 'BB';
    if (yuzde >= 75) return 'CB';
    if (yuzde >= 70) return 'CC';
    if (yuzde >= 65) return 'DC';
    if (yuzde >= 60) return 'DD';
    if (yuzde >= 50) return 'FD';
    return 'FF';
  }

  // Başarı durumu rengi
  Color get basariRengi {
    if (yuzde >= 85) return const Color(0xFF10B981); // Yeşil - Çok İyi
    if (yuzde >= 70) return const Color(0xFF3B82F6); // Mavi - İyi
    if (yuzde >= 60) return const Color(0xFFF59E0B); // Sarı - Orta
    return const Color(0xFFEF4444); // Kırmızı - Kötü
  }

  // Başarı durumu metni
  String get basariDurumu {
    if (yuzde >= 85) return 'Çok İyi';
    if (yuzde >= 70) return 'İyi';
    if (yuzde >= 60) return 'Orta';
    if (yuzde >= 50) return 'Zayıf';
    return 'Başarısız';
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'ogrenciId': ogrenciId,
      'dersId': dersId,
      'sinavId': sinavId,
      'baslik': baslik,
      'aciklama': aciklama,
      'notTuru': notTuru.value,
      'alinanPuan': alinanPuan,
      'toplamPuan': toplamPuan,
      'notTarihi': Timestamp.fromDate(notTarihi),
      'sinavTarihi':
          sinavTarihi != null ? Timestamp.fromDate(sinavTarihi!) : null,
      'ogretmenId': ogretmenId,
      'ogretmenNotu': ogretmenNotu,
      'gectiMi': gectiMi,
      'agirlik': agirlik,
      'seviye': seviye,
      'detaylar': detaylar,
      'aktif': aktif,
      'iptalNedeni': iptalNedeni,
      'ekstraBilgiler': ekstraBilgiler,
      'yuzde': yuzde, // Hesaplanan değerler
      'harfNotu': harfNotu,
      'basariDurumu': basariDurumu,
    });
    return map;
  }

  static EducationGrade fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationGrade(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      ogrenciId: map['ogrenciId'] as String? ?? '',
      dersId: map['dersId'] as String? ?? '',
      sinavId: map['sinavId'] as String?,
      baslik: map['baslik'] as String? ?? '',
      aciklama: map['aciklama'] as String? ?? '',
      notTuru: GradeType.values.firstWhere(
        (type) => type.value == map['notTuru'],
        orElse: () => GradeType.other,
      ),
      alinanPuan: (map['alinanPuan'] as num?)?.toDouble() ?? 0.0,
      toplamPuan: (map['toplamPuan'] as num?)?.toDouble() ?? 100.0,
      notTarihi: (map['notTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sinavTarihi: (map['sinavTarihi'] as Timestamp?)?.toDate(),
      ogretmenId: map['ogretmenId'] as String?,
      ogretmenNotu: map['ogretmenNotu'] as String?,
      gectiMi: map['gectiMi'] as bool? ?? false,
      agirlik: (map['agirlik'] as num?)?.toDouble() ?? 1.0,
      seviye: map['seviye'] as String?,
      detaylar: map['detaylar'] as Map<String, dynamic>?,
      aktif: map['aktif'] as bool? ?? true,
      iptalNedeni: map['iptalNedeni'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationGrade copyWith({
    String? ogrenciId,
    String? dersId,
    String? sinavId,
    String? baslik,
    String? aciklama,
    GradeType? notTuru,
    double? alinanPuan,
    double? toplamPuan,
    DateTime? notTarihi,
    DateTime? sinavTarihi,
    String? ogretmenId,
    String? ogretmenNotu,
    bool? gectiMi,
    double? agirlik,
    String? seviye,
    Map<String, dynamic>? detaylar,
    bool? aktif,
    String? iptalNedeni,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationGrade(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      ogrenciId: ogrenciId ?? this.ogrenciId,
      dersId: dersId ?? this.dersId,
      sinavId: sinavId ?? this.sinavId,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      notTuru: notTuru ?? this.notTuru,
      alinanPuan: alinanPuan ?? this.alinanPuan,
      toplamPuan: toplamPuan ?? this.toplamPuan,
      notTarihi: notTarihi ?? this.notTarihi,
      sinavTarihi: sinavTarihi ?? this.sinavTarihi,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      ogretmenNotu: ogretmenNotu ?? this.ogretmenNotu,
      gectiMi: gectiMi ?? this.gectiMi,
      agirlik: agirlik ?? this.agirlik,
      seviye: seviye ?? this.seviye,
      detaylar: detaylar ?? this.detaylar,
      aktif: aktif ?? this.aktif,
      iptalNedeni: iptalNedeni ?? this.iptalNedeni,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      ogrenciId.isNotEmpty &&
      dersId.isNotEmpty &&
      baslik.isNotEmpty &&
      alinanPuan >= 0 &&
      toplamPuan > 0 &&
      alinanPuan <= toplamPuan;

  @override
  String toString() =>
      'EducationGrade(id: $id, baslik: $baslik, puan: $formatliPuan, yuzde: $formatliYuzde)';
}
