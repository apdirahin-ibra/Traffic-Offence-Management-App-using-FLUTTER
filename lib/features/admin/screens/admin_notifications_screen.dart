import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/audit_log_model.dart';
import '../../../widgets/glass_card.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return StreamBuilder<List<AuditLogModel>>(
      stream: db.auditLogsStream(limit: 60),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Failed to load notifications: ${snap.error}',
                style: const TextStyle(color: TomsColors.destructive),
              ),
            ),
          );
        }

        final logs = snap.data ?? const <AuditLogModel>[];
        final notificationLogs = logs.where(_isNotificationWorthy).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Recent operational alerts and important system activity.',
                style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground),
              ),
              const SizedBox(height: 24),
              if (notificationLogs.isEmpty)
                const GlassCard(
                  elevated: true,
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No notifications yet.')),
                )
              else
                GlassCard(
                  elevated: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      for (var index = 0; index < notificationLogs.length; index++) ...[
                        _NotificationTile(log: notificationLogs[index]),
                        if (index != notificationLogs.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isNotificationWorthy(AuditLogModel log) {
    const importantActions = {
      'payment',
      'appeal_status_update',
      'appeal_message',
      'driver_auto_suspended',
      'admin_suspend_license',
      'admin_restore_license',
      'issue_fine',
      'admin_create_user',
      'admin_deactivate_user',
      'admin_reactivate_user',
    };
    return importantActions.contains(log.action);
  }
}

class _NotificationTile extends StatelessWidget {
  final AuditLogModel log;

  const _NotificationTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(log.action);
    final timestamp = log.timestamp;
    final timeLabel = timestamp == null
        ? 'Just now'
        : '${timestamp.year}-${_two(timestamp.month)}-${_two(timestamp.day)} ${_two(timestamp.hour)}:${_two(timestamp.minute)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(meta.icon, color: meta.color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(log.details, style: const TextStyle(color: TomsColors.foreground)),
              const SizedBox(height: 6),
              Text(timeLabel, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
            ],
          ),
        ),
      ],
    );
  }

  _NotificationMeta _metaFor(String action) {
    switch (action) {
      case 'payment':
        return const _NotificationMeta('Payment Received', Icons.payments_outlined, TomsColors.success);
      case 'appeal_status_update':
      case 'appeal_message':
        return const _NotificationMeta('Appeal Activity', Icons.forum_outlined, TomsColors.accent);
      case 'driver_auto_suspended':
      case 'admin_suspend_license':
        return const _NotificationMeta('License Suspended', Icons.gpp_bad_outlined, TomsColors.destructive);
      case 'admin_restore_license':
        return const _NotificationMeta('License Restored', Icons.verified_outlined, TomsColors.success);
      case 'issue_fine':
        return const _NotificationMeta('New Fine Issued', Icons.receipt_long_outlined, TomsColors.primary);
      default:
        return const _NotificationMeta('Admin Activity', Icons.notifications_active_outlined, TomsColors.primarySoft);
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _NotificationMeta {
  final String title;
  final IconData icon;
  final Color color;

  const _NotificationMeta(this.title, this.icon, this.color);
}
