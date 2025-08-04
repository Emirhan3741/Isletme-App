import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart' as auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/global_header_widget.dart';
import '../sports/sports_members_page.dart';
import '../sports/sports_sessions_page.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import '../sports/sports_calendar_page.dart';
import '../sports/sports_programs_page.dart';
import '../sports/sports_payments_page.dart';
import '../sports/sports_expenses_page.dart';
import '../sports/sports_services_page.dart';
import '../sports/sports_coaches_page.dart';
import '../sports/sports_documents_page.dart';
import '../sports/sports_reports_page.dart';
import '../notes/notes_list_page.dart';
import '../settings/settings_page.dart';

class SportsDashboard extends StatefulWidget {
  const SportsDashboard({super.key});

  @override
  State<SportsDashboard> createState() => _SportsDashboardState();
}

class _SportsDashboardState extends State<SportsDashboard> {
  int _selectedIndex = 0;

  // Dashboard verileri
  int _totalMembers = 0;
  int _todaySessions = 0;
  double _monthlyRevenue = 0.0;
  double _monthlyExpenses = 0.0;
  int _activePrograms = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Simüle edilmiş veriler
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _totalMembers = 75;
          _todaySessions = 12;
          _monthlyRevenue = 18500.0;
          _monthlyExpenses = 8200.0;
          _activePrograms = 8;
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

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return const SportsMembersPage();
      case 2:
        return const SportsCalendarPage();
      case 3:
        return const SportsProgramsPage();
      case 4:
        return const SportsSessionsPage();
      case 5:
        return const SportsPaymentsPage();
      case 6:
        return const SportsExpensesPage();
      case 7:
        return const SportsServicesPage();
      case 8:
        return const SportsCoachesPage();
      case 9:
        return const SportsDocumentsPage(customerId: '');
      case 10:
        return const NotesListPage();
      case 11:
        return const SportsReportsPage();
      case 12:
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
        return localizations.members;
      case 2:
        return localizations.calendar;
      case 3:
        return localizations.programs;
      case 4:
        return localizations.sessionsAppointments;
      case 5:
        return localizations.payments;
      case 6:
        return localizations.expenses;
      case 7:
        return localizations.services;
      case 8:
        return localizations.coaches;
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
        return '${localizations.sportsCoaching} ${localizations.managementPanel}';
    }
  }

  String _getPageSubtitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.statistics;
      case 1:
        return localizations.memberManagement;
      case 2:
        return localizations.calendarView;
      case 3:
        return localizations.trainingPrograms;
      case 4:
        return localizations.sessionTracking;
      case 5:
        return localizations.incomeManagement;
      case 6:
        return localizations.expenseTracking;
      case 7:
        return localizations.serviceDefinitions;
      case 8:
        return localizations.coachManagement;
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
        return 'Spor ve fitness yönetim sistemi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Dinamik menü öğeleri
    final List<SportsMenuItem> _menuItems = [
      SportsMenuItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        title: localizations.dashboard,
        color: Colors.orange,
      ),
      SportsMenuItem(
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
        title: localizations.members,
        color: Colors.blue,
      ),
      SportsMenuItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        title: localizations.calendar,
        color: Colors.purple,
      ),
      SportsMenuItem(
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        title: localizations.programs,
        color: Colors.green,
      ),
      SportsMenuItem(
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        title: localizations.sessionsAppointments,
        color: Colors.teal,
      ),
      SportsMenuItem(
        icon: Icons.payment_outlined,
        selectedIcon: Icons.payment,
        title: localizations.payments,
        color: Colors.orange,
      ),
      SportsMenuItem(
        icon: Icons.money_off_outlined,
        selectedIcon: Icons.money_off,
        title: localizations.expenses,
        color: Colors.red,
      ),
      SportsMenuItem(
        icon: Icons.sports_outlined,
        selectedIcon: Icons.sports,
        title: localizations.services,
        color: Colors.pink,
      ),
      SportsMenuItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        title: localizations.coaches,
        color: Colors.indigo,
      ),
      SportsMenuItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        title: localizations.documents,
        color: Colors.brown,
      ),
      SportsMenuItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        title: localizations.notes,
        color: Colors.deepPurple,
      ),
      SportsMenuItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        title: localizations.reports,
        color: Colors.amber,
      ),
      SportsMenuItem(
        icon: Icons.account_circle_outlined,
        selectedIcon: Icons.account_circle,
        title: localizations.myAccount,
        color: Colors.blueGrey,
      ),
      SportsMenuItem(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune,
        title: localizations.customize,
        color: Colors.deepOrange,
      ),
    ];

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppConstants.surfaceColor,
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
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
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
                              localizations.sportsCoaching,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              localizations.managementSystem,
                              style: const TextStyle(
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
                                    ? const Color(0xFFFF6B35)
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
                                        ? const Color(0xFFFF6B35)
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
                                          ? const Color(0xFFFF6B35)
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
                              'Antrenör',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Spor Uzmanı',
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
                  child: GlobalHeaderWidget.sports(
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
                        _selectedIndex = 12; // Settings sayfası
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
          color: Color(0xFFFF6B35),
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
                  localizations.totalMembers,
                  _totalMembers.toString(),
                  Icons.group,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.todaySessions,
                  _todaySessions.toString(),
                  Icons.schedule,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.monthlyIncome,
                  '${_monthlyRevenue.toStringAsFixed(0)} ₺',
                  Icons.trending_up,
                  const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  localizations.activePrograms,
                  _activePrograms.toString(),
                  Icons.fitness_center,
                  const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Hızlı İşlemler
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
                  localizations.quickActions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildQuickActionButton(
                      localizations.newMember,
                      Icons.person_add,
                      const Color(0xFF3B82F6),
                      () => setState(() => _selectedIndex = 1),
                    ),
                    _buildQuickActionButton(
                      localizations.newSession,
                      Icons.add_circle,
                      const Color(0xFF10B981),
                      () => setState(() => _selectedIndex = 4),
                    ),
                    _buildQuickActionButton(
                      localizations.addPayment,
                      Icons.payment,
                      const Color(0xFF059669),
                      () => setState(() => _selectedIndex = 5),
                    ),
                    _buildQuickActionButton(
                      localizations.createProgram,
                      Icons.fitness_center,
                      const Color(0xFFFF6B35),
                      () => setState(() => _selectedIndex = 3),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: Color(0xFFFF6B35),
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
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}

class SportsMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final Color color;

  SportsMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.color,
  });
}
