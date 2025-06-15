import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';

class ReportDashboardPage extends StatefulWidget {
  const ReportDashboardPage({super.key});

  @override
  State<ReportDashboardPage> createState() => _ReportDashboardPageState();
}

class _ReportDashboardPageState extends State<ReportDashboardPage> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;

  // Özet veriler
  double _todayIncome = 0.0;
  double _monthExpenses = 0.0;
  double _totalDebt = 0.0;
  int _todayAppointments = 0;
  int _weekAppointments = 0;
  Map<String, dynamic> _mostCommonTransaction = {};
  Map<String, dynamic> _mostFrequentCustomer = {};

  // Grafik verileri
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _transactionDistribution = [];
  List<Map<String, dynamic>> _dailyAppointments = [];
  List<Map<String, dynamic>> _notesCategoryDistribution = [];
  List<Map<String, dynamic>> _topCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Paralel olarak tüm verileri yükle
      final results = await Future.wait([
        _reportService.getOverallSummary(),
        _reportService.getMonthlyIncomeExpenseComparison(),
        _reportService.getTransactionTypeDistribution(),
        _reportService.getDailyAppointmentCounts(),
        _reportService.getNotesCategoryDistribution(),
        _reportService.getTopCustomersBySpending(),
      ]);

      if (mounted) {
        setState(() {
          // Özet veriler
          final summary = results[0] as Map<String, dynamic>;
          _todayIncome = (summary['todayIncome'] ?? 0.0).toDouble();
          _monthExpenses = (summary['monthExpenses'] ?? 0.0).toDouble();
          _totalDebt = (summary['totalDebt'] ?? 0.0).toDouble();
          _todayAppointments = (summary['todayAppointments'] ?? 0).toInt();
          _weekAppointments = (summary['weekAppointments'] ?? 0).toInt();
          _mostCommonTransaction = summary['mostCommonTransactionType'] ?? {};
          _mostFrequentCustomer = summary['mostFrequentCustomer'] ?? {};

          // Grafik verileri
          _monthlyData = results[1] as List<Map<String, dynamic>>;
          _transactionDistribution = results[2] as List<Map<String, dynamic>>;
          _dailyAppointments = results[3] as List<Map<String, dynamic>>;
          _notesCategoryDistribution = results[4] as List<Map<String, dynamic>>;
          _topCustomers = results[5] as List<Map<String, dynamic>>;

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Özet kartları
                    _buildSummarySection(),
                    const SizedBox(height: 24),

                    // Gelir/Gider karşılaştırması
                    _buildIncomeExpenseChart(),
                    const SizedBox(height: 24),

                    // İşlem türü dağılımı
                    _buildTransactionDistributionChart(),
                    const SizedBox(height: 24),

                    // Günlük randevular
                    _buildDailyAppointmentsChart(),
                    const SizedBox(height: 24),

                    // Not kategorileri
                    _buildNotesCategoryChart(),
                    const SizedBox(height: 24),

                    // En değerli müşteriler
                    _buildTopCustomersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // Özet kartları bölümü
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genel Özet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildSummaryCard(
              'Bugünün Geliri',
              '₺${NumberFormat('#,##0.00').format(_todayIncome)}',
              Icons.trending_up,
              Colors.green,
            ),
            _buildSummaryCard(
              'Bu Ayın Gideri',
              '₺${NumberFormat('#,##0.00').format(_monthExpenses)}',
              Icons.trending_down,
              Colors.red,
            ),
            _buildSummaryCard(
              'Toplam Borç',
              '₺${NumberFormat('#,##0.00').format(_totalDebt)}',
              Icons.warning,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Bugünkü Randevular',
              _todayAppointments.toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3,
          children: [
            _buildInfoCard(
              'En Çok Yapılan İşlem',
              '${_mostCommonTransaction['type'] ?? 'Bilinmiyor'} (${_mostCommonTransaction['count'] ?? 0} adet)',
              Icons.bar_chart,
              Colors.purple,
            ),
            _buildInfoCard(
              'En Sık Gelen Müşteri',
              '${_mostFrequentCustomer['name'] ?? 'Bilinmiyor'} (${_mostFrequentCustomer['count'] ?? 0} randevu)',
              Icons.person_pin,
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  // Özet kartı
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bilgi kartı
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gelir/Gider karşılaştırma grafiği
  Widget _buildIncomeExpenseChart() {
    if (_monthlyData.isEmpty) {
      return _buildEmptyChart('Gelir/Gider Karşılaştırması', 'Veri bulunamadı');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık Gelir/Gider Karşılaştırması',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _monthlyData.length) {
                            return Text(
                              _monthlyData[index]['month'].toString().substring(0, 3),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₺${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Gelir çizgisi
                    LineChartBarData(
                      spots: _monthlyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['income'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    // Gider çizgisi
                    LineChartBarData(
                      spots: _monthlyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['expense'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Gelir', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Gider', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // İşlem türü dağılımı pasta grafiği
  Widget _buildTransactionDistributionChart() {
    if (_transactionDistribution.isEmpty) {
      return _buildEmptyChart('İşlem Türü Dağılımı', 'Veri bulunamadı');
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İşlem Türü Dağılımı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _transactionDistribution.take(8).map((data) {
                          final index = _transactionDistribution.indexOf(data);
                          final color = colors[index % colors.length];
                          return PieChartSectionData(
                            value: data['amount'].toDouble(),
                            title: '${data['percentage'].toStringAsFixed(1)}%',
                            color: color,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _transactionDistribution.take(8).map((data) {
                        final index = _transactionDistribution.indexOf(data);
                        final color = colors[index % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['type'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Günlük randevular bar grafiği
  Widget _buildDailyAppointmentsChart() {
    if (_dailyAppointments.isEmpty) {
      return _buildEmptyChart('Günlük Randevu Sayıları', 'Veri bulunamadı');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son 7 Günün Randevu Sayıları',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _dailyAppointments.length) {
                            return Text(
                              _dailyAppointments[index]['day'],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _dailyAppointments.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Not kategorileri grafiği
  Widget _buildNotesCategoryChart() {
    if (_notesCategoryDistribution.isEmpty) {
      return _buildEmptyChart('Not Kategorileri', 'Veri bulunamadı');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not Kategorileri Dağılımı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_notesCategoryDistribution.take(5).map((data) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      data['icon'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['category'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${data['count']} not',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: data['percentage'] / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  // En değerli müşteriler
  Widget _buildTopCustomersSection() {
    if (_topCustomers.isEmpty) {
      return _buildEmptyCard('En Değerli Müşteriler', 'Veri bulunamadı');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Değerli Müşteriler (Top 5)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_topCustomers.map((customer) {
              final rank = customer['rank'];
              final name = customer['name'];
              final amount = customer['amount'];
              
              Color rankColor;
              switch (rank) {
                case 1:
                  rankColor = Colors.amber;
                  break;
                case 2:
                  rankColor = Colors.grey[400]!;
                  break;
                case 3:
                  rankColor = Colors.brown;
                  break;
                default:
                  rankColor = Colors.blue;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rank.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₺${NumberFormat('#,##0.00').format(amount)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  // Boş grafik
  Widget _buildEmptyChart(String title, String message) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Boş kart
  Widget _buildEmptyCard(String title, String message) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}