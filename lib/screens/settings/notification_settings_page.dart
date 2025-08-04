import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/notification_preferences.dart';
import '../../services/notification_preferences_service.dart';
import '../../services/daily_summary_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();
  final DailySummaryService _summaryService = DailySummaryService();
  
  NotificationPreferences? _preferences;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    try {
      final preferences = await _preferencesService.getUserPreferences();
      setState(() {
        _preferences = preferences;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackBar('Ayarlar yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _updatePreference({
    required String key,
    required bool value,
    required String description,
  }) async {
    if (_updating) return;
    
    setState(() => _updating = true);
    
    try {
      await _preferencesService.updateSpecificPreference(
        preferenceKey: key,
        value: value,
      );
      
      // Local state'i güncelle
      setState(() {
        _preferences = _updateLocalPreference(key, value);
      });
      
      _showSuccessSnackBar('$description ${value ? 'açıldı' : 'kapatıldı'}');
    } catch (e) {
      _showErrorSnackBar('Ayar güncellenirken hata oluştu: $e');
    } finally {
      setState(() => _updating = false);
    }
  }

  NotificationPreferences _updateLocalPreference(String key, bool value) {
    if (_preferences == null) return NotificationPreferences.defaultPreferences;
    
    switch (key) {
      case 'dailySummary':
        return _preferences!.copyWith(dailySummary: value);
      case 'appointmentReminder':
        return _preferences!.copyWith(appointmentReminder: value);
      case 'meetingReminder':
        return _preferences!.copyWith(meetingReminder: value);
      case 'hearingReminder':
        return _preferences!.copyWith(hearingReminder: value);
      case 'todoReminder':
        return _preferences!.copyWith(todoReminder: value);
      case 'eventReminder':
        return _preferences!.copyWith(eventReminder: value);
      case 'noteReminder':
        return _preferences!.copyWith(noteReminder: value);
      default:
        return _preferences!;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPreferences,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading ? _buildLoadingView() : _buildSettingsView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildSettingsView() {
    if (_preferences == null) {
      return const Center(
        child: Text('Ayarlar yüklenemedi'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildDailySummarySection(),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildReminderSection(),
          const SizedBox(height: AppConstants.paddingLarge),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bildirim Yönetimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hangi tür bildirimler almak istediğinizi ayarlayabilirsiniz. '
              'Ayarlarınız anında kaydedilir ve tüm cihazlarınızda geçerli olur.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📅',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Günlük Özet',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Her gün saat 19:00\'da ertesi günün planınızı özetleyen bildirim',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Günlük Özet Bildirimi',
              subtitle: 'Saat 19:00\'da yarının planı',
              value: _preferences!.dailySummary,
              onChanged: (value) => _updatePreference(
                key: 'dailySummary',
                value: value,
                description: 'Günlük özet',
              ),
              icon: Icons.today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '⏰',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hatırlatmalar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'İşlemlerinizden 1 saat önce gelen hatırlatma bildirimleri',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Randevu Hatırlatması',
              subtitle: '1 saat önceden randevu bildirimi',
              value: _preferences!.appointmentReminder,
              onChanged: (value) => _updatePreference(
                key: 'appointmentReminder',
                value: value,
                description: 'Randevu hatırlatması',
              ),
              icon: Icons.calendar_today,
            ),
            _buildSwitchTile(
              title: 'Görüşme Hatırlatması',
              subtitle: '1 saat önceden görüşme bildirimi',
              value: _preferences!.meetingReminder,
              onChanged: (value) => _updatePreference(
                key: 'meetingReminder',
                value: value,
                description: 'Görüşme hatırlatması',
              ),
              icon: Icons.meeting_room,
            ),
            _buildSwitchTile(
              title: 'Duruşma Hatırlatması',
              subtitle: '1 saat önceden duruşma bildirimi',
              value: _preferences!.hearingReminder,
              onChanged: (value) => _updatePreference(
                key: 'hearingReminder',
                value: value,
                description: 'Duruşma hatırlatması',
              ),
              icon: Icons.gavel,
            ),
            _buildSwitchTile(
              title: 'Görev Hatırlatması',
              subtitle: '1 saat önceden to-do bildirimi',
              value: _preferences!.todoReminder,
              onChanged: (value) => _updatePreference(
                key: 'todoReminder',
                value: value,
                description: 'Görev hatırlatması',
              ),
              icon: Icons.task_alt,
            ),
            _buildSwitchTile(
              title: 'Etkinlik Hatırlatması',
              subtitle: '1 saat önceden etkinlik bildirimi',
              value: _preferences!.eventReminder,
              onChanged: (value) => _updatePreference(
                key: 'eventReminder',
                value: value,
                description: 'Etkinlik hatırlatması',
              ),
              icon: Icons.event,
            ),
            _buildSwitchTile(
              title: 'Not Hatırlatması',
              subtitle: '1 saat önceden not bildirimi',
              value: _preferences!.noteReminder,
              onChanged: (value) => _updatePreference(
                key: 'noteReminder',
                value: value,
                description: 'Not hatırlatması',
              ),
              icon: Icons.note,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value ? AppConstants.primaryColor : AppConstants.textLight,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: value ? AppConstants.textPrimary : AppConstants.textLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppConstants.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: _updating ? null : onChanged,
        activeColor: AppConstants.primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '⚡',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hızlı İşlemler',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updating ? null : () async {
                      setState(() => _updating = true);
                      try {
                        await _preferencesService.resetToDefault();
                        await _loadPreferences();
                        _showSuccessSnackBar('Ayarlar varsayılana sıfırlandı');
                      } catch (e) {
                        _showErrorSnackBar('Sıfırlama hatası: $e');
                      }
                      setState(() => _updating = false);
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Varsayılan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: AppConstants.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _updating ? null : () async {
                      setState(() => _updating = true);
                      try {
                        await _preferencesService.disableAllNotifications();
                        await _loadPreferences();
                        _showSuccessSnackBar('Tüm bildirimler kapatıldı');
                      } catch (e) {
                        _showErrorSnackBar('Kapatma hatası: $e');
                      }
                      setState(() => _updating = false);
                    },
                    icon: const Icon(Icons.notifications_off),
                    label: const Text('Tümünü Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updating ? null : () async {
                  setState(() => _updating = true);
                  try {
                    await _summaryService.sendDailySummaryNow();
                    _showSuccessSnackBar('Test özet bildirimi gönderildi');
                  } catch (e) {
                    _showErrorSnackBar('Test hatası: $e');
                  }
                  setState(() => _updating = false);
                },
                icon: const Icon(Icons.send),
                label: const Text('Test Özet Gönder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}