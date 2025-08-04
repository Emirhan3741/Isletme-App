import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class SportsReportsPage extends StatefulWidget {
  const SportsReportsPage({super.key});

  @override
  State<SportsReportsPage> createState() => _SportsReportsPageState();
}

class _SportsReportsPageState extends State<SportsReportsPage> {
  String _selectedPeriod = 'Bu Ay';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  // 📊 Rapor verileri
  Map<String, dynamic> _reportData = {
    'totalSessions': 0,
    'activeMembers': 0,
    'monthlyRevenue': 0.0,
    'completionRate': 0.0,
    'popularServices': <Map<String, dynamic>>[],
    'weeklyData': <Map<String, dynamic>>[],
    'membershipStats': <Map<String, dynamic>>[],
    'trainerPerformance': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  // 🔥 Firebase'den rapor verilerini yükle
  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('❌ Kullanıcı oturumu bulunamadı');
      }

      // Paralel veri yükleme
      final results = await Future.wait([
        _loadSessionStats(user.uid),
        _loadMemberStats(user.uid),
        _loadRevenueStats(user.uid),
        _loadServiceStats(user.uid),
        _loadWeeklyStats(user.uid),
        _loadTrainerStats(user.uid),
      ]);

      // 🔧 TIP DÖNÜŞÜMÜ - Object'leri Map'e cast ediyoruz
      final sessionStats = results[0] as Map<String, dynamic>;
      final memberStats = results[1] as Map<String, dynamic>;
      final revenueStats = results[2] as Map<String, dynamic>;
      final popularServices = results[3] as List<Map<String, dynamic>>;
      final weeklyData = results[4] as List<Map<String, dynamic>>;
      final trainerPerformance = results[5] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _reportData = {
            'totalSessions': sessionStats['totalSessions'] ?? 0,
            'activeMembers': memberStats['activeMembers'] ?? 0,
            'monthlyRevenue': revenueStats['monthlyRevenue'] ?? 0.0,
            'completionRate': sessionStats['completionRate'] ?? 0.0,
            'popularServices': popularServices,
            'weeklyData': weeklyData,
            'membershipStats': memberStats['membershipStats'] ?? [],
            'trainerPerformance': trainerPerformance,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Rapor verisi yükleme hatası: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📅 Seans istatistikleri
  Future<Map<String, dynamic>> _loadSessionStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sports_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final totalSessions = snapshot.docs.length;
      final completedSessions = snapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'totalSessions': totalSessions,
        'completionRate':
            totalSessions > 0 ? completedSessions / totalSessions : 0.0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Seans stats hatası: $e');
      return {'totalSessions': 0, 'completionRate': 0.0};
    }
  }

  // 👥 Üye istatistikleri
  Future<Map<String, dynamic>> _loadMemberStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sports_members')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final activeMembers = snapshot.docs.length;

      // Üyelik türü dağılımı
      final membershipTypes = <String, int>{};
      for (final doc in snapshot.docs) {
        final type = doc.data()['membershipType'] ?? 'Bilinmiyor';
        membershipTypes[type] = (membershipTypes[type] ?? 0) + 1;
      }

      return {
        'activeMembers': activeMembers,
        'membershipStats': membershipTypes.entries
            .map((e) => {'type': e.key, 'count': e.value})
            .toList(),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Member stats hatası: $e');
      return {'activeMembers': 0, 'membershipStats': []};
    }
  }

  // 💰 Gelir istatistikleri
  Future<Map<String, dynamic>> _loadRevenueStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sports_payments')
          .where('userId', isEqualTo: userId)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('paymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      double totalRevenue = 0.0;
      for (final doc in snapshot.docs) {
        totalRevenue += (doc.data()['amount'] ?? 0.0) as double;
      }

      return {'monthlyRevenue': totalRevenue};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Revenue stats hatası: $e');
      return {'monthlyRevenue': 0.0};
    }
  }

  // 🏃‍♂️ Hizmet istatistikleri
  Future<List<Map<String, dynamic>>> _loadServiceStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sports_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final serviceStats = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final serviceName = doc.data()['serviceName'] ?? 'Bilinmiyor';
        final amount = (doc.data()['amount'] ?? 0.0) as double;

        if (!serviceStats.containsKey(serviceName)) {
          serviceStats[serviceName] = {
            'name': serviceName,
            'count': 0,
            'revenue': 0.0
          };
        }

        serviceStats[serviceName]!['count'] =
            serviceStats[serviceName]!['count'] + 1;
        serviceStats[serviceName]!['revenue'] =
            serviceStats[serviceName]!['revenue'] + amount;
      }

      final result = serviceStats.values.toList();
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return result.take(5).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Service stats hatası: $e');
      return [];
    }
  }

  // 📈 Haftalık veriler
  Future<List<Map<String, dynamic>>> _loadWeeklyStats(String userId) async {
    try {
      final weeklyData = <Map<String, dynamic>>[];
      final days = ['Pts', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];

      for (int i = 0; i < 7; i++) {
        final dayStart = _startDate.add(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));

        final snapshot = await FirebaseFirestore.instance
            .collection('sports_sessions')
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('date', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        final memberSnapshot = await FirebaseFirestore.instance
            .collection('sports_members')
            .where('userId', isEqualTo: userId)
            .where('joinDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('joinDate', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        weeklyData.add({
          'day': days[dayStart.weekday - 1],
          'sessions': snapshot.docs.length,
          'members': memberSnapshot.docs.length,
        });
      }

      return weeklyData;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Weekly stats hatası: $e');
      return [];
    }
  }

  // 🏃‍♂️ Antrenör performansı
  Future<List<Map<String, dynamic>>> _loadTrainerStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sports_sessions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .get();

      final trainerStats = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final trainerName = doc.data()['trainerName'] ?? 'Bilinmiyor';
        final rating = (doc.data()['rating'] ?? 0.0) as double;

        if (!trainerStats.containsKey(trainerName)) {
          trainerStats[trainerName] = {
            'name': trainerName,
            'sessions': 0,
            'totalRating': 0.0,
            'avgRating': 0.0,
          };
        }

        trainerStats[trainerName]!['sessions'] =
            trainerStats[trainerName]!['sessions'] + 1;
        trainerStats[trainerName]!['totalRating'] =
            trainerStats[trainerName]!['totalRating'] + rating;
      }

      // Ortalama rating hesapla
      for (final trainer in trainerStats.values) {
        final sessions = trainer['sessions'] as int;
        if (sessions > 0) {
          trainer['avgRating'] = (trainer['totalRating'] as double) / sessions;
        }
      }

      final result = trainerStats.values.toList();
      result.sort(
          (a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));

      return result.take(5).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Trainer stats hatası: $e');
      return [];
    }
  }

  // 📅 Tarih aralığı değiştir
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Bu Hafta':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Bu Ay':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'Son 3 Ay':
          _startDate = DateTime.now().subtract(const Duration(days: 90));
          break;
        case 'Bu Yıl':
          _startDate = DateTime(DateTime.now().year, 1, 1);
          break;
      }
      _endDate = DateTime.now();
    });
    _loadReportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Raporlar ve Analiz'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: _changePeriod,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Bu Hafta', child: Text('Bu Hafta')),
              const PopupMenuItem(value: 'Bu Ay', child: Text('Bu Ay')),
              const PopupMenuItem(value: 'Son 3 Ay', child: Text('Son 3 Ay')),
              const PopupMenuItem(value: 'Bu Yıl', child: Text('Bu Yıl')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📊 Özet kartları
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // 📈 Haftalık aktivite grafiği
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),

                    // 🏃‍♂️ Popüler hizmetler
                    _buildPopularServices(),
                    const SizedBox(height: 24),

                    // 👥 Üyelik türü dağılımı
                    _buildMembershipChart(),
                    const SizedBox(height: 24),

                    // 🏃‍♂️ Antrenör performansı
                    _buildTrainerPerformance(),
                  ],
                ),
              ),
            ),
    );
  }

  // 📊 Özet kartları
  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Text(
              'Özet ($_selectedPeriod)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'Toplam Seans',
              _reportData['totalSessions'].toString(),
              Icons.fitness_center,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Aktif Üye',
              _reportData['activeMembers'].toString(),
              Icons.people,
              Colors.green,
            ),
            _buildSummaryCard(
              'Aylık Gelir',
              '₺${NumberFormat('#,##0.00', 'tr_TR').format(_reportData['monthlyRevenue'])}',
              Icons.attach_money,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Tamamlanma',
              '%${(_reportData['completionRate'] * 100).toStringAsFixed(1)}',
              Icons.check_circle,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 📈 Haftalık aktivite grafiği
  Widget _buildWeeklyChart() {
    final weeklyData = _reportData['weeklyData'] as List<Map<String, dynamic>>;

    if (weeklyData.isEmpty) {
      return _buildEmptyChart('Haftalık Aktivite');
    }

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
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Haftalık Aktivite',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weeklyData.length) {
                          return Text(
                            weeklyData[index]['day'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['sessions'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange[700],
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏃‍♂️ Popüler hizmetler
  Widget _buildPopularServices() {
    final services =
        _reportData['popularServices'] as List<Map<String, dynamic>>;

    if (services.isEmpty) {
      return _buildEmptySection(
          'Popüler Hizmetler', 'Henüz hizmet verisi bulunmuyor');
    }

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
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Popüler Hizmetler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...services.map((service) => _buildServiceItem(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.orange[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] ?? 'Bilinmiyor',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${service['count']} seans • ₺${NumberFormat('#,##0.00', 'tr_TR').format(service['revenue'])}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${service['count']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 👥 Üyelik türü dağılımı
  Widget _buildMembershipChart() {
    final membershipStats =
        _reportData['membershipStats'] as List<Map<String, dynamic>>;

    if (membershipStats.isEmpty) {
      return _buildEmptySection(
          'Üyelik Dağılımı', 'Henüz üyelik verisi bulunmuyor');
    }

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
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Üyelik Türü Dağılımı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: membershipStats.asMap().entries.map((entry) {
                  final colors = [
                    Colors.orange,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.red
                  ];
                  return PieChartSectionData(
                    value: (entry.value['count'] ?? 0).toDouble(),
                    title: entry.value['type'] ?? 'Bilinmiyor',
                    color: colors[entry.key % colors.length],
                    radius: 80,
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
        ],
      ),
    );
  }

  // 🏃‍♂️ Antrenör performansı
  Widget _buildTrainerPerformance() {
    final trainers =
        _reportData['trainerPerformance'] as List<Map<String, dynamic>>;

    if (trainers.isEmpty) {
      return _buildEmptySection(
          'Antrenör Performansı', 'Henüz antrenör verisi bulunmuyor');
    }

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
          Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Antrenör Performansı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...trainers.map((trainer) => _buildTrainerItem(trainer)).toList(),
        ],
      ),
    );
  }

  Widget _buildTrainerItem(Map<String, dynamic> trainer) {
    final rating = (trainer['avgRating'] ?? 0.0) as double;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[100],
            child: Icon(Icons.person, color: Colors.orange[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainer['name'] ?? 'Bilinmiyor',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '${rating.toStringAsFixed(1)} • ${trainer['sessions']} seans',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${trainer['sessions']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 📊 Boş grafik
  Widget _buildEmptyChart(String title) {
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
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Henüz veri bulunmuyor',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 📊 Boş bölüm
  Widget _buildEmptySection(String title, String message) {
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
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Icon(Icons.data_usage, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
