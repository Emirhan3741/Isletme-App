import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/global_header_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import 'psychology_clients_page.dart';
import 'psychology_sessions_page.dart';
import 'psychology_calendar_page.dart';
import 'psychology_services_page.dart';
import '../expenses/expense_list_page.dart';
import '../notes/notes_list_page.dart';
import '../settings/settings_page.dart';

class PsychologyDashboardPage extends StatefulWidget {
  const PsychologyDashboardPage({super.key});

  @override
  State<PsychologyDashboardPage> createState() =>
      _PsychologyDashboardPageState();
}

class _PsychologyDashboardPageState extends State<PsychologyDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Paralel veri çekme
      final futures = await Future.wait([
        _getTodaySessions(currentUser.uid, startOfDay, endOfDay),
        _getActiveClients(currentUser.uid),
        _getActiveServices(currentUser.uid),
        _getMonthlyIncome(currentUser.uid, startOfMonth, today),
        _getPendingPayments(currentUser.uid),
        _getMonthlyExpenses(currentUser.uid, startOfMonth, today),
        _getUrgentClients(currentUser.uid),
        _getUpcomingAppointments(currentUser.uid),
      ]);

      setState(() {
        _stats = {
          'todaySessions': futures[0],
          'activeClients': futures[1],
          'activeServices': futures[2],
          'monthlyIncome': futures[3],
          'pendingPayments': futures[4],
          'monthlyExpenses': futures[5],
          'urgentClients': futures[6],
          'upcomingAppointments': futures[7],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<int> _getTodaySessions(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('seansTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('seansTarihi', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', isEqualTo: 'tamamlandi')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveClients(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveServices(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyServicesCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
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
          .collection(AppConstants.psychologyPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .where('odemeTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('odemeTarihi', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['tutar'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getPendingPayments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['tutar'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getMonthlyExpenses(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyExpensesCollection)
          .where('userId', isEqualTo: userId)
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['tutar'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUrgentClients(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .where('userId', isEqualTo: userId)
          .where('oncelikDurumu', isEqualTo: 'acil')
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUpcomingAppointments(String userId) async {
    try {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('seansTarihi',
              isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
          .where('seansTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .where('status', isEqualTo: 'planli')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return const PsychologyClientsPage();
      case 2:
        return const PsychologySessionsPage();
      case 3:
        return const PsychologyCalendarPage();
      case 4:
        return const PsychologyServicesPage();
      case 5:
        return _PsychologyTherapyPlansTab();
      case 6:
        return _PsychologyPaymentsTab();
      case 7:
        return const ExpenseListPage();
      case 8:
        return _PsychologyDocumentsTab();
      case 9:
        return const NotesListPage();
      case 10:
        return _PsychologyReportsTab();
      case 11:
        return const SettingsPage();
      default:
        return _buildOverviewPage();
    }
  }

  String _getPageTitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.dashboard;
      case 1:
        return localizations.clients;
      case 2:
        return localizations.sessions;
      case 3:
        return localizations.calendar;
      case 4:
        return localizations.services;
      case 5:
        return localizations.therapyPlans;
      case 6:
        return localizations.payments;
      case 7:
        return localizations.expenses;
      case 8:
        return localizations.documents;
      case 9:
        return localizations.notes;
      case 10:
        return localizations.reports;
      case 11:
        return localizations.settings;
      default:
        return 'Psikoloji & Danışmanlık';
    }
  }

  String _getPageSubtitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.statistics;
      case 1:
        return 'Danışan yönetimi ve dosyaları';
      case 2:
        return localizations.sessionTracking;
      case 3:
        return localizations.calendarView;
      case 4:
        return localizations.serviceDefinitions;
      case 5:
        return 'Terapi planları ve takibi';
      case 6:
        return localizations.incomeManagement;
      case 7:
        return localizations.expenseTracking;
      case 8:
        return localizations.documentManagement;
      case 9:
        return localizations.notesReminders;
      case 10:
        return localizations.analysisReports;
      case 11:
        return localizations.profileSettings;
      default:
        return 'Psikoloji danışmanlık sistemi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Dinamik menü öğeleri
    final List<PsychologyMenuItem> menuItems = [
      PsychologyMenuItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        title: localizations.dashboard,
        color: Colors.deepPurple,
      ),
      PsychologyMenuItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        title: localizations.clients,
        color: Colors.blue,
      ),
      PsychologyMenuItem(
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
        title: localizations.sessions,
        color: Colors.green,
      ),
      PsychologyMenuItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        title: localizations.calendar,
        color: Colors.purple,
      ),
      PsychologyMenuItem(
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        title: localizations.services,
        color: Colors.teal,
      ),
      PsychologyMenuItem(
        icon: Icons.psychology_outlined,
        selectedIcon: Icons.psychology,
        title: 'Terapi Planları',
        color: Colors.orange,
      ),
      PsychologyMenuItem(
        icon: Icons.payment_outlined,
        selectedIcon: Icons.payment,
        title: localizations.payments,
        color: Colors.amber,
      ),
      PsychologyMenuItem(
        icon: Icons.trending_down_outlined,
        selectedIcon: Icons.trending_down,
        title: localizations.expenses,
        color: Colors.red,
      ),
      PsychologyMenuItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        title: localizations.documents,
        color: Colors.brown,
      ),
      PsychologyMenuItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        title: localizations.notes,
        color: Colors.deepPurple,
      ),
      PsychologyMenuItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        title: localizations.reports,
        color: Colors.indigo,
      ),
      PsychologyMenuItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        title: localizations.settings,
        color: Colors.blueGrey,
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
                            colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Psikoloji & Danışmanlık',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Terapi Yönetimi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Menü Öğeleri
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
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
                                    ? const Color(0xFF6A5ACD)
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
                                        ? const Color(0xFF6A5ACD)
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
                                          ? const Color(0xFF6A5ACD)
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Psikolog',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Danışmanlık Uzmanı',
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
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18),
                                const SizedBox(width: 8),
                                Text('Çıkış Yap'),
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
                // Global Header
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: GlobalHeaderWidget.psychology(
                    title: _getPageTitle(),
                    subtitle: _getPageSubtitle(),
                    onNotificationTap: () {
                      // Bildirimler açılabilir
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Bildirimler özelliği yakında!')),
                      );
                    },
                    onProfileTap: () {
                      // Profil ayarları açılabilir
                      setState(() {
                        _selectedIndex = 11; // Settings sayfası
                      });
                    },
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
    );
  }

  Widget _buildOverviewPage() {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6A5ACD),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik Kartları
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  localizations.clients,
                  _stats['activeClients']?.toString() ?? '0',
                  Icons.people,
                  const Color(0xFF6A5ACD),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.todaySessions,
                  _stats['todaySessions']?.toString() ?? '0',
                  Icons.event,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.services,
                  _stats['activeServices']?.toString() ?? '0',
                  Icons.medical_services,
                  const Color(0xFF9370DB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.monthlyIncome,
                  '${_stats['monthlyIncome']?.toStringAsFixed(0) ?? '0'} ₺',
                  Icons.trending_up,
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // İkinci Sıra İstatistikler
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Bekleyen Ödemeler',
                  '${_stats['pendingPayments']?.toStringAsFixed(0) ?? '0'} ₺',
                  Icons.payment,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aylık Giderler',
                  '${_stats['monthlyExpenses']?.toStringAsFixed(0) ?? '0'} ₺',
                  Icons.trending_down,
                  const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Acil Durumlar',
                  _stats['urgentClients']?.toString() ?? '0',
                  Icons.warning,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Yaklaşan Randevular',
                  _stats['upcomingAppointments']?.toString() ?? '0',
                  Icons.schedule,
                  const Color(0xFF7C3AED),
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
                const Text(
                  'Hızlı Erişim',
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
                        localizations.newClient ?? 'Yeni Danışan',
                        Icons.person_add,
                        const Color(0xFF6A5ACD),
                        () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        localizations.newSession ?? 'Seans Planla',
                        Icons.add_circle,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedIndex = 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Terapi Planı',
                        Icons.psychology,
                        const Color(0xFF9370DB),
                        () => setState(() => _selectedIndex = 5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        localizations.addPayment ?? 'Ödeme Al',
                        Icons.payment,
                        const Color(0xFFF59E0B),
                        () => setState(() => _selectedIndex = 6),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              color: const Color(0xFF6A5ACD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: Color(0xFF6A5ACD),
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
          ),
        ],
      ),
    );
  }

  void _showAddTreatmentPlanDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.settings),
        content: Text(localizations.comingSoon),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.ok ?? 'Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ödeme'),
        content: const Text(
            'Ödeme ekleme özelliği demo amaçlıdır.\nGerçek veri girişi için giriş yapınız.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Belge'),
        content: const Text(
            'Belge ekleme özelliği demo amaçlıdır.\nGerçek veri girişi için giriş yapınız.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAddReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Rapor'),
        content: const Text(
            'Rapor oluşturma özelliği demo amaçlıdır.\nGerçek veri girişi için giriş yapınız.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

// Case 5: Terapi Planları Sekmesi
class _PsychologyTherapyPlansTab extends StatefulWidget {
  @override
  State<_PsychologyTherapyPlansTab> createState() =>
      _PsychologyTherapyPlansTabState();
}

class _PsychologyTherapyPlansTabState
    extends State<_PsychologyTherapyPlansTab> {
  void _showAddTherapyPlanDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTherapyPlanDialog(
        onPlanAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildTherapyPlansList()),
      ],
    );
  }

  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.therapyPlans,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  localizations.therapyPlanDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddTherapyPlanDialog,
            icon: const Icon(Icons.add),
            label: Text(localizations.newPlan),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyPlansList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTherapyPlansStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTherapyPlanCard(data, doc.id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTherapyPlansStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('psychology_therapy_plans')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildTherapyPlanCard(Map<String, dynamic> data, String id) {
    final localizations = AppLocalizations.of(context)!;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final duration = data['duration'] as int? ?? 0;
    final isActive = data['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2)
            : null,
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
                  color: isActive
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: isActive ? Colors.orange : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? localizations.therapyPlan,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (data['clientName'] != null)
                      Text(
                        '${localizations.client}: ${data['clientName']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Tamamlandı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data['goal'] != null)
            Text(
              'Hedef: ${data['goal']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Süre: $duration hafta',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (data['method'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Yöntem: ${data['method']}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.psychology,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noTherapyPlansYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.createFirstTherapyPlan,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddTherapyPlanDialog,
              icon: const Icon(Icons.add),
              label: Text(localizations.createFirstPlan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Case 6: Ödemeler Sekmesi
class _PsychologyPaymentsTab extends StatefulWidget {
  @override
  State<_PsychologyPaymentsTab> createState() => _PsychologyPaymentsTabState();
}

class _PsychologyPaymentsTabState extends State<_PsychologyPaymentsTab> {
  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(
        onPaymentAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTotalCard(),
        Expanded(child: _buildPaymentsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ödemeler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Danışan ödemelerini yönetin ve takip edin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Ödeme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPaymentsStream(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        // Error state
        if (snapshot.hasError) {
          return _buildErrorCard('Veri yüklenemedi');
        }

        double total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam Gelir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₺${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${snapshot.data?.docs.length} ödeme',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPaymentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPaymentCard(data, doc.id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getPaymentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('psychology_payments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('paymentDate', descending: true)
        .snapshots();
  }

  Widget _buildPaymentCard(Map<String, dynamic> data, String id) {
    final paymentDate = (data['paymentDate'] as Timestamp).toDate();
    final amount = (data['amount'] as num?)?.toDouble();
    final paymentType = data['paymentType'] ?? 'nakit';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['clientName'] ?? 'Danışan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  paymentType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₺${(amount ?? 0.0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.payment,
                size: 50,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz ödeme yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk ödeme kaydınızı ekleyerek başlayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddPaymentDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Ödemeyi Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Case 8: Belgeler Sekmesi
class _PsychologyDocumentsTab extends StatefulWidget {
  @override
  State<_PsychologyDocumentsTab> createState() =>
      _PsychologyDocumentsTabState();
}

class _PsychologyDocumentsTabState extends State<_PsychologyDocumentsTab> {
  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddDocumentDialog(
        onDocumentAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildDocumentsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder,
              color: Colors.brown,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belgeler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Danışan belgeleri ve dosyalarını yönetin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddDocumentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Belge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getDocumentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildDocumentCard(data, doc.id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getDocumentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('psychology_documents')
        .where('userId', isEqualTo: user.uid)
        .orderBy('uploadDate', descending: true)
        .snapshots();
  }

  Widget _buildDocumentCard(Map<String, dynamic> data, String id) {
    final uploadDate = (data['uploadDate'] as Timestamp).toDate();
    final documentType = data['documentType'] ?? 'pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDocumentTypeColor(documentType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getDocumentTypeIcon(documentType),
              color: _getDocumentTypeColor(documentType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['documentName'] ?? 'Belge',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (data['clientName'] != null)
                  Text(
                    'Danışan: ${data['clientName']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  '${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16),
                    const SizedBox(width: 8),
                    Text('Görüntüle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 16),
                    const SizedBox(width: 8),
                    Text('İndir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleDocumentAction(value, id, data),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'png':
      case 'jpeg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'png':
      case 'jpeg':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleDocumentAction(
      String action, String id, Map<String, dynamic> data) {
    switch (action) {
      case 'view':
        // TODO: Belge görüntüleme işlevi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Belge görüntüleme özelliği yakında gelecek')),
        );
        break;
      case 'download':
        // TODO: Belge indirme işlevi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Belge indirme özelliği yakında gelecek')),
        );
        break;
      case 'delete':
        _deleteDocument(id);
        break;
    }
  }

  Future<void> _deleteDocument(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('psychology_documents')
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.brown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.folder,
                size: 50,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz belge yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk belgenizi yükleyerek başlayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddDocumentDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Belgeyi Yükle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Case 10: Raporlar Sekmesi
class _PsychologyReportsTab extends StatefulWidget {
  @override
  State<_PsychologyReportsTab> createState() => _PsychologyReportsTabState();
}

class _PsychologyReportsTabState extends State<_PsychologyReportsTab> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildDateFilter(),
        Expanded(child: _buildReportsContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Raporlar & Analiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Performans analizi ve istatistikler',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.download),
            label: const Text('Dışa Aktar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Tarih Aralığı:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            label: Text(
              '${_selectedDateRange.start.day}/${_selectedDateRange.start.month} - ${_selectedDateRange.end.day}/${_selectedDateRange.end.month}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildReportPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Danışan',
            '0',
            Icons.people,
            Colors.blue,
            _getTotalClients(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Bu Ay Seans',
            '0',
            Icons.event,
            Colors.green,
            _getMonthlySessions(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ortalama Süre',
            '0 dk',
            Icons.schedule,
            Colors.orange,
            _getAverageSessionDuration(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Bu Ay Gelir',
            '₺0',
            Icons.trending_up,
            Colors.purple,
            _getMonthlyIncome(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String defaultValue, IconData icon,
      Color color, Future<String> valueFuture) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: valueFuture,
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? defaultValue,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(48),
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
      child: const Column(
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.indigo),
          const SizedBox(height: 24),
          Text(
            'Gelişmiş Raporlar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seans grafikleri, danışan istatistikleri ve gelir analizleri burada gösterilecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '💡 fl_chart paketi eklendiğinde detaylı grafikler görüntülenecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getTotalClients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0';

      final snapshot = await FirebaseFirestore.instance
          .collection('psychology_clients')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.length.toString();
    } catch (e) {
      return '0';
    }
  }

  Future<String> _getMonthlySessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0';

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('psychology_sessions')
          .where('userId', isEqualTo: user.uid)
          .where('seansTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('seansTarihi',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      return snapshot.docs.length.toString();
    } catch (e) {
      return '0';
    }
  }

  Future<String> _getAverageSessionDuration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0 dk';

      final snapshot = await FirebaseFirestore.instance
          .collection('psychology_sessions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      if (snapshot.docs.isEmpty) return '0 dk';

      int totalDuration = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalDuration += (data['duration'] as int?) ?? 0;
      }

      final average = totalDuration / snapshot.docs.length;
      return '${average.toInt()} dk';
    } catch (e) {
      return '0 dk';
    }
  }

  Future<String> _getMonthlyIncome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '₺0';

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('psychology_payments')
          .where('userId', isEqualTo: user.uid)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return '₺${total.toStringAsFixed(0)}';
    } catch (e) {
      return '₺0';
    }
  }

  void _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  void _exportReport() {
    // TODO: PDF/Excel export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Rapor dışa aktarma özelliği yakında gelecek')),
    );
  }
}

// Dialog Sınıfları
class _AddTherapyPlanDialog extends StatefulWidget {
  final VoidCallback onPlanAdded;

  const _AddTherapyPlanDialog({required this.onPlanAdded});

  @override
  State<_AddTherapyPlanDialog> createState() => _AddTherapyPlanDialogState();
}

class _AddTherapyPlanDialogState extends State<_AddTherapyPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  final _methodController = TextEditingController();
  final _notesController = TextEditingController();

  final String _selectedClientId = '';
  final String _selectedClientName = '';
  int _duration = 8;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _methodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final planData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'goal': _goalController.text.trim(),
        'method': _methodController.text.trim(),
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'clientId': _selectedClientId.isNotEmpty ? _selectedClientId : null,
        'clientName':
            _selectedClientName.isNotEmpty ? _selectedClientName : null,
        'duration': _duration,
        'status': 'active',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('psychology_therapy_plans')
          .add(planData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terapi planı başarıyla eklendi')),
        );
        widget.onPlanAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yeni Terapi Planı',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Başlığı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bu alan gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _goalController,
                  decoration: const InputDecoration(
                    labelText: 'Hedef *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bu alan gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _methodController,
                        decoration: const InputDecoration(
                          labelText: 'Uygulama Yöntemi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _duration,
                        decoration: const InputDecoration(
                          labelText: 'Süre (Hafta)',
                          border: OutlineInputBorder(),
                        ),
                        items: [4, 6, 8, 10, 12, 16, 20, 24].map((duration) {
                          return DropdownMenuItem<int>(
                            value: duration,
                            child: Text('$duration hafta'),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _duration = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notlar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPaymentDialog extends StatefulWidget {
  final VoidCallback onPaymentAdded;

  const _AddPaymentDialog({required this.onPaymentAdded});

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _paymentType = 'nakit';
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _paymentTypes = ['nakit', 'kart', 'havale', 'online'];

  @override
  void dispose() {
    _clientNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final paymentData = {
        'userId': user.uid,
        'clientName': _clientNameController.text.trim(),
        'amount': double.parse(_amountController.text),
        'paymentType': _paymentType,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'paymentDate': Timestamp.fromDate(_paymentDate),
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('psychology_payments')
          .add(paymentData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarıyla eklendi')),
        );
        widget.onPaymentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yeni Ödeme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Danışan Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bu alan gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tutar (₺) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bu alan gerekli';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Ödeme Türü',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _paymentType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _paymentDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ödeme Tarihi',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDocumentDialog extends StatefulWidget {
  final VoidCallback onDocumentAdded;

  const _AddDocumentDialog({required this.onDocumentAdded});

  @override
  State<_AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<_AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _documentNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _documentType = 'pdf';
  bool _isLoading = false;

  final List<String> _documentTypes = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'png',
    'jpeg'
  ];

  @override
  void dispose() {
    _documentNameController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final documentData = {
        'userId': user.uid,
        'documentName': _documentNameController.text.trim(),
        'clientName': _clientNameController.text.trim().isNotEmpty
            ? _clientNameController.text.trim()
            : null,
        'documentType': _documentType,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'uploadDate': Timestamp.now(),
        'fileUrl': null, // TODO: Firebase Storage entegrasyonu
      };

      await FirebaseFirestore.instance
          .collection('psychology_documents')
          .add(documentData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge başarıyla eklendi')),
        );
        widget.onDocumentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yeni Belge',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _documentNameController,
                decoration: const InputDecoration(
                  labelText: 'Belge Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bu alan gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Danışan Adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _documentType,
                      decoration: const InputDecoration(
                        labelText: 'Belge Türü',
                        border: OutlineInputBorder(),
                      ),
                      items: _documentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _documentType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Dosya seçme işlevi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dosya seçme özelliği yakında gelecek')),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Dosya Seç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}

class PsychologyMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final Color color;

  PsychologyMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.color,
  });
}
