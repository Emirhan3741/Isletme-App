// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../services/report_service.dart';
import '../../services/transaction_service.dart';
import '../../core/widgets/form_field_with_custom_option.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class ReportDashboardPage extends StatefulWidget {
  const ReportDashboardPage({super.key});

  @override
  State<ReportDashboardPage> createState() => _ReportDashboardPageState();
}

class _ReportDashboardPageState extends State<ReportDashboardPage> {
  final TransactionService _transactionService = TransactionService();
  final ExpenseService _expenseService = ExpenseService();
  final AppointmentService _appointmentService = AppointmentService();

  bool _isLoading = true;
  String _selectedPeriod = 'Bu Ay';
  String _selectedServiceType = 'Tümü';
  String _selectedEmployee = 'Tümü';

  // Özet veriler
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _netProfit = 0.0;
  double _pendingPayments = 0.0;

  // Grafik verileri
  List<TransactionModel> _transactions = [];
  List<ExpenseModel> _expenses = [];
  List<AppointmentModel> _appointments = [];
  List<BarData> _incomeExpenseData = [];
  List<PieData> _serviceDistributionData = [];
  List<PieData> _expenseDistributionData = [];
  List<EmployeePerformance> _employeePerformanceData = [];
  List<TopService> _topServicesData = [];
  List<TopCustomer> _topCustomersData = [];

  final List<String> _periodOptions = [
    'Bu Hafta',
    'Bu Ay',
    'Geçen Ay',
    'Son 3 Ay',
    'Bu Yıl'
  ];
  final List<String> _serviceTypes = [
    'Tümü',
    'Saç Kesim',
    'Saç Boyama',
    'Makyaj',
    'Cilt Bakımı',
    'Masaj'
  ];
  final List<String> _employees = ['Tümü'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Firebase'den gerçek zamanlı veri çekme
      final results = await Future.wait([
        _transactionService.getTransactions(),
        _expenseService.getExpenses(),
        _appointmentService.getAppointments(),
      ]);

      _transactions = results[0] as List<TransactionModel>;
      _expenses = results[1] as List<ExpenseModel>;
      _appointments = results[2] as List<AppointmentModel>;

      // Çalışan listesini dinamik olarak oluştur
      _updateEmployeeList();

      _calculateSummaryData();
      _generateChartData();
      _generateTableData();
    } catch (e) {
      if (kDebugMode) debugPrint('Veri yükleme hatası: $e');
      _showErrorSnackBar('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateEmployeeList() {
    final employees = _appointments
        .where((a) => a.employeeName != null && a.employeeName!.isNotEmpty)
        .map((a) => a.employeeName!)
        .toSet()
        .toList();

    setState(() {
      _employees.clear();
      _employees.add('Tümü');
      _employees.addAll(employees);
    });
  }

  void _calculateSummaryData() {
    final filteredTransactions = _getFilteredTransactions();
    final filteredExpenses = _getFilteredExpenses();
    final filteredAppointments = _getFilteredAppointments();

    // Gelir hesaplama (randevular + diğer gelirler)
    _totalIncome = filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Randevu gelirlerini de ekle
    _totalIncome += filteredAppointments
        .where(
            (a) => a.status == AppointmentStatus.completed && a.price != null)
        .fold(0.0, (sum, a) => sum + (a.price ?? 0.0));

    // Gider hesaplama
    _totalExpense = filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    _totalExpense += filteredExpenses
        .where((e) => e.isPaid)
        .fold(0.0, (sum, e) => sum + e.amount);

    // Net kar hesaplama
    _netProfit = _totalIncome - _totalExpense;

    // Bekleyen ödemeler hesaplama
    _pendingPayments = filteredExpenses
        .where((e) => !e.isPaid)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<TransactionModel> _getFilteredTransactions() {
    final dateRange = _getDateRange();
    return _transactions.where((t) {
      final date = t.createdAt;
      return date
              .isAfter(dateRange['start']!.subtract(const Duration(days: 1))) &&
          date.isBefore(dateRange['end']!.add(const Duration(days: 1)));
    }).toList();
  }

  List<ExpenseModel> _getFilteredExpenses() {
    final dateRange = _getDateRange();
    return _expenses.where((e) {
      final date = e.date;
      return date
              .isAfter(dateRange['start']!.subtract(const Duration(days: 1))) &&
          date.isBefore(dateRange['end']!.add(const Duration(days: 1)));
    }).toList();
  }

  List<AppointmentModel> _getFilteredAppointments() {
    final dateRange = _getDateRange();
    return _appointments.where((a) {
      final date = a.dateTime;
      bool dateMatch =
          date.isAfter(dateRange['start']!.subtract(const Duration(days: 1))) &&
              date.isBefore(dateRange['end']!.add(const Duration(days: 1)));

      bool serviceMatch = _selectedServiceType == 'Tümü' ||
          a.serviceName == _selectedServiceType;
      bool employeeMatch =
          _selectedEmployee == 'Tümü' || a.employeeName == _selectedEmployee;

      return dateMatch && serviceMatch && employeeMatch;
    }).toList();
  }

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    DateTime startDate, endDate;

    switch (_selectedPeriod) {
      case 'Bu Hafta':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'Bu Ay':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Geçen Ay':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Son 3 Ay':
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Bu Yıl':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
    }

    return {'start': startDate, 'end': endDate};
  }

  void _generateChartData() {
    // Aylık gelir-gider grafiği için veri oluştur
    _incomeExpenseData.clear();
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      // O aya ait gelirler
      final monthlyIncome = _transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.createdAt.isAfter(month.subtract(const Duration(days: 1))) &&
              t.createdAt.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthlyAppointmentIncome = _appointments
          .where((a) =>
              a.status == AppointmentStatus.completed &&
              a.price != null &&
              a.dateTime.isAfter(month.subtract(const Duration(days: 1))) &&
              a.dateTime.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, a) => sum + (a.price ?? 0.0));

      // O aya ait giderler
      final monthlyExpense = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.createdAt.isAfter(month.subtract(const Duration(days: 1))) &&
              t.createdAt.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthlyExpenseFromExpenses = _expenses
          .where((e) =>
              e.isPaid &&
              e.date.isAfter(month.subtract(const Duration(days: 1))) &&
              e.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, e) => sum + e.amount);

      _incomeExpenseData.add(BarData(
        DateFormat('MMM', 'tr_TR').format(month),
        (monthlyIncome + monthlyAppointmentIncome).toInt(),
        (monthlyExpense + monthlyExpenseFromExpenses).toInt(),
      ));
    }

    // Hizmet dağılımı pie chart
    _generateServiceDistribution();

    // Gider dağılımı pie chart
    _generateExpenseDistribution();
  }

  void _generateServiceDistribution() {
    final filteredAppointments = _getFilteredAppointments();
    final serviceMap = <String, double>{};

    for (final appointment in filteredAppointments) {
      if (appointment.status == AppointmentStatus.completed &&
          appointment.serviceName != null) {
        serviceMap[appointment.serviceName!] =
            (serviceMap[appointment.serviceName!] ?? 0) +
                (appointment.price ?? 0);
      }
    }

    final total = serviceMap.values.fold(0.0, (sum, value) => sum + value);
    if (total > 0) {
      final colors = [
        Colors.blue,
        Colors.orange,
        Colors.green,
        Colors.purple,
        Colors.red,
        Colors.teal
      ];
      int colorIndex = 0;

      _serviceDistributionData = serviceMap.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return PieData(entry.key, percentage.toInt(), color);
      }).toList();
    } else {
      _serviceDistributionData = [
        PieData('Veri Yok', 100, Colors.grey),
      ];
    }
  }

  void _generateExpenseDistribution() {
    final filteredExpenses = _getFilteredExpenses();
    final expenseMap = <String, double>{};

    for (final expense in filteredExpenses.where((e) => e.isPaid)) {
      expenseMap[expense.category] =
          (expenseMap[expense.category] ?? 0) + expense.amount;
    }

    final total = expenseMap.values.fold(0.0, (sum, value) => sum + value);
    if (total > 0) {
      final colors = [
        Colors.red,
        Colors.orange,
        Colors.purple,
        Colors.brown,
        Colors.pink,
        Colors.indigo
      ];
      int colorIndex = 0;

      _expenseDistributionData = expenseMap.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return PieData(entry.key, percentage.toInt(), color);
      }).toList();
    } else {
      _expenseDistributionData = [
        PieData('Veri Yok', 100, Colors.grey),
      ];
    }
  }

  void _generateTableData() {
    final filteredAppointments = _getFilteredAppointments();

    // En çok kazandıran hizmetler
    final serviceRevenue = <String, double>{};
    for (final appointment in filteredAppointments) {
      if (appointment.status == AppointmentStatus.completed &&
          appointment.serviceName != null &&
          appointment.price != null) {
        serviceRevenue[appointment.serviceName!] =
            (serviceRevenue[appointment.serviceName!] ?? 0) +
                appointment.price!;
      }
    }

    _topServicesData = serviceRevenue.entries
        .map((e) => TopService(e.key, e.value))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    if (_topServicesData.length > 5) {
      _topServicesData = _topServicesData.take(5).toList();
    }

    // En çok ödeme yapan müşteriler
    final customerPayments = <String, double>{};
    for (final appointment in filteredAppointments) {
      if (appointment.status == AppointmentStatus.completed &&
          appointment.customerName != null &&
          appointment.price != null) {
        customerPayments[appointment.customerName!] =
            (customerPayments[appointment.customerName!] ?? 0) +
                appointment.price!;
      }
    }

    _topCustomersData = customerPayments.entries
        .map((e) => TopCustomer(e.key, e.value))
        .toList()
      ..sort((a, b) => b.totalPayment.compareTo(a.totalPayment));

    if (_topCustomersData.length > 5) {
      _topCustomersData = _topCustomersData.take(5).toList();
    }

    // Çalışan performansı
    final employeeData = <String, Map<String, dynamic>>{};
    for (final appointment in filteredAppointments) {
      if (appointment.employeeName != null) {
        if (!employeeData.containsKey(appointment.employeeName!)) {
          employeeData[appointment.employeeName!] = {
            'count': 0,
            'revenue': 0.0
          };
        }
        employeeData[appointment.employeeName!]!['count']++;
        if (appointment.status == AppointmentStatus.completed &&
            appointment.price != null) {
          employeeData[appointment.employeeName!]!['revenue'] +=
              appointment.price!;
        }
      }
    }

    _employeePerformanceData = employeeData.entries
        .map((e) => EmployeePerformance(
            e.key, e.value['count'] as int, e.value['revenue'] as double))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Yeniden Dene',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filtreler 🔍',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Tarih Aralığı',
                    value: _selectedPeriod,
                    items: _periodOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                        _calculateSummaryData();
                        _generateChartData();
                        _generateTableData();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Hizmet Türü',
                    value: _selectedServiceType,
                    items: _serviceTypes,
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceType = value!;
                        _calculateSummaryData();
                        _generateChartData();
                        _generateTableData();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Çalışan',
                    value: _selectedEmployee,
                    items: _employees,
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployee = value!;
                        _calculateSummaryData();
                        _generateChartData();
                        _generateTableData();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FormFieldWithCustomOption<String>(
      label: label,
      value: value,
      options: items,
      optionLabel: (item) => item,
      optionValue: (item) => item,
      onChanged: onChanged,
      customOptionLabel: 'Özel',
      customInputLabel: 'Özel $label',
      customInputHint: 'Özel $label girin...',
      fieldType: FormFieldType.dropdown,
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Toplam Gelir',
                amount: '₺${NumberFormat('#,##0').format(_totalIncome)}',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: 'Bu dönem',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Toplam Gider',
                amount: '₺${NumberFormat('#,##0').format(_totalExpense)}',
                icon: Icons.trending_down,
                color: Colors.red,
                subtitle: 'Bu dönem',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Net Kar',
                amount: '₺${NumberFormat('#,##0').format(_netProfit)}',
                icon: Icons.account_balance_wallet,
                color: _netProfit >= 0 ? Colors.blue : Colors.red,
                subtitle: _netProfit >= 0 ? 'Kâr' : 'Zarar',
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Bekleyen Ödeme',
                amount: '₺${NumberFormat('#,##0').format(_pendingPayments)}',
                icon: Icons.schedule,
                color: Colors.orange,
                subtitle: 'Ödenmemiş',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool highlight = false,
  }) {
    return Card(
      elevation: highlight ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: highlight
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 25),
                    color.withValues(alpha: 12)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (highlight)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.green.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gelir-Gider Grafiği 📊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _incomeExpenseData.isNotEmpty
                      ? _incomeExpenseData
                              .map((e) => [e.income, e.expense])
                              .expand((e) => e)
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() *
                          1.2
                      : 10000,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = rodIndex == 0;
                        final label = isIncome ? 'Gelir' : 'Gider';
                        return BarTooltipItem(
                          '$label\n₺${rod.toY.toInt()}',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _incomeExpenseData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _incomeExpenseData[value.toInt()].month,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₺${(value / 1000).toInt()}K',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _incomeExpenseData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.income.toDouble(),
                          color: Colors.green,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          gradient: LinearGradient(
                            colors: [Colors.green.shade300, Colors.green],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        BarChartRodData(
                          toY: data.expense.toDouble(),
                          color: Colors.red,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          gradient: LinearGradient(
                            colors: [Colors.red.shade300, Colors.red],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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

  Widget _buildServicePieChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.green.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gelir Dağılımı 💰',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Touch interaction
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _serviceDistributionData.map((data) {
                    return PieChartSectionData(
                      color: data.color,
                      value: data.value.toDouble(),
                      title: '${data.value.toInt()}%',
                      radius: 50,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _serviceDistributionData.map((data) {
                return _buildLegendItem(data.label, data.color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.red.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gider Dağılımı 📊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Touch interaction
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _expenseDistributionData.map((data) {
                    return PieChartSectionData(
                      color: data.color,
                      value: data.value.toDouble(),
                      title: '${data.value.toInt()}%',
                      radius: 50,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _expenseDistributionData.map((data) {
                return _buildLegendItem(data.label, data.color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.purple.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Çalışan Performansı 👥',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._employeePerformanceData.map((employee) {
              final maxRevenue = _employeePerformanceData
                  .map((e) => e.revenue)
                  .reduce((a, b) => a > b ? a : b);
              final percentage = employee.revenue / maxRevenue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${employee.appointments} randevu • ₺${NumberFormat('#,##0').format(employee.revenue)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
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
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTopServicesTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.blue.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'En Çok Kazandıran Hizmetler ⭐',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topServicesData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Henüz veri yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _topServicesData.map((service) {
                  final maxRevenue = _topServicesData.isNotEmpty
                      ? _topServicesData.first.revenue
                      : 1.0;
                  final percentage = service.revenue / maxRevenue;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₺${NumberFormat('#,##0').format(service.revenue)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.purple.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'En Değerli Müşteriler 👑',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topCustomersData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Henüz veri yok',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _topCustomersData.map((customer) {
                  final maxPayment = _topCustomersData.isNotEmpty
                      ? _topCustomersData.first.totalPayment
                      : 1.0;
                  final percentage = customer.totalPayment / maxPayment;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₺${NumberFormat('#,##0').format(customer.totalPayment)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text(
          'Raporlar & Analizler 📈',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Verileri Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapor dışa aktarma özelliği yakında! 📄'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Raporu Dışa Aktar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Raporlar hazırlanıyor... 📊',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Filtreler
                _buildFilterRow(),
                const SizedBox(height: 24),

                // Özet Kartlar
                _buildSummaryCards(),
                const SizedBox(height: 24),

                // Gelir-Gider Grafiği
                _buildIncomeExpenseChart(),
                const SizedBox(height: 24),

                // Pie Chart'lar
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gelir Dağılımı
                          Expanded(child: _buildServicePieChart()),
                          const SizedBox(width: 16),

                          // Gider Dağılımı
                          Expanded(child: _buildExpensePieChart()),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildServicePieChart(),
                          const SizedBox(height: 16),
                          _buildExpensePieChart(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Çalışan Performansı
                _buildEmployeePerformanceChart(),
                const SizedBox(height: 24),

                // Tablolar
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En Çok Kazandıran Hizmetler
                          Expanded(child: _buildTopServicesTable()),
                          const SizedBox(width: 16),

                          // En Değerli Müşteriler
                          Expanded(child: _buildTopCustomersTable()),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildTopServicesTable(),
                          const SizedBox(height: 16),
                          _buildTopCustomersTable(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

// Veri modelleri
class BarData {
  final String month;
  final int income;
  final int expense;

  BarData(this.month, this.income, this.expense);
}

class PieData {
  final String label;
  final int value;
  final Color color;

  PieData(this.label, this.value, this.color);
}

class EmployeePerformance {
  final String name;
  final int appointments;
  final double revenue;

  EmployeePerformance(this.name, this.appointments, this.revenue);
}

class TopService {
  final String name;
  final double revenue;

  TopService(this.name, this.revenue);
}

class TopCustomer {
  final String name;
  final double totalPayment;

  TopCustomer(this.name, this.totalPayment);
}
