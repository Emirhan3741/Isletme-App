import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/feedback_utils.dart';

class VeterinaryReportsPage extends StatefulWidget {
  const VeterinaryReportsPage({super.key});

  @override
  State<VeterinaryReportsPage> createState() => _VeterinaryReportsPageState();
}

class _VeterinaryReportsPageState extends State<VeterinaryReportsPage> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  String _selectedReportType = 'özet';

  final List<Map<String, String>> _reportTypes = [
    {'value': 'özet', 'label': 'Genel Özet'},
    {'value': 'gelir', 'label': 'Gelir Analizi'},
    {'value': 'hasta', 'label': 'Hasta İstatistikleri'},
    {'value': 'stok', 'label': 'Stok Durumu'},
    {'value': 'performans', 'label': 'Performans'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildFilterSection(),
          Expanded(child: _buildReportsContent()),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
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
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Raporlar & Analiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Kliniğinizin performansını analiz edin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.download),
            label: const Text('Dışa Aktar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _reportTypes.firstWhere(
                            (r) => r['value'] == _selectedReportType)['label']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
              itemBuilder: (context) => _reportTypes.map((type) {
                return PopupMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onSelected: (value) =>
                  setState(() => _selectedReportType = value),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            label: Text(
              '${_selectedDateRange.start.day}/${_selectedDateRange.start.month} - ${_selectedDateRange.end.day}/${_selectedDateRange.end.month}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    switch (_selectedReportType) {
      case 'özet':
        return _buildGeneralSummary();
      case 'gelir':
        return _buildIncomeAnalysis();
      case 'hasta':
        return _buildPatientStatistics();
      case 'stok':
        return _buildStockStatus();
      case 'performans':
        return _buildPerformanceReport();
      default:
        return _buildGeneralSummary();
    }
  }

  Widget _buildGeneralSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Toplam Hasta',
            '0',
            Icons.pets,
            Colors.blue,
            _getTotalPatients(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Bu Ay Gelir',
            '₺0',
            Icons.trending_up,
            Colors.green,
            _getMonthlyIncome(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Bu Ay İşlem',
            '0',
            Icons.medical_services,
            Colors.orange,
            _getMonthlyTreatments(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Kritik Stok',
            '0',
            Icons.warning,
            Colors.red,
            _getCriticalStock(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String defaultValue, IconData icon,
      Color color, Future<String> valueFuture) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FutureBuilder<String>(
              future: valueFuture,
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? defaultValue,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Ortalama İşlem Ücreti', '₺0', Icons.payment),
              ),
              Expanded(
                child: _buildStatItem(
                    'En Çok Tedavi', 'Genel Muayene', Icons.healing),
              ),
              Expanded(
                child: _buildStatItem('Aktif Hasta', '0', Icons.favorite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Aktiviteler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
              'Yeni hasta kaydı: Max', '2 saat önce', Icons.pets),
          _buildActivityItem(
              'Aşı işlemi tamamlandı', '4 saat önce', Icons.vaccines),
          _buildActivityItem(
              'Stok güncellendi', '6 saat önce', Icons.inventory),
          _buildActivityItem(
              'Ödeme alındı: ₺250', '8 saat önce', Icons.payment),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeAnalysis() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            Text(
              'Gelir Analizi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gelir grafikleri ve trend analizleri burada gösterilecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '💡 fl_chart paketi eklendiğinde detaylı grafikler görüntülenecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientStatistics() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            Text(
              'Hasta İstatistikleri',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hasta demografileri, türler ve tedavi istatistikleri',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '💡 Hasta dağılımı, yaş grupları ve tedavi başarı oranları gösterilecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatus() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            Text(
              'Stok Durumu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok seviyeleri, kritik ürünler ve tedarik analizi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '💡 Stok rotasyonu, kritik seviyeler ve tedarikçi performansı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceReport() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            Text(
              'Performans Raporu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klinik performansı ve verimlilik metrikleri',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '💡 Hasta başına ortalama gelir, tedavi süreleri ve memnuniyet oranları',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getTotalPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0';

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_patients')
          .where('kullaniciId', isEqualTo: user.uid)
          .where('aktif', isEqualTo: true)
          .get();

      return snapshot.docs.length.toString();
    } catch (e) {
      return '0';
    }
  }

  Future<String> _getMonthlyIncome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '₺0';

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_payments')
          .where('userId', isEqualTo: user.uid)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      return '₺${total.toStringAsFixed(0)}';
    } catch (e) {
      return '₺0';
    }
  }

  Future<String> _getMonthlyTreatments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0';

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_treatments')
          .where('userId', isEqualTo: user.uid)
          .where('treatmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('treatmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      return snapshot.docs.length.toString();
    } catch (e) {
      return '0';
    }
  }

  Future<String> _getCriticalStock() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0';

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_inventory')
          .where('userId', isEqualTo: user.uid)
          .get();

      int criticalCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currentStock = data['currentStock'] as int? ?? 0;
        final criticalLevel = data['criticalLevel'] as int? ?? 5;
        if (currentStock <= criticalLevel) {
          criticalCount++;
        }
      }

      return criticalCount.toString();
    } catch (e) {
      return '0';
    }
  }

  void _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  void _exportReport() {
    // TODO: PDF/Excel export functionality
    FeedbackUtils.showInfo(
        context, 'Rapor dışa aktarma özelliği yakında gelecek');
  }
}
