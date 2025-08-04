import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_schedule_item.dart';

class DailyScheduleService {
  static final DailyScheduleService _instance = DailyScheduleService._internal();
  factory DailyScheduleService() => _instance;
  DailyScheduleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Bugünün tüm işlemlerini getir
  Future<List<DailyScheduleItem>> getTodaySchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    List<DailyScheduleItem> allItems = [];

    // Farklı koleksiyonlardan veri çek
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
            .where('userId', isEqualTo: user.uid)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('status', whereIn: ['active', 'pending'])
            .orderBy('startTime')
            .get();

        for (var doc in snapshot.docs) {
          final item = DailyScheduleItem.fromFirestore(doc, collections[collection]!);
          allItems.add(item);
        }
      }

      // Saate göre sırala
      allItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return allItems;
    } catch (e) {
      print('Günlük işlemler yüklenirken hata: $e');
      return [];
    }
  }

  /// Gelecek 7 gün için işlemleri getir
  Future<List<DailyScheduleItem>> getWeeklySchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final today = DateTime.now();
    final startOfWeek = DateTime(today.year, today.month, today.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

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
            .where('userId', isEqualTo: user.uid)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .where('startTime', isLessThan: Timestamp.fromDate(endOfWeek))
            .where('status', whereIn: ['active', 'pending'])
            .orderBy('startTime')
            .get();

        for (var doc in snapshot.docs) {
          final item = DailyScheduleItem.fromFirestore(doc, collections[collection]!);
          allItems.add(item);
        }
      }

      allItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      return allItems;
    } catch (e) {
      print('Haftalık işlemler yüklenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir panel için günlük işlemleri getir
  Future<List<DailyScheduleItem>> getTodayScheduleByPanel(String panel) async {
    final allItems = await getTodaySchedule();
    return allItems.where((item) => item.panel == panel).toList();
  }

  /// Yaklaşan işlemleri getir (sonraki 2 saat)
  Future<List<DailyScheduleItem>> getUpcomingSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final nextTwoHours = now.add(const Duration(hours: 2));

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
            .where('userId', isEqualTo: user.uid)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(nextTwoHours))
            .where('status', isEqualTo: 'active')
            .orderBy('startTime')
            .get();

        for (var doc in snapshot.docs) {
          final item = DailyScheduleItem.fromFirestore(doc, collections[collection]!);
          allItems.add(item);
        }
      }

      allItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      return allItems;
    } catch (e) {
      print('Yaklaşan işlemler yüklenirken hata: $e');
      return [];
    }
  }

  /// İşlem durumunu güncelle
  Future<void> updateItemStatus(String collection, String itemId, String status) async {
    try {
      await _firestore
          .collection(collection)
          .doc(itemId)
          .update({'status': status});
    } catch (e) {
      print('Durum güncellenirken hata: $e');
    }
  }

  /// İşlemi tamamlandı olarak işaretle
  Future<void> markAsCompleted(DailyScheduleItem item) async {
    final collection = _getCollectionFromItemType(item.itemType);
    await updateItemStatus(collection, item.id, 'completed');
  }

  /// İşlemi iptal et
  Future<void> markAsCanceled(DailyScheduleItem item) async {
    final collection = _getCollectionFromItemType(item.itemType);
    await updateItemStatus(collection, item.id, 'canceled');
  }

  /// Item type'dan koleksiyon adını çıkar
  String _getCollectionFromItemType(String itemType) {
    switch (itemType) {
      case 'appointment':
        return 'appointments';
      case 'hearing':
        return 'hearings';
      case 'meeting':
        return 'meetings';
      case 'task':
        return 'tasks';
      case 'note':
        return 'notes';
      case 'event':
        return 'events';
      default:
        return 'appointments';
    }
  }

  /// Istatistikleri getir
  Future<Map<String, int>> getTodayStats() async {
    final todayItems = await getTodaySchedule();
    
    final completed = todayItems.where((item) => item.status == 'completed').length;
    final pending = todayItems.where((item) => item.status == 'active').length;
    final canceled = todayItems.where((item) => item.status == 'canceled').length;
    
    return {
      'total': todayItems.length,
      'completed': completed,
      'pending': pending,
      'canceled': canceled,
    };
  }
}