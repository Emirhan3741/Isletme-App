import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';



import 'beauty_appointment_page.dart';
import 'beauty_calendar_page.dart';
import 'beauty_customer_list_page.dart';
import 'beauty_transaction_page.dart';
import 'beauty_expense_page.dart';
import 'beauty_service_page.dart';
import 'beauty_employee_page.dart';
import 'beauty_reports_page.dart';
import 'beauty_notes_todo_page.dart';

class BeautyDashboardPage extends StatefulWidget {
  const BeautyDashboardPage({super.key});

  @override
  State<BeautyDashboardPage> createState() => _BeautyDashboardPageState();
}

class _BeautyDashboardPageState extends State<BeautyDashboardPage> {
  int _selectedIndex = 0;

  // Dashboard verileri
  int _todayAppointments = 0;
  double _monthlyIncome = 0.0;
  double _pendingPayments = 0.0;
  int _totalCustomers = 0;
  double _monthlyExpenses = 0.0;
  String _popularService = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Paralel olarak tüm verileri çek
      final results = await Future.wait([
        _getTodayAppointments(user.uid, startOfDay, endOfDay),
        _getMonthlyIncome(user.uid, startOfMonth),
        _getTotalCustomers(user.uid),
        _getMonthlyExpenses(user.uid, startOfMonth),
        _getPendingPayments(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _todayAppointments = results[0] as int;
          _monthlyIncome = results[1] as double;
          _totalCustomers = results[2] as int;
          _monthlyExpenses = results[3] as double;
          _pendingPayments = results[4] as double;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _getTodayAppointments(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      // Tarihi manuel olarak filtrele
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] != null) {
          final docDate = (data['date'] as Timestamp).toDate();
          if (docDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              docDate.isBefore(end.add(const Duration(seconds: 1)))) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint('Randevu sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<double> _getMonthlyIncome(String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'income')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] != null) {
          final docDate = (data['date'] as Timestamp).toDate();
          if (docDate
              .isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            total += (data['amount'] ?? 0.0).toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık gelir alınamadı: $e');
      return 0.0;
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
      if (kDebugMode) debugPrint('Müşteri sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<double> _getMonthlyExpenses(
      String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] != null) {
          final docDate = (data['date'] as Timestamp).toDate();
          if (docDate
              .isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            total += (data['amount'] ?? 0.0).toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık gider alınamadı: $e');
      return 0.0;
    }
  }

  Future<double> _getPendingPayments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final debtAmount = (doc.data()['debtAmount'] ?? 0.0).toDouble();
        if (debtAmount > 0) {
          total += debtAmount;
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Bekleyen ödeme alınamadı: $e');
      return 0.0;
    }
  }

  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Dinamik menü öğeleri
    final List<MenuItem> _menuItems = [
      MenuItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        title: localizations.dashboard,
        route: '/beauty-dashboard',
      ),
      MenuItem(
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        title: localizations.appointments,
        route: '/beauty-appointments',
      ),
      MenuItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        title: localizations.calendar,
        route: '/beauty-calendar',
      ),
      MenuItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        title: localizations.customers,
        route: '/beauty-customers',
      ),
      MenuItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        title: 'İşlemler',
        route: '/beauty-transactions',
      ),
      MenuItem(
        icon: Icons.trending_down_outlined,
        selectedIcon: Icons.trending_down,
        title: localizations.expenses,
        route: '/beauty-expenses',
      ),
      MenuItem(
        icon: Icons.content_cut_outlined,
        selectedIcon: Icons.content_cut,
        title: localizations.services,
        route: '/beauty-services',
      ),
      MenuItem(
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        title: localizations.employees,
        route: '/beauty-employees',
      ),
      MenuItem(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        title: localizations.reports,
        route: '/beauty-reports',
      ),
      MenuItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        title: localizations.notes,
        route: '/beauty-notes',
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Row(
        children: [
          // Sol Menü
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Logo ve Başlık
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.content_cut,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.beautySalon,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.managementSystem,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hızlı Dil Değiştirme Kısayolu
                      Consumer<LocaleProvider>(
                        builder: (context, localeProvider, child) {
                          return PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getLanguageFlag(
                                        localeProvider.locale.languageCode),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: AppConstants.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (String languageCode) {
                              localeProvider.setLocale(Locale(languageCode));
                            },
                            itemBuilder: (BuildContext context) {
                              return LocaleProvider.supportedLocales
                                  .map((locale) {
                                return PopupMenuItem<String>(
                                  value: locale.languageCode,
                                  child: Row(
                                    children: [
                                      Text(
                                        _getLanguageFlag(locale.languageCode),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        LocaleProvider.languageNames[
                                                locale.languageCode] ??
                                            '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Menü Öğeleri
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEC4899)
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFFEC4899)
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFEC4899)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Alt Kısım - Kullanıcı Bilgisi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.beautySpecialist,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.salonOwner,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await FirebaseAuth.instance.signOut();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.signOut),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ana İçerik Alanı
          Expanded(
            child: Column(
              children: [
                // Üst Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPageTitle(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPageSubtitle(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCurrentDate(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sayfa İçeriği
                Expanded(
                  child: _getSelectedPage(),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }

  String _getPageTitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.dashboard;
      case 1:
        return localizations.appointments;
      case 2:
        return localizations.calendar;
      case 3:
        return localizations.customers;
      case 4:
        return 'İşlemler';
      case 5:
        return localizations.expenses;
      case 6:
        return localizations.services;
      case 7:
        return localizations.employees;
      case 8:
        return localizations.reports;
      case 9:
        return localizations.notes;
      default:
        return localizations.dashboard;
    }
  }

  String _getPageSubtitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.statistics;
      case 1:
        return localizations.appointmentTracking;
      case 2:
        return localizations.calendarView;
      case 3:
        return localizations.customerManagement;
      case 4:
        return '${localizations.transactions} ${localizations.payments}';
      case 5:
        return localizations.expenseTracking;
      case 6:
        return localizations.serviceDefinitions;
      case 7:
        return localizations.employeeManagement;
      case 8:
        return localizations.analysisReports;
      case 9:
        return localizations.notesReminders;
      default:
        return localizations.beautySalonManagement;
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return BeautyAppointmentPage();
      case 2:
        return BeautyCalendarPage();
      case 3:
        return BeautyCustomerListPage();
      case 4:
        return BeautyTransactionPage();
      case 5:
        return BeautyExpensePage();
      case 6:
        return BeautyServicePage();
      case 7:
        return BeautyEmployeePage();
      case 8:
        return BeautyReportsPage();
      case 9:
        return BeautyNotesTodoPage();
      default:
        return _buildDashboardPage();
    }
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'ar':
        return '🇸🇦';
      case 'ru':
        return '🇷🇺';
      default:
        return '🌐';
    }
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hızlı İstatistikler
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: Color(0xFFEC4899),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.todayAppointments,
                    value: _todayAppointments.toString(),
                    change: '+12%',
                    isPositive: true,
                    icon: Icons.event,
                    color: const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.monthlyIncome,
                    value: '₺${_monthlyIncome.toStringAsFixed(0)}',
                    change: '+8%',
                    isPositive: true,
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.monthlyExpense,
                    value: '₺${_monthlyExpenses.toStringAsFixed(0)}',
                    change: '-5%',
                    isPositive: false,
                    icon: Icons.trending_down,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.pendingPayment,
                    value: '₺${_pendingPayments.toStringAsFixed(0)}',
                    change: '-3%',
                    isPositive: false,
                    icon: Icons.schedule,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // İkinci satır istatistikler
          if (!_isLoading)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.totalCustomers,
                    value: _totalCustomers.toString(),
                    change: '+15%',
                    isPositive: true,
                    icon: Icons.people,
                    color: const Color(0xFFA78BFA),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.netProfit,
                    value:
                        '₺${(_monthlyIncome - _monthlyExpenses).toStringAsFixed(0)}',
                    change: '+22%',
                    isPositive: (_monthlyIncome - _monthlyExpenses) > 0,
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.popularService,
                    value: _popularService.isEmpty
                        ? AppLocalizations.of(context)!.loading
                        : _popularService,
                    change: '',
                    isPositive: true,
                    icon: Icons.star,
                    color: const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: AppLocalizations.of(context)!.thisMonthNew,
                    value: '12',
                    change: '+25%',
                    isPositive: true,
                    icon: Icons.person_add,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),

          // Hızlı Erişim
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.quickAccess,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        AppLocalizations.of(context)!.newAppointment,
                        Icons.add,
                        const Color(0xFFEC4899),
                        () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        AppLocalizations.of(context)!.newCustomer,
                        Icons.person_add,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedIndex = 3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        AppLocalizations.of(context)!.recordPayment,
                        Icons.receipt_long,
                        const Color(0xFF8B5CF6),
                        () => setState(() => _selectedIndex = 4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        AppLocalizations.of(context)!.addExpense,
                        Icons.trending_down,
                        const Color(0xFFEF4444),
                        () => setState(() => _selectedIndex = 5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (change.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final localizations = AppLocalizations.of(context)!;
    final months = [
      localizations.january,
      localizations.february,
      localizations.march,
      localizations.april,
      localizations.may,
      localizations.june,
      localizations.july,
      localizations.august,
      localizations.september,
      localizations.october,
      localizations.november,
      localizations.december
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class MenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final String route;

  MenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.route,
  });
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 14,
                    ),
                  ),
                  const Spacer(),
                  if (change.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        change,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final String customerName;
  final String service;
  final String time;
  final String status;

  const _AppointmentItem({
    required this.customerName,
    required this.service,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    final localizations = AppLocalizations.of(context)!;

    switch (status) {
      case 'confirmed':
        statusColor = const Color(0xFF10B981);
        statusText = localizations.confirmed;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusText = localizations.pending;
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusText = localizations.unknown;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3366FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                customerName[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3366FF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3366FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3366FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
