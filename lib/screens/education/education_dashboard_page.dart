import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import 'education_students_page.dart';
import 'education_courses_page.dart';
import 'education_calendar_page.dart';
import 'education_exams_page.dart';
import 'education_grades_page.dart';
import 'education_payments_page.dart';
import '../expenses/expense_list_page.dart';
import 'education_teachers_page.dart';
import 'education_documents_page.dart';
import 'education_reports_page.dart';
import 'education_settings_page.dart';

class EducationDashboardPage extends StatefulWidget {
  const EducationDashboardPage({super.key});

  @override
  State<EducationDashboardPage> createState() => _EducationDashboardPageState();
}

class _EducationDashboardPageState extends State<EducationDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  final List<EducationMenuItem> _menuItems = [
    EducationMenuItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      title: 'Dashboard',
      color: Colors.indigo,
    ),
    EducationMenuItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      title: 'Öğrenciler',
      color: Colors.blue,
    ),
    EducationMenuItem(
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
      title: 'Dersler',
      color: Colors.green,
    ),
    EducationMenuItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      title: 'Takvim',
      color: Colors.purple,
    ),
    EducationMenuItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      title: 'Sınavlar',
      color: Colors.orange,
    ),
    EducationMenuItem(
      icon: Icons.grade_outlined,
      selectedIcon: Icons.grade,
      title: 'Notlar',
      color: Colors.teal,
    ),
    EducationMenuItem(
      icon: Icons.payment_outlined,
      selectedIcon: Icons.payment,
      title: 'Ödemeler',
      color: Colors.amber,
    ),
    EducationMenuItem(
      icon: Icons.trending_down_outlined,
      selectedIcon: Icons.trending_down,
      title: 'Giderler',
      color: Colors.red,
    ),
    EducationMenuItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      title: 'Öğretmenler',
      color: Colors.indigo,
    ),
    EducationMenuItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      title: 'Belgeler',
      color: Colors.brown,
    ),
    EducationMenuItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      title: 'Raporlar',
      color: Colors.deepPurple,
    ),
    EducationMenuItem(
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
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Paralel veri çekme
      final futures = await Future.wait([
        _getTodayClasses(currentUser.uid, startOfDay, endOfDay),
        _getActiveStudents(currentUser.uid),
        _getActiveCourses(currentUser.uid),
        _getMonthlyIncome(currentUser.uid, startOfMonth, today),
        _getPendingPayments(currentUser.uid),
        _getMonthlyExpenses(currentUser.uid, startOfMonth, today),
        _getActiveTeachers(currentUser.uid),
        _getUpcomingExams(currentUser.uid),
      ]);

      if (mounted) {
        setState(() {
          _stats = {
            'todayClasses': futures[0],
            'activeStudents': futures[1],
            'activeCourses': futures[2],
            'monthlyIncome': futures[3],
            'pendingPayments': futures[4],
            'monthlyExpenses': futures[5],
            'activeTeachers': futures[6],
            'upcomingExams': futures[7],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  Future<int> _getTodayClasses(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', isEqualTo: 'confirmed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveStudents(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationStudentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveCourses(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationCoursesCollection)
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
          .collection(AppConstants.educationPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .where('odemeTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('odemeTarihi', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['odenecekTutar'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getPendingPayments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['odenecekTutar'] as num?)?.toDouble() ?? 0;
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
          .collection(AppConstants.educationExpensesCollection)
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

  Future<int> _getActiveTeachers(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationTeachersCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUpcomingExams(String userId) async {
    try {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationExamsCollection)
          .where('userId', isEqualTo: userId)
          .where('examDate', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
          .where('examDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
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
        return EducationStudentsPage();
      case 2:
        return EducationCoursesPage();
      case 3:
        return EducationCalendarPage();
      case 4:
        return EducationExamsPage();
      case 5:
        return EducationGradesPage();
      case 6:
        return EducationPaymentsPage();
      case 7:
        return ExpenseListPage();
      case 8:
        return EducationTeachersPage();
      case 9:
        return const EducationDocumentsPage(customerId: '');
      case 10:
        return EducationReportsPage();
      case 11:
        return EducationSettingsPage();
      default:
        return _buildOverviewPage();
    }
  }

  String _getPageTitle() {
    if (_selectedIndex < _menuItems.length) {
      return _menuItems[_selectedIndex].title;
    }
    return 'Eğitim & Kurs Paneli';
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'İstatistikler ve hızlı erişim';
      case 1:
        return 'Öğrenci yönetimi ve kayıtları';
      case 2:
        return 'Ders programları ve içerikler';
      case 3:
        return 'Takvim ve program görünümü';
      case 4:
        return 'Sınav yönetimi ve sonuçları';
      case 5:
        return 'Not takibi ve değerlendirme';
      case 6:
        return 'Ödeme yönetimi ve takibi';
      case 7:
        return 'Gider takibi ve muhasebe';
      case 8:
        return 'Öğretmen yönetimi';
      case 9:
        return 'Belge ve dosya yönetimi';
      case 10:
        return 'Analiz ve raporlar';
      case 11:
        return 'Panel ayarları';
      default:
        return 'Eğitim yönetim sistemi';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
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
                              'Eğitim & Kurs',
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
                                    ? const Color(0xFF667EEA)
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
                                        ? const Color(0xFF667EEA)
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
                                          ? const Color(0xFF667EEA)
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
                              'Öğretmen',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Eğitim Uzmanı',
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF667EEA),
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
                  'Aktif Öğrenciler',
                  _stats['activeStudents']?.toString() ?? '0',
                  Icons.people,
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Bugünkü Dersler',
                  _stats['todayClasses']?.toString() ?? '0',
                  Icons.today,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aktif Dersler',
                  _stats['activeCourses']?.toString() ?? '0',
                  Icons.book,
                  const Color(0xFF764BA2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aylık Gelir',
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
                  'Aktif Öğretmen',
                  _stats['activeTeachers']?.toString() ?? '0',
                  Icons.person,
                  const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Yaklaşan Sınav',
                  _stats['upcomingExams']?.toString() ?? '0',
                  Icons.school,
                  const Color(0xFFEF4444),
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
                        'Yeni Öğrenci',
                        Icons.person_add,
                        const Color(0xFF667EEA),
                        () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Yeni Ders',
                        Icons.add_circle,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedIndex = 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Sınav Ekle',
                        Icons.quiz,
                        const Color(0xFF764BA2),
                        () => setState(() => _selectedIndex = 4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        'Ödeme Al',
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
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction,
              size: 64,
              color: Color(0xFF667EEA),
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
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}

class EducationMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final Color color;

  EducationMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.color,
  });
}
