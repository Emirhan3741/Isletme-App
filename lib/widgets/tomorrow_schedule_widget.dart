import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/daily_summary_service.dart';
import '../core/constants/app_constants.dart';

class TomorrowScheduleWidget extends StatefulWidget {
  const TomorrowScheduleWidget({super.key});

  @override
  State<TomorrowScheduleWidget> createState() => _TomorrowScheduleWidgetState();
}

class _TomorrowScheduleWidgetState extends State<TomorrowScheduleWidget> {
  final DailySummaryService _summaryService = DailySummaryService();
  Map<String, int>? _tomorrowSummary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTomorrowSummary();
  }

  Future<void> _loadTomorrowSummary() async {
    setState(() => _loading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final summary = await _summaryService.getTomorrowSummaryForUser(user.uid);
        setState(() {
          _tomorrowSummary = summary;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Yarın özeti yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    
    return Row(
      children: [
        Icon(
          Icons.schedule,
          color: AppConstants.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yarın için Planlananlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.textLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadTomorrowSummary,
          icon: const Icon(Icons.refresh),
          color: AppConstants.textLight,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tomorrowSummary == null || _tomorrowSummary!['total'] == 0) {
      return _buildEmptyState();
    }

    return _buildSummaryContent();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Yarın için planlanmış işlem yok',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppConstants.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni işlemler ekleyebilir veya mevcut planlarınızı düzenleyebilirsiniz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    final total = _tomorrowSummary!['total'] ?? 0;
    
    return Column(
      children: [
        // Toplam sayı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Column(
            children: [
              Text(
                total.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              Text(
                'toplam işlem',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        // Detaylar
        _buildDetailsList(),
      ],
    );
  }

  Widget _buildDetailsList() {
    final items = <Widget>[];
    
    final typeMapping = {
      'appointment': {'name': 'Randevu', 'icon': Icons.calendar_today, 'emoji': '📅'},
      'hearing': {'name': 'Duruşma', 'icon': Icons.gavel, 'emoji': '🧑‍⚖️'},
      'meeting': {'name': 'Görüşme', 'icon': Icons.meeting_room, 'emoji': '💼'},
      'task': {'name': 'Görev', 'icon': Icons.task_alt, 'emoji': '✅'},
      'event': {'name': 'Etkinlik', 'icon': Icons.event, 'emoji': '🎉'},
      'note': {'name': 'Not', 'icon': Icons.note, 'emoji': '📝'},
    };
    
    typeMapping.forEach((type, info) {
      final count = _tomorrowSummary![type] ?? 0;
      if (count > 0) {
        items.add(_buildDetailItem(
          emoji: info['emoji'] as String,
          name: info['name'] as String,
          count: count,
          icon: info['icon'] as IconData,
        ));
      }
    });
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(children: items);
  }

  Widget _buildDetailItem({
    required String emoji,
    required String name,
    required int count,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}