import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class EducationReportsPage extends StatefulWidget {
  const EducationReportsPage({super.key});

  @override
  State<EducationReportsPage> createState() => _EducationReportsPageState();
}

class _EducationReportsPageState extends State<EducationReportsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  String _selectedPeriod = 'thisMonth';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadReportData();
  }

  void _initializeDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'thisMonth':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'lastMonth':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'thisYear':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case 'custom':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
    }
  }

  Future<void> _loadReportData() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final futures = await Future.wait([
        _getIncomeData(user.uid),
        _getExpenseData(user.uid),
        _getStudentStats(user.uid),
        _getCourseStats(user.uid),
        _getTeacherStats(user.uid),
        _getAttendanceStats(user.uid),
      ]);

      setState(() {
        _reportData = {
          'income': futures[0],
          'expense': futures[1],
          'students': futures[2],
          'courses': futures[3],
          'teachers': futures[4],
          'attendance': futures[5],
        };
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Rapor verileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getIncomeData(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .where('odemeTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('odemeTarihi',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      double totalIncome = 0;
      Map<String, double> incomeByType = {};
      Map<String, double> incomeByMonth = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['odenecekTutar'] as num?)?.toDouble() ?? 0;
        final type = data['odemeTuru'] as String? ?? 'diger';
        final date =
            (data['odemeTarihi'] as Timestamp?)?.toDate() ?? DateTime.now();
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        totalIncome += amount;
        incomeByType[type] = (incomeByType[type] ?? 0) + amount;
        incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + amount;
      }

      return {
        'total': totalIncome,
        'byType': incomeByType,
        'byMonth': incomeByMonth,
        'count': snapshot.docs.length,
      };
    } catch (e) {
      return {'total': 0.0, 'byType': {}, 'byMonth': {}, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _getExpenseData(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationExpensesCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      double totalExpense = 0;
      Map<String, double> expenseByCategory = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final category = data['category'] as String? ?? 'diger';

        totalExpense += amount;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }

      return {
        'total': totalExpense,
        'byCategory': expenseByCategory,
        'count': snapshot.docs.length,
      };
    } catch (e) {
      return {'total': 0.0, 'byCategory': {}, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _getStudentStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationStudentsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalStudents = snapshot.docs.length;
      int activeStudents = 0;
      int vipStudents = 0;
      int scholarshipStudents = 0;
      Map<String, int> studentsByClass = {};
      Map<String, int> studentsByLevel = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final isVip = data['vipOgrenci'] as bool? ?? false;
        final isScholarship = data['bursluOgrenci'] as bool? ?? false;
        final studentClass = data['sinif'] as String? ?? 'Belirtilmemiş';
        final level = data['seviye'] as String? ?? 'Belirtilmemiş';

        if (status == 'active') activeStudents++;
        if (isVip) vipStudents++;
        if (isScholarship) scholarshipStudents++;

        studentsByClass[studentClass] =
            (studentsByClass[studentClass] ?? 0) + 1;
        studentsByLevel[level] = (studentsByLevel[level] ?? 0) + 1;
      }

      return {
        'total': totalStudents,
        'active': activeStudents,
        'vip': vipStudents,
        'scholarship': scholarshipStudents,
        'byClass': studentsByClass,
        'byLevel': studentsByLevel,
      };
    } catch (e) {
      return {
        'total': 0,
        'active': 0,
        'vip': 0,
        'scholarship': 0,
        'byClass': {},
        'byLevel': {}
      };
    }
  }

  Future<Map<String, dynamic>> _getCourseStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationCoursesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalCourses = snapshot.docs.length;
      int activeCourses = 0;
      int groupCourses = 0;
      int privateCourses = 0;
      Map<String, int> coursesByCategory = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final isGroup = data['grupDersi'] as bool? ?? true;
        final category = data['kategori'] as String? ?? 'Diğer';

        if (status == 'active') activeCourses++;
        if (isGroup) {
          groupCourses++;
        } else {
          privateCourses++;
        }

        coursesByCategory[category] = (coursesByCategory[category] ?? 0) + 1;
      }

      return {
        'total': totalCourses,
        'active': activeCourses,
        'group': groupCourses,
        'private': privateCourses,
        'byCategory': coursesByCategory,
      };
    } catch (e) {
      return {
        'total': 0,
        'active': 0,
        'group': 0,
        'private': 0,
        'byCategory': {}
      };
    }
  }

  Future<Map<String, dynamic>> _getTeacherStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationTeachersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int totalTeachers = snapshot.docs.length;
      int activeTeachers = 0;
      int fullTimeTeachers = 0;
      int partTimeTeachers = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final isFullTime = data['tamZamanli'] as bool? ?? true;

        if (status == 'active') activeTeachers++;
        if (isFullTime) {
          fullTimeTeachers++;
        } else {
          partTimeTeachers++;
        }
      }

      return {
        'total': totalTeachers,
        'active': activeTeachers,
        'fullTime': fullTimeTeachers,
        'partTime': partTimeTeachers,
      };
    } catch (e) {
      return {'total': 0, 'active': 0, 'fullTime': 0, 'partTime': 0};
    }
  }

  Future<Map<String, dynamic>> _getAttendanceStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('baslangicZamani',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('baslangicZamani',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      int totalSessions = snapshot.docs.length;
      double totalAttendanceRate = 0;
      int sessionCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final attendanceRate = (data['devamOrani'] as num?)?.toDouble();
        if (attendanceRate != null) {
          totalAttendanceRate += attendanceRate;
          sessionCount++;
        }
      }

      double averageAttendance =
          sessionCount > 0 ? totalAttendanceRate / sessionCount : 0;

      return {
        'totalSessions': totalSessions,
        'averageAttendance': averageAttendance,
      };
    } catch (e) {
      return {'totalSessions': 0, 'averageAttendance': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dönem Seçici
          _buildPeriodSelector(),

          // Raporlar
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                  )
                : _buildReportsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _initializeDates();
                });
                _loadReportData();
              },
              decoration: InputDecoration(
                labelText: 'Dönem',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'thisMonth', child: Text('Bu Ay')),
                DropdownMenuItem(value: 'lastMonth', child: Text('Geçen Ay')),
                DropdownMenuItem(value: 'thisYear', child: Text('Bu Yıl')),
                DropdownMenuItem(value: 'custom', child: Text('Özel Dönem')),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (_selectedPeriod == 'custom') ...[
            TextButton(
              onPressed: _showDatePicker,
              child: Text(
                '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}',
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getPeriodText(),
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'thisMonth':
        return 'Bu Ay';
      case 'lastMonth':
        return 'Geçen Ay';
      case 'thisYear':
        return 'Bu Yıl';
      default:
        return 'Özel';
    }
  }

  void _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  Widget _buildReportsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Finansal Özet
          _buildFinancialSummary(),
          const SizedBox(height: 16),

          // Öğrenci İstatistikleri
          _buildStudentStatistics(),
          const SizedBox(height: 16),

          // Ders İstatistikleri
          _buildCourseStatistics(),
          const SizedBox(height: 16),

          // Öğretmen İstatistikleri
          _buildTeacherStatistics(),
          const SizedBox(height: 16),

          // Devam İstatistikleri
          _buildAttendanceStatistics(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final income = _reportData['income'] ?? {};
    final expense = _reportData['expense'] ?? {};
    final totalIncome = income['total'] ?? 0.0;
    final totalExpense = expense['total'] ?? 0.0;
    final profit = totalIncome - totalExpense;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Finansal Özet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    'Toplam Gelir',
                    '₺${totalIncome.toStringAsFixed(0)}',
                    AppConstants.successColor,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialCard(
                    'Toplam Gider',
                    '₺${totalExpense.toStringAsFixed(0)}',
                    AppConstants.errorColor,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialCard(
                    'Net Kar',
                    '₺${profit.toStringAsFixed(0)}',
                    profit >= 0
                        ? AppConstants.successColor
                        : AppConstants.errorColor,
                    profit >= 0 ? Icons.thumb_up : Icons.thumb_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatistics() {
    final students = _reportData['students'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Color(0xFF667EEA),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Öğrenci İstatistikleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Öğrenci',
                    '${students['total'] ?? 0}',
                    const Color(0xFF667EEA),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Öğrenci',
                    '${students['active'] ?? 0}',
                    AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'VIP Öğrenci',
                    '${students['vip'] ?? 0}',
                    AppConstants.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Burslu Öğrenci',
                    '${students['scholarship'] ?? 0}',
                    AppConstants.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStatistics() {
    final courses = _reportData['courses'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF764BA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Color(0xFF764BA2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ders İstatistikleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Ders',
                    '${courses['total'] ?? 0}',
                    const Color(0xFF764BA2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Ders',
                    '${courses['active'] ?? 0}',
                    AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Grup Dersi',
                    '${courses['group'] ?? 0}',
                    AppConstants.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Özel Ders',
                    '${courses['private'] ?? 0}',
                    AppConstants.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherStatistics() {
    final teachers = _reportData['teachers'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.infoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppConstants.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Öğretmen İstatistikleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Öğretmen',
                    '${teachers['total'] ?? 0}',
                    AppConstants.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Öğretmen',
                    '${teachers['active'] ?? 0}',
                    AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Tam Zamanlı',
                    '${teachers['fullTime'] ?? 0}',
                    const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Yarı Zamanlı',
                    '${teachers['partTime'] ?? 0}',
                    AppConstants.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatistics() {
    final attendance = _reportData['attendance'] ?? {};
    final averageAttendance = attendance['averageAttendance'] ?? 0.0;
    final totalSessions = attendance['totalSessions'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Devam İstatistikleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Seans',
                    '$totalSessions',
                    const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Ortalama Devam',
                    '%${averageAttendance.toStringAsFixed(1)}',
                    averageAttendance >= 80
                        ? AppConstants.successColor
                        : averageAttendance >= 60
                            ? AppConstants.warningColor
                            : AppConstants.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raporu Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF olarak dışa aktar'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel olarak dışa aktar'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF dışa aktarma özelliği yakında aktif olacak'),
        backgroundColor: AppConstants.infoColor,
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel dışa aktarma özelliği yakında aktif olacak'),
        backgroundColor: AppConstants.infoColor,
      ),
    );
  }
}
