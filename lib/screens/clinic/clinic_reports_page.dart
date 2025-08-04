import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicReportsPage extends StatefulWidget {
  const ClinicReportsPage({super.key});

  @override
  State<ClinicReportsPage> createState() => _ClinicReportsPageState();
}

class _ClinicReportsPageState extends State<ClinicReportsPage> {
  bool _isLoading = false;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  // Rapor verileri
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = await Future.wait([
        _getTotalPatients(user.uid),
        _getTotalAppointments(user.uid),
        _getCompletedTreatments(user.uid),
        _getTotalRevenue(user.uid),
        _getTotalExpenses(user.uid),
        _getMonthlyStats(user.uid),
      ]);

      setState(() {
        _reportData = {
          'totalPatients': data[0],
          'totalAppointments': data[1],
          'completedTreatments': data[2],
          'totalRevenue': data[3],
          'totalExpenses': data[4],
          'monthlyStats': data[5],
        };
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Rapor verileri yüklenirken hata: $e');
    }

    setState(() => _isLoading = false);
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
      return 0;
    }
  }

  Future<int> _getTotalAppointments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getCompletedTreatments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicTreatmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .where('treatmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('treatmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getTotalRevenue(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('kategori', isEqualTo: 'gelir')
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getTotalExpenses(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .where('userId', isEqualTo: userId)
          .where('kategori', isEqualTo: 'gider')
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _getMonthlyStats(String userId) async {
    try {
      // Son 6 aylık veri
      List<Map<String, dynamic>> monthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final month =
            DateTime(DateTime.now().year, DateTime.now().month - i, 1);
        final nextMonth = DateTime(month.year, month.month + 1, 1);

        final revenueSnapshot = await FirebaseFirestore.instance
            .collection(AppConstants.clinicPaymentsCollection)
            .where('userId', isEqualTo: userId)
            .where('kategori', isEqualTo: 'gelir')
            .where('paymentDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(month))
            .where('paymentDate', isLessThan: Timestamp.fromDate(nextMonth))
            .get();

        double revenue = 0.0;
        for (var doc in revenueSnapshot.docs) {
          revenue += (doc.data()['amount'] ?? 0.0).toDouble();
        }

        monthlyData.add({
          'month': '${month.month}/${month.year}',
          'revenue': revenue,
        });
      }

      return monthlyData;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Başlık ve tarih seçimi
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Raporlar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadReportData,
                      icon: const Icon(Icons.refresh,
                          size: 18, color: Colors.white),
                      label: const Text('Yenile',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Başlangıç Tarihi',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bitiş Tarihi',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              Text(
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rapor içeriği
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      children: [
                        // Özet kartları
                        _buildSummaryCards(),

                        const SizedBox(height: 20),

                        // Gelir-Gider kartı
                        _buildRevenueExpenseCard(),

                        const SizedBox(height: 20),

                        // Aylık trend kartı
                        _buildMonthlyTrendCard(),

                        const SizedBox(height: 20),

                        // Hızlı istatistikler
                        _buildQuickStats(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Toplam Hasta', '${_reportData['totalPatients'] ?? 0}',
            Colors.blue, Icons.people),
        _buildStatCard('Randevular', '${_reportData['totalAppointments'] ?? 0}',
            Colors.green, Icons.calendar_today),
        _buildStatCard(
            'Tamamlanan Tedavi',
            '${_reportData['completedTreatments'] ?? 0}',
            Colors.teal,
            Icons.medical_services),
        _buildStatCard(
            'Net Kar',
            '₺${((_reportData['totalRevenue'] ?? 0.0) - (_reportData['totalExpenses'] ?? 0.0)).toStringAsFixed(0)}',
            Colors.purple,
            Icons.account_balance),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueExpenseCard() {
    final revenue = _reportData['totalRevenue'] ?? 0.0;
    final expenses = _reportData['totalExpenses'] ?? 0.0;
    final profit = revenue - expenses;

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Gelir & Gider Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    const Text('Toplam Gelir',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      '₺${revenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.trending_down,
                        color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    const Text('Toplam Gider',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      '₺${expenses.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      profit >= 0
                          ? Icons.account_balance_wallet
                          : Icons.money_off,
                      color: profit >= 0 ? Colors.blue : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text('Net Kar', style: TextStyle(color: Colors.grey)),
                    Text(
                      '₺${profit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: profit >= 0 ? Colors.blue : Colors.red,
                      ),
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

  Widget _buildMonthlyTrendCard() {
    final monthlyStats =
        _reportData['monthlyStats'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Aylık Gelir Trendi (Son 6 Ay)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (monthlyStats.isEmpty)
            const Center(
              child: Text(
                'Veri bulunamadı',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: monthlyStats.length,
                itemBuilder: (context, index) {
                  final stat = monthlyStats[index];
                  final revenue = (stat['revenue'] as double? ?? 0.0);
                  final maxRevenue = monthlyStats.fold(
                      0.0,
                      (prev, element) =>
                          (element['revenue'] as double? ?? 0.0) > prev
                              ? (element['revenue'] as double? ?? 0.0)
                              : prev);
                  final height =
                      maxRevenue > 0 ? (revenue / maxRevenue) * 150 : 0.0;

                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₺${revenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stat['month'] ?? '',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Hızlı İstatistikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickStatItem('Ortalama Günlük Gelir',
              '₺${_calculateDailyAverage().toStringAsFixed(0)}'),
          _buildQuickStatItem('Seçilen Dönem',
              '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'),
          _buildQuickStatItem(
              'Rapor Oluşturma Tarihi', _formatDate(DateTime.now())),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  double _calculateDailyAverage() {
    final revenue = _reportData['totalRevenue'] ?? 0.0;
    final daysDiff = _endDate.difference(_startDate).inDays + 1;
    return daysDiff > 0 ? revenue / daysDiff : 0.0;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadReportData();
    }
  }
}
