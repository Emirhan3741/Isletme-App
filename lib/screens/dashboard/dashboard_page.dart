// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import '../../widgets/daily_schedule_widget.dart';
import '../../widgets/tomorrow_schedule_widget.dart';
import '../../services/appointment_service.dart';
import '../../services/transaction_service.dart';
import '../../services/customer_service.dart';
import '../../services/expense_service.dart';
import '../../services/stock_service.dart';
import '../customers/add_edit_customer_page.dart';
import '../../core/widgets/common_widgets.dart';
import '../customers/customer_list_page.dart';
import '../notes/add_edit_note_page.dart';
import '../notes/notes_list_page.dart';
import '../transactions/add_edit_transaction_page.dart';
import '../transactions/transaction_list_page.dart';
import '../appointments/add_edit_appointment_page.dart';
import '../appointments/calendar_page.dart';
import '../expenses/add_edit_expense_page.dart';
import '../expenses/expense_list_page.dart';
import '../stocks/stock_list_page.dart';
import '../reports/report_dashboard_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();
  final ExpenseService _expenseService = ExpenseService();
  final StockService _stockService = StockService();

  @override
  void initState() {
    super.initState();
  }

  // Stream'leri kombine eden metod
  Stream<Map<String, dynamic>> get _dashboardStatsStream {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value({});

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final startOfMonth = DateTime(today.year, today.month, 1);

    return Rx.combineLatest6(
      _getTodayAppointmentsStream(currentUser.uid, startOfDay, endOfDay),
      _getMonthlyIncomeStream(currentUser.uid, startOfMonth, today),
      _getPendingPaymentsStream(currentUser.uid),
      _getTotalCustomersStream(currentUser.uid),
      _getMonthlyExpensesStream(currentUser.uid, startOfMonth, today),
      _getStockAlertsStream(currentUser.uid),
      (todayAppointments, monthlyIncome, pendingPayments, totalCustomers,
              monthlyExpenses, stockAlerts) =>
          {
        'todayAppointments': todayAppointments,
        'monthlyIncome': monthlyIncome,
        'pendingPayments': pendingPayments,
        'totalCustomers': totalCustomers,
        'monthlyExpenses': monthlyExpenses,
        'stockAlerts': stockAlerts,
      },
    );
  }

  // Stream veri çekme metodları
  Stream<int> _getTodayAppointmentsStream(
      String userId, DateTime start, DateTime end) {
    return _appointmentService
        .getAppointmentsByDateRange(start, end)
        .map((appointments) => appointments.length);
  }

  Stream<double> _getMonthlyIncomeStream(
      String userId, DateTime start, DateTime end) {
    return _transactionService.getTransactionsByDateRangeStream(start, end).map(
        (transactions) => transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (totalAmount, t) => totalAmount + t.amount));
  }

  Stream<double> _getPendingPaymentsStream(String userId) {
    return _transactionService
        .getTransactionsByTypeStream(TransactionType.expense)
        .map((transactions) =>
            transactions.fold(0.0, (totalAmount, t) => totalAmount + t.amount));
  }

  Stream<int> _getTotalCustomersStream(String userId) {
    return _customerService
        .getCustomersStream()
        .map((customers) => customers.length);
  }

  Stream<double> _getMonthlyExpensesStream(
      String userId, DateTime start, DateTime end) {
    return _expenseService.getExpensesByDateRangeStream(start, end).map(
        (expenses) => expenses
            .where((e) => e.isPaid)
            .fold(0.0, (totalAmount, e) => totalAmount + e.amount));
  }

  Stream<int> _getStockAlertsStream(String userId) {
    return _stockService.getUserStocks().map(
        (stocks) => stocks.where((s) => s.quantity <= s.minQuantity).length);
  }

  Future<int> _getTodayAppointments(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getMonthlyIncome(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'income')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getPendingPayments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalCustomers(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getMonthlyExpenses(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getStockAlerts(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .where('userId', isEqualTo: userId)
          .where('quantity', isLessThanOrEqualTo: 10)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<auth_provider.AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dashboardStatsStream,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoş geldin bölümü
                _buildWelcomeSection(user, snapshot.data),
                const SizedBox(height: AppConstants.paddingLarge),

                // İstatistik kartları
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                else if (snapshot.hasError)
                  Center(
                    child: Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (snapshot.hasData)
                  _buildStatsSection(snapshot.data!),
                const SizedBox(height: AppConstants.paddingLarge),

                // Günlük işlemler
                const DailyScheduleWidget(showOnlyUpcoming: false, maxItems: 5),
                const SizedBox(height: AppConstants.paddingLarge),

                // Yarın için planlananlar
                const TomorrowScheduleWidget(),
                const SizedBox(height: AppConstants.paddingLarge),

                // Hızlı aksiyonlar
                _buildQuickActionsSection(),
                const SizedBox(height: AppConstants.paddingLarge),

                // Son aktiviteler
                _buildRecentActivitiesSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(UserModel? user, Map<String, dynamic>? stats) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 17) {
      greeting = 'İyi öğleden sonralar';
    } else {
      greeting = 'İyi akşamlar';
    }

    return CommonCard(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${user?.name ?? 'Kullanıcı'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bugün ${stats?['todayAppointments'] ?? 0} randevunuz var',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'İşlerinizi takip etmek için dashboard\'u kullanın',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final List<Widget> cards = [
      _buildDashboardCard(
        title: 'Bugünkü Randevular',
        value: stats['todayAppointments']?.toString() ?? '0',
        subtitle: 'Aktif randevu sayısı',
        icon: Icons.today,
        color: AppConstants.primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        ),
      ),
      _buildDashboardCard(
        title: 'Aylık Gelir',
        value: '₺${(stats['monthlyIncome'] ?? 0).toStringAsFixed(0)}',
        subtitle: 'Bu ay toplam gelir',
        icon: Icons.trending_up,
        color: AppConstants.successColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionListPage()),
        ),
      ),
      _buildDashboardCard(
        title: 'Bekleyen Ödemeler',
        value: '₺${(stats['pendingPayments'] ?? 0).toStringAsFixed(0)}',
        subtitle: 'Tahsil edilecek',
        icon: Icons.schedule,
        color: AppConstants.warningColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionListPage()),
        ),
      ),
      _buildDashboardCard(
        title: 'Toplam Müşteri',
        value: stats['totalCustomers']?.toString() ?? '0',
        subtitle: 'Kayıtlı müşteri sayısı',
        icon: Icons.people,
        color: AppConstants.infoColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerListPage()),
        ),
      ),
      _buildDashboardCard(
        title: 'Aylık Gider',
        value: '₺${(stats['monthlyExpenses'] ?? 0).toStringAsFixed(0)}',
        subtitle: 'Bu ay toplam gider',
        icon: Icons.trending_down,
        color: AppConstants.errorColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseListPage()),
        ),
      ),
      _buildDashboardCard(
        title: 'Stok Uyarıları',
        value: stats['stockAlerts']?.toString() ?? '0',
        subtitle: 'Azalan ürün sayısı',
        icon: Icons.inventory,
        color: AppConstants.warningColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StockListPage()),
        ),
      ),
    ];

    return Column(
      children: [
        _buildSectionHeader(
          title: 'Genel Bakış',
          subtitle: 'İşletmenizin güncel durumu',
          icon: Icons.analytics,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    final List<CommonQuickAction> actions = [
      CommonQuickAction(
        label: 'Yeni Randevu',
        icon: Icons.add_box,
        color: AppConstants.primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditAppointmentPage(
              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          ),
        ),
      ),
      CommonQuickAction(
        label: 'Müşteri Ekle',
        icon: Icons.person_add,
        color: AppConstants.successColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditCustomerPage(
              currentUserId: FirebaseAuth.instance.currentUser?.uid,
            ),
          ),
        ),
      ),
      CommonQuickAction(
        label: 'Gelir Kaydet',
        icon: Icons.attach_money,
        color: AppConstants.successColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditTransactionPage(

            ),
          ),
        ),
      ),
      CommonQuickAction(
        label: 'Gider Kaydet',
        icon: Icons.money_off,
        color: AppConstants.errorColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditExpensePage(),
          ),
        ),
      ),
      CommonQuickAction(
        label: 'Not Ekle',
        icon: Icons.note_add,
        color: AppConstants.infoColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditNotePage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          ),
        ),
      ),
      CommonQuickAction(
        label: 'Raporlar',
        icon: Icons.bar_chart,
        color: AppConstants.warningColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportDashboardPage(),
          ),
        ),
      ),
    ];

    return Column(
      children: [
        const CommonSectionHeader(
          title: 'Hızlı İşlemler',
          subtitle: 'Sık kullanılan işlemler',
          icon: Icons.flash_on,
        ),
        CommonQuickActionsGrid(
          actions: actions,
          crossAxisCount: 6,
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      children: [
        CommonSectionHeader(
          title: 'Son Aktiviteler',
          subtitle: 'Son yapılan işlemler',
          icon: Icons.history,
          action: TextButton(
            onPressed: () {
              // Tüm aktiviteleri göster
            },
            child: const Text('Tümünü Gör'),
          ),
        ),
        CommonCard(
          child: Column(
            children: [
              CommonActivityItem(
                icon: Icons.event,
                title: 'Yeni randevu eklendi',
                subtitle: 'Ahmet Yılmaz - Saç kesimi',
                time: '2 saat önce',
                color: AppConstants.primaryColor,
                onTap: () {
                  // Randevu detayına git
                },
              ),
              const Divider(height: 1),
              CommonActivityItem(
                icon: Icons.attach_money,
                title: 'Ödeme alındı',
                subtitle: '₺150 - Nakit ödeme',
                time: '3 saat önce',
                color: AppConstants.successColor,
                onTap: () {
                  // İşlem detayına git
                },
              ),
              const Divider(height: 1),
              CommonActivityItem(
                icon: Icons.person_add,
                title: 'Yeni müşteri eklendi',
                subtitle: 'Ayşe Demir',
                time: '5 saat önce',
                color: AppConstants.infoColor,
                onTap: () {
                  // Müşteri detayına git
                },
              ),
              const Divider(height: 1),
              CommonActivityItem(
                icon: Icons.inventory_2,
                title: 'Stok uyarısı',
                subtitle: 'Şampuan stoku azaldı',
                time: '1 gün önce',
                color: AppConstants.warningColor,
                onTap: () {
                  // Stok sayfasına git
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📊 Dashboard Card Widget
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: AppConstants.elevationMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_forward_ios, 
                      size: 16, 
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📑 Section Header Widget
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingMedium,
        right: AppConstants.paddingMedium,
        bottom: AppConstants.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: AppConstants.paddingSmall),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Modern Navigation Item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? const Color(0xFF1A73E8) : Colors.black54,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1A73E8) : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Modern Dashboard Card
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: const Color(0xFF1A73E8).withValues(alpha: 0.3),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// Activity Item
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        time,
        style: const TextStyle(
          color: Colors.black38,
          fontSize: 11,
        ),
      ),
    );
  }
}



// PsychologistDashboard sınıfı (değişmeden kalabilir)
class PsychologistDashboard extends StatelessWidget {
  const PsychologistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psikolog Paneli'),
      ),
      body: const Center(
        child: Text('Psikologlara özel modüller burada!'),
      ),
    );
  }


}

// User Info Widget
class _UserInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1A73E8),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? "Kullanıcı",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? "",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }

  /// 📊 Dashboard Card Widget
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: AppConstants.elevationMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_forward_ios, 
                      size: 16, 
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📑 Section Header Widget
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingMedium,
        right: AppConstants.paddingMedium,
        bottom: AppConstants.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: AppConstants.paddingSmall),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Duplicate PsychologistDashboard removed

// Modern Dashboard by Cursor
// Cleaned for Web Build by Cursor
