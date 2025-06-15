// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/expense_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Bildirim service'ini başlat
  Future<void> initialize() async {
    // Android ayarları
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Genel ayarlar
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Timezone'ları başlat
    tz.initializeTimeZones();
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // İzinleri iste
    await _requestPermissions();
  }

  // İzinleri iste
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Bildirime tıklandığında
  static void _onNotificationTapped(NotificationResponse response) {
    print('Bildirime tıklandı: ${response.payload}');
    // Buraya bildirime tıklandığında yapılacak işlemler eklenebilir
  }

  // Gider hatırlatıcısı zamanla
  Future<void> scheduleExpenseReminder(ExpenseModel expense) async {
    // Gider tarihinden 1 gün önce hatırlatıcı ayarla
    final reminderDate = expense.createdAt.subtract(const Duration(days: 1));
    // Eğer hatırlatıcı tarihi geçmişte ise, hatırlatıcı ayarlama
    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }
    // Hatırlatıcı zamanı: Sabah 9:00
    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // Saat 9
      0,  // Dakika 0
    );
    final categoryIcon = getExpenseCategoryIcon(expense.category);
    await _notifications.zonedSchedule(
      expense.id.hashCode, // Unique ID
      'Gider Hatırlatıcısı',
      'Yarın ${expense.category} gideriniz var: ${expense.amount.toStringAsFixed(2)} ₺ $categoryIcon',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_reminders',
          'Gider Hatırlatıcıları',
          channelDescription: 'Yaklaşan giderler için hatırlatıcılar',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'expense_${expense.id}',
    );
    print('Gider hatırlatıcısı ayarlandı: ${expense.category} - $scheduledDate');
  }

  // Gider hatırlatıcısını iptal et
  Future<void> cancelExpenseReminder(String expenseId) async {
    await _notifications.cancel(expenseId.hashCode);
    print('Gider hatırlatıcısı iptal edildi: $expenseId');
  }

  // Anında bildirim gönder (test için)
  Future<void> showImmediateNotification(String title, String body) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_notifications',
          'Anında Bildirimler',
          channelDescription: 'Test bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Belirli kategorideki tüm gider hatırlatıcılarını iptal et
  Future<void> cancelCategoryReminders(String category) async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    for (final notification in pendingNotifications) {
      if (notification.payload?.contains('expense_') == true &&
          notification.body?.contains(category) == true) {
        await _notifications.cancel(notification.id);
      }
    }
    
    print('$category kategorisi hatırlatıcıları iptal edildi');
  }

  // Tüm gider hatırlatıcılarını iptal et
  Future<void> cancelAllExpenseReminders() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    for (final notification in pendingNotifications) {
      if (notification.payload?.contains('expense_') == true) {
        await _notifications.cancel(notification.id);
      }
    }
    
    print('Tüm gider hatırlatıcıları iptal edildi');
  }

  // Bekleyen bildirimlerinin listesini al
  Future<List<PendingNotificationRequest>> getPendingExpenseReminders() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    return pendingNotifications.where((notification) => 
        notification.payload?.contains('expense_') == true).toList();
  }

  // Bildirim ayarlarını kontrol et
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    
    if (iosImplementation != null) {
      final settings = await iosImplementation.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    
    return false;
  }

  // Günlük gider hatırlatıcısı ayarla (sabah 8:00'de bugünün giderlerini hatırlat)
  Future<void> scheduleDailyExpenseCheck() async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
    
    // Eğer şu anki saat 8:00'i geçmişse, yarın için ayarla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      999999, // Daily reminder için özel ID
      'Günlük Gider Kontrolü',
      'Bugün ödenecek giderlerinizi kontrol etmeyi unutmayın! 📋',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_expense_check',
          'Günlük Gider Kontrolü',
          channelDescription: 'Günlük gider kontrol hatırlatıcısı',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily_expense_check',
      matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
    );

    print('Günlük gider kontrolü hatırlatıcısı ayarlandı: $scheduledDate');
  }

  // Kategori ikonunu almak için fonksiyon
  String getExpenseCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return '🏠';
      case ExpenseCategory.electricity:
        return '⚡';
      case ExpenseCategory.water:
        return '💧';
      case ExpenseCategory.naturalGas:
        return '🔥';
      case ExpenseCategory.phone:
        return '📞';
      case ExpenseCategory.internet:
        return '📶';
      case ExpenseCategory.salary:
        return '💰';
      case ExpenseCategory.material:
        return '📦';
      case ExpenseCategory.cleaning:
        return '🧹';
      case ExpenseCategory.advertising:
        return '📢';
      case ExpenseCategory.tax:
        return '📋';
      case ExpenseCategory.insurance:
        return '🛡️';
      case ExpenseCategory.fuel:
        return '⛽';
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.maintenance:
        return '🔧';
      case ExpenseCategory.other:
        return '💼';
    }
  }
} 