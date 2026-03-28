import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/audit_log_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _db = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _actionFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuditLogModel>>(
      stream: _db.auditLogsStream(limit: 200),
      builder: (context, logsSnap) {
        return StreamBuilder<List<UserModel>>(
          stream: _db.allUsersStream(),
          builder: (context, usersSnap) {
            if (logsSnap.connectionState == ConnectionState.waiting || usersSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (logsSnap.hasError) {
              return _errorView('Unable to load audit logs', '${logsSnap.error}');
            }
            if (usersSnap.hasError) {
              return _errorView('Unable to load user directory', '${usersSnap.error}');
            }

            final logs = logsSnap.data ?? const <AuditLogModel>[];
            final users = {
              for (final user in (usersSnap.data ?? const <UserModel>[])) user.uid: user,
            };
            final filteredLogs = _filterLogs(logs, users);
            final actionOptions = _buildActionOptions(logs);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Track administrative activity across the system in real time.', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search by action, details, or actor...',
                            prefixIcon: Icon(Icons.search, size: 18),
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _actionFilter,
                        items: actionOptions
                            .map((action) => DropdownMenuItem<String>(
                                  value: action,
                                  child: Text(action == 'all' ? 'All actions' : action),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _actionFilter = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _metricCard('Visible Logs', '${filteredLogs.length}', Icons.history, TomsColors.primary),
                      _metricCard('All Loaded', '${logs.length}', Icons.storage_outlined, TomsColors.success),
                      _metricCard('Unique Actions', '${actionOptions.length - 1}', Icons.tune, TomsColors.accent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    elevated: true,
                    padding: const EdgeInsets.all(20),
                    child: filteredLogs.isEmpty
                        ? _emptyView()
                        : Column(
                            children: filteredLogs.map((log) => _logRow(log, users[log.userId])).toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<AuditLogModel> _filterLogs(List<AuditLogModel> logs, Map<String, UserModel> users) {
    final search = _searchCtrl.text.trim().toLowerCase();

    return logs.where((log) {
      final actor = users[log.userId];
      final actorText = actor == null ? log.userId : '${actor.name} ${actor.email} ${actor.role}';
      final matchesAction = _actionFilter == 'all' || log.action == _actionFilter;
      final matchesSearch = search.isEmpty ||
          log.action.toLowerCase().contains(search) ||
          log.details.toLowerCase().contains(search) ||
          actorText.toLowerCase().contains(search);
      return matchesAction && matchesSearch;
    }).toList();
  }

  List<String> _buildActionOptions(List<AuditLogModel> logs) {
    final actions = logs.map((log) => log.action).where((action) => action.trim().isNotEmpty).toSet().toList()..sort();
    return ['all', ...actions];
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logRow(AuditLogModel log, UserModel? actor) {
    final actorName = actor?.name ?? 'Unknown User';
    final actorMeta = actor == null ? log.userId : '${actor.role.toUpperCase()} • ${actor.email}';
    final actionLabel = log.action.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TomsColors.border.withValues(alpha: 0.9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: TomsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 20, color: TomsColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(actionLabel),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(actorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TomsColors.foreground)),
                      const SizedBox(height: 2),
                      Text(actorMeta, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                    ],
                  ),
                ),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground),
                ),
              ],
            ),
            if (log.details.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TomsColors.secondary.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(log.details, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off, size: 42, color: TomsColors.mutedForeground),
          const SizedBox(height: 12),
          const Text('No audit logs match the current filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Try clearing the search box or switching the action filter.',
            style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorView(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: TomsColors.destructive),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Pending time';
    final local = timestamp.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute $period';
  }
}
