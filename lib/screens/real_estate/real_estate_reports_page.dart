import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/feedback_utils.dart';

class RealEstateReportsPage extends StatefulWidget {
  const RealEstateReportsPage({super.key});

  @override
  State<RealEstateReportsPage> createState() => _RealEstateReportsPageState();
}

class _RealEstateReportsPageState extends State<RealEstateReportsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Report Data
  Map<String, dynamic> _salesData = {};
  Map<String, dynamic> _expenseData = {};
  Map<String, dynamic> _clientData = {};
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _propertyData = [];

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    if (currentUserId == null) return;

    try {
      setState(() => _isLoading = true);

      await Future.wait([
        _loadSalesData(),
        _loadExpenseData(),
        _loadClientData(),
        _loadMonthlyData(),
        _loadPropertyData(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      FeedbackUtils.showError(context, 'Rapor verileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadSalesData() async {
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.realEstatePaymentsCollection)
        .where('userId', isEqualTo: currentUserId)
        .get();

    double totalSales = 0;
    double thisMonthSales = 0;
    int totalTransactions = paymentsSnapshot.docs.length;

    final thisMonth = DateTime.now();

    for (var doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      totalSales += amount;

      final paymentDate = (data['paymentDate'] as Timestamp?)?.toDate();
      if (paymentDate != null &&
          paymentDate.year == thisMonth.year &&
          paymentDate.month == thisMonth.month) {
        thisMonthSales += amount;
      }
    }

    _salesData = {
      'totalSales': totalSales,
      'thisMonthSales': thisMonthSales,
      'totalTransactions': totalTransactions,
      'averageTransaction':
          totalTransactions > 0 ? totalSales / totalTransactions : 0,
    };
  }

  Future<void> _loadExpenseData() async {
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.realEstateExpensesCollection)
        .where('userId', isEqualTo: currentUserId)
        .get();

    double totalExpenses = 0;
    double thisMonthExpenses = 0;
    Map<String, double> categoryExpenses = {};

    final thisMonth = DateTime.now();

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final category = data['category'] ?? 'diğer';

      totalExpenses += amount;
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;

      final expenseDate = (data['expenseDate'] as Timestamp?)?.toDate();
      if (expenseDate != null &&
          expenseDate.year == thisMonth.year &&
          expenseDate.month == thisMonth.month) {
        thisMonthExpenses += amount;
      }
    }

    _expenseData = {
      'totalExpenses': totalExpenses,
      'thisMonthExpenses': thisMonthExpenses,
      'categoryExpenses': categoryExpenses,
    };
  }

  Future<void> _loadClientData() async {
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.realEstateClientsCollection)
        .where('userId', isEqualTo: currentUserId)
        .get();

    int totalClients = clientsSnapshot.docs.length;
    Map<String, int> clientsByType = {};
    Map<String, int> clientsByStatus = {};

    for (var doc in clientsSnapshot.docs) {
      final data = doc.data();
      final type = data['clientType'] ?? 'alıcı';
      final status = data['status'] ?? 'aktif';

      clientsByType[type] = (clientsByType[type] ?? 0) + 1;
      clientsByStatus[status] = (clientsByStatus[status] ?? 0) + 1;
    }

    _clientData = {
      'totalClients': totalClients,
      'clientsByType': clientsByType,
      'clientsByStatus': clientsByStatus,
    };
  }

  Future<void> _loadMonthlyData() async {
    _monthlyData = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.realEstatePaymentsCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('paymentDate', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      final expensesSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.realEstateExpensesCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('expenseDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('expenseDate', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      double sales = 0;
      double expenses = 0;

      for (var doc in paymentsSnapshot.docs) {
        sales += (doc.data()['amount'] ?? 0).toDouble();
      }

      for (var doc in expensesSnapshot.docs) {
        expenses += (doc.data()['amount'] ?? 0).toDouble();
      }

      _monthlyData.add({
        'month': DateFormat('MMM', 'tr_TR').format(month),
        'sales': sales,
        'expenses': expenses,
        'profit': sales - expenses,
      });
    }
  }

  Future<void> _loadPropertyData() async {
    final propertiesSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.realEstatePropertiesCollection)
        .where('userId', isEqualTo: currentUserId)
        .get();

    Map<String, int> propertiesByType = {};
    Map<String, int> propertiesByStatus = {};

    for (var doc in propertiesSnapshot.docs) {
      final data = doc.data();
      final type = data['propertyType'] ?? 'ev';
      final status = data['status'] ?? 'aktif';

      propertiesByType[type] = (propertiesByType[type] ?? 0) + 1;
      propertiesByStatus[status] = (propertiesByStatus[status] ?? 0) + 1;
    }

    _propertyData = [
      {'title': 'Tip Dağılımı', 'data': propertiesByType},
      {'title': 'Durum Dağılımı', 'data': propertiesByStatus},
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesReport(),
                _buildExpenseReport(),
                _buildClientReport(),
                _buildOverviewReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.cyan, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raporlar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'İş performansınızı analiz edin',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Satışlar', icon: Icon(Icons.trending_up)),
          Tab(text: 'Giderler', icon: Icon(Icons.trending_down)),
          Tab(text: 'Müşteriler', icon: Icon(Icons.people)),
          Tab(text: 'Genel Bakış', icon: Icon(Icons.dashboard)),
        ],
        labelColor: Colors.cyan,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.cyan,
      ),
    );
  }

  Widget _buildSalesReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Toplam Satış',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(_salesData['totalSales'] ?? 0)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Bu Ay Satış',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(_salesData['thisMonthSales'] ?? 0)}',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Toplam İşlem',
                  '${_salesData['totalTransactions'] ?? 0}',
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Ortalama İşlem',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(_salesData['averageTransaction'] ?? 0)}',
                  Icons.analytics,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildMonthlyChart(),
        ],
      ),
    );
  }

  Widget _buildExpenseReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Toplam Gider',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(_expenseData['totalExpenses'] ?? 0)}',
                  Icons.money_off,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Bu Ay Gider',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(_expenseData['thisMonthExpenses'] ?? 0)}',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Net Kâr',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format((_salesData['totalSales'] ?? 0) - (_expenseData['totalExpenses'] ?? 0))}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildExpenseCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildClientReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'Toplam Müşteri',
            '${_clientData['totalClients'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildClientTypeChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildClientStatusChart(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyChart(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildExpenseCategoryChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildClientTypeChart(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aylık Satış & Gider Trendi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _monthlyData.length) {
                          return const Text('');
                        }
                        return Text(_monthlyData[index]['month']);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: _monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['sales'].toDouble(),
                        color: Colors.green,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: data['expenses'].toDouble(),
                        color: Colors.red,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryChart() {
    final categoryExpenses =
        _expenseData['categoryExpenses'] as Map<String, double>? ?? {};

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gider Kategorileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: categoryExpenses.isEmpty
                ? const Center(child: Text('Veri bulunamadı'))
                : PieChart(
                    PieChartData(
                      sections: _buildPieSections(categoryExpenses),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTypeChart() {
    final clientsByType =
        _clientData['clientsByType'] as Map<String, int>? ?? {};

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müşteri Tipleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: clientsByType.isEmpty
                ? const Center(child: Text('Veri bulunamadı'))
                : PieChart(
                    PieChartData(
                      sections: _buildClientPieSections(clientsByType),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStatusChart() {
    final clientsByStatus =
        _clientData['clientsByStatus'] as Map<String, int>? ?? {};

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müşteri Durumları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: clientsByStatus.isEmpty
                ? const Center(child: Text('Veri bulunamadı'))
                : PieChart(
                    PieChartData(
                      sections: _buildStatusPieSections(clientsByStatus),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal
    ];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: mapEntry.value,
        title:
            '${mapEntry.key}\n₺${NumberFormat('#,##0', 'tr_TR').format(mapEntry.value)}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildClientPieSections(Map<String, int> data) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: mapEntry.value.toDouble(),
        title: '${mapEntry.key}\n${mapEntry.value}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildStatusPieSections(Map<String, int> data) {
    final colors = [Colors.green, Colors.orange, Colors.blue, Colors.red];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: mapEntry.value.toDouble(),
        title: '${mapEntry.key}\n${mapEntry.value}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  double _getMaxValue() {
    double max = 0;
    for (var data in _monthlyData) {
      final sales = data['sales'].toDouble();
      final expenses = data['expenses'].toDouble();
      if (sales > max) max = sales;
      if (expenses > max) max = expenses;
    }
    return max > 0 ? max * 1.2 : 100;
  }
}
