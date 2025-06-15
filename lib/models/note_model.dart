import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String baslik;
  final String icerik;
  final String kategori;
  final bool tamamlandi;
  final int onem; // 1-5 arası öncelik seviyesi
  final String renk; // Hex color code
  final Timestamp olusturulmaTarihi;
  final String kullaniciId;

  NoteModel({
    required this.id,
    required this.baslik,
    required this.icerik,
    required this.kategori,
    required this.tamamlandi,
    required this.onem,
    required this.renk,
    required this.olusturulmaTarihi,
    required this.kullaniciId,
  });

  // Firestore'dan gelen verileri modele dönüştürme
  factory NoteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NoteModel(
      id: documentId,
      baslik: map['baslik'] ?? '',
      icerik: map['icerik'] ?? '',
      kategori: map['kategori'] ?? NoteCategory.genel,
      tamamlandi: map['tamamlandi'] ?? false,
      onem: map['onem'] ?? 1,
      renk: map['renk'] ?? NoteColors.mavi,
      olusturulmaTarihi: map['olusturulmaTarihi'] ?? Timestamp.now(),
      kullaniciId: map['kullaniciId'] ?? '',
    );
  }

  // Model verisini Firestore formatına dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'baslik': baslik,
      'icerik': icerik,
      'kategori': kategori,
      'tamamlandi': tamamlandi,
      'onem': onem,
      'renk': renk,
      'olusturulmaTarihi': olusturulmaTarihi,
      'kullaniciId': kullaniciId,
    };
  }

  // Model kopyalama fonksiyonu
  NoteModel copyWith({
    String? id,
    String? baslik,
    String? icerik,
    String? kategori,
    bool? tamamlandi,
    int? onem,
    String? renk,
    Timestamp? olusturulmaTarihi,
    String? kullaniciId,
  }) {
    return NoteModel(
      id: id ?? this.id,
      baslik: baslik ?? this.baslik,
      icerik: icerik ?? this.icerik,
      kategori: kategori ?? this.kategori,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      onem: onem ?? this.onem,
      renk: renk ?? this.renk,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      kullaniciId: kullaniciId ?? this.kullaniciId,
    );
  }

  @override
  String toString() {
    return 'NoteModel{id: $id, baslik: $baslik, kategori: $kategori, tamamlandi: $tamamlandi}';
  }
}

// Not kategorileri sabit değerleri
class NoteCategory {
  static const String genel = 'Genel';
  static const String pazarlama = 'Pazarlama';
  static const String personel = 'Personel';
  static const String uretim = 'Üretim';
  static const String finans = 'Finans';
  static const String musteri = 'Müşteri';
  static const String tedarik = 'Tedarik';
  static const String kalite = 'Kalite';
  static const String teknoloji = 'Teknoloji';
  static const String hukuk = 'Hukuk';
  static const String satis = 'Satış';
  static const String proje = 'Proje';

  static List<String> get tumKategoriler => [
        genel,
        pazarlama,
        personel,
        uretim,
        finans,
        musteri,
        tedarik,
        kalite,
        teknoloji,
        hukuk,
        satis,
        proje,
      ];

  // Kategori ikonları
  static Map<String, String> get kategoriIkonlari => {
        genel: '📝',
        pazarlama: '📊',
        personel: '👥',
        uretim: '🏭',
        finans: '💰',
        musteri: '🤝',
        tedarik: '📦',
        kalite: '✅',
        teknoloji: '💻',
        hukuk: '⚖️',
        satis: '🛍️',
        proje: '🎯',
      };
}

// Not renkleri sabit değerleri
class NoteColors {
  static const String mavi = '#2196F3';
  static const String yesil = '#4CAF50';
  static const String kirmizi = '#F44336';
  static const String turuncu = '#FF9800';
  static const String mor = '#9C27B0';
  static const String pembe = '#E91E63';
  static const String sari = '#FFEB3B';
  static const String gri = '#9E9E9E';
  static const String turkuaz = '#00BCD4';
  static const String lime = '#CDDC39';

  static List<String> get tumRenkler => [
        mavi,
        yesil,
        kirmizi,
        turuncu,
        mor,
        pembe,
        sari,
        gri,
        turkuaz,
        lime,
      ];

  // Renk isimleri
  static Map<String, String> get renkIsimleri => {
        mavi: 'Mavi',
        yesil: 'Yeşil',
        kirmizi: 'Kırmızı',
        turuncu: 'Turuncu',
        mor: 'Mor',
        pembe: 'Pembe',
        sari: 'Sarı',
        gri: 'Gri',
        turkuaz: 'Turkuaz',
        lime: 'Lime',
      };
}

// Önem seviyeleri
class NotePriority {
  static const int cokDusuk = 1;
  static const int dusuk = 2;
  static const int orta = 3;
  static const int yuksek = 4;
  static const int cokYuksek = 5;

  static Map<int, String> get onemIsimleri => {
        cokDusuk: 'Çok Düşük',
        dusuk: 'Düşük',
        orta: 'Orta',
        yuksek: 'Yüksek',
        cokYuksek: 'Çok Yüksek',
      };

  static Map<int, String> get onemIkonlari => {
        cokDusuk: '⚪',
        dusuk: '🔵',
        orta: '🟡',
        yuksek: '🟠',
        cokYuksek: '🔴',
      };

  static List<int> get tumOnemler => [
        cokDusuk,
        dusuk,
        orta,
        yuksek,
        cokYuksek,
      ];
} 