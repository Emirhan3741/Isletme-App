import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdvancedReportPage extends StatefulWidget {
  final bool isAdmin;
  final List<String> employees;
  final List<String> services;
  final List<String> customerTags;
  const AdvancedReportPage({
    Key? key,
    required this.isAdmin,
    required this.employees,
    required this.services,
    required this.customerTags,
  }) : super(key: key);

  @override
  State<AdvancedReportPage> createState() => _AdvancedReportPageState();
}

class _AdvancedReportPageState extends State<AdvancedReportPage> {
  DateTimeRange? _dateRange;
  String? _selectedEmployee;
  String? _selectedService;
  String? _selectedTag;
  bool _isLoading = false;

  // Özet veriler
  double _income = 12000;
  double _expense = 8000;
  double _netProfit = 4000;
  final int _customerIncrease = 12;
  final int _totalAppointments = 145;
  final double _avgAppointmentValue = 85.5;

  // Grafik verileri
  final List<double> _monthlyIncome = [
    1000,
    2000,
    3000,
    4000,
    3500,
    5000,
    6000
  ];
  final List<double> _monthlyExpense = [
    800,
    1500,
    2500,
    3000,
    3200,
    4000,
    4200
  ];
  final List<Map<String, dynamic>> _categoryDistribution = [
    {'label': 'Randevu', 'value': 5000.0, 'color': Colors.blue},
    {'label': 'Ürün Satışı', 'value': 3000.0, 'color': Colors.orange},
    {'label': 'Kira', 'value': 2000.0, 'color': Colors.green},
    {'label': 'Fatura', 'value': 1000.0, 'color': Colors.purple},
  ];
  List<Map<String, dynamic>> _employeePerformance = [
    {'name': 'Ali Yılmaz', 'performance': 95.0, 'appointments': 45},
    {'name': 'Ayşe Demir', 'performance': 87.0, 'appointments': 38},
    {'name': 'Mehmet Kaya', 'performance': 92.0, 'appointments': 42},
    {'name': 'Fatma Şahin', 'performance': 79.0, 'appointments': 31},
  ];

  // Tablo verisi
  final List<Map<String, dynamic>> _tableData = [
    {
      'tarih': '01.06.2024',
      'tip': 'Gelir',
      'kategori': 'Randevu',
      'tutar': 500,
      'musteri': 'Ayşe Kaya'
    },
    {
      'tarih': '02.06.2024',
      'tip': 'Gider',
      'kategori': 'Kira',
      'tutar': 1000,
      'musteri': '-'
    },
    {
      'tarih': '03.06.2024',
      'tip': 'Gelir',
      'kategori': 'Ürün Satışı',
      'tutar': 800,
      'musteri': 'Mehmet Demir'
    },
    {
      'tarih': '04.06.2024',
      'tip': 'Gelir',
      'kategori': 'Randevu',
      'tutar': 650,
      'musteri': 'Fatma Şen'
    },
    {
      'tarih': '05.06.2024',
      'tip': 'Gider',
      'kategori': 'Malzeme',
      'tutar': 300,
      'musteri': '-'
    },
  ];

  void _applyFilters() {
    setState(() => _isLoading = true);

    // Simüle edilmiş filtreleme
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        if (_selectedEmployee != null && _selectedEmployee != 'Tümü') {
          _income = 6000;
          _expense = 4000;
          _netProfit = 2000;
          _employeePerformance = [
            {'name': _selectedEmployee!, 'value': 6000.0, 'appointments': 35},
          ];
        } else {
          _income = 12000;
          _expense = 8000;
          _netProfit = 4000;
          _employeePerformance = [
            {'name': 'Ahmet', 'value': 7000.0, 'appointments': 45},
            {'name': 'Ayşe', 'value': 4000.0, 'appointments': 32},
            {'name': 'Mehmet', 'value': 3000.0, 'appointments': 28},
          ];
        }
        _isLoading = false;
      });
    });
  }

  Future<void> _exportCsv() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV dışa aktarma başlatılıyor... 📄'),
          backgroundColor: Colors.blue,
        ),
      );

      // CSV export logic burada olacak
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV dosyası başarıyla oluşturuldu! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF dışa aktarma başlatılıyor... 📋'),
          backgroundColor: Colors.blue,
        ),
      );

      // PDF export logic burada olacak
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF dosyası başarıyla oluşturuldu! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterSection() {
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
                    color: const Color(0xFF1A73E8).withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gelişmiş Filtreler 🔧',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDateRangeButton(),
                if (widget.isAdmin) _buildEmployeeDropdown(),
                _buildServiceDropdown(),
                _buildTagDropdown(),
                _buildApplyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(
        _dateRange == null
            ? 'Tarih Aralığı'
            : '${DateFormat('dd.MM.yy').format(_dateRange!.start)} - ${DateFormat('dd.MM.yy').format(_dateRange!.end)}',
        style: const TextStyle(fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: const Color(0xFF1A73E8),
                    ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
        }
      },
    );
  }

  Widget _buildEmployeeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedEmployee,
        hint: const Text('Çalışan', style: TextStyle(fontSize: 14)),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tümü')),
          ...widget.employees
              .map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: (v) => setState(() => _selectedEmployee = v),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedService,
        hint: const Text('Hizmet', style: TextStyle(fontSize: 14)),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tümü')),
          ...widget.services
              .map((s) => DropdownMenuItem(value: s, child: Text(s))),
        ],
        onChanged: (v) => setState(() => _selectedService = v),
      ),
    );
  }

  Widget _buildTagDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedTag,
        hint: const Text('Müşteri Etiketi', style: TextStyle(fontSize: 14)),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tümü')),
          ...widget.customerTags
              .map((t) => DropdownMenuItem(value: t, child: Text(t))),
        ],
        onChanged: (v) => setState(() => _selectedTag = v),
      ),
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : const Icon(Icons.search, size: 18),
      label: Text(_isLoading ? 'Uygulanıyor...' : 'Filtreleri Uygula'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isLoading ? null : _applyFilters,
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Gelir',
                value: '₺${NumberFormat('#,##0').format(_income)}',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: '+%12 bu ay',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Gider',
                value: '₺${NumberFormat('#,##0').format(_expense)}',
                icon: Icons.trending_down,
                color: Colors.red,
                subtitle: '+%8 bu ay',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Net Kar',
                value: '₺${NumberFormat('#,##0').format(_netProfit)}',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
                subtitle: _netProfit >= 0 ? 'Kârlı' : 'Zararlı',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Toplam Randevu',
                value: _totalAppointments.toString(),
                icon: Icons.event,
                color: Colors.purple,
                subtitle: 'Bu dönem',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Ort. Randevu Değeri',
                value: '₺${_avgAppointmentValue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.teal,
                subtitle: 'Per randevu',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Müşteri Artışı',
                value: '+$_customerIncrease',
                icon: Icons.people,
                color: Colors.amber,
                subtitle: 'Bu ay',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // Gelir-Gider Line Chart
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: const Icon(Icons.show_chart,
                          color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Gelir & Gider Trendi 📈',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _monthlyIncome
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withValues(alpha: 25)),
                        ),
                        LineChartBarData(
                          spots: _monthlyExpense
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withValues(alpha: 25)),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text('₺${(value / 1000).toInt()}K',
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final aylar = [
                                'Oca',
                                'Şub',
                                'Mar',
                                'Nis',
                                'May',
                                'Haz',
                                'Tem'
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < aylar.length) {
                                return Text(aylar[value.toInt()],
                                    style: const TextStyle(fontSize: 10));
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
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: Colors.green, label: 'Gelir'),
                    const SizedBox(width: 24),
                    _LegendDot(color: Colors.red, label: 'Gider'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori Dağılımı Pie Chart
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
                              color: Colors.orange.withValues(alpha: 25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pie_chart,
                                color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kategori Dağılımı 🥧',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _categoryDistribution.map((d) {
                              return PieChartSectionData(
                                value: d['value'],
                                color: d['color'],
                                title:
                                    '${((d['value'] / _categoryDistribution.fold(0.0, (sum, item) => sum + item['value'])) * 100).toInt()}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _categoryDistribution.map((d) {
                          return _LegendDot(
                              color: d['color'], label: d['label']);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Çalışan Performansı Bar Chart
            if (widget.isAdmin)
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                              child: const Icon(Icons.people,
                                  color: Colors.purple, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Çalışan Performansı 👥',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups:
                                  _employeePerformance.asMap().entries.map((e) {
                                return BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value['value'],
                                      color: Colors.purple,
                                      width: 24,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('₺${(value / 1000).toInt()}K',
                                          style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() <
                                          _employeePerformance.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _employeePerformance[value.toInt()]
                                                ['name'],
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
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
                              gridData: FlGridData(
                                  show: true, drawVerticalLine: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart,
                          color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Detaylı İşlem Listesi 📋',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildExportButton('CSV', Icons.file_download, _exportCsv),
                    const SizedBox(width: 8),
                    _buildExportButton('PDF', Icons.picture_as_pdf, _exportPdf),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF5F9FC)),
                columns: const [
                  DataColumn(
                      label: Text('Tarih',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Tip',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Kategori',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Müşteri',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Tutar',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _tableData.map((row) {
                  final isIncome = row['tip'] == 'Gelir';
                  return DataRow(
                    cells: [
                      DataCell(Text(row['tarih'])),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? Colors.green.withValues(alpha: 25)
                                : Colors.red.withValues(alpha: 25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            row['tip'],
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(row['kategori'])),
                      DataCell(Text(row['musteri'])),
                      DataCell(
                        Text(
                          '₺${row['tutar']}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
      String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text(
          'Gelişmiş Raporlar ��',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filtreler
          _buildFilterSection(),
          const SizedBox(height: 24),

          // Özet Kartlar
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Grafikler
          _buildChartsSection(),
          const SizedBox(height: 24),

          // Veri Tablosu
          _buildDataTable(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool highlight;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: color, size: 18),
                ),
                if (highlight) const Text('⭐', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
}
