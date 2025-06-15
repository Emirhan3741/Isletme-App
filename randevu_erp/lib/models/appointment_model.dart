import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppointmentModel {
  final String id;
  final String musteriId;
  final String calisanId;
  final DateTime tarih;
  final String saat;
  final String islemAdi;
  final String? not;
  final DateTime olusturulmaTarihi;

  AppointmentModel({
    required this.id,
    required this.musteriId,
    required this.calisanId,
    required this.tarih,
    required this.saat,
    required this.islemAdi,
    this.not,
    required this.olusturulmaTarihi,
  });

  // Firestore'dan AppointmentModel oluştur
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppointmentModel(
      id: documentId,
      musteriId: map['musteriId'] ?? '',
      calisanId: map['calisanId'] ?? '',
      tarih: (map['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      saat: map['saat'] ?? '',
      islemAdi: map['islemAdi'] ?? '',
      not: map['not'],
      olusturulmaTarihi: (map['olusturulmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore DocumentSnapshot'tan oluştur
  factory AppointmentModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap(data, snapshot.id);
  }

  // Firestore için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'musteriId': musteriId,
      'calisanId': calisanId,
      'tarih': Timestamp.fromDate(tarih),
      'saat': saat,
      'islemAdi': islemAdi,
      'not': not,
      'olusturulmaTarihi': Timestamp.fromDate(olusturulmaTarihi),
    };
  }

  // Randevu bilgilerini güncelle
  AppointmentModel copyWith({
    String? id,
    String? musteriId,
    String? calisanId,
    DateTime? tarih,
    String? saat,
    String? islemAdi,
    String? not,
    DateTime? olusturulmaTarihi,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      musteriId: musteriId ?? this.musteriId,
      calisanId: calisanId ?? this.calisanId,
      tarih: tarih ?? this.tarih,
      saat: saat ?? this.saat,
      islemAdi: islemAdi ?? this.islemAdi,
      not: not ?? this.not,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
    );
  }

  // Tam tarih saat bilgisi
  DateTime get tamTarih {
    final saatParcalari = saat.split(':');
    if (saatParcalari.length >= 2) {
      final saat = int.tryParse(saatParcalari[0]) ?? 0;
      final dakika = int.tryParse(saatParcalari[1]) ?? 0;
      return DateTime(
        tarih.year,
        tarih.month,
        tarih.day,
        saat,
        dakika,
      );
    }
    return tarih;
  }

  // TimeOfDay formatında saat
  TimeOfDay get timeOfDay {
    final saatParcalari = saat.split(':');
    if (saatParcalari.length >= 2) {
      final saat = int.tryParse(saatParcalari[0]) ?? 0;
      final dakika = int.tryParse(saatParcalari[1]) ?? 0;
      return TimeOfDay(hour: saat, minute: dakika);
    }
    return TimeOfDay.now();
  }

  // Formatlı saat gösterimi
  String get formatliSaat {
    final timeOfDay = this.timeOfDay;
    return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
  }

  // Formatlı tarih gösterimi
  String get formatliTarih {
    final gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    
    return '${tarih.day} ${aylar[tarih.month - 1]} ${tarih.year}, ${gunler[tarih.weekday - 1]}';
  }

  // Randevu geçerli mi kontrol et
  bool get isValid {
    return musteriId.isNotEmpty &&
           calisanId.isNotEmpty &&
           islemAdi.isNotEmpty &&
           saat.isNotEmpty;
  }

  // Randevu geçmiş mi
  bool get isExpired {
    return tamTarih.isBefore(DateTime.now());
  }

  // Randevu bugün mü
  bool get isToday {
    final bugun = DateTime.now();
    return tarih.year == bugun.year &&
           tarih.month == bugun.month &&
           tarih.day == bugun.day;
  }

  // Randevu yarın mı
  bool get isTomorrow {
    final yarin = DateTime.now().add(const Duration(days: 1));
    return tarih.year == yarin.year &&
           tarih.month == yarin.month &&
           tarih.day == yarin.day;
  }

  // Arama için kullanılacak text
  String get aramaMetni => '$islemAdi ${formatliTarih} $formatliSaat ${not ?? ''}'.toLowerCase();

  // Randevu durumu
  String get durum {
    if (isExpired) return 'Geçmiş';
    if (isToday) return 'Bugün';
    if (isTomorrow) return 'Yarın';
    return 'Gelecek';
  }

  // Durum rengi
  Color get durumRengi {
    if (isExpired) return Colors.grey;
    if (isToday) return Colors.green;
    if (isTomorrow) return Colors.orange;
    return Colors.blue;
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, islemAdi: $islemAdi, tarih: $formatliTarih, saat: $formatliSaat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Static metodlar
  static String timeOfDayToString(TimeOfDay timeOfDay) {
    return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay.now();
  }

  // Çakışma kontrolü
  bool hasConflictWith(AppointmentModel other) {
    // Aynı çalışan ve aynı gün kontrolü
    if (calisanId != other.calisanId) return false;
    if (!isSameDay(tarih, other.tarih)) return false;

    // Saat çakışması kontrolü (30 dakika buffer)
    final thisDateTime = tamTarih;
    final otherDateTime = other.tamTarih;
    final difference = thisDateTime.difference(otherDateTime).abs();
    
    return difference.inMinutes < 30;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 