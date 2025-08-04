import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import '../clinic/clinic_clients_page.dart';
import '../clinic/clinic_appointments_page.dart';
import '../clinic/clinic_calendar_page.dart';
import '../clinic/clinic_treatments_page.dart';
import '../clinic/clinic_payments_page.dart';
import '../clinic/clinic_expenses_page.dart';
import '../clinic/clinic_services_page.dart';
import '../clinic/clinic_employees_page.dart';
import '../clinic/clinic_documents_page.dart';
import '../clinic/clinic_notes_page.dart';
import '../clinic/clinic_reports_page.dart';
import '../clinic/clinic_profile_page.dart';
import '../../core/models/user_profile_model.dart';

class ClinicDashboard extends StatefulWidget {
  const ClinicDashboard({super.key});

  @override
  State<ClinicDashboard> createState() => _ClinicDashboardState();
}

class _ClinicDashboardState extends State<ClinicDashboard> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;

  // Dashboard verileri
  int _totalClients = 0;
  int _todayAppointments = 0;
  double _monthlyRevenue = 0.0;
  double _monthlyExpenses = 0.0;
  int _pendingPayments = 0;
  bool _isLoading = true;

  final List<ClinicMenuItem> _menuItems = [
    ClinicMenuItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      title: 'Özet',
      color: Colors.teal,
    ),
    ClinicMenuItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      title: 'Hastalar',
      color: Colors.blue,
    ),
    ClinicMenuItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      title: 'Randevular',
      color: Colors.green,
    ),
    ClinicMenuItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      title: 'Takvim',
      color: Colors.purple,
    ),
    ClinicMenuItem(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      title: 'Tedavi & İşlemler',
      color: Colors.teal,
    ),
    ClinicMenuItem(
      icon: Icons.payment_outlined,
      selectedIcon: Icons.payment,
      title: 'İşlem & Ödemeler',
      color: Colors.orange,
    ),
    ClinicMenuItem(
      icon: Icons.money_off_outlined,
      selectedIcon: Icons.money_off,
      title: 'Giderler',
      color: Colors.red,
    ),
    ClinicMenuItem(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      title: 'Hizmetler',
      color: Colors.pink,
    ),
    ClinicMenuItem(
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      title: 'Çalışanlar',
      color: Colors.indigo,
    ),
    ClinicMenuItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      title: 'Belgeler',
      color: Colors.brown,
    ),
    ClinicMenuItem(
      icon: Icons.note_outlined,
      selectedIcon: Icons.note,
      title: 'Notlar',
      color: Colors.deepPurple,
    ),
    ClinicMenuItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      title: 'Raporlar',
      color: Colors.amber,
    ),
    ClinicMenuItem(
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle,
      title: 'Hesabım',
      color: Colors.blueGrey,
    ),
    ClinicMenuItem(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      title: 'Özelleştir',
      color: Colors.deepOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.userProfilesCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        setState(() {
          _userProfile =
              UserProfile.fromMap(doc.docs.first.data(), doc.docs.first.id);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Profil yükleme hatası: $e');
    }
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
        _getTotalPatients(user.uid),
        _getTodayAppointments(user.uid, startOfDay, endOfDay),
        _getMonthlyRevenue(user.uid, startOfMonth),
        _getMonthlyExpenses(user.uid, startOfMonth),
        _getPendingPayments(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _totalClients = results[0] as int;
          _todayAppointments = results[1] as int;
          _monthlyRevenue = results[2] as double;
          _monthlyExpenses = results[3] as double;
          _pendingPayments = results[4] as int;
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

  Future<int> _getTotalPatients(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPatientsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('Toplam hasta sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<int> _getTodayAppointments(
      String userId, DateTime startOfDay, DateTime endOfDay) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('Bugünün randevu sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<double> _getMonthlyRevenue(
      String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('kategori', isEqualTo: 'gelir')
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık gelir alınamadı: $e');
      return 0.0;
    }
  }

  Future<double> _getMonthlyExpenses(
      String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicExpensesCollection)
          .where('userId', isEqualTo: userId)
          .where('expenseDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık gider alınamadı: $e');
      return 0.0;
    }
  }

  Future<int> _getPendingPayments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('Bekleyen ödeme sayısı alınamadı: $e');
      return 0;
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return const ClinicClientsPage();
      case 2:
        return const ClinicAppointmentsPage();
      case 3:
        return const ClinicCalendarPage();
      case 4:
        return const ClinicTreatmentsPage();
      case 5:
        return const ClinicPaymentsPage();
      case 6:
        return const ClinicExpensesPage();
      case 7:
        return const ClinicServicesPage();
      case 8:
        return const ClinicEmployeesPage();
      case 9:
        return const ClinicDocumentsPage();
      case 10:
        return const ClinicNotesPage();
      case 11:
        return const ClinicReportsPage();
      case 12:
        return const ClinicProfilePage();
      case 13:
        return _buildCustomizationPlaceholder();
      default:
        return _buildOverviewPage();
    }
  }

  String _getPageTitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.overview;
      case 1:
        return localizations.patients;
      case 2:
        return localizations.appointments;
      case 3:
        return localizations.calendar;
      case 4:
        return localizations.treatments;
      case 5:
        return localizations.treatmentsProcedures;
      case 6:
        return localizations.expenses;
      case 7:
        return localizations.services;
      case 8:
        return localizations.employees;
      case 9:
        return localizations.documents;
      case 10:
        return localizations.notes;
      case 11:
        return localizations.reports;
      case 12:
        return localizations.myAccount;
      case 13:
        return localizations.customize;
      default:
        return '${localizations.clinic} ${localizations.managementPanel}';
    }
  }

  String _getPageSubtitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.statistics;
      case 1:
        return localizations.patientManagement;
      case 2:
        return localizations.appointmentTracking;
      case 3:
        return localizations.calendarView;
      case 4:
        return localizations.treatmentTracking;
      case 5:
        return localizations.incomeManagement;
      case 6:
        return localizations.expenseTracking;
      case 7:
        return localizations.serviceDefinitions;
      case 8:
        return localizations.employeeManagement;
      case 9:
        return localizations.documentManagement;
      case 10:
        return localizations.notesReminders;
      case 11:
        return localizations.analysisReports;
      case 12:
        return localizations.profileSettings;
      case 13:
        return localizations.panelCustomization;
      default:
        return 'Klinik yönetim sistemi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Dinamik menü öğeleri
    final List<ClinicMenuItem> _menuItems = [
      ClinicMenuItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        title: localizations.overview,
        color: Colors.teal,
      ),
      ClinicMenuItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        title: localizations.patients,
        color: Colors.blue,
      ),
      ClinicMenuItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        title: localizations.appointments,
        color: Colors.green,
      ),
      ClinicMenuItem(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        title: localizations.calendar,
        color: Colors.purple,
      ),
      ClinicMenuItem(
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        title: localizations.treatments,
        color: Colors.teal,
      ),
      ClinicMenuItem(
        icon: Icons.payment_outlined,
        selectedIcon: Icons.payment,
        title: localizations.treatmentsProcedures,
        color: Colors.orange,
      ),
      ClinicMenuItem(
        icon: Icons.money_off_outlined,
        selectedIcon: Icons.money_off,
        title: localizations.expenses,
        color: Colors.red,
      ),
      ClinicMenuItem(
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        title: localizations.services,
        color: Colors.pink,
      ),
      ClinicMenuItem(
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
        title: localizations.employees,
        color: Colors.indigo,
      ),
      ClinicMenuItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        title: localizations.documents,
        color: Colors.brown,
      ),
      ClinicMenuItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        title: localizations.notes,
        color: Colors.deepPurple,
      ),
      ClinicMenuItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        title: localizations.reports,
        color: Colors.amber,
      ),
      ClinicMenuItem(
        icon: Icons.account_circle_outlined,
        selectedIcon: Icons.account_circle,
        title: localizations.myAccount,
        color: Colors.blueGrey,
      ),
      ClinicMenuItem(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
        title: localizations.customize,
        color: Colors.deepOrange,
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
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
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
                              _userProfile?.specialization ?? 'Klinik',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Text(
                              'Yönetim Sistemi',
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
                                    ? const Color(0xFF059669)
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
                                        ? const Color(0xFF059669)
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
                                          ? const Color(0xFF059669)
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
                              _userProfile?.name ?? 'Kullanıcı',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              _userProfile?.title ?? 'Doktor',
                              style: const TextStyle(
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
                                Icon(Icons.logout,
                                    size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 8),
                                Text('Çıkış Yap'),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF6B7280),
                          size: 20,
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
                // Üst Başlık
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getPageTitle(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            _getPageSubtitle(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF6B7280),
                          size: 20,
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
    );
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik Kutuları
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildStatisticsGrid(),

          const SizedBox(height: 32),

          // Hızlı Erişim
          _buildQuickActions(),

          const SizedBox(height: 32),

          // Bugünün Randevuları
          _buildTodayAppointments(),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final netProfit = _monthlyRevenue - _monthlyExpenses;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Hasta',
              _totalClients.toString(),
              Icons.people,
              const Color(0xFF3366FF),
              'Aktif hastalar',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatCard(
              'Bugünün Randevuları',
              _todayAppointments.toString(),
              Icons.calendar_today,
              const Color(0xFF10B981),
              '${_todayAppointments > 0 ? 'Randevular var' : 'Randevu yok'}',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatCard(
              'Aylık Gelir',
              '₺${_monthlyRevenue.toStringAsFixed(0)}',
              Icons.trending_up,
              const Color(0xFF059669),
              'Bu ay toplam',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildStatCard(
              'Net Kar',
              '₺${netProfit.toStringAsFixed(0)}',
              netProfit >= 0 ? Icons.account_balance_wallet : Icons.money_off,
              netProfit >= 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              netProfit >= 0 ? 'Kârlı' : 'Zararlı',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Randevu',
                    Icons.add_circle_outline,
                    const Color(0xFF10B981),
                    () => setState(() => _selectedIndex = 2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Hasta',
                    Icons.person_add,
                    const Color(0xFF3366FF),
                    () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Tedavi',
                    Icons.medical_services,
                    const Color(0xFF059669),
                    () => setState(() => _selectedIndex = 4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    'Ödeme Ekle',
                    Icons.payment,
                    const Color(0xFFF59E0B),
                    () => setState(() => _selectedIndex = 5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    'Gider Ekle',
                    Icons.money_off,
                    const Color(0xFFEF4444),
                    () => setState(() => _selectedIndex = 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bugünün Randevuları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text('Tümünü Görüntüle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTodayAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildTodayAppointmentsList() {
    // Mock data for today's appointments
    final todayAppointments = [
      {
        'client': 'Ayşe Yılmaz',
        'time': '10:00',
        'service': 'Muayene',
        'type': 'appointment',
      },
      {
        'client': 'Mehmet Demir',
        'time': '14:30',
        'service': 'Kontrol',
        'type': 'appointment',
      },
    ];

    if (todayAppointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Bugün randevu bulunmuyor',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayAppointments.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final appointment = todayAppointments[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          title: Text(
            appointment['client'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            appointment['service'] as String,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3366FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment['time'] as String,
              style: const TextStyle(
                color: Color(0xFF3366FF),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomizationPlaceholder() {
    return _ClinicDashboardCustomizationTab();
  }
}

// Panel Özelleştirmesi Sekmesi
class _ClinicDashboardCustomizationTab extends StatefulWidget {
  @override
  State<_ClinicDashboardCustomizationTab> createState() =>
      _ClinicDashboardCustomizationTabState();
}

class _ClinicDashboardCustomizationTabState
    extends State<_ClinicDashboardCustomizationTab> {
  Map<String, bool> _dashboardSettings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Dashboard bileşenlerinin tanımları
  final List<DashboardComponent> _dashboardComponents = [
    DashboardComponent(
      key: 'daily_appointments',
      title: 'Günlük Randevular',
      description: 'Bugünkü randevu listesi ve durum özeti',
      icon: Icons.today,
      category: 'Randevular',
      defaultEnabled: true,
    ),
    DashboardComponent(
      key: 'quick_actions',
      title: 'Hızlı İşlem Butonları',
      description: 'Yeni hasta, randevu ve fatura oluşturma',
      icon: Icons.flash_on,
      category: 'İşlemler',
      defaultEnabled: true,
    ),
    DashboardComponent(
      key: 'revenue_summary',
      title: 'Gelir Özeti',
      description: 'Aylık gelir ve ödeme durumu kartları',
      icon: Icons.trending_up,
      category: 'Finansal',
      defaultEnabled: true,
    ),
    DashboardComponent(
      key: 'recent_notes',
      title: 'Son Notlar',
      description: 'Hasta notları ve hatırlatmalar',
      icon: Icons.note,
      category: 'Notlar',
      defaultEnabled: true,
    ),
    DashboardComponent(
      key: 'patient_statistics',
      title: 'Hasta İstatistikleri',
      description: 'Toplam hasta sayısı ve demografik bilgiler',
      icon: Icons.people,
      category: 'İstatistikler',
      defaultEnabled: false,
    ),
    DashboardComponent(
      key: 'appointment_calendar',
      title: 'Haftalık Takvim',
      description: 'Bu haftanın randevu takvimi görünümü',
      icon: Icons.calendar_view_week,
      category: 'Randevular',
      defaultEnabled: false,
    ),
    DashboardComponent(
      key: 'pending_payments',
      title: 'Bekleyen Ödemeler',
      description: 'Ödenmemiş fatura ve borç listesi',
      icon: Icons.pending_actions,
      category: 'Finansal',
      defaultEnabled: true,
    ),
    DashboardComponent(
      key: 'treatment_overview',
      title: 'Tedavi Durumu',
      description: 'Aktif tedaviler ve işlem özetleri',
      icon: Icons.medical_services,
      category: 'Tedaviler',
      defaultEnabled: false,
    ),
    DashboardComponent(
      key: 'employee_status',
      title: 'Personel Durumu',
      description: 'Çalışan listesi ve günlük program',
      icon: Icons.badge,
      category: 'Personel',
      defaultEnabled: false,
    ),
    DashboardComponent(
      key: 'recent_documents',
      title: 'Son Belgeler',
      description: 'Yeni yüklenen hasta belgeleri',
      icon: Icons.folder,
      category: 'Belgeler',
      defaultEnabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardSettings();
  }

  Future<void> _loadDashboardSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_dashboard_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _dashboardSettings =
              Map<String, bool>.from(data['clinic_dashboard'] ?? {});
        });
      }

      // Varsayılan ayarları ekle
      for (var component in _dashboardComponents) {
        if (!_dashboardSettings.containsKey(component.key)) {
          _dashboardSettings[component.key] = component.defaultEnabled;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard ayarları yüklenemedi: $e');
      // Varsayılan ayarları kullan
      for (var component in _dashboardComponents) {
        _dashboardSettings[component.key] = component.defaultEnabled;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDashboardSettings() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await FirebaseFirestore.instance
          .collection('user_dashboard_settings')
          .doc(user.uid)
          .set({
        'clinic_dashboard': _dashboardSettings,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panel ayarları başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varsayılan Ayarlar'),
        content: const Text(
            'Tüm panel ayarlarınız varsayılan değerlere döndürülecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (var component in _dashboardComponents) {
                  _dashboardSettings[component.key] = component.defaultEnabled;
                }
              });
              _saveDashboardSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSettingsGrid(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel Özelleştirmesi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Dashboard\'unuzda hangi bileşenlerin görüneceğini ayarlayın',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Değişiklikler anında kaydedilir ve ana sayfa yenilendiğinde görünür',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGrid() {
    // Kategorilere göre grupla
    Map<String, List<DashboardComponent>> componentsByCategory = {};
    for (var component in _dashboardComponents) {
      if (!componentsByCategory.containsKey(component.category)) {
        componentsByCategory[component.category] = [];
      }
      componentsByCategory[component.category]!.add(component);
    }

    return Column(
      children: componentsByCategory.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
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
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              ...entry.value.map((component) => _buildComponentTile(component)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComponentTile(DashboardComponent component) {
    final isEnabled = _dashboardSettings[component.key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isEnabled ? Colors.teal.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? Colors.teal.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.teal.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              component.icon,
              color: isEnabled ? Colors.teal : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isEnabled ? const Color(0xFF111827) : Colors.grey[600],
                  ),
                ),
                Text(
                  component.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _dashboardSettings[component.key] = value;
              });
              _saveDashboardSettings();
            },
            activeColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final enabledCount = _dashboardSettings.values.where((v) => v).length;
    final totalCount = _dashboardComponents.length;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Durum Özeti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '$enabledCount / $totalCount bileşen aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Varsayılana Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: enabledCount / totalCount,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ayarlar kaydediliyor...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}

// Dashboard bileşeni model sınıfı
class DashboardComponent {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final bool defaultEnabled;

  DashboardComponent({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.defaultEnabled,
  });
}

class ClinicMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final Color color;

  ClinicMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.color,
  });
}
