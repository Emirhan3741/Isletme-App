import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class EducationDocument extends BaseModel implements CategoryModel {
  final String dosyaAdi;
  final String aciklama;
  final String
      kategori; // sinav_sonucu, yoklama, gelisim_raporu, sertifika, diger
  final String dosyaTuru; // pdf, image, doc, excel, txt
  final String dosyaUrl; // Firebase Storage URL
  final String? ogrenciId; // Öğrenciye özel belgeler için
  final String? dersId; // Derse özel belgeler için
  final String? ogretmenId; // Öğretmene özel belgeler için
  final bool herkesGorebilir; // Public/Private belge
  final List<String> erisimYetkisi; // Erişim yetkisi olan kullanıcılar
  final double dosyaBoyutu; // Byte cinsinden
  final String dosyaFormati; // application/pdf, image/jpeg, vb.
  final DateTime yuklemeTarihi;
  final String? klasor; // Klasör yapısı
  final Map<String, dynamic>? metaData; // Ek bilgiler
  final bool arsivlendi; // Arşivlenmiş mi?
  final int indirmeSayisi; // Kaç kez indirildi
  final DateTime? sonIndirmeTarihi; // Son indirme tarihi
  final String? etiketler; // Arama için etiketler
  final bool silinebilir; // Silinebilir mi?
  final bool duzenlenebilir; // Düzenlenebilir mi?
  final String? versiyonNo; // Versiyon bilgisi
  final String? eskiVersionId; // Eski version ID
  final Map<String, dynamic>? ekstraBilgiler;

  const EducationDocument({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.updatedAt,
    required this.dosyaAdi,
    required this.aciklama,
    required this.kategori,
    required this.dosyaTuru,
    required this.dosyaUrl,
    this.ogrenciId,
    this.dersId,
    this.ogretmenId,
    this.herkesGorebilir = false,
    this.erisimYetkisi = const [],
    required this.dosyaBoyutu,
    required this.dosyaFormati,
    required this.yuklemeTarihi,
    this.klasor,
    this.metaData,
    this.arsivlendi = false,
    this.indirmeSayisi = 0,
    this.sonIndirmeTarihi,
    this.etiketler,
    this.silinebilir = true,
    this.duzenlenebilir = true,
    this.versiyonNo,
    this.eskiVersionId,
    this.ekstraBilgiler,
  });

  // CategoryModel implementation
  @override
  String get category => kategori;

  @override
  String get categoryDisplayName => _getCategoryDisplayName(kategori);

  // Dosya boyutu formatı
  String get formatliDosyaBoyutu {
    if (dosyaBoyutu < 1024) {
      return '${dosyaBoyutu.toStringAsFixed(0)} B';
    } else if (dosyaBoyutu < 1024 * 1024) {
      return '${(dosyaBoyutu / 1024).toStringAsFixed(1)} KB';
    } else if (dosyaBoyutu < 1024 * 1024 * 1024) {
      return '${(dosyaBoyutu / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(dosyaBoyutu / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Dosya türü ikonu
  String get dosyaTuruIcon {
    switch (dosyaTuru.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'excel':
      case 'xlsx':
      case 'xls':
        return '📊';
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'video':
      case 'mp4':
      case 'avi':
        return '🎥';
      case 'audio':
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'txt':
        return '📋';
      case 'zip':
      case 'rar':
        return '🗜️';
      default:
        return '📎';
    }
  }

  // Kategori ikonu
  String get kategoriIcon {
    switch (kategori) {
      case 'sinav_sonucu':
        return '📊';
      case 'yoklama':
        return '✅';
      case 'gelisim_raporu':
        return '📈';
      case 'sertifika':
        return '🏆';
      case 'odev':
        return '📚';
      case 'proje':
        return '💻';
      case 'belge':
        return '📋';
      case 'resim':
        return '🖼️';
      default:
        return '📄';
    }
  }

  // Özel belge mi?
  bool get ozelBelge =>
      ogrenciId != null || dersId != null || ogretmenId != null;

  // Kime ait
  String get sahiplik {
    if (ogrenciId != null) return 'Öğrenciye Özel';
    if (dersId != null) return 'Derse Özel';
    if (ogretmenId != null) return 'Öğretmene Özel';
    return 'Genel';
  }

  // Dosya uzantısı
  String get uzanti {
    final parts = dosyaAdi.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Tam klasör yolu
  String get tamKlasorYolu {
    if (klasor == null || klasor!.isEmpty) return '/';
    return klasor!.startsWith('/') ? klasor! : '/$klasor';
  }

  // Popülerlik skoru
  double get populerlikSkoru {
    if (indirmeSayisi == 0) return 0.0;
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    if (daysSinceCreated == 0) return indirmeSayisi.toDouble();
    return indirmeSayisi / daysSinceCreated;
  }

  // Son indirme bilgisi
  String get sonIndirmeBilgisi {
    if (sonIndirmeTarihi == null) return 'Hiç indirilmedi';

    final now = DateTime.now();
    final difference = now.difference(sonIndirmeTarihi!);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'sinav_sonucu':
        return 'Sınav Sonucu';
      case 'yoklama':
        return 'Yoklama';
      case 'gelisim_raporu':
        return 'Gelişim Raporu';
      case 'sertifika':
        return 'Sertifika';
      case 'odev':
        return 'Ödev';
      case 'proje':
        return 'Proje';
      case 'belge':
        return 'Belge';
      case 'resim':
        return 'Resim';
      case 'video':
        return 'Video';
      case 'diger':
        return 'Diğer';
      default:
        return category;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.baseToMap();
    map.addAll({
      'dosyaAdi': dosyaAdi,
      'aciklama': aciklama,
      'kategori': kategori,
      'dosyaTuru': dosyaTuru,
      'dosyaUrl': dosyaUrl,
      'ogrenciId': ogrenciId,
      'dersId': dersId,
      'ogretmenId': ogretmenId,
      'herkesGorebilir': herkesGorebilir,
      'erisimYetkisi': erisimYetkisi,
      'dosyaBoyutu': dosyaBoyutu,
      'dosyaFormati': dosyaFormati,
      'yuklemeTarihi': Timestamp.fromDate(yuklemeTarihi),
      'klasor': klasor,
      'metaData': metaData,
      'arsivlendi': arsivlendi,
      'indirmeSayisi': indirmeSayisi,
      'sonIndirmeTarihi': sonIndirmeTarihi != null
          ? Timestamp.fromDate(sonIndirmeTarihi!)
          : null,
      'etiketler': etiketler,
      'silinebilir': silinebilir,
      'duzenlenebilir': duzenlenebilir,
      'versiyonNo': versiyonNo,
      'eskiVersionId': eskiVersionId,
      'ekstraBilgiler': ekstraBilgiler,
      'formatliDosyaBoyutu': formatliDosyaBoyutu, // Arama için
      'sahiplik': sahiplik, // Filtreleme için
      'uzanti': uzanti, // Filtreleme için
      'populerlikSkoru': populerlikSkoru, // Sıralama için
    });
    return map;
  }

  static EducationDocument fromMap(Map<String, dynamic> map, String id) {
    final baseFields = BaseModel.getBaseFields(map);

    return EducationDocument(
      id: baseFields['id'],
      userId: baseFields['userId'],
      createdAt: baseFields['createdAt'],
      updatedAt: baseFields['updatedAt'],
      dosyaAdi: map['dosyaAdi'] as String? ?? '',
      aciklama: map['aciklama'] as String? ?? '',
      kategori: map['kategori'] as String? ?? 'diger',
      dosyaTuru: map['dosyaTuru'] as String? ?? '',
      dosyaUrl: map['dosyaUrl'] as String? ?? '',
      ogrenciId: map['ogrenciId'] as String?,
      dersId: map['dersId'] as String?,
      ogretmenId: map['ogretmenId'] as String?,
      herkesGorebilir: map['herkesGorebilir'] as bool? ?? false,
      erisimYetkisi: List<String>.from(map['erisimYetkisi'] ?? []),
      dosyaBoyutu: (map['dosyaBoyutu'] as num?)?.toDouble() ?? 0.0,
      dosyaFormati: map['dosyaFormati'] as String? ?? '',
      yuklemeTarihi:
          (map['yuklemeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      klasor: map['klasor'] as String?,
      metaData: map['metaData'] as Map<String, dynamic>?,
      arsivlendi: map['arsivlendi'] as bool? ?? false,
      indirmeSayisi: map['indirmeSayisi'] as int? ?? 0,
      sonIndirmeTarihi: (map['sonIndirmeTarihi'] as Timestamp?)?.toDate(),
      etiketler: map['etiketler'] as String?,
      silinebilir: map['silinebilir'] as bool? ?? true,
      duzenlenebilir: map['duzenlenebilir'] as bool? ?? true,
      versiyonNo: map['versiyonNo'] as String?,
      eskiVersionId: map['eskiVersionId'] as String?,
      ekstraBilgiler: map['ekstraBilgiler'] as Map<String, dynamic>?,
    );
  }

  EducationDocument copyWith({
    String? dosyaAdi,
    String? aciklama,
    String? kategori,
    String? dosyaTuru,
    String? dosyaUrl,
    String? ogrenciId,
    String? dersId,
    String? ogretmenId,
    bool? herkesGorebilir,
    List<String>? erisimYetkisi,
    double? dosyaBoyutu,
    String? dosyaFormati,
    DateTime? yuklemeTarihi,
    String? klasor,
    Map<String, dynamic>? metaData,
    bool? arsivlendi,
    int? indirmeSayisi,
    DateTime? sonIndirmeTarihi,
    String? etiketler,
    bool? silinebilir,
    bool? duzenlenebilir,
    String? versiyonNo,
    String? eskiVersionId,
    Map<String, dynamic>? ekstraBilgiler,
    DateTime? updatedAt,
  }) {
    return EducationDocument(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dosyaAdi: dosyaAdi ?? this.dosyaAdi,
      aciklama: aciklama ?? this.aciklama,
      kategori: kategori ?? this.kategori,
      dosyaTuru: dosyaTuru ?? this.dosyaTuru,
      dosyaUrl: dosyaUrl ?? this.dosyaUrl,
      ogrenciId: ogrenciId ?? this.ogrenciId,
      dersId: dersId ?? this.dersId,
      ogretmenId: ogretmenId ?? this.ogretmenId,
      herkesGorebilir: herkesGorebilir ?? this.herkesGorebilir,
      erisimYetkisi: erisimYetkisi ?? this.erisimYetkisi,
      dosyaBoyutu: dosyaBoyutu ?? this.dosyaBoyutu,
      dosyaFormati: dosyaFormati ?? this.dosyaFormati,
      yuklemeTarihi: yuklemeTarihi ?? this.yuklemeTarihi,
      klasor: klasor ?? this.klasor,
      metaData: metaData ?? this.metaData,
      arsivlendi: arsivlendi ?? this.arsivlendi,
      indirmeSayisi: indirmeSayisi ?? this.indirmeSayisi,
      sonIndirmeTarihi: sonIndirmeTarihi ?? this.sonIndirmeTarihi,
      etiketler: etiketler ?? this.etiketler,
      silinebilir: silinebilir ?? this.silinebilir,
      duzenlenebilir: duzenlenebilir ?? this.duzenlenebilir,
      versiyonNo: versiyonNo ?? this.versiyonNo,
      eskiVersionId: eskiVersionId ?? this.eskiVersionId,
      ekstraBilgiler: ekstraBilgiler ?? this.ekstraBilgiler,
    );
  }

  @override
  bool get isValid =>
      super.isValid &&
      dosyaAdi.isNotEmpty &&
      kategori.isNotEmpty &&
      dosyaTuru.isNotEmpty &&
      dosyaUrl.isNotEmpty &&
      dosyaBoyutu >= 0;

  @override
  String toString() =>
      'EducationDocument(id: $id, dosyaAdi: $dosyaAdi, kategori: $kategori, boyut: $formatliDosyaBoyutu)';
}
