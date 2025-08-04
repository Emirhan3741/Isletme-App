// Refactored by Cursor

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Kullanıcının randevularını getirme
  Stream<List<AppointmentModel>> getUserAppointments() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) debugPrint('❌ Randevu stream hatası: $error');
          if (error is FirebaseException && error.code == 'failed-precondition') {
            debugPrint('🔍 Index eksik! FIRESTORE_INDEX_URLS.md dosyasını kontrol edin');
          }
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  // Randevu ekleme
  Future<void> addAppointment(AppointmentModel appointment) async {
    try {
      if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
      
      if (kDebugMode) debugPrint('🔄 Randevu ekleniyor...');
      
      // Null kontrolleri
      if (appointment.customerId?.trim().isEmpty == true) {
        throw Exception('Müşteri seçilmeli');
      }

      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
      
      if (kDebugMode) debugPrint('✅ Randevu başarıyla eklendi: ${appointment.id}');
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase randevu ekleme hatası: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'failed-precondition':
          if (e.message?.contains('index') == true) {
            final indexUrl = _extractIndexUrl(e.message ?? '');
            debugPrint('🔍 Index gerekli - URL: $indexUrl');
            throw Exception('Veritabanı index\'i eksik.\n\n📋 ÇÖZÜM:\n1. FIRESTORE_INDEX_URLS.md dosyasını açın\n2. Appointments Collection bölümündeki URL\'leri açın\n3. "Create Index" butonlarına tıklayın\n4. 2-3 dakika bekleyin');
          }
          throw Exception('Veritabanı koşulları sağlanmamış: ${e.message}');
        case 'permission-denied':
          throw Exception('Bu işlem için yetkiniz yok. Giriş yapınız.');
        case 'unavailable':
          throw Exception('Veritabanı servis kullanılamıyor. İnternet bağlantınızı kontrol edin.');
        default:
          throw Exception('Randevu eklenemedi: ${e.message ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen randevu ekleme hatası: $e');
      throw Exception('Randevu eklenemedi: $e');
    }
  }
  
  String _extractIndexUrl(String errorMessage) {
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0) ?? 'FIRESTORE_INDEX_URLS.md dosyasına bakın';
  }

  // Randevu güncelleme
  Future<void> updateAppointment(AppointmentModel appointment) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore
        .collection('appointments')
        .doc(appointment.id)
        .update(appointment.toMap());
  }

  // Randevu silme
  Future<void> deleteAppointment(String appointmentId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  // Bugünün randevularını getirme
  Stream<List<AppointmentModel>> getTodayAppointments() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThanOrEqualTo: endOfDay)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  // Çalışana göre randevuları getirme
  Stream<List<AppointmentModel>> getAppointmentsByEmployee(String employeeId) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  // Müşteriye göre randevuları getirme
  Stream<List<AppointmentModel>> getAppointmentsByCustomer(String customerId) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data()))
            .toList());
  }

  // Tek randevu getirme
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    if (_userId == null) return null;

    final doc =
        await _firestore.collection('appointments').doc(appointmentId).get();
    if (doc.exists) {
      return AppointmentModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Randevu durumunu güncelleme
  Future<void> updateAppointmentStatus(
      String appointmentId, AppointmentStatus status) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');

    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.name,
    });
  }

  Future<List<AppointmentModel>> getAppointmentsByCustomerId(
      String customerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<AppointmentModel>> getAllAppointments() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: _userId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Randevular yüklenirken hata oluştu: $e');
    }
  }

  // Tüm randevuları getir (admin için)
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      if (_userId == null) return [];

      final snapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: _userId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Randevular yüklenirken hata oluştu: $e');
    }
  }

  // Ek Stream metodları
  Stream<List<AppointmentModel>> getAppointmentsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<AppointmentModel>> getAppointmentsByStatusStream(
      AppointmentStatus status) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: status.name)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<AppointmentModel>> getAppointmentsByCustomerIdStream(
      String customerId) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<AppointmentModel?> getAppointmentStream(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .map((doc) => doc.exists
            ? AppointmentModel.fromMap({...doc.data()!, 'id': doc.id})
            : null);
  }

  // Tarih aralığına göre randevuları getir
  Stream<List<AppointmentModel>> getAppointmentsByDateRange(
      DateTime startDate, DateTime endDate) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Randevu çakışması kontrolü
  bool hasTimeConflict(AppointmentModel newAppointment, List<AppointmentModel> existingAppointments) {
    final newStart = newAppointment.dateTime;
    final newEnd = getAppointmentEndTime(newAppointment);

    for (final existing in existingAppointments) {
      if (existing.id == newAppointment.id) continue; // Aynı randevuyu atlıyoruz
      
      final existingStart = existing.dateTime;
      final existingEnd = getAppointmentEndTime(existing);

      // Çakışma kontrolü: yeni randevu var olan ile çakışıyor mu?
      if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // Randevu bitiş zamanını hesaplama
  DateTime getAppointmentEndTime(AppointmentModel appointment) {
    final duration = appointment.duration ?? 60; // Varsayılan 60 dakika
    return appointment.dateTime.add(Duration(minutes: duration));
  }
}
