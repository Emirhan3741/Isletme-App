import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_client_model.dart';

class LawyerReportsPage extends StatefulWidget {
  const LawyerReportsPage({super.key});

  @override
  State<LawyerReportsPage> createState() => _LawyerReportsPageState();
}

class _LawyerReportsPageState extends State<LawyerReportsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  // Veriler
  List<TransactionModel> _transactions = [];
  List<LawyerClientModel> _clients = [];
  List<CaseModel> _cases = [];

  // Rapor verileri
  Map<String, double> _monthlyIncome = {};
  Map<String, double> _monthlyExpense = {};
  Map<String, int> _casesByType = {};
  Map<String, double> _casesByDuration = {};

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

      // Paralel veri yükleme
      final results = await Future.wait([
        _loadTransactions(user.uid),
        _loadClients(user.uid),
        _loadCases(user.uid),
      ]);

      setState(() {
        _transactions = results[0] as List<TransactionModel>;
        _clients = results[1] as List<LawyerClientModel>;
        _cases = results[2] as List<CaseModel>;
        _isLoading = false;
      });

      _calculateReports();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<TransactionModel>> _loadTransactions(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerTransactionsCollection)
        .where('userId', isEqualTo: userId)
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TransactionModel(
        id: doc.id,
        userId: userId,
        kategori: data['kategori'] ?? 'gelir',
        tutar: (data['tutar'] ?? 0.0).toDouble(),
        aciklama: data['aciklama'] ?? '',
        tarih: (data['tarih'] as Timestamp).toDate(),
        clientId: data['clientId'],
      );
    }).toList();
  }

  Future<List<LawyerClientModel>> _loadClients(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerClientsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => LawyerClientModel.fromFirestore(doc))
        .toList();
  }

  Future<List<CaseModel>> _loadCases(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerCasesCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CaseModel(
        id: doc.id,
        userId: userId,
        baslik: data['davaAdi'] ?? '',
        davaTuru: data['davaTuru'] ?? 'hukuk',
        durum: data['davaDurumu'] ?? 'devam_ediyor',
        baslangicTarihi: (data['davaBaslangicTarihi'] as Timestamp?)?.toDate(),
        bitisTarihi: (data['davaBitisTarihi'] as Timestamp?)?.toDate(),
        clientId: data['clientId'],
      );
    }).toList();
  }

  void _calculateReports() {
    // Aylık gelir-gider hesaplama
    _monthlyIncome.clear();
    _monthlyExpense.clear();

    for (var transaction in _transactions) {
      final monthKey =
          '${transaction.tarih.year}-${transaction.tarih.month.toString().padLeft(2, '0')}';

      if (transaction.kategori == 'gelir') {
        _monthlyIncome[monthKey] =
            (_monthlyIncome[monthKey] ?? 0) + transaction.tutar;
      } else {
        _monthlyExpense[monthKey] =
            (_monthlyExpense[monthKey] ?? 0) + transaction.tutar;
      }
    }

    // Dava türü dağılımı
    _casesByType.clear();
    for (var case_ in _cases) {
      _casesByType[case_.davaTuru] = (_casesByType[case_.davaTuru] ?? 0) + 1;
    }

    // Müvekkil başına ortalama dava süresi
    _casesByDuration.clear();
    for (var client in _clients) {
      final clientCases = _cases.where((c) => c.clientId == client.id).toList();
      if (clientCases.isNotEmpty) {
        double totalDuration = 0;
        int completedCases = 0;

        for (var case_ in clientCases) {
          if (case_.baslangicTarihi != null) {
            final endDate = case_.bitisTarihi ?? DateTime.now();
            final duration = endDate.difference(case_.baslangicTarihi!).inDays;
            totalDuration += duration;
            completedCases++;
          }
        }

        if (completedCases > 0) {
          _casesByDuration[client.name] = totalDuration / completedCases;
        }
      }
    }

    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Başlık ve tarih aralığı seçimi
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
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
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Raporlar listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      children: [
                        // Özet kartları
                        _buildSummaryCards(),

                        const SizedBox(height: AppConstants.paddingLarge),

                        // Aylık gelir-gider grafiği
                        _buildIncomeExpenseChart(),

                        const SizedBox(height: AppConstants.paddingLarge),

                        // Dava türü dağılımı
                        _buildCaseTypeChart(),

                        const SizedBox(height: AppConstants.paddingLarge),

                        // Müvekkil başına dava süresi
                        _buildCaseDurationChart(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalIncome = _monthlyIncome.values
        .fold(0.0, (totalAmount, value) => totalAmount + value);
    final totalExpense = _monthlyExpense.values
        .fold(0.0, (totalAmount, value) => totalAmount + value);
    final netProfit = totalIncome - totalExpense;
    final totalCases = _cases.length;
    final activeCases = _cases.where((c) => c.durum == 'devam_ediyor').length;
    final completedCases = _cases.where((c) => c.durum == 'tamamlandi').length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Gelir',
                value: '₺${totalIncome.toStringAsFixed(0)}',
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Gider',
                value: '₺${totalExpense.toStringAsFixed(0)}',
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Net Kar',
                value: '₺${netProfit.toStringAsFixed(0)}',
                color: netProfit >= 0 ? Colors.green : Colors.red,
                icon: netProfit >= 0
                    ? Icons.account_balance_wallet
                    : Icons.money_off,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Dava',
                value: totalCases.toString(),
                color: Colors.blue,
                icon: Icons.gavel,
                subtitle: 'Aktif: $activeCases | Tamamlanan: $completedCases',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseChart() {
    if (_monthlyIncome.isEmpty && _monthlyExpense.isEmpty) {
      return _buildEmptyChart(
          'Gelir-Gider Grafiği', 'Bu tarih aralığında işlem bulunamadı');
    }

    // Ortak ay listesi oluştur
    final allMonths =
        <String>{..._monthlyIncome.keys, ..._monthlyExpense.keys}.toList();
    allMonths.sort();

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < allMonths.length; i++) {
      final month = allMonths[i];
      incomeSpots.add(FlSpot(i.toDouble(), _monthlyIncome[month] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), _monthlyExpense[month] ?? 0));
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aylık Gelir-Gider Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₺${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < allMonths.length) {
                          final month = allMonths[index];
                          return Text(
                            month.substring(5),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Gelir', Colors.green),
              const SizedBox(width: AppConstants.paddingLarge),
              _buildLegendItem('Gider', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTypeChart() {
    if (_casesByType.isEmpty) {
      return _buildEmptyChart(
          'Dava Türü Dağılımı', 'Henüz dava kaydı bulunamadı');
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dava Türüne Göre Dağılım',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _casesByType.entries.map((entry) {
                  final index = _casesByType.keys.toList().indexOf(entry.key);
                  final color = colors[index % colors.length];
                  final total = _casesByType.values
                      .fold(0, (totalAmount, value) => totalAmount + value);
                  final percentage =
                      (entry.value / total * 100).toStringAsFixed(1);

                  return PieChartSectionData(
                    color: color,
                    value: entry.value.toDouble(),
                    title: '$percentage%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Wrap(
            spacing: AppConstants.paddingMedium,
            runSpacing: AppConstants.paddingSmall,
            children: _casesByType.entries.map((entry) {
              final index = _casesByType.keys.toList().indexOf(entry.key);
              final color = colors[index % colors.length];
              return _buildLegendItem('${entry.key} (${entry.value})', color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDurationChart() {
    if (_casesByDuration.isEmpty) {
      return _buildEmptyChart(
          'Müvekkil Başına Dava Süresi', 'Dava süresi hesaplanamadı');
    }

    final sortedEntries = _casesByDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müvekkil Başına Ortalama Dava Süresi (Gün)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topEntries.length) {
                          final name = topEntries[index].key;
                          return Text(
                            name.length > 10
                                ? '${name.substring(0, 10)}...'
                                : name,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: topEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: Colors.purple,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
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

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Icon(
            Icons.bar_chart,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            message,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Özet kartı widget'ı
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
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
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Veri modelleri
class TransactionModel {
  final String id;
  final String userId;
  final String kategori;
  final double tutar;
  final String aciklama;
  final DateTime tarih;
  final String? clientId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.kategori,
    required this.tutar,
    required this.aciklama,
    required this.tarih,
    this.clientId,
  });
}

class CaseModel {
  final String id;
  final String userId;
  final String baslik;
  final String davaTuru;
  final String durum;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final String? clientId;

  CaseModel({
    required this.id,
    required this.userId,
    required this.baslik,
    required this.davaTuru,
    required this.durum,
    this.baslangicTarihi,
    this.bitisTarihi,
    this.clientId,
  });
}
