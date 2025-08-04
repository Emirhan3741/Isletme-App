import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/auth_guard.dart';

// TODO: Bu sayfaya widget gösterim seçimi, görevlendirme entegrasyonu, bildirim sistemi eklenecek
class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  bool _isLoading = false;
  String _employeeName = '';
  int _todayAppointments = 0;
  int _pendingTasks = 0;
  int _notifications = 0;
  double _thisMonthPerformance = 0.0;
  List<AppointmentSummary> _todayAppointmentsList = [];
  List<TaskSummary> _recentTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Çalışan bilgilerini yükle
      await _loadEmployeeInfo();

      // Dashboard verilerini paralel yükle
      await Future.wait([
        _loadTodayAppointments(),
        _loadPendingTasks(),
        _loadNotifications(),
        _loadPerformanceData(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard verisi yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEmployeeInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Çalışan koleksiyonundan bilgi al
      final employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (employeeDoc.docs.isNotEmpty) {
        final data = employeeDoc.docs.first.data();
        setState(() {
          _employeeName = data['name'] ?? user.displayName ?? 'Çalışan';
        });
      } else {
        setState(() {
          _employeeName = user.displayName ?? 'Çalışan';
        });
      }
    } catch (e) {
      setState(() {
        _employeeName =
            FirebaseAuth.instance.currentUser?.displayName ?? 'Çalışan';
      });
    }
  }

  Future<void> _loadTodayAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('employeeId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      final appointments = appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return AppointmentSummary(
          id: doc.id,
          customerName: data['customerName'] ?? 'Müşteri',
          serviceName: data['serviceName'] ?? 'Hizmet',
          time: (data['date'] as Timestamp).toDate(),
          status: data['status'] ?? 'pending',
        );
      }).toList();

      setState(() {
        _todayAppointments = appointments.length;
        _todayAppointmentsList =
            appointments.take(5).toList(); // İlk 5'ini göster
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Randevular yüklenirken hata: $e');
    }
  }

  Future<void> _loadPendingTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('employee_tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        return TaskSummary(
          id: doc.id,
          title: data['title'] ?? 'Görev',
          description: data['description'] ?? '',
          dueDate: data['dueDate'] != null
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
          priority: data['priority'] ?? 'normal',
        );
      }).toList();

      setState(() {
        _pendingTasks = tasksSnapshot.docs.length;
        _recentTasks = tasks.take(5).toList(); // İlk 5'ini göster
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Görevler yüklenirken hata: $e');
    }
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      setState(() {
        _notifications = notificationsSnapshot.docs.length;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Bildirimler yüklenirken hata: $e');
    }
  }

  Future<void> _loadPerformanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Bu ay tamamlanan randevuları say
      final completedAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('employeeId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Hedefi Firebase'dan al (varsayılan 50)
      final employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      int monthlyTarget = 50;
      if (employeeDoc.docs.isNotEmpty) {
        monthlyTarget = employeeDoc.docs.first.data()['monthlyTarget'] ?? 50;
      }

      final performance =
          (completedAppointments.docs.length / monthlyTarget) * 100;
      setState(() {
        _thisMonthPerformance = performance.clamp(0.0, 100.0);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Performans verisi yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRoles: ['employee', 'worker'],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Çalışan Paneli'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      _buildTodayAppointments(),
                      const SizedBox(height: 24),
                      _buildRecentTasks(),
                      const SizedBox(height: 24),
                      _buildPerformanceSection(),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: AppConstants.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, $_employeeName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                      .format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Bugünkü Randevular',
            value: _todayAppointments.toString(),
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Bekleyen Görevler',
            value: _pendingTasks.toString(),
            icon: Icons.task_alt,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Bildirimler',
            value: _notifications.toString(),
            icon: Icons.notifications,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAppointments() {
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
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Bugünkü Randevular',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (_todayAppointments > 5)
                Text(
                  '+${_todayAppointments - 5} daha',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayAppointmentsList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Bugün randevunuz bulunmuyor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...(_todayAppointmentsList
                .map((appointment) => _buildAppointmentItem(appointment))
                .toList()),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentSummary appointment) {
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
              color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.person,
              size: 16,
              color: _getStatusColor(appointment.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  appointment.serviceName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(appointment.time),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasks() {
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
              const Icon(Icons.task_alt, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Bekleyen Görevler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (_pendingTasks > 5)
                Text(
                  '+${_pendingTasks - 5} daha',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Bekleyen göreviniz bulunmuyor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...(_recentTasks.map((task) => _buildTaskItem(task)).toList()),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskSummary task) {
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
              color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.task,
              size: 16,
              color: _getPriorityColor(task.priority),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (task.dueDate != null)
            Text(
              DateFormat('dd/MM').format(task.dueDate!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: task.dueDate!.isBefore(DateTime.now())
                    ? Colors.red
                    : const Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
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
              const Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Bu Ay Performansı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_thisMonthPerformance.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      'Hedef Tamamlama',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _thisMonthPerformance / 100,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _thisMonthPerformance >= 80
                            ? Colors.green
                            : _thisMonthPerformance >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '100%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Data Models
class AppointmentSummary {
  final String id;
  final String customerName;
  final String serviceName;
  final DateTime time;
  final String status;

  AppointmentSummary({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.time,
    required this.status,
  });
}

class TaskSummary {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;

  TaskSummary({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
  });
}
