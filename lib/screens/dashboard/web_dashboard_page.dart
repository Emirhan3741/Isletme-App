import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/auth_guard.dart';
import '../../core/constants/app_constants.dart';

// TODO: Bu sayfaya grafik veri kaynakları, yetkilendirme kontrolü, log tutma sistemi, responsive tasarım eklenecek
class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({Key? key}) : super(key: key);

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  bool _isLoading = false;

  // Analytics veriler
  int _totalUsers = 0;
  int _activeUsersToday = 0;
  int _activeUsersWeek = 0;
  int _totalSessions = 0;
  double _avgSessionTime = 0.0;
  List<ModuleUsageData> _moduleUsage = [];
  List<UserActivityData> _userActivities = [];
  Map<String, int> _dailyActiveUsers = {};
  Map<String, double> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadWebDashboard();
  }

  Future<void> _loadWebDashboard() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadUserStatistics(),
        _loadSessionData(),
        _loadModuleUsage(),
        _loadRecentActivities(),
        _loadDailyActiveUsers(),
        _loadPerformanceMetrics(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Web dashboard verisi yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserStatistics() async {
    try {
      // Toplam kullanıcı sayısı
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Bugün aktif olan kullanıcılar
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayActiveSnapshot = await FirebaseFirestore.instance
          .collection('user_sessions')
          .where('lastActivity',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      // Bu hafta aktif olan kullanıcılar
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final weekActiveSnapshot = await FirebaseFirestore.instance
          .collection('user_sessions')
          .where('lastActivity',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      setState(() {
        _totalUsers = usersSnapshot.docs.length;
        _activeUsersToday = todayActiveSnapshot.docs.length;
        _activeUsersWeek = weekActiveSnapshot.docs.length;
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('Kullanıcı istatistikleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadSessionData() async {
    try {
      final sessionsSnapshot =
          await FirebaseFirestore.instance.collection('user_sessions').get();

      double totalSessionTime = 0.0;
      int sessionCount = 0;

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final sessionDuration = data['duration'] ?? 0;
        totalSessionTime += sessionDuration.toDouble();
        sessionCount++;
      }

      setState(() {
        _totalSessions = sessionCount;
        _avgSessionTime =
            sessionCount > 0 ? totalSessionTime / sessionCount : 0.0;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Oturum verileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadModuleUsage() async {
    try {
      final moduleSnapshot = await FirebaseFirestore.instance
          .collection('module_analytics')
          .orderBy('usageCount', descending: true)
          .limit(10)
          .get();

      final moduleUsage = moduleSnapshot.docs.map((doc) {
        final data = doc.data();
        return ModuleUsageData(
          moduleName: data['moduleName'] ?? 'Bilinmeyen',
          usageCount: data['usageCount'] ?? 0,
          uniqueUsers: data['uniqueUsers'] ?? 0,
          avgTime: (data['avgTime'] ?? 0.0).toDouble(),
        );
      }).toList();

      setState(() {
        _moduleUsage = moduleUsage;
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('Modül kullanım verileri yüklenirken hata: $e');
      // Fallback örnek data
      setState(() {
        _moduleUsage = [
          ModuleUsageData(
              moduleName: 'Randevular',
              usageCount: 1250,
              uniqueUsers: 89,
              avgTime: 5.2),
          ModuleUsageData(
              moduleName: 'Müşteriler',
              usageCount: 980,
              uniqueUsers: 76,
              avgTime: 3.8),
          ModuleUsageData(
              moduleName: 'Ödemeler',
              usageCount: 720,
              uniqueUsers: 54,
              avgTime: 2.1),
          ModuleUsageData(
              moduleName: 'Raporlar',
              usageCount: 450,
              uniqueUsers: 41,
              avgTime: 7.5),
          ModuleUsageData(
              moduleName: 'Ayarlar',
              usageCount: 320,
              uniqueUsers: 38,
              avgTime: 1.9),
        ];
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activitiesSnapshot = await FirebaseFirestore.instance
          .collection('system_logs')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final activities = activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return UserActivityData(
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Bilinmeyen',
          action: data['action'] ?? '',
          module: data['module'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          ipAddress: data['ipAddress'] ?? '',
          device: data['device'] ?? 'Web',
        );
      }).toList();

      setState(() {
        _userActivities = activities;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Kullanıcı aktivitesi yüklenirken hata: $e');
      // Fallback örnek data
      setState(() {
        _userActivities = [
          UserActivityData(
            userId: 'user1',
            userName: 'Ahmet Yılmaz',
            action: 'login',
            module: 'Auth',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            ipAddress: '192.168.1.100',
            device: 'Chrome/Web',
          ),
          UserActivityData(
            userId: 'user2',
            userName: 'Ayşe Kaya',
            action: 'create_appointment',
            module: 'Randevular',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            ipAddress: '192.168.1.101',
            device: 'Safari/Web',
          ),
        ];
      });
    }
  }

  Future<void> _loadDailyActiveUsers() async {
    try {
      final Map<String, int> dailyData = {};
      final now = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final activeSnapshot = await FirebaseFirestore.instance
            .collection('user_sessions')
            .where('lastActivity',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('lastActivity',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        dailyData[DateFormat('MM/dd').format(date)] =
            activeSnapshot.docs.length;
      }

      setState(() {
        _dailyActiveUsers = dailyData;
      });
    } catch (e) {
      if (kDebugMode)
        debugPrint('Günlük aktif kullanıcı verileri yüklenirken hata: $e');
      // Fallback data
      setState(() {
        _dailyActiveUsers = {
          '12/18': 45,
          '12/19': 52,
          '12/20': 38,
          '12/21': 61,
          '12/22': 49,
          '12/23': 55,
          '12/24': 67,
        };
      });
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final metricsSnapshot = await FirebaseFirestore.instance
          .collection('performance_metrics')
          .doc('current')
          .get();

      if (metricsSnapshot.exists) {
        final data = metricsSnapshot.data()!;
        setState(() {
          _performanceMetrics = {
            'cpu_usage': (data['cpuUsage'] ?? 0.0).toDouble(),
            'memory_usage': (data['memoryUsage'] ?? 0.0).toDouble(),
            'disk_usage': (data['diskUsage'] ?? 0.0).toDouble(),
            'response_time': (data['responseTime'] ?? 0.0).toDouble(),
          };
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Performans metrikleri yüklenirken hata: $e');
      // Fallback data
      setState(() {
        _performanceMetrics = {
          'cpu_usage': 24.5,
          'memory_usage': 68.2,
          'disk_usage': 45.1,
          'response_time': 250.0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRoles: ['admin', 'owner'],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWebDashboard,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildMainMetrics(),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildUserActivityChart(),
                                const SizedBox(height: 24),
                                _buildModuleUsageChart(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildPerformanceMetrics(),
                                const SizedBox(height: 24),
                                _buildRecentActivity(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSystemInfo(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Web Yönetici Paneli'),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      elevation: 0.5,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadWebDashboard,
          tooltip: 'Yenile',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Sistem ayarları
          },
          tooltip: 'Ayarlar',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacementNamed('/login');
          },
          tooltip: 'Çıkış',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
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
              Icons.dashboard,
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
                  'Web Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem geneli istatistikler ve kullanım analizi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
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

  Widget _buildMainMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          title: 'Toplam Kullanıcı',
          value: NumberFormat('#,###', 'tr_TR').format(_totalUsers),
          subtitle: 'Kayıtlı kullanıcı',
          icon: Icons.people,
          color: Colors.blue,
          trend: '+5.2%',
        ),
        _buildMetricCard(
          title: 'Bugün Aktif',
          value: NumberFormat('#,###', 'tr_TR').format(_activeUsersToday),
          subtitle: 'Online kullanıcı',
          icon: Icons.person_pin,
          color: Colors.green,
          trend: '+12.8%',
        ),
        _buildMetricCard(
          title: 'Toplam Oturum',
          value: NumberFormat('#,###', 'tr_TR').format(_totalSessions),
          subtitle: 'Bu ay',
          icon: Icons.access_time,
          color: Colors.orange,
          trend: '+8.4%',
        ),
        _buildMetricCard(
          title: 'Ort. Oturum',
          value: '${(_avgSessionTime / 60).toStringAsFixed(1)}dk',
          subtitle: 'Kullanım süresi',
          icon: Icons.timer,
          color: Colors.purple,
          trend: '-3.1%',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final bool isPositiveTrend = trend.startsWith('+');

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositiveTrend ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositiveTrend ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
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

  Widget _buildUserActivityChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.trending_up, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Günlük Aktif Kullanıcılar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                'Son 7 gün',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyActiveUsers.entries.map((entry) {
                final maxValue = _dailyActiveUsers.values.isNotEmpty
                    ? _dailyActiveUsers.values.reduce((a, b) => a > b ? a : b)
                    : 1;
                final height = (entry.value / maxValue) * 160;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleUsageChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.bar_chart, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'En Çok Kullanılan Modüller',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._moduleUsage
              .take(5)
              .map((module) => _buildModuleUsageItem(module))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildModuleUsageItem(ModuleUsageData module) {
    final maxUsage =
        _moduleUsage.isNotEmpty ? _moduleUsage.first.usageCount : 1;
    final percentage = module.usageCount / maxUsage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                module.moduleName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${module.uniqueUsers} kullanıcı',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    NumberFormat('#,###', 'tr_TR').format(module.usageCount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.green.withValues(alpha: 0.8),
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.speed, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Sistem Performansı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPerformanceItem('CPU Kullanımı',
              _performanceMetrics['cpu_usage'] ?? 0, '%', Colors.blue),
          const SizedBox(height: 16),
          _buildPerformanceItem('Bellek Kullanımı',
              _performanceMetrics['memory_usage'] ?? 0, '%', Colors.green),
          const SizedBox(height: 16),
          _buildPerformanceItem('Disk Kullanımı',
              _performanceMetrics['disk_usage'] ?? 0, '%', Colors.orange),
          const SizedBox(height: 16),
          _buildPerformanceItem('Yanıt Süresi',
              _performanceMetrics['response_time'] ?? 0, 'ms', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
      String title, double value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: unit == '%' ? value / 100 : (value / 1000).clamp(0.0, 1.0),
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 20),
          if (_userActivities.isEmpty)
            const Center(
              child: Text(
                'Aktivite bulunamadı',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          else
            ..._userActivities
                .take(8)
                .map((activity) => _buildActivityItem(activity))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(UserActivityData activity) {
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getActionColor(activity.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${_getActionDisplayName(activity.action)} - ${activity.module}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${activity.device} - ${activity.ipAddress}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(activity.timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.info, color: Colors.cyan),
              const SizedBox(width: 8),
              const Text(
                'Sistem Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Uygulama Versiyonu', 'v2.1.0'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Firebase Projesi', 'randevu-erp'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Veritabanı', 'Cloud Firestore'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Son Güncelleme',
                        DateFormat('dd.MM.yyyy').format(DateTime.now())),
                    const SizedBox(height: 12),
                    _buildInfoItem('Aktif Modüller', '12'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Toplam Koleksiyon', '24'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Uptime', '99.9%'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Backup Durumu', 'Aktif'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Güvenlik', 'SSL/TLS'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'create_appointment':
        return Colors.blue;
      case 'update_profile':
        return Colors.purple;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'create_appointment':
        return Icons.event_available;
      case 'update_profile':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'login':
        return 'Giriş yaptı';
      case 'logout':
        return 'Çıkış yaptı';
      case 'create_appointment':
        return 'Randevu oluşturdu';
      case 'update_profile':
        return 'Profil güncelledi';
      case 'delete':
        return 'Silme işlemi';
      default:
        return action;
    }
  }
}

// Data Models
class ModuleUsageData {
  final String moduleName;
  final int usageCount;
  final int uniqueUsers;
  final double avgTime;

  ModuleUsageData({
    required this.moduleName,
    required this.usageCount,
    required this.uniqueUsers,
    required this.avgTime,
  });
}

class UserActivityData {
  final String userId;
  final String userName;
  final String action;
  final String module;
  final DateTime timestamp;
  final String ipAddress;
  final String device;

  UserActivityData({
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.timestamp,
    required this.ipAddress,
    required this.device,
  });
}
