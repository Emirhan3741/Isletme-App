import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_schedule_item.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_service.dart';

class DailySummaryService {
  static final DailySummaryService _instance = DailySummaryService._internal();
  factory DailySummaryService() => _instance;
  DailySummaryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  Timer? _dailyTimer;

  /// Servisi başlat ve günlük timer'ı kur
  void initialize() {
    _scheduleDailySummary();
  }

  /// Günlük özet için timer kurar
  void _scheduleDailySummary() {
    _dailyTimer?.cancel();
    
    // Her gün saat 19:00'da çalışacak timer
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 19, 0, 0);
    
    // Eğer saat 19:00 geçtiyse, ertesi güne ayarla
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final timeUntilExecution = scheduledTime.difference(now);
    
    _dailyTimer = Timer(timeUntilExecution, () {
      _sendDailySummaryToAllUsers();
      
      // 24 saat sonraki için tekrar timer kur
      _dailyTimer = Timer.periodic(const Duration(days: 1), (timer) {
        _sendDailySummaryToAllUsers();
      });
    });
    
    print('Günlük özet bildirimi ${scheduledTime.toString()} için zamanlandı');
  }

  /// Tüm kullanıcılara günlük özet gönder
  Future<void> _sendDailySummaryToAllUsers() async {
    try {
      // Günlük özet aktif olan kullanıcıları getir
      final userIds = await _preferencesService.getUsersWithDailySummaryEnabled();
      
      print('${userIds.length} kullanıcıya günlük özet gönderiliyor...');
      
      for (String userId in userIds) {
        await _sendDailySummaryToUser(userId);
        // Rate limiting için küçük bekleme
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('Günlük özet bildirimleri gönderildi');
    } catch (e) {
      print('Günlük özet gönderilirken hata: $e');
    }
  }

  /// Belirli bir kullanıcıya günlük özet gönder
  Future<void> _sendDailySummaryToUser(String userId) async {
    try {
      final tomorrowSchedule = await _getTomorrowScheduleForUser(userId);
      
      if (tomorrowSchedule.isEmpty) {
        // Yarın hiç işlem yoksa bildirim gönderme
        return;
      }
      
      final summary = _generateSummaryText(tomorrowSchedule);
      
      // FCM token'ını getir ve bildirim gönder
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final fcmToken = userDoc.data()!['fcmToken'] as String?;
        
        if (fcmToken != null) {
          await NotificationService().sendNotificationToToken(
            token: fcmToken,
            title: '🎯 Yarın için planın hazır',
            body: summary['body']!,
            data: {
              'type': 'daily_summary',
              'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'itemCount': tomorrowSchedule.length.toString(),
            },
          );
          
          // Bildirim geçmişini kaydet
          await _saveNotificationHistory(userId, summary, tomorrowSchedule);
        }
      }
    } catch (e) {
      print('Kullanıcı $userId için günlük özet gönderilirken hata: $e');
    }
  }

  /// Kullanıcının yarınki işlemlerini getir
  Future<List<DailyScheduleItem>> _getTomorrowScheduleForUser(String userId) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    List<DailyScheduleItem> allItems = [];

    final collections = {
      'appointments': 'appointment',
      'hearings': 'hearing',
      'meetings': 'meeting',
      'tasks': 'task',
      'notes': 'note',
      'events': 'event'
    };

    try {
      for (String collection in collections.keys) {
        final snapshot = await _firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow))
            .where('status', isEqualTo: 'active')
            .get();

        for (var doc in snapshot.docs) {
          final item = DailyScheduleItem.fromFirestore(doc, collections[collection]!);
          allItems.add(item);
        }
      }

      allItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      return allItems;
    } catch (e) {
      print('Yarın işlemleri yüklenirken hata: $e');
      return [];
    }
  }

  /// Özet metni oluştur
  Map<String, String> _generateSummaryText(List<DailyScheduleItem> items) {
    final Map<String, int> counts = {};
    
    for (var item in items) {
      final displayName = item.typeDisplayName;
      counts[displayName] = (counts[displayName] ?? 0) + 1;
    }
    
    final parts = <String>[];
    
    counts.forEach((type, count) {
      parts.add('$count $type');
    });
    
    String body;
    if (parts.length == 1) {
      body = '${parts.first} planlandı.';
    } else if (parts.length == 2) {
      body = '${parts[0]} ve ${parts[1]} planlandı.';
    } else {
      final lastPart = parts.removeLast();
      body = '${parts.join(', ')} ve $lastPart planlandı.';
    }
    
    return {
      'title': '🎯 Yarın için planın hazır',
      'body': body,
    };
  }

  /// Bildirim geçmişini kaydet
  Future<void> _saveNotificationHistory(
    String userId,
    Map<String, String> summary,
    List<DailyScheduleItem> items,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'daily_summary',
        'title': summary['title'],
        'body': summary['body'],
        'sentAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().add(const Duration(days: 1)),
        'itemCount': items.length,
        'items': items.map((item) => {
          'id': item.id,
          'title': item.title,
          'type': item.itemType,
          'startTime': item.startTime,
        }).toList(),
      });
    } catch (e) {
      print('Bildirim geçmişi kaydedilirken hata: $e');
    }
  }

  /// Manuel olarak günlük özet gönder (test amaçlı)
  Future<void> sendDailySummaryNow([String? specificUserId]) async {
    if (specificUserId != null) {
      await _sendDailySummaryToUser(specificUserId);
    } else {
      await _sendDailySummaryToAllUsers();
    }
  }

  /// Yarın için planlanan işlem sayısını getir (Dashboard için)
  Future<Map<String, int>> getTomorrowSummaryForUser(String userId) async {
    final items = await _getTomorrowScheduleForUser(userId);
    
    final Map<String, int> summary = {};
    
    for (var item in items) {
      final type = item.itemType;
      summary[type] = (summary[type] ?? 0) + 1;
    }
    
    summary['total'] = items.length;
    return summary;
  }

  /// Günlük özet geçmişini getir
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'daily_summary')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Bildirim geçmişi yüklenirken hata: $e');
      return [];
    }
  }

  /// Timer'ı durdur
  void dispose() {
    _dailyTimer?.cancel();
  }
}