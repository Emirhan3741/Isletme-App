import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection referansı
  CollectionReference get _appointmentsCollection => _firestore.collection('appointments');

  // Mevcut kullanıcı ID'si
  String? get _currentUserId => _auth.currentUser?.uid;

  // Randevu ekle
  Future<AppointmentModel?> addAppointment({
    required String musteriId,
    required DateTime tarih,
    required String saat,
    required String islemAdi,
    String? not,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final appointmentData = {
        'musteriId': musteriId,
        'calisanId': _currentUserId!,
        'tarih': Timestamp.fromDate(tarih),
        'saat': saat,
        'islemAdi': islemAdi.trim(),
        'not': not?.trim(),
        'olusturulmaTarihi': Timestamp.now(),
      };

      final docRef = await _appointmentsCollection.add(appointmentData);
      
      // Eklenen randevuyu geri döndür
      return AppointmentModel.fromMap(appointmentData, docRef.id);
    } catch (e) {
      print('Randevu ekleme hatası: $e');
      rethrow;
    }
  }

  // Randevu güncelle
  Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      if (appointment.calisanId != _currentUserId) {
        throw Exception('Bu randevuyu güncelleme yetkiniz yok');
      }

      await _appointmentsCollection.doc(appointment.id).update(appointment.toMap());
    } catch (e) {
      print('Randevu güncelleme hatası: $e');
      rethrow;
    }
  }

  // Randevu sil
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Önce randevunun sahibini kontrol et
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (!doc.exists) {
        throw Exception('Randevu bulunamadı');
      }

      final appointmentData = doc.data() as Map<String, dynamic>;
      if (appointmentData['calisanId'] != _currentUserId) {
        throw Exception('Bu randevuyu silme yetkiniz yok');
      }

      await _appointmentsCollection.doc(appointmentId).delete();
    } catch (e) {
      print('Randevu silme hatası: $e');
      rethrow;
    }
  }

  // Tek randevu getir
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final doc = await _appointmentsCollection.doc(appointmentId).get();
      
      if (!doc.exists) {
        return null;
      }

      final appointmentData = doc.data() as Map<String, dynamic>;
      
      // Sadece kendi randevusunu döndür
      if (appointmentData['calisanId'] != _currentUserId) {
        throw Exception('Bu randevuyu görüntüleme yetkiniz yok');
      }

      return AppointmentModel.fromSnapshot(doc);
    } catch (e) {
      print('Randevu getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının tüm randevularını getir (Stream)
  Stream<List<AppointmentModel>> getAppointmentsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _appointmentsCollection
        .where('calisanId', isEqualTo: _currentUserId)
        .orderBy('tarih', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    });
  }

  // Kullanıcının tüm randevularını getir (Future)
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .orderBy('tarih', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Randevuları getirme hatası: $e');
      rethrow;
    }
  }

  // Belirli bir tarih aralığındaki randevuları getir
  Future<List<AppointmentModel>> getAppointmentsByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('tarih', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Tarih aralığı randevu getirme hatası: $e');
      rethrow;
    }
  }

  // Belirli bir gündeki randevuları getir
  Future<List<AppointmentModel>> getAppointmentsByDate(DateTime date) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('tarih', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Günlük randevu getirme hatası: $e');
      rethrow;
    }
  }

  // Randevu ara
  Future<List<AppointmentModel>> searchAppointments(String query) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      if (query.isEmpty) {
        return await getAppointments();
      }

      final allAppointments = await getAppointments();
      final searchQuery = query.toLowerCase();

      return allAppointments.where((appointment) {
        return appointment.aramaMetni.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Randevu arama hatası: $e');
      rethrow;
    }
  }

  // Çakışan randevuları kontrol et
  Future<List<AppointmentModel>> getConflictingAppointments(
    DateTime tarih,
    String saat,
    {String? excludeAppointmentId}
  ) async {
    try {
      if (_currentUserId == null) {
        return [];
      }

      final dayAppointments = await getAppointmentsByDate(tarih);
      
      final newAppointment = AppointmentModel(
        id: 'temp',
        musteriId: 'temp',
        calisanId: _currentUserId!,
        tarih: tarih,
        saat: saat,
        islemAdi: 'temp',
        olusturulmaTarihi: DateTime.now(),
      );

      return dayAppointments.where((appointment) {
        if (excludeAppointmentId != null && appointment.id == excludeAppointmentId) {
          return false;
        }
        return appointment.hasConflictWith(newAppointment);
      }).toList();
    } catch (e) {
      print('Çakışma kontrolü hatası: $e');
      return [];
    }
  }

  // Bugünün randevularını getir
  Future<List<AppointmentModel>> getTodayAppointments() async {
    return await getAppointmentsByDate(DateTime.now());
  }

  // Gelecek randevuları getir
  Future<List<AppointmentModel>> getUpcomingAppointments({int limit = 10}) async {
    try {
      if (_currentUserId == null) {
        return [];
      }

      final now = DateTime.now();
      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('tarih', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Gelecek randevuları getirme hatası: $e');
      return [];
    }
  }

  // Randevu sayısını getir
  Future<int> getAppointmentCount() async {
    try {
      if (_currentUserId == null) {
        return 0;
      }

      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Randevu sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Bugünün randevu sayısını getir
  Future<int> getTodayAppointmentCount() async {
    try {
      final todayAppointments = await getTodayAppointments();
      return todayAppointments.length;
    } catch (e) {
      print('Bugünün randevu sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Belirli bir müşterinin randevularını getir
  Future<List<AppointmentModel>> getCustomerAppointments(String musteriId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      final querySnapshot = await _appointmentsCollection
          .where('calisanId', isEqualTo: _currentUserId)
          .where('musteriId', isEqualTo: musteriId)
          .orderBy('tarih', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return AppointmentModel.fromSnapshot(doc);
      }).toList();
    } catch (e) {
      print('Müşteri randevuları getirme hatası: $e');
      rethrow;
    }
  }

  // Haftalık randevuları getir
  Future<List<AppointmentModel>> getWeeklyAppointments(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return await getAppointmentsByDateRange(weekStart, weekEnd);
  }

  // Aylık randevuları getir  
  Future<List<AppointmentModel>> getMonthlyAppointments(DateTime month) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    return await getAppointmentsByDateRange(monthStart, monthEnd);
  }
} 