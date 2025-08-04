import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/global_header_widget.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import '../../core/models/lawyer_client_model.dart';
import '../../core/models/case_model.dart';
import 'lawyer_clients_page.dart';
import 'lawyer_cases_page.dart';
import 'lawyer_calendar_page.dart';
import 'lawyer_hearings_page.dart';
import 'lawyer_contracts_page.dart';
import 'lawyer_transactions_page.dart';
import 'lawyer_documents_page.dart';
import 'lawyer_notes_page.dart';
import 'lawyer_reports_page.dart';
import '../settings/settings_page.dart';

class LawyerDashboardPage extends StatefulWidget {
  const LawyerDashboardPage({super.key});

  @override
  State<LawyerDashboardPage> createState() => _LawyerDashboardPageState();
}

class _LawyerDashboardPageState extends State<LawyerDashboardPage> {
  int _selectedIndex = 0;

  // Dashboard verileri
  int _activeClients = 0;
  int _pendingHearings = 0;
  double _monthlyIncome = 0.0;
  int _monthlyCases = 0;
  bool _isLoading = true;

  final List<LawyerMenuItem> _menuItems = [
    LawyerMenuItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      title: 'Dashboard',
      color: Colors.indigo,
    ),
    LawyerMenuItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      title: 'Müvekkiller',
      color: Colors.blue,
    ),
    LawyerMenuItem(
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
      title: 'Davalar',
      color: Colors.orange,
    ),
    LawyerMenuItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      title: 'Takvim',
      color: Colors.purple,
    ),
    LawyerMenuItem(
      icon: Icons.balance_outlined,
      selectedIcon: Icons.balance,
      title: 'Duruşmalar',
      color: Colors.red,
    ),
    LawyerMenuItem(
      icon: Icons.attach_money_outlined,
      selectedIcon: Icons.attach_money,
      title: 'Mali İşler',
      color: Colors.teal,
    ),
    LawyerMenuItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      title: 'Belgeler',
      color: Colors.brown,
    ),
    LawyerMenuItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      title: 'Sözleşmeler',
      color: Colors.green,
    ),
    LawyerMenuItem(
      icon: Icons.note_outlined,
      selectedIcon: Icons.note,
      title: 'Notlar',
      color: Colors.deepPurple,
    ),
    LawyerMenuItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      title: 'Raporlar',
      color: Colors.amber,
    ),
    LawyerMenuItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      title: 'Ayarlar',
      color: Colors.blueGrey,
    ),
  ];

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

      // Paralel olarak tüm verileri çek
      final results = await Future.wait([
        _getActiveClients(user.uid),
        _getPendingHearings(user.uid),
        _getMonthlyIncome(user.uid, startOfMonth),
        _getMonthlyCases(user.uid, startOfMonth),
      ]);

      if (mounted) {
        setState(() {
          _activeClients = results[0] as int;
          _pendingHearings = results[1] as int;
          _monthlyIncome = results[2] as double;
          _monthlyCases = results[3] as int;
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

  Future<int> _getActiveClients(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.lawyerClientsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('Aktif müvekkil sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<int> _getPendingHearings(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.courtDatesCollection)
          .where('userId', isEqualTo: userId)
          .where('durusmaDurumu', isEqualTo: 'bekliyor')
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['durusmaTarihi'] != null) {
          final hearingDate = (data['durusmaTarihi'] as Timestamp).toDate();
          if (hearingDate.isAfter(now.subtract(const Duration(days: 1)))) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint('Bekleyen duruşma sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<double> _getMonthlyIncome(String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.lawyerTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('kategori', isEqualTo: 'gelir')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['tarih'] != null) {
          final docDate = (data['tarih'] as Timestamp).toDate();
          if (docDate
              .isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            total += (data['tutar'] ?? 0.0).toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık gelir alınamadı: $e');
      return 0.0;
    }
  }

  Future<int> _getMonthlyCases(String userId, DateTime startOfMonth) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.lawyerCasesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['davaBaslangicTarihi'] != null) {
          final docDate = (data['davaBaslangicTarihi'] as Timestamp).toDate();
          if (docDate
              .isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      if (kDebugMode) debugPrint('Aylık dava sayısı alınamadı: $e');
      return 0;
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return const LawyerClientsPage();
      case 2:
        return const LawyerCasesPage();
      case 3:
        return const LawyerCalendarPage();
      case 4:
        return const LawyerHearingsPage();
      case 5:
        return const LawyerTransactionsPage();
      case 6:
        return const LawyerDocumentsPage(clientId: '');
      case 7:
        return const LawyerContractsPage();
      case 8:
        return const LawyerNotesPage();
      case 9:
        return const LawyerReportsPage();
      case 10:
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
        return 'Davalar';
      case 3:
        return localizations.calendar;
      case 4:
        return 'Duruşmalar';
      case 5:
        return 'Mali İşler';
      case 6:
        return localizations.documents;
      case 7:
        return 'Sözleşmeler';
      case 8:
        return localizations.notes;
      case 9:
        return localizations.reports;
      case 10:
        return localizations.settings;
      default:
        return 'Avukat Paneli';
    }
  }

  String _getPageSubtitle() {
    final localizations = AppLocalizations.of(context)!;

    switch (_selectedIndex) {
      case 0:
        return localizations.statistics;
      case 1:
        return 'Müvekkil yönetimi ve dosyaları';
      case 2:
        return 'Dava takibi ve yönetimi';
      case 3:
        return localizations.calendarView;
      case 4:
        return 'Duruşma takibi ve planlaması';
      case 5:
        return 'Mali işler ve ödeme yönetimi';
      case 6:
        return localizations.documentManagement;
      case 7:
        return 'Sözleşme yönetimi';
      case 8:
        return localizations.notesReminders;
      case 9:
        return localizations.analysisReports;
      case 10:
        return localizations.profileSettings;
      default:
        return 'Hukuki işler yönetim sistemi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Dinamik menü öğeleri
    final List<LawyerMenuItem> _menuItems = [
      LawyerMenuItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        title: localizations.dashboard,
        color: Colors.indigo,
      ),
      LawyerMenuItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        title: localizations.clients,
        color: Colors.blue,
      ),
      LawyerMenuItem(
        icon: Icons.gavel_outlined,
        selectedIcon: Icons.gavel,
        title: 'Davalar',
        color: Colors.orange,
      ),
      LawyerMenuItem(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        title: localizations.calendar,
        color: Colors.purple,
      ),
      LawyerMenuItem(
        icon: Icons.balance_outlined,
        selectedIcon: Icons.balance,
        title: 'Duruşmalar',
        color: Colors.red,
      ),
      LawyerMenuItem(
        icon: Icons.attach_money_outlined,
        selectedIcon: Icons.attach_money,
        title: 'Mali İşler',
        color: Colors.teal,
      ),
      LawyerMenuItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        title: localizations.documents,
        color: Colors.brown,
      ),
      LawyerMenuItem(
        icon: Icons.description_outlined,
        selectedIcon: Icons.description,
        title: 'Sözleşmeler',
        color: Colors.green,
      ),
      LawyerMenuItem(
        icon: Icons.note_outlined,
        selectedIcon: Icons.note,
        title: localizations.notes,
        color: Colors.deepPurple,
      ),
      LawyerMenuItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        title: localizations.reports,
        color: Colors.amber,
      ),
      LawyerMenuItem(
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
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.gavel,
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
                              'Avukat & Hukuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
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
                                    ? const Color(0xFF4F46E5)
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
                                        ? const Color(0xFF4F46E5)
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
                                          ? const Color(0xFF4F46E5)
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
                              'Avukat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Hukuk Uzmanı',
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
                  child: GlobalHeaderWidget.lawyer(
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
                        _selectedIndex = 10; // Settings sayfası
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
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
                  'Aktif Müvekkiller',
                  _activeClients.toString(),
                  Icons.people,
                  const Color(0xFF4F46E5),
                  '+${(_activeClients * 0.1).round()} bu ay',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Bekleyen Duruşmalar',
                  _pendingHearings.toString(),
                  Icons.gavel,
                  const Color(0xFFEF4444),
                  _pendingHearings > 0 ? 'Yaklaşan var!' : 'Tümü tamamlandı',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aylık Gelir',
                  '₺${_monthlyIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                  'Bu ay',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aylık Dava Sayısı',
                  _monthlyCases.toString(),
                  Icons.folder,
                  const Color(0xFFF59E0B),
                  'Bu ay açılan',
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
                        'Yeni Dava',
                        Icons.add_circle_outline,
                        const Color(0xFFF59E0B),
                        () => setState(() => _selectedIndex = 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Yeni Müvekkil',
                        Icons.person_add,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Belge Yükle',
                        Icons.upload_file,
                        const Color(0xFF8B5CF6),
                        () => setState(() => _selectedIndex = 6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Ücret Ekle',
                        Icons.payment,
                        const Color(0xFF06B6D4),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
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
              color: Color(0xFF111827),
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
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: Color(0xFF4F46E5),
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
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}

class LawyerTab {
  final IconData icon;
  final String label;
  final Color color;

  LawyerTab({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class LawyerMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final Color color;

  LawyerMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.color,
  });
}
