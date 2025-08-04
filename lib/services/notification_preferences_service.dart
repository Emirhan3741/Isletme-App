import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance = NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının bildirim tercihlerini getir
  Future<NotificationPreferences> getUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return NotificationPreferences.defaultPreferences;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('notificationPreferences')) {
          return NotificationPreferences.fromFirestore(
            data['notificationPreferences'] as Map<String, dynamic>
          );
        }
      }

      // Eğer tercihler yoksa varsayılan ayarları kaydet
      await updateUserPreferences(NotificationPreferences.defaultPreferences);
      return NotificationPreferences.defaultPreferences;
    } catch (e) {
      print('Bildirim tercihleri yüklenirken hata: $e');
      return NotificationPreferences.defaultPreferences;
    }
  }

  /// Kullanıcının bildirim tercihlerini güncelle
  Future<void> updateUserPreferences(NotificationPreferences preferences) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'notificationPreferences': preferences.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Bildirim tercihleri güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Belirli bir tercihi güncelle
  Future<void> updateSpecificPreference({
    required String preferenceKey,
    required bool value,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'notificationPreferences.$preferenceKey': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Bildirim tercihi güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Günlük özet bildirimini aç/kapat
  Future<void> toggleDailySummary(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'dailySummary',
      value: enabled,
    );
  }

  /// Randevu hatırlatmasını aç/kapat
  Future<void> toggleAppointmentReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'appointmentReminder',
      value: enabled,
    );
  }

  /// Görüşme hatırlatmasını aç/kapat
  Future<void> toggleMeetingReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'meetingReminder',
      value: enabled,
    );
  }

  /// Duruşma hatırlatmasını aç/kapat
  Future<void> toggleHearingReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'hearingReminder',
      value: enabled,
    );
  }

  /// To-do hatırlatmasını aç/kapat
  Future<void> toggleTodoReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'todoReminder',
      value: enabled,
    );
  }

  /// Etkinlik hatırlatmasını aç/kapat
  Future<void> toggleEventReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'eventReminder',
      value: enabled,
    );
  }

  /// Not hatırlatmasını aç/kapat
  Future<void> toggleNoteReminder(bool enabled) async {
    await updateSpecificPreference(
      preferenceKey: 'noteReminder',
      value: enabled,
    );
  }

  /// Stream ile tercihleri dinle
  Stream<NotificationPreferences> getUserPreferencesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(NotificationPreferences.defaultPreferences);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('notificationPreferences')) {
          return NotificationPreferences.fromFirestore(
            data['notificationPreferences'] as Map<String, dynamic>
          );
        }
      }
      return NotificationPreferences.defaultPreferences;
    });
  }

  /// Belirli kullanıcının tercihlerini getir (admin için)
  Future<NotificationPreferences> getPreferencesForUser(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('notificationPreferences')) {
          return NotificationPreferences.fromFirestore(
            data['notificationPreferences'] as Map<String, dynamic>
          );
        }
      }

      return NotificationPreferences.defaultPreferences;
    } catch (e) {
      print('Kullanıcı tercihleri yüklenirken hata: $e');
      return NotificationPreferences.defaultPreferences;
    }
  }

  /// Günlük özet için kullanıcıları getir
  Future<List<String>> getUsersWithDailySummaryEnabled() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('notificationPreferences.dailySummary', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Günlük özet kullanıcıları alınırken hata: $e');
      return [];
    }
  }

  /// Test amaçlı tüm tercihleri sıfırla
  Future<void> resetToDefault() async {
    await updateUserPreferences(NotificationPreferences.defaultPreferences);
  }

  /// Tüm bildirimleri kapat
  Future<void> disableAllNotifications() async {
    await updateUserPreferences(NotificationPreferences.allDisabled);
  }
}