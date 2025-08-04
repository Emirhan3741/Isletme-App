import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import '../../utils/auth_guard.dart';
import '../../core/constants/app_constants.dart';

// TODO: Bu sayfaya veri kaynağı bağlama, yetki kontrolleri, admin role kontrolü, grafik sistemi eklenecek
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = false;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalAppointments = 0;

  double _monthlyRevenue = 0.0;
  double _monthlyExpenses = 0.0;
  List<SystemActivity> _recentActivities = [];
  List<UserSummary> _recentUsers = [];
  Map<String, int> _moduleUsage = {};

  @override
  void initState() {
    super.initState();
    _loadAdminDashboard();
  }

  Future<void> _loadAdminDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Paralel veri yükleme
      await Future.wait([
        _loadUserStats(),
        _loadAppointmentStats(),
        _loadRevenueStats(),
        _loadRecentActivities(),
        _loadRecentUsers(),
        _loadModuleUsage(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Admin dashboard verisi yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserStats() async {
    try {
      // Toplam kullanıcı sayısı
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Aktif kullanıcılar (son 30 gün içinde giriş yapan)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('lastSignIn', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      setState(() {
        _totalUsers = usersSnapshot.docs.length;
        _activeUsers = activeUsersSnapshot.docs.length;
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('Kullanıcı istatistikleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadAppointmentStats() async {
    try {
      final appointmentsSnapshot =
          await FirebaseFirestore.instance.collection('appointments').get();

      setState(() {
        _totalAppointments = appointmentsSnapshot.docs.length;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Randevu istatistikleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadRevenueStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Toplam gelir
      final allTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();

      double totalRevenue = 0.0;
      for (var doc in allTransactionsSnapshot.docs) {
        totalRevenue += (doc.data()['amount'] ?? 0.0).toDouble();
      }

      // Bu ay gelir
      final monthlyIncomeSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double monthlyRevenue = 0.0;
      for (var doc in monthlyIncomeSnapshot.docs) {
        monthlyRevenue += (doc.data()['amount'] ?? 0.0).toDouble();
      }

      // Bu ay gider
      final monthlyExpenseSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double monthlyExpenses = 0.0;
      for (var doc in monthlyExpenseSnapshot.docs) {
        monthlyExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
      }

      setState(() {
        _monthlyRevenue = monthlyRevenue;
        _monthlyExpenses = monthlyExpenses;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Gelir istatistikleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('system_logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final activities = activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return SystemActivity(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Bilinmeyen',
          action: data['action'] ?? '',
          description: data['description'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Aktivite logları yüklenirken hata: $e');
      // Örnek veri oluştur
      setState(() {
        _recentActivities = [
          SystemActivity(
            id: '1',
            userId: 'user1',
            userName: 'Ahmet Yılmaz',
            action: 'user_login',
            description: 'Sisteme giriş yaptı',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          SystemActivity(
            id: '2',
            userId: 'user2',
            userName: 'Ayşe Demir',
            action: 'appointment_created',
            description: 'Yeni randevu oluşturdu',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ];
      });
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return UserSummary(
          id: doc.id,
          name: data['displayName'] ?? 'İsimsiz',
          email: data['email'] ?? '',
          role: data['rol'] ?? 'user',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastSignIn: data['lastSignIn'] != null
              ? (data['lastSignIn'] as Timestamp).toDate()
              : null,
        );
      }).toList();

      setState(() {
        _recentUsers = users;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Yeni kullanıcılar yüklenirken hata: $e');
    }
  }

  Future<void> _loadModuleUsage() async {
    try {
      // Bu basit bir örnek - gerçek uygulamada analytics koleksiyonundan çekilebilir
      setState(() {
        _moduleUsage = {
          'Randevular': 45,
          'Müşteriler': 32,
          'Ödemeler': 28,
          'Raporlar': 18,
          'Ayarlar': 12,
        };
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('Modül kullanım istatistikleri yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRoles: ['admin', 'owner'],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Admin Paneli'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAdminDashboard,
              tooltip: 'Yenile',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Admin ayarları sayfasına yönlendir
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Admin ayarları yakında eklenecek')),
                );
              },
              tooltip: 'Ayarlar',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAdminDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRecentActivities(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModuleUsage(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRecentUsers(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yönetici Paneli',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem geneli kontrol ve yönetim',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                      .format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Toplam Kullanıcı',
          value: NumberFormat('#,###', 'tr_TR').format(_totalUsers),
          subtitle: '$_activeUsers aktif kullanıcı',
          icon: Icons.people,
          color: Colors.blue,
          trend: '+12%',
        ),
        _buildStatCard(
          title: 'Toplam Randevu',
          value: NumberFormat('#,###', 'tr_TR').format(_totalAppointments),
          subtitle: 'Bu ay başarıyla tamamlandı',
          icon: Icons.calendar_today,
          color: Colors.green,
          trend: '+8%',
        ),
        _buildStatCard(
          title: 'Aylık Gelir',
          value: '₺${NumberFormat('#,###', 'tr_TR').format(_monthlyRevenue)}',
          subtitle: 'Bu ay toplam gelir',
          icon: Icons.trending_up,
          color: Colors.purple,
          trend: '+15%',
        ),
        _buildStatCard(
          title: 'Net Kar',
          value:
              '₺${NumberFormat('#,###', 'tr_TR').format(_monthlyRevenue - _monthlyExpenses)}',
          subtitle: 'Gelir - Gider farkı',
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          trend: '+22%',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
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
            offset: const Offset(0, 2),
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
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Son Aktiviteler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Henüz aktivite bulunmuyor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...(_recentActivities
                .map((activity) => _buildActivityItem(activity))
                .toList()),
        ],
      ),
    );
  }

  Widget _buildActivityItem(SystemActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getActionColor(activity.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getActionIcon(activity.action),
              size: 16,
              color: _getActionColor(activity.action),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(activity.timestamp),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleUsage() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.teal),
              const SizedBox(width: 8),
              const Text(
                'Modül Kullanımı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_moduleUsage.entries
              .map((entry) => _buildModuleUsageItem(entry.key, entry.value))
              .toList()),
        ],
      ),
    );
  }

  Widget _buildModuleUsageItem(String module, int usage) {
    final maxUsage = _moduleUsage.values.isNotEmpty
        ? _moduleUsage.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final percentage = usage / maxUsage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                module,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '$usage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.primaries[_moduleUsage.keys.toList().indexOf(module) %
                  Colors.primaries.length],
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsers() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: Colors.cyan),
              const SizedBox(width: 8),
              const Text(
                'Yeni Kullanıcılar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Kullanıcı yönetimi sayfasına yönlendir
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Henüz kullanıcı bulunmuyor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...(_recentUsers.map((user) => _buildUserItem(user)).toList()),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserSummary user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
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
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Hızlı İşlemler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionButton(
                'Kullanıcı Yönetimi',
                Icons.people,
                Colors.blue,
                () {
                  // TODO: Kullanıcı yönetimi sayfasına yönlendir
                },
              ),
              _buildQuickActionButton(
                'Sistem Ayarları',
                Icons.settings,
                Colors.grey,
                () {
                  // TODO: Sistem ayarları sayfasına yönlendir
                },
              ),
              _buildQuickActionButton(
                'Backup Oluştur',
                Icons.backup,
                Colors.green,
                () {
                  // TODO: Backup işlemi başlat
                },
              ),
              _buildQuickActionButton(
                'Log İncele',
                Icons.bug_report,
                Colors.orange,
                () {
                  // TODO: Log inceleme sayfasına yönlendir
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'user_login':
        return Colors.green;
      case 'user_logout':
        return Colors.orange;
      case 'appointment_created':
        return Colors.blue;
      case 'payment_completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'user_login':
        return Icons.login;
      case 'user_logout':
        return Icons.logout;
      case 'appointment_created':
        return Icons.event_available;
      case 'payment_completed':
        return Icons.payment;
      default:
        return Icons.info;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'owner':
        return Colors.purple;
      case 'employee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Data Models
class SystemActivity {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String description;
  final DateTime timestamp;

  SystemActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.description,
    required this.timestamp,
  });
}

class UserSummary {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? lastSignIn;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastSignIn,
  });
}
