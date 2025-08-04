import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_schedule_item.dart';
import '../services/daily_schedule_service.dart';
import '../core/constants/app_constants.dart';

class DailyScheduleWidget extends StatefulWidget {
  final bool showOnlyUpcoming;
  final int maxItems;

  const DailyScheduleWidget({
    super.key,
    this.showOnlyUpcoming = false,
    this.maxItems = 10,
  });

  @override
  State<DailyScheduleWidget> createState() => _DailyScheduleWidgetState();
}

class _DailyScheduleWidgetState extends State<DailyScheduleWidget> {
  final DailyScheduleService _scheduleService = DailyScheduleService();
  List<DailyScheduleItem> _items = [];
  bool _loading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    
    try {
      List<DailyScheduleItem> items;
      if (widget.showOnlyUpcoming) {
        items = await _scheduleService.getUpcomingSchedule();
      } else {
        items = await _scheduleService.getTodaySchedule();
      }
      
      setState(() {
        _items = items.take(widget.maxItems).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Günlük program yüklenirken hata: $e');
    }
  }

  List<DailyScheduleItem> get _filteredItems {
    if (_selectedFilter == 'all') return _items;
    return _items.where((item) => item.itemType == _selectedFilter).toList();
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
            _buildFilterTabs(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          widget.showOnlyUpcoming ? Icons.schedule : Icons.today,
          color: AppConstants.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.showOnlyUpcoming ? 'Yaklaşan İşlemler' : 'Bugün Planlananlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (!widget.showOnlyUpcoming)
                Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textLight,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadSchedule,
          icon: const Icon(Icons.refresh),
          color: AppConstants.textLight,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'name': 'Tümü', 'icon': Icons.list},
      {'key': 'appointment', 'name': 'Randevu', 'icon': Icons.calendar_today},
      {'key': 'hearing', 'name': 'Duruşma', 'icon': Icons.gavel},
      {'key': 'meeting', 'name': 'Görüşme', 'icon': Icons.meeting_room},
      {'key': 'task', 'name': 'Görev', 'icon': Icons.task_alt},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : AppConstants.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    filter['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              selectedColor: AppConstants.primaryColor,
              backgroundColor: Colors.grey[100],
            ),
          );
        },
      ),
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

    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: filteredItems.map((item) => _buildScheduleItem(item)).toList(),
    );
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
            widget.showOnlyUpcoming ? 'Yaklaşan işlem yok' : 'Bugün planlanmış işlem yok',
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

  Widget _buildScheduleItem(DailyScheduleItem item) {
    final Color panelColor = AppConstants.panelColors[item.panel] ?? AppConstants.primaryColor;
    final bool isPastDue = item.startTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: panelColor,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        color: isPastDue ? Colors.grey[50] : Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: panelColor.withValues(alpha: 0.1),
          child: Text(
            item.typeEmoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isPastDue ? AppConstants.textLight : AppConstants.textPrimary,
                  decoration: isPastDue ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.documentAttached)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.attach_file,
                  size: 12,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isPastDue ? AppConstants.textLight : panelColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPastDue ? AppConstants.textLight : AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPastDue ? Colors.grey[200] : panelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPastDue ? 'Geçti' : item.remainingTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isPastDue ? AppConstants.textLight : panelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (item.customerName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: AppConstants.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.customerName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textLight,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  item.panelEmoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  item.typeDisplayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildItemActions(item),
        onTap: () => _showItemDetails(item),
      ),
    );
  }

  Widget _buildItemActions(DailyScheduleItem item) {
    if (item.status == 'completed') {
      return Icon(
        Icons.check_circle,
        color: Colors.green[600],
        size: 20,
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: AppConstants.textLight,
      ),
      onSelected: (value) => _handleItemAction(item, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(Icons.check, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('Tamamlandı'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('İptal Et'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleItemAction(DailyScheduleItem item, String action) async {
    try {
      switch (action) {
        case 'complete':
          await _scheduleService.markAsCompleted(item);
          break;
        case 'cancel':
          await _scheduleService.markAsCanceled(item);
          break;
      }
      _loadSchedule(); // Refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'complete' ? 'İşlem tamamlandı' : 'İşlem iptal edildi'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem güncellenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showItemDetails(DailyScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(item.typeEmoji),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tür', item.typeDisplayName),
            _buildDetailRow('Panel', '${item.panelEmoji} ${item.panel}'),
            _buildDetailRow('Saat', '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}'),
            if (item.customerName != null)
              _buildDetailRow('Müşteri', item.customerName!),
            if (item.description != null)
              _buildDetailRow('Açıklama', item.description!),
            _buildDetailRow('Durum', item.status),
            _buildDetailRow('Kalan Süre', item.remainingTime),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}