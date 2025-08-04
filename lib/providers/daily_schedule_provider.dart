import 'package:flutter/foundation.dart';
import '../models/daily_schedule_item.dart';
import '../services/daily_schedule_service.dart';

class DailyScheduleProvider with ChangeNotifier {
  final DailyScheduleService _scheduleService = DailyScheduleService();

  List<DailyScheduleItem> _todayItems = [];
  List<DailyScheduleItem> _upcomingItems = [];
  List<DailyScheduleItem> _weeklyItems = [];
  Map<String, int> _todayStats = {};
  
  bool _loading = false;
  String? _error;

  // Getters
  List<DailyScheduleItem> get todayItems => _todayItems;
  List<DailyScheduleItem> get upcomingItems => _upcomingItems;
  List<DailyScheduleItem> get weeklyItems => _weeklyItems;
  Map<String, int> get todayStats => _todayStats;
  bool get loading => _loading;
  String? get error => _error;

  /// Bugünün işlemlerini yükle
  Future<void> loadTodaySchedule() async {
    _setLoading(true);
    try {
      _todayItems = await _scheduleService.getTodaySchedule();
      _todayStats = await _scheduleService.getTodayStats();
      _error = null;
    } catch (e) {
      _error = 'Günlük program yüklenirken hata: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Yaklaşan işlemleri yükle
  Future<void> loadUpcomingSchedule() async {
    _setLoading(true);
    try {
      _upcomingItems = await _scheduleService.getUpcomingSchedule();
      _error = null;
    } catch (e) {
      _error = 'Yaklaşan işlemler yüklenirken hata: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Haftalık işlemleri yükle
  Future<void> loadWeeklySchedule() async {
    _setLoading(true);
    try {
      _weeklyItems = await _scheduleService.getWeeklySchedule();
      _error = null;
    } catch (e) {
      _error = 'Haftalık program yüklenirken hata: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Tüm verileri yükle
  Future<void> loadAllSchedules() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadTodaySchedule(),
        loadUpcomingSchedule(),
        loadWeeklySchedule(),
      ]);
    } catch (e) {
      _error = 'Programlar yüklenirken hata: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Belirli panel için günlük işlemleri yükle
  Future<List<DailyScheduleItem>> loadTodayScheduleByPanel(String panel) async {
    try {
      return await _scheduleService.getTodayScheduleByPanel(panel);
    } catch (e) {
      print('Panel işlemleri yüklenirken hata: $e');
      return [];
    }
  }

  /// İşlemi tamamlandı olarak işaretle
  Future<void> markAsCompleted(DailyScheduleItem item) async {
    try {
      await _scheduleService.markAsCompleted(item);
      
      // Local state'i güncelle
      _updateItemInLists(item.copyWith(status: 'completed'));
      
      // Stats'ı güncelle
      await _refreshStats();
      
      notifyListeners();
    } catch (e) {
      _error = 'İşlem tamamlanırken hata: $e';
      print(_error);
      notifyListeners();
    }
  }

  /// İşlemi iptal et
  Future<void> markAsCanceled(DailyScheduleItem item) async {
    try {
      await _scheduleService.markAsCanceled(item);
      
      // Local state'i güncelle
      _updateItemInLists(item.copyWith(status: 'canceled'));
      
      // Stats'ı güncelle
      await _refreshStats();
      
      notifyListeners();
    } catch (e) {
      _error = 'İşlem iptal edilirken hata: $e';
      print(_error);
      notifyListeners();
    }
  }

  /// İşlem durumunu güncelle
  Future<void> updateItemStatus(DailyScheduleItem item, String status) async {
    try {
      final collection = _getCollectionFromItemType(item.itemType);
      await _scheduleService.updateItemStatus(collection, item.id, status);
      
      // Local state'i güncelle
      _updateItemInLists(item.copyWith(status: status));
      
      // Stats'ı güncelle
      await _refreshStats();
      
      notifyListeners();
    } catch (e) {
      _error = 'İşlem durumu güncellenirken hata: $e';
      print(_error);
      notifyListeners();
    }
  }

  /// Tüm verileri yenile
  Future<void> refresh() async {
    await loadAllSchedules();
  }

  /// Sadece bugünün verilerini yenile
  Future<void> refreshToday() async {
    await loadTodaySchedule();
  }

  /// İstatistikleri yenile
  Future<void> _refreshStats() async {
    try {
      _todayStats = await _scheduleService.getTodayStats();
    } catch (e) {
      print('Stats yenilenirken hata: $e');
    }
  }

  /// Local listelerde item'ı güncelle
  void _updateItemInLists(DailyScheduleItem updatedItem) {
    // Today items'ı güncelle
    final todayIndex = _todayItems.indexWhere((item) => item.id == updatedItem.id);
    if (todayIndex != -1) {
      _todayItems[todayIndex] = updatedItem;
    }

    // Upcoming items'ı güncelle
    final upcomingIndex = _upcomingItems.indexWhere((item) => item.id == updatedItem.id);
    if (upcomingIndex != -1) {
      _upcomingItems[upcomingIndex] = updatedItem;
    }

    // Weekly items'ı güncelle
    final weeklyIndex = _weeklyItems.indexWhere((item) => item.id == updatedItem.id);
    if (weeklyIndex != -1) {
      _weeklyItems[weeklyIndex] = updatedItem;
    }
  }

  /// Loading state'i güncelle
  void _setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
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

  /// Panel türüne göre filtreleme
  List<DailyScheduleItem> getItemsByPanel(String panel) {
    return _todayItems.where((item) => item.panel == panel).toList();
  }

  /// İşlem türüne göre filtreleme
  List<DailyScheduleItem> getItemsByType(String itemType) {
    return _todayItems.where((item) => item.itemType == itemType).toList();
  }

  /// Durum türüne göre filtreleme
  List<DailyScheduleItem> getItemsByStatus(String status) {
    return _todayItems.where((item) => item.status == status).toList();
  }

  /// Yaklaşan işlemleri al (sonraki 1 saat)
  List<DailyScheduleItem> getImmediateUpcoming() {
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    
    return _todayItems.where((item) {
      return item.startTime.isAfter(now) && 
             item.startTime.isBefore(oneHourLater) &&
             item.status == 'active';
    }).toList();
  }

  /// Geçen işlemleri al
  List<DailyScheduleItem> getPastItems() {
    final now = DateTime.now();
    return _todayItems.where((item) => item.startTime.isBefore(now)).toList();
  }

  /// Aktif işlemleri al
  List<DailyScheduleItem> getActiveItems() {
    return _todayItems.where((item) => item.status == 'active').toList();
  }
}