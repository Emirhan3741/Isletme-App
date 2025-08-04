import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import '../models/transaction_model.dart';

import '../models/expense_model.dart';
import '../services/transaction_service.dart';
import '../services/customer_service.dart';
import '../services/notification_service.dart';
import '../services/stock_service.dart';
import '../utils/error_handler.dart';

class AutomationService {
  static final AutomationService _instance = AutomationService._internal();
  factory AutomationService() => _instance;
  AutomationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();
  final NotificationService _notificationService = NotificationService();
  final StockService _stockService = StockService();

  // Get current user ID from Firebase Auth
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Initialize automation service
  static Future<void> initialize() async {
    final instance = AutomationService();
    // Listen for appointment status changes
    instance._listenForAppointmentChanges();

    // Schedule daily automation tasks
    instance._scheduleDailyTasks();

    // Listen for stock changes
    instance._listenForStockChanges();
  }

  // Listen for appointment status changes
  void _listenForAppointmentChanges() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final appointment = AppointmentModel.fromMap({
            ...change.doc.data() as Map<String, dynamic>,
            'id': change.doc.id,
          });

          _handleAppointmentStatusChange(appointment);
        }
      }
    });
  }

  // Handle appointment status change
  Future<void> _handleAppointmentStatusChange(
      AppointmentModel appointment) async {
    try {
      switch (appointment.status) {
        case AppointmentStatus.completed:
          await _onAppointmentCompleted(appointment);
          break;
        case AppointmentStatus.cancelled:
          await _onAppointmentCancelled(appointment);
          break;
        case AppointmentStatus.noShow:
          await _onAppointmentNoShow(appointment);
          break;
        case AppointmentStatus.pending:
          await _onAppointmentScheduled(appointment);
          break;
        default:
          break;
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Appointment status change automation');
    }
  }

  // When appointment is completed
  Future<void> _onAppointmentCompleted(AppointmentModel appointment) async {
    // 1. Create income transaction
    await _createIncomeTransaction(appointment);

    // 2. Update customer statistics
    await _updateCustomerStats(appointment);

    // 3. Send completion notification
    await _sendCompletionNotification(appointment);

    // 4. Schedule follow-up reminder
    await _scheduleFollowUpReminder(appointment);
  }

  // When appointment is cancelled
  Future<void> _onAppointmentCancelled(AppointmentModel appointment) async {
    // 1. Send cancellation notification
    await _notificationService.scheduleNotification(
      title: 'Randevu İptal Edildi',
      body: '${appointment.customerName} randevusu iptal edildi.',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      payload: 'appointment_cancelled_${appointment.id}',
    );

    // 2. Update customer cancellation statistics
    await _updateCustomerCancellationStats(appointment);
  }

  // When appointment is no-show
  Future<void> _onAppointmentNoShow(AppointmentModel appointment) async {
    // 1. Send no-show notification
    await _notificationService.scheduleNotification(
      title: 'Randevuya Gelmedi',
      body: '${appointment.customerName} randevuya gelmedi.',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      payload: 'appointment_noshow_${appointment.id}',
    );

    // 2. Update customer no-show statistics
    await _updateCustomerNoShowStats(appointment);
  }

  // When appointment is scheduled
  Future<void> _onAppointmentScheduled(AppointmentModel appointment) async {
    // 1. Send appointment reminder notification
    await _notificationService.sendAppointmentReminder(appointment.toMap());

    // 2. Check for conflicting appointments
    await _checkForConflictingAppointments(appointment);
  }

  // Create income transaction from completed appointment
  Future<void> _createIncomeTransaction(AppointmentModel appointment) async {
    if (appointment.price == null || appointment.price! <= 0) return;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: appointment.userId,
      type: TransactionType.income,
      category: TransactionCategory.serviceFee.name,
      title: 'Randevu Geliri - ${appointment.customerName}',
      description: 'Otomatik oluşturulan randevu geliri',
      amount: appointment.price!,
      createdAt: DateTime.now(),
      fileUrls: [],
    );

    await _transactionService.addTransaction(transaction);
  }

  // Update customer statistics
  Future<void> _updateCustomerStats(AppointmentModel appointment) async {
    if (appointment.customerId == null) return;

    try {
      final customer =
          await _customerService.getCustomerById(appointment.customerId!);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          lastVisit: DateTime.now(),
          totalVisits: customer.totalVisits + 1,
          totalSpent: customer.totalSpent + (appointment.price ?? 0),
        );

        await _customerService.updateCustomer(updatedCustomer);
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Update customer stats');
    }
  }

  // Send completion notification
  Future<void> _sendCompletionNotification(AppointmentModel appointment) async {
    await _notificationService.scheduleNotification(
      title: 'Randevu Tamamlandı',
      body:
          '${appointment.customerName} randevusu başarıyla tamamlandı. Gelir: ₺${appointment.price?.toStringAsFixed(2) ?? '0.00'}',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      payload: 'appointment_completed_${appointment.id}',
    );
  }

  // Schedule follow-up reminder
  Future<void> _scheduleFollowUpReminder(AppointmentModel appointment) async {
    final followUpDate = DateTime.now().add(const Duration(days: 7));

    await _notificationService.scheduleNotification(
      title: 'Müşteri Takibi',
      body:
          '${appointment.customerName} müşterisi için takip randevusu planlamayı unutmayın.',
      scheduledTime: followUpDate,
      payload: 'follow_up_${appointment.customerId}',
    );
  }

  // Update customer cancellation statistics
  Future<void> _updateCustomerCancellationStats(
      AppointmentModel appointment) async {
    // This could be used to track customer reliability
    // For now, we'll just log it
    ErrorHandler.logError(
      'Customer ${appointment.customerName} cancelled appointment',
      'Customer cancellation tracking',
    );
  }

  // Update customer no-show statistics
  Future<void> _updateCustomerNoShowStats(AppointmentModel appointment) async {
    // This could be used to track customer reliability
    // For now, we'll just log it
    ErrorHandler.logError(
      'Customer ${appointment.customerName} no-show for appointment',
      'Customer no-show tracking',
    );
  }

  // Check for conflicting appointments
  Future<void> _checkForConflictingAppointments(
      AppointmentModel appointment) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final startTime = appointment.date;
      final endTime = appointment.date
          .add(const Duration(hours: 1)); // Assume 1 hour appointments

      final conflictingAppointments = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('date', isLessThan: Timestamp.fromDate(endTime))
          .get();

      if (conflictingAppointments.docs.length > 1) {
        await _notificationService.scheduleNotification(
          title: 'Randevu Çakışması',
          body: 'Aynı saatte birden fazla randevu bulunuyor. Kontrol ediniz.',
          scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
          payload: 'appointment_conflict_${appointment.id}',
        );
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Check conflicting appointments');
    }
  }

  // Schedule daily automation tasks
  void _scheduleDailyTasks() {
    // This would typically be done with a cron job or scheduled function
    // For now, we'll simulate with periodic checks
    _schedulePaymentReminders();
    _scheduleExpenseReminders();
    _scheduleStockChecks();
  }

  // Schedule payment reminders
  void _schedulePaymentReminders() {
    // Check for customers with outstanding payments
    Timer.periodic(const Duration(hours: 24), (timer) async {
      await _checkOutstandingPayments();
    });
  }

  // Schedule expense reminders
  void _scheduleExpenseReminders() {
    // Check for upcoming expenses
    Timer.periodic(const Duration(hours: 12), (timer) async {
      await _checkUpcomingExpenses();
    });
  }

  // Schedule stock checks
  void _scheduleStockChecks() {
    // Check for low stock items
    Timer.periodic(const Duration(hours: 6), (timer) async {
      await _checkLowStockItems();
    });
  }

  // Check outstanding payments
  Future<void> _checkOutstandingPayments() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final customers = await _customerService.getCustomers();

      for (final _ in customers) {
        // TODO: Müşterinin borç bakiyesini işlem geçmişinden hesapla.
        // Mevcut CustomerModel'de debtAmount alanı bulunmuyor.
        /*
        if (customer.debtAmount > 0) {
          await _notificationService.sendCustomNotification(
            userId: customer.userId,
            title: 'Ödeme Hatırlatması',
            body: '${customer.name} müşterisinin ₺${customer.debtAmount.toStringAsFixed(2)} tutarında ödeme borcu bulunmaktadır.',
            data: {'type': 'payment_reminder', 'customerId': customer.id ?? ''},
          );
        }
        */
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Check outstanding payments');
    }
  }

  // Check upcoming expenses
  Future<void> _checkUpcomingExpenses() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final endOfDay =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

      final upcomingExpenses = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('isPaid', isEqualTo: false)
          .get();

      for (final doc in upcomingExpenses.docs) {
        final expense = ExpenseModel.fromMap({
          ...doc.data(),
          'id': doc.id,
        });

        await _notificationService.sendCustomNotification(
          userId: _userId!,
          title: 'Gider Hatırlatması',
          body:
              '${expense.title} için ₺${expense.amount.toStringAsFixed(2)} tutarında ödeme yarın son gün.',
          data: {'type': 'expense_reminder', 'expenseId': expense.id ?? ''},
        );
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Check upcoming expenses');
    }
  }

  // Check low stock items
  Future<void> _checkLowStockItems() async {
    try {
      final lowStockItems = await _stockService.getLowStockItems();

      for (final item in lowStockItems) {
        await _notificationService.showInstantNotification(
          title: 'Stok Uyarısı',
          body:
              '${item.name} ürününde sadece ${item.quantity} adet kaldı. Stok yenilemeyi unutmayın.',
          payload: 'low_stock_${item.id}',
        );
      }
    } catch (e) {
      ErrorHandler.logError(e, 'Check low stock items');
    }
  }

  // Listen for stock changes
  void _listenForStockChanges() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('stocks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final quantity = data['quantity'] as int? ?? 0;
          final minQuantity = data['minQuantity'] as int? ?? 0;
          final name = data['name'] as String? ?? 'Unknown';

          if (quantity <= minQuantity) {
            _notificationService.showInstantNotification(
              title: 'Stok Uyarısı',
              body:
                  '$name ürününde sadece $quantity adet kaldı. Stok yenilemeyi unutmayın.',
              payload: 'low_stock_$name',
            );
          }
        }
      }
    });
  }

  // Create recurring expense
  Future<void> createRecurringExpense(ExpenseModel expense) async {
    if (!expense.isRecurring) return;

    try {
      final nextExpense = expense.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _getNextRecurringDate(expense.date),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('expenses').add(nextExpense.toMap());

      // Send reminder for the recurring expense
      await _notificationService.sendCustomNotification(
        userId: _userId!,
        title: 'Tekrarlanan Gider Hatırlatması',
        body:
            '${nextExpense.title} için ₺${nextExpense.amount.toStringAsFixed(2)} tutarında ödeme yapmanız gerekiyor.',
        data: {'type': 'recurring_expense', 'expenseId': nextExpense.id ?? ''},
      );
    } catch (e) {
      ErrorHandler.logError(e, 'Create recurring expense');
    }
  }

  // Get next recurring date
  DateTime _getNextRecurringDate(DateTime currentDate) {
    // For now, assume monthly recurrence
    // This could be extended to support weekly, quarterly, etc.
    return DateTime(
      currentDate.year,
      currentDate.month + 1,
      currentDate.day,
    );
  }

  // Send daily business summary
  Future<void> sendDailyBusinessSummary() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Get today's statistics
      final todayAppointments =
          await _getTodayAppointments(startOfDay, endOfDay);
      final todayIncome = await _getTodayIncome(startOfDay, endOfDay);
      final todayExpenses = await _getTodayExpenses(startOfDay, endOfDay);

      await _notificationService.scheduleNotification(
        title: 'Günlük İş Özeti',
        body:
            'Bugün: ${todayAppointments.length} randevu, ₺${todayIncome.toStringAsFixed(2)} gelir, ₺${todayExpenses.toStringAsFixed(2)} gider',
        scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
        payload: 'daily_summary',
      );
    } catch (e) {
      ErrorHandler.logError(e, 'Send daily business summary');
    }
  }

  // Get today's appointments
  Future<List<AppointmentModel>> _getTodayAppointments(
      DateTime start, DateTime end) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList();
  }

  // Get today's income
  Future<double> _getTodayIncome(DateTime start, DateTime end) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'income')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      final data = doc.data();
      return sum + ((data['amount'] as num?)?.toDouble() ?? 0.0);
    });
  }

  // Get today's expenses
  Future<double> _getTodayExpenses(DateTime start, DateTime end) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    final snapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.fold<double>(0.0, (double sum, doc) {
      final data = doc.data();
      return sum + ((data['amount'] as num?)?.toDouble() ?? 0.0);
    });
  }
}
