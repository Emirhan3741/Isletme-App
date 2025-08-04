import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';

import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.notifications),
            const SizedBox(width: 8),
            // Okunmamış bildirim sayısı badge'i
            StreamBuilder<int>(
              stream: _notificationService
                  .getUnreadNotificationCountStream(user?.uid ?? ''),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                if (unreadCount > 0) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: l10n.markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllNotifications,
            tooltip: l10n.clearAllNotifications,
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(l10n.userNotLoggedIn))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('${l10n.error}: ${snapshot.error}'),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notificationDoc = notifications[index];
                    final notification =
                        notificationDoc.data() as Map<String, dynamic>;

                    return _buildNotificationCard(
                      context,
                      notificationDoc.id,
                      notification,
                      l10n,
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestNotification,
        child: const Icon(Icons.add_alert),
        tooltip: l10n.createTestNotification,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            l10n.noNotifications,
            style: const TextStyle(
              fontSize: 18,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            l10n.notificationsWillAppearHere,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    String notificationId,
    Map<String, dynamic> notification,
    AppLocalizations l10n,
  ) {
    final createdAt = (notification['createdAt'] as Timestamp?)?.toDate();
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'info';
    final title = notification['title'] ?? '';
    final message = notification['message'] ?? '';

    IconData getTypeIcon() {
      switch (type) {
        case 'appointment':
          return Icons.event;
        case 'reminder':
          return Icons.alarm;
        case 'payment':
          return Icons.payment;
        case 'warning':
          return Icons.warning;
        case 'success':
          return Icons.check_circle;
        case 'error':
          return Icons.error;
        default:
          return Icons.info;
      }
    }

    Color getTypeColor() {
      switch (type) {
        case 'appointment':
          return Colors.blue;
        case 'reminder':
          return Colors.orange;
        case 'payment':
          return Colors.green;
        case 'warning':
          return Colors.amber;
        case 'success':
          return Colors.green;
        case 'error':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getTypeColor().withValues(alpha: 0.1),
          child: Icon(
            getTypeIcon(),
            color: getTypeColor(),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color:
                isRead ? AppConstants.textSecondary : AppConstants.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: isRead
                      ? AppConstants.textLight
                      : AppConstants.textSecondary,
                ),
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textLight,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'markAsRead':
                _markAsRead(notificationId, !isRead);
                break;
              case 'delete':
                _deleteNotification(notificationId);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'markAsRead',
              child: Text(isRead ? l10n.markAsUnread : l10n.markAsRead),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.delete),
            ),
          ],
        ),
        onTap: () => _markAsRead(notificationId, true),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId, bool isRead) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': isRead});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllNotifications),
        content: Text(l10n.clearAllNotificationsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );

    if (confirmed == true && user != null) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user!.uid)
            .get();

        for (final doc in notifications.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  Future<void> _createSampleNotification() async {
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user!.uid,
        'title': l10n.createTestNotification,
        'message':
            '${l10n.createTestNotification} - ${DateTime.now().toString()}',
        'type': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createTestNotification)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.markAllAsRead)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _createTestNotification() async {
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      await _notificationService.createUserNotification(
        userId: user!.uid,
        title: l10n.createTestNotification,
        message:
            '${l10n.createTestNotification} - ${DateTime.now().toString()}',
        type: 'info',
        additionalData: {
          'source': 'manual_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.createTestNotification)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }
}
