import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/feedback_utils.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart' as auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// TODO: Bu sayfaya GPS takip, çevrimdışı mod, senkronizasyon, kullanıcı ID'si ile filtreleme eklenecek
class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  String _employeeName = '';
  int _todayTasks = 0;
  int _completedTasks = 0;
  int _pendingAppointments = 0;
  List<MobileTask> _urgentTasks = [];
  List<MobileAppointment> _todayAppointments = [];
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkCurrentStatus();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await Future.wait([
        _loadEmployeeInfo(),
        _loadTodayTasks(),
        _loadTodayAppointments(),
        _loadUrgentTasks(),
      ]);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard verisi yüklenirken hata: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEmployeeInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() {
        _employeeName = user.displayName ?? 'Çalışan';
      });
    }
  }

  Future<void> _loadTodayTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('mobile_tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      int totalTasks = tasksSnapshot.docs.length;
      int completed = tasksSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      setState(() {
        _todayTasks = totalTasks;
        _completedTasks = completed;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Görevler yüklenirken hata: $e');
    }
  }

  Future<void> _loadTodayAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
        return MobileAppointment(
          id: doc.id,
          customerName: data['customerName'] ?? 'Müşteri',
          serviceName: data['serviceName'] ?? 'Hizmet',
          time: (data['date'] as Timestamp).toDate(),
          address: data['address'] ?? '',
          status: data['status'] ?? 'pending',
        );
      }).toList();

      setState(() {
        _todayAppointments = appointments.take(3).toList(); // İlk 3'ünü göster
        _pendingAppointments = appointments
            .where(
                (app) => app.status == 'pending' || app.status == 'confirmed')
            .length;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Randevular yüklenirken hata: $e');
    }
  }

  Future<void> _loadUrgentTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('mobile_tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('priority', isEqualTo: 'high')
          .where('status', whereIn: ['pending', 'in_progress'])
          .orderBy('dueDate')
          .limit(5)
          .get();

      final tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        return MobileTask(
          id: doc.id,
          title: data['title'] ?? 'Görev',
          description: data['description'] ?? '',
          dueDate: data['dueDate'] != null
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
          priority: data['priority'] ?? 'normal',
          status: data['status'] ?? 'pending',
          address: data['address'] ?? '',
        );
      }).toList();

      setState(() {
        _urgentTasks = tasks;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Acil görevler yüklenirken hata: $e');
    }
  }

  Future<void> _checkCurrentStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employee_attendance')
          .where('employeeId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        final data = attendanceSnapshot.docs.first.data();
        setState(() {
          _isCheckedIn = data['status'] == 'checked_in';
          _checkInTime = data['checkInTime'] != null
              ? (data['checkInTime'] as Timestamp).toDate()
              : null;
          _checkOutTime = data['checkOutTime'] != null
              ? (data['checkOutTime'] as Timestamp).toDate()
              : null;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Devam durumu kontrol edilirken hata: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Konum izni reddedildi';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() {
        _currentLocation = 'Konum alınamadı';
      });
    }
  }

  Future<void> _handleCheckInOut() async {
    await _getCurrentLocation();

    if (_currentLocation == null ||
        _currentLocation!.contains('alınamadı') ||
        _currentLocation!.contains('reddedildi')) {
      FeedbackUtils.showError(context, 'Konum bilgisi gerekli');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (!_isCheckedIn) {
        // Check-in
        await FirebaseFirestore.instance.collection('employee_attendance').add({
          'employeeId': user.uid,
          'employeeName': _employeeName,
          'date': Timestamp.fromDate(today),
          'checkInTime': Timestamp.now(),
          'checkInLocation': _currentLocation,
          'status': 'checked_in',
          'createdAt': Timestamp.now(),
        });

        setState(() {
          _isCheckedIn = true;
          _checkInTime = now;
        });

        FeedbackUtils.showSuccess(context, 'Giriş yapıldı');
      } else {
        // Check-out
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('employee_attendance')
            .where('employeeId', isEqualTo: user.uid)
            .where('date', isEqualTo: Timestamp.fromDate(today))
            .limit(1)
            .get();

        if (attendanceSnapshot.docs.isNotEmpty) {
          await attendanceSnapshot.docs.first.reference.update({
            'checkOutTime': Timestamp.now(),
            'checkOutLocation': _currentLocation,
            'status': 'checked_out',
            'updatedAt': Timestamp.now(),
          });

          setState(() {
            _isCheckedIn = false;
            _checkOutTime = now;
          });

          FeedbackUtils.showSuccess(context, 'Çıkış yapıldı');
        }
      }
    } catch (e) {
      FeedbackUtils.showError(context, 'İşlem sırasında hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildCheckInOutCard(),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildTodayAppointments(),
                      const SizedBox(height: 24),
                      _buildUrgentTasks(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.person,
            color: AppConstants.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, $_employeeName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                    .format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Bildirimler sayfasına yönlendir
          },
        ),
      ],
    );
  }

  Widget _buildCheckInOutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCheckedIn
              ? [Colors.green.shade600, Colors.green.shade700]
              : [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isCheckedIn ? Colors.green : Colors.blue)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isCheckedIn ? Icons.work : Icons.work_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isCheckedIn ? 'İş Başındasınız' : 'İşe Başlayın',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_checkInTime != null)
            Text(
              'Giriş: ${DateFormat('HH:mm').format(_checkInTime!)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          if (_checkOutTime != null)
            Text(
              'Çıkış: ${DateFormat('HH:mm').format(_checkOutTime!)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleCheckInOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    _isCheckedIn ? Colors.green.shade700 : Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isCheckedIn ? 'Çıkış Yap' : 'Giriş Yap',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Bugünkü Görevler',
            value: '$_completedTasks/$_todayTasks',
            icon: Icons.task_alt,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Bekleyen Randevular',
            value: '$_pendingAppointments',
            icon: Icons.calendar_today,
            color: Colors.purple,
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
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
              const Icon(Icons.today, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Bugünkü Randevular',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (_todayAppointments.length > 3)
                Text(
                  '+${_todayAppointments.length - 3} daha',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayAppointments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Bugün randevunuz yok',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ..._todayAppointments
                .map((appointment) => _buildAppointmentItem(appointment))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(MobileAppointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
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
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  appointment.serviceName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (appointment.address.isNotEmpty)
                  Text(
                    appointment.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(appointment.time),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusDisplayName(appointment.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(appointment.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentTasks() {
    if (_urgentTasks.isEmpty) return const SizedBox();

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
              const Icon(Icons.priority_high, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Acil Görevler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._urgentTasks.map((task) => _buildTaskItem(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskItem(MobileTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.warning,
              size: 14,
              color: Colors.red,
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
                    color: Color(0xFF111827),
                  ),
                ),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
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
                    : const Color(0xFF6B7280),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickActionButton(
                'Görevlerim',
                Icons.task,
                Colors.blue,
                () {
                  // TODO: Görevler sayfasına yönlendir
                },
              ),
              _buildQuickActionButton(
                'Randevular',
                Icons.calendar_today,
                Colors.green,
                () {
                  // TODO: Randevular sayfasına yönlendir
                },
              ),
              _buildQuickActionButton(
                'Harita',
                Icons.map,
                Colors.orange,
                () {
                  // TODO: Harita sayfasına yönlendir
                },
              ),
              _buildQuickActionButton(
                'Raporlar',
                Icons.assessment,
                Colors.purple,
                () {
                  // TODO: Raporlar sayfasına yönlendir
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
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
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      case 'confirmed':
        return 'Onaylandı';
      case 'pending':
        return 'Bekliyor';
      default:
        return status;
    }
  }
}

// Data Models
class MobileAppointment {
  final String id;
  final String customerName;
  final String serviceName;
  final DateTime time;
  final String address;
  final String status;

  MobileAppointment({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.time,
    required this.address,
    required this.status,
  });
}

class MobileTask {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final String address;

  MobileTask({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.address,
  });
}
