import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/appeal_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class AppealsManagementScreen extends StatefulWidget {
  const AppealsManagementScreen({super.key});

  @override
  State<AppealsManagementScreen> createState() => _AppealsManagementScreenState();
}

class _AppealsManagementScreenState extends State<AppealsManagementScreen> {
  final _db = FirestoreService();
  final _auth = AuthService();
  final _messageCtrl = TextEditingController();
  String? _selectedAppealId;
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(AppealModel appeal) async {
    final text = _messageCtrl.text.trim();
    final uid = _auth.currentUid;
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    try {
      await _db.addAppealMessage(
        appeal.id,
        AppealMessage(senderId: uid, text: text, timestamp: DateTime.now()),
        actorUserId: uid,
      );
      _messageCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(AppealModel appeal, String status) async {
    final uid = _auth.currentUid;
    await _db.updateAppealStatus(appeal.id, status, actorUserId: uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppealModel>>(
      stream: _db.allAppealsStream(),
      builder: (context, appealSnap) {
        if (appealSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
        }

        final appeals = appealSnap.data ?? const [];
        final selectedAppeal = _resolveSelectedAppeal(appeals);

        return StreamBuilder<List<UserModel>>(
          stream: _db.allUsersStream(),
          builder: (context, userSnap) {
            final users = {for (final user in (userSnap.data ?? const <UserModel>[])) user.uid: user};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appeals Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Review driver appeals and reply in chat', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 24),
                  if (appeals.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: const Center(child: Text('No appeals submitted yet', style: TextStyle(color: TomsColors.mutedForeground))),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 1000;
                        final list = _appealList(appeals, users);
                        final detail = _appealDetail(selectedAppeal, users);

                        if (stacked) {
                          return Column(
                            children: [
                              list,
                              const SizedBox(height: 16),
                              detail,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 360, child: list),
                            const SizedBox(width: 16),
                            Expanded(child: detail),
                          ],
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  AppealModel? _resolveSelectedAppeal(List<AppealModel> appeals) {
    if (appeals.isEmpty) return null;
    final selected = appeals.where((appeal) => appeal.id == _selectedAppealId).cast<AppealModel?>().firstOrNull;
    return selected ?? appeals.first;
  }

  Widget _appealList(List<AppealModel> appeals, Map<String, UserModel> users) {
    return Column(
      children: appeals.map((appeal) {
        final selected = appeal.id == (_selectedAppealId ?? appeals.first.id);
        final driver = users[appeal.driverId];
        final driverLicense = (driver?.licenseNumber ?? '').trim();
        final fineShortId = appeal.fineId.length > 5 ? 'FN-${appeal.fineId.substring(appeal.fineId.length - 5).toUpperCase()}' : appeal.fineId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedAppealId = appeal.id),
            child: GlassCard(
              elevated: true,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(color: TomsColors.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                padding: selected ? const EdgeInsets.all(12) : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appeal.shortId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              Text(driver?.name ?? appeal.driverId, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                              if (driverLicense.isNotEmpty)
                                Text('License: $driverLicense', style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                            ],
                          ),
                        ),
                        StatusBadge.fromStatus(appeal.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Fine: $fineShortId', style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                    const SizedBox(height: 6),
                    Text(appeal.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('${appeal.messages.length} messages', style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _appealDetail(AppealModel? appeal, Map<String, UserModel> users) {
    if (appeal == null) {
      return GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(32),
        child: const Center(child: Text('Select an appeal to review the conversation.', style: TextStyle(color: TomsColors.mutedForeground))),
      );
    }

    final adminUid = _auth.currentUid ?? '';
    final driver = users[appeal.driverId];
    final driverLicense = (driver?.licenseNumber ?? '').trim();
    final fineShortId = appeal.fineId.length > 5 ? 'FN-${appeal.fineId.substring(appeal.fineId.length - 5).toUpperCase()}' : appeal.fineId;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appeal.shortId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    Text(
                      driverLicense.isNotEmpty
                          ? '${driver?.name ?? appeal.driverId} - $driverLicense - Fine $fineShortId'
                          : '${driver?.name ?? appeal.driverId} - Fine $fineShortId',
                      style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              StatusBadge.fromStatus(appeal.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(appeal.reason, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          if (appeal.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(appeal, 'approved'),
                    style: OutlinedButton.styleFrom(foregroundColor: TomsColors.success, side: const BorderSide(color: TomsColors.success)),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(appeal, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: TomsColors.destructive, side: const BorderSide(color: TomsColors.destructive)),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          if (appeal.isPending) const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 220),
            child: Column(
              children: [
                if (appeal.messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No messages yet. Send the first reply to the driver.', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  )
                else
                  ...appeal.messages.map((message) {
                    final isAdmin = message.senderId == adminUid;
                    final sender = users[message.senderId];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin ? TomsColors.primary : TomsColors.secondary,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                              bottomRight: Radius.circular(isAdmin ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sender?.name ?? (isAdmin ? 'Administrator' : 'Driver'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isAdmin ? Colors.white.withValues(alpha: 0.85) : TomsColors.mutedForeground),
                              ),
                              const SizedBox(height: 4),
                              Text(message.text, style: TextStyle(fontSize: 13, color: isAdmin ? Colors.white : TomsColors.foreground)),
                              if (message.timestamp != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatMessageTime(message.timestamp!),
                                  style: TextStyle(fontSize: 10, color: isAdmin ? Colors.white.withValues(alpha: 0.7) : TomsColors.mutedForeground),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Reply to this appeal...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : () => _sendMessage(appeal),
                  style: ElevatedButton.styleFrom(backgroundColor: TomsColors.primary, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${timestamp.month}/${timestamp.day} $hour:$minute $suffix';
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
