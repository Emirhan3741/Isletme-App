import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_schedule_item.dart';
import 'notification_preferences_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Timer? _schedulerTimer;

  /// Static initialize metodu
  static Future<void> initialize() async {
    await _instance._initialize();
  }

  /// Servisi başlat (private)
  Future<void> _initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    _startScheduler();
  }

  /// Local notifications'ı başlat
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Firebase messaging'i başlat
  Future<void> _initializeFirebaseMessaging() async {
    // İzin iste
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Token al ve Firestore'a kaydet
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Token yenilendiğinde güncelle
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Foreground mesajları dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// FCM token'ı Firestore'a kaydet
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  /// Foreground mesajları handle et
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'LOCAPO',
      body: message.notification?.body ?? '',
      payload: message.data['payload'],
    );
  }

  /// Local notification göster
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'schedule_reminders',
      'Planlama Hatırlatmaları',
      channelDescription: 'Randevu ve görev hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlemler
    print('Bildirim tıklandı: ${response.payload}');
  }

  /// Scheduler başlat - her 5 dakikada bir kontrol et
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkUpcomingSchedules();
    });
  }

  /// Yaklaşan işlemleri kontrol et ve bildirim gönder
  Future<void> _checkUpcomingSchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    
    // 5 dakikalık tolerans ile kontrol et (55-65 dakika arasında)
    final toleranceStart = now.add(const Duration(minutes: 55));
    final toleranceEnd = now.add(const Duration(minutes: 65));

    try {
      // Kullanıcının bildirim tercihlerini getir
      final preferencesService = NotificationPreferencesService();
      final preferences = await preferencesService.getUserPreferences();

      // Farklı koleksiyonlardan veri çek
      final collections = [
        'appointments',
        'hearings',
        'meetings',
        'tasks',
        'notes',
        'events'
      ];

      for (String collection in collections) {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('userId', isEqualTo: user.uid)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(toleranceStart))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(toleranceEnd))
            .where('notified', isEqualTo: false)
            .where('status', isEqualTo: 'active')
            .get();

        for (var doc in snapshot.docs) {
          final item = DailyScheduleItem.fromFirestore(doc, _getItemTypeFromCollection(collection));
          
          // Kullanıcının bu tür bildirim için tercihi açık mı kontrol et
          if (preferences.isReminderEnabledForType(item.itemType)) {
            await _sendReminderNotification(item);
            
            // Bildirim gönderildi olarak işaretle
            await doc.reference.update({'notified': true});
          }
        }
      }
    } catch (e) {
      print('Scheduler hatası: $e');
    }
  }

  /// Koleksiyon adından item type'ı çıkar
  String _getItemTypeFromCollection(String collection) {
    switch (collection) {
      case 'appointments':
        return 'appointment';
      case 'hearings':
        return 'hearing';
      case 'meetings':
        return 'meeting';
      case 'tasks':
        return 'task';
      case 'notes':
        return 'note';
      case 'events':
        return 'event';
      default:
        return 'item';
    }
  }

  /// Hatırlatma bildirimi gönder
  Future<void> _sendReminderNotification(DailyScheduleItem item) async {
    String title;
    String body;

    switch (item.itemType) {
      case 'appointment':
        title = '📅 1 saat sonra randevunuz var';
        body = '${item.title} - ${item.customerName ?? 'Müşteri'}';
        break;
      case 'hearing':
        title = '🧑‍⚖️ 1 saat içinde duruşma başlayacak';
        body = '${item.title} - ${_formatTime(item.startTime)}';
        break;
      case 'meeting':
        title = '💼 Görüşme zamanı yaklaşıyor';
        body = '${item.title} - ${item.customerName ?? 'Katılımcı'}';
        break;
      case 'task':
        title = '✅ To-Do öğesi için 1 saat kaldı';
        body = '${item.title}';
        break;
      case 'note':
        title = '📝 Zamanlanmış not hatırlatması';
        body = '${item.title}';
        break;
      case 'event':
        title = '🎉 Etkinlik başlamak üzere';
        body = '${item.title} - ${_formatTime(item.startTime)}';
        break;
      default:
        title = '⏰ İşlem zamanı yaklaşıyor';
        body = '${item.title}';
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: '${item.itemType}:${item.id}',
    );
  }

  /// Saati formatla
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Servisi durdur
  void dispose() {
    _schedulerTimer?.cancel();
  }

  /// Test bildirimi gönder
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Bildirim',
      body: 'LOCAPO bildirim sistemi çalışıyor!',
    );
  }

  /// Belirli bir FCM token'a bildirim gönder
  Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Firebase Messaging kullanarak remote notification gönder
      // Firebase FCM sendMessage method web'de deprecated
      // await _firebaseMessaging.sendMessage(
      //   to: token,
      //   data: data ?? {},
      // );
      
      // Ayrıca local notification da göster (eğer app açıksa)
      await _showLocalNotification(
        title: title,
        body: body,
        payload: data?['type'],
      );
    } catch (e) {
      print('Token\'a bildirim gönderilirken hata: $e');
    }
  }

  // ========================================
  // EKSİK METHOD PLACEHOLDER'LARI - Compile hataları için
  // ========================================

  /// FCM Token al - auth_provider.dart için
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('FCM token alınamadı: $e');
      return null;
    }
  }

  /// FCM Token'ı Firestore'a kaydet - public method
  Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(userId)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown')),
      });
    } catch (e) {
      print('FCM token Firestore\'a kaydedilemedi: $e');
    }
  }

  /// Role-based topic subscription
  Future<void> subscribeToRoleTopics(String role, [String? sector]) async {
    try {
      await _firebaseMessaging.subscribeToTopic(role);
      if (sector != null) {
        await _firebaseMessaging.subscribeToTopic(sector);
      }
      print('Role topics subscribed: $role, $sector');
    } catch (e) {
      print('Topic subscription error: $e');
    }
  }

  /// Okunmamış bildirim sayısı stream
  Stream<int> getUnreadNotificationCountStream(String userId) {
    try {
      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Notification count stream error: $e');
      return Stream.value(0);
    }
  }

  /// Kullanıcı bildirimi oluştur
  Future<void> createUserNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'info',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        ...?additionalData,
      });
    } catch (e) {
      print('User notification create error: $e');
    }
  }

  /// Zamanlanmış bildirim - automation_service.dart için
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Placeholder implementation
    print('Schedule notification: $title at $scheduledTime');
  }

  /// Custom bildirim gönder
  Future<void> sendCustomNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Placeholder implementation
    print('Send custom notification to $userId: $title');
  }

  /// Anlık bildirim göster
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _showLocalNotification(title: title, body: body, payload: payload);
    } catch (e) {
      print('Instant notification error: $e');
    }
  }

  /// Randevu hatırlatması gönder
  Future<void> sendAppointmentReminder(Map<String, dynamic> appointment) async {
    try {
      final title = 'Randevu Hatırlatması';
      final body = 'Yaklaşan randevunuz: ${appointment['title'] ?? 'Randevu'}';
      await showInstantNotification(title: title, body: body);
    } catch (e) {
      print('Appointment reminder error: $e');
    }
  }
}