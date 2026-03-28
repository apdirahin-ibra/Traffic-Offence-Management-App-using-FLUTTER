import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/appeal_model.dart';
import '../../../models/fine_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../widgets/status_badge.dart';

class DriverAppealsScreen extends StatefulWidget {
  final String? initialFineId;

  const DriverAppealsScreen({super.key, required this.initialFineId});

  @override
  State<DriverAppealsScreen> createState() => _DriverAppealsScreenState();
}

class _DriverAppealsScreenState extends State<DriverAppealsScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  final _messageCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _uid = '';
  Stream<List<AppealModel>>? _appealsStream;
  Stream<List<FineModel>>? _finesStream;
  List<AppealModel> _cachedAppeals = const [];
  List<FineModel> _cachedFines = const [];

  int _tab = 0; // 0=history, 1=submit, 2=chat
  String? _selectedAppealId;
  String? _selectedFineId;
  bool _sending = false;
  bool _submitting = false;

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFineId != null && widget.initialFineId!.isNotEmpty) {
      _tab = 1;
      _selectedFineId = widget.initialFineId;
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _reasonCtrl.dispose();
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
        AppealMessage(
          senderId: uid,
          text: text,
          timestamp: DateTime.now(),
        ),
        actorUserId: uid,
      );
      _messageCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitAppeal(List<FineModel> fines, List<AppealModel> appeals) async {
    final uid = _auth.currentUid;
    final selectedFineId = _selectedFineId;
    final reason = _reasonCtrl.text.trim();

    if (uid == null) return;
    if (selectedFineId == null || selectedFineId.isEmpty) {
      _showSnack('Select the fine you want to appeal.');
      return;
    }
    if (reason.isEmpty) {
      _showSnack('Explain why this fine is incorrect.');
      return;
    }

    final fine = fines.where((item) => item.id == selectedFineId).cast<FineModel?>().firstOrNull;
    if (fine == null) {
      _showSnack('The selected fine could not be found.');
      return;
    }

    final existingAppeal = appeals.where((appeal) => appeal.fineId == selectedFineId).cast<AppealModel?>().firstOrNull;
    if (existingAppeal != null) {
      setState(() {
        _selectedAppealId = existingAppeal.id;
        _tab = 2;
      });
      _showSnack('An appeal already exists for this fine. Opening the chat.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final appeal = AppealModel(
        id: '',
        fineId: fine.id,
        driverId: uid,
        reason: reason,
        messages: [
          AppealMessage(
            senderId: uid,
            text: reason,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final appealId = await _db.createAppeal(appeal);
      await _db.logAction(
        uid,
        'appeal_created',
        'Created an appeal for fine ${fine.shortId} (${fine.offenceType}).',
      );

      if (!mounted) return;
      setState(() {
        _selectedAppealId = appealId;
        _tab = 2;
        _reasonCtrl.clear();
      });
      _showSnack('Appeal submitted successfully.');
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _ensureStreams() {
    final currentUid = _auth.currentUid ?? '';
    if (currentUid.isEmpty) return;
    if (_uid == currentUid && _appealsStream != null && _finesStream != null) return;

    _uid = currentUid;
    _appealsStream = _db.appealsByDriverStream(currentUid);
    _finesStream = _db.finesByDriverStream(currentUid);
  }

  @override
  Widget build(BuildContext context) {
    _ensureStreams();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 32),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Appeals', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Manage fine appeals', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                      ]),
                    ]),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<List<AppealModel>>(
                        stream: _appealsStream,
                        builder: (context, appealSnapshot) {
                          if (_appealsStream == null || _finesStream == null) {
                            return const Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (appealSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (appealSnapshot.hasError) {
                            return GlassCard(
                              elevated: true,
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Unable to load appeals: ${appealSnapshot.error}',
                                style: const TextStyle(fontSize: 13, color: TomsColors.destructive),
                              ),
                            );
                          }

                          final incomingAppeals = appealSnapshot.data;
                          final appeals = (incomingAppeals != null && incomingAppeals.isNotEmpty)
                              ? incomingAppeals
                              : _cachedAppeals;
                          if (incomingAppeals != null && (incomingAppeals.isNotEmpty || _cachedAppeals.isEmpty)) {
                            _cachedAppeals = incomingAppeals;
                          }
                          if (appeals.isNotEmpty && (_selectedAppealId == null || appeals.every((appeal) => appeal.id != _selectedAppealId))) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() {
                                _selectedAppealId = appeals.first.id;
                              });
                            });
                          }
                          final selectedAppeal = _resolveSelectedAppeal(appeals);

                          return StreamBuilder<List<FineModel>>(
                            stream: _finesStream,
                            builder: (context, fineSnapshot) {
                              if (fineSnapshot.hasError) {
                                return GlassCard(
                                  elevated: true,
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Unable to load fines: ${fineSnapshot.error}',
                                    style: const TextStyle(fontSize: 13, color: TomsColors.destructive),
                                  ),
                                );
                              }

                              final incomingFines = fineSnapshot.data;
                              final fines = (incomingFines != null && incomingFines.isNotEmpty)
                                  ? incomingFines
                                  : _cachedFines;
                              if (incomingFines != null && (incomingFines.isNotEmpty || _cachedFines.isEmpty)) {
                                _cachedFines = incomingFines;
                              }

                              if (appeals.isNotEmpty && _selectedFineId != null) {
                                final matchingAppeal = appeals.where((appeal) => appeal.fineId == _selectedFineId).cast<AppealModel?>().firstOrNull;
                                if (matchingAppeal != null && matchingAppeal.id != _selectedAppealId) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() {
                                      _selectedAppealId = matchingAppeal.id;
                                    });
                                  });
                                }
                              }

                              return Column(
                                children: [
                                  GlassCard(
                                    elevated: true,
                                    padding: const EdgeInsets.all(4),
                                    child: Row(children: [
                                      _tabBtn(0, 'My Appeals'),
                                      _tabBtn(1, 'New Appeal'),
                                      _tabBtn(2, 'Messages'),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_tab == 0) _historyTab(appeals),
                                  if (_tab == 1) _submitTab(fines, appeals),
                                  if (_tab == 2) _chatTab(selectedAppeal, _uid),
                                  const SizedBox(height: 60),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          MobileNav(items: _navItems, currentRoute: '/driver/appeals', onNavigate: (r) => context.push(r)),
        ],
      ),
    );
  }

  AppealModel? _resolveSelectedAppeal(List<AppealModel> appeals) {
    if (appeals.isEmpty) return null;
    final selected = appeals.where((a) => a.id == _selectedAppealId).cast<AppealModel?>().firstOrNull;
    return selected ?? appeals.first;
  }

  Widget _tabBtn(int idx, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? TomsColors.success : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [BoxShadow(color: TomsColors.success.withValues(alpha: 0.3), blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : TomsColors.mutedForeground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyTab(List<AppealModel> appeals) {
    if (appeals.isEmpty) {
      return GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text('No appeals submitted yet', style: TextStyle(color: TomsColors.mutedForeground))),
      );
    }

    return Column(
      children: appeals.map((appeal) {
        final fineShortId = appeal.fineId.length > 5 ? 'FN-${appeal.fineId.substring(appeal.fineId.length - 5).toUpperCase()}' : appeal.fineId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            elevated: true,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${appeal.shortId} -> $fineShortId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
                StatusBadge.fromStatus(appeal.status),
              ]),
              const SizedBox(height: 8),
              Text(appeal.reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text('${appeal.messages.length} messages', style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _selectedAppealId = appeal.id;
                    _tab = 2;
                  }),
                  icon: const Icon(Icons.message_outlined, size: 14),
                  label: const Text('Open Chat', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _submitTab(List<FineModel> fines, List<AppealModel> appeals) {
    if (fines.isEmpty) {
      return GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(20),
        child: const Text(
          'You have no fines available to appeal yet.',
          style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground),
        ),
      );
    }

    final selectedFine = fines.where((fine) => fine.id == _selectedFineId).cast<FineModel?>().firstOrNull;
    final existingAppeal = _selectedFineId == null
        ? null
        : appeals.where((appeal) => appeal.fineId == _selectedFineId).cast<AppealModel?>().firstOrNull;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEW APPEAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedFineId != null && fines.any((fine) => fine.id == _selectedFineId) ? _selectedFineId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Select Fine'),
            items: fines.map((fine) {
              return DropdownMenuItem<String>(
                value: fine.id,
                child: Text(
                  '${fine.shortId} • ${fine.offenceType} • ${fine.vehiclePlate}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) => fines.map((fine) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${fine.shortId} • ${fine.offenceType} • ${fine.vehiclePlate}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedFineId = value),
          ),
          if (selectedFine != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TomsColors.secondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedFine.offenceType, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Officer ${selectedFine.officerName ?? 'Unknown'} • Vehicle ${selectedFine.vehiclePlate} • \$${selectedFine.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Why are you appealing?',
              hintText: 'Example: Vehicle AH3000 is not my vehicle. Please review this fine.',
            ),
          ),
          if (existingAppeal != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TomsColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TomsColors.accent.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('An appeal already exists for this fine.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(existingAppeal.reason, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedAppealId = existingAppeal.id;
                      _tab = 2;
                    }),
                    child: const Text('Open Existing Appeal'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _submitAppeal(fines, appeals),
              style: ElevatedButton.styleFrom(
                backgroundColor: TomsColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Appeal', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTab(AppealModel? appeal, String currentUserId) {
    if (appeal == null) {
      return GlassCard(
        elevated: true,
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text('No appeal selected yet. Open one from My Appeals.', style: TextStyle(color: TomsColors.mutedForeground))),
      );
    }

    final fineShortId = appeal.fineId.length > 5 ? 'FN-${appeal.fineId.substring(appeal.fineId.length - 5).toUpperCase()}' : appeal.fineId;

    return Column(
      children: [
        GlassCard(
          elevated: true,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${appeal.shortId} -> $fineShortId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
              const SizedBox(width: 8),
              StatusBadge.fromStatus(appeal.status),
            ]),
            const SizedBox(height: 12),
            if (appeal.isRejected)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TomsColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TomsColors.accent.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'Your appeal was rejected. This fine is active again and must be paid before the due date.',
                  style: TextStyle(fontSize: 12, color: TomsColors.foreground),
                ),
              ),
            if (appeal.isApproved)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TomsColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TomsColors.success.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'Your appeal was approved. This fine has been cleared and no payment is required.',
                  style: TextStyle(fontSize: 12, color: TomsColors.foreground),
                ),
              ),
            if (appeal.messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No messages yet. Start the conversation with the appeals team.', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
              )
            else
              ...appeal.messages.map((message) {
                final isDriver = message.senderId == currentUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDriver ? TomsColors.success : TomsColors.secondary,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isDriver ? 16 : 4),
                          bottomRight: Radius.circular(isDriver ? 4 : 16),
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          message.text,
                          style: TextStyle(fontSize: 13, color: isDriver ? Colors.white : TomsColors.foreground),
                        ),
                        if (message.timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatMessageTime(message.timestamp!),
                            style: TextStyle(fontSize: 10, color: isDriver ? Colors.white.withValues(alpha: 0.65) : TomsColors.mutedForeground),
                          ),
                        ],
                      ]),
                    ),
                  ),
                );
              }),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type a message...',
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
              style: ElevatedButton.styleFrom(backgroundColor: TomsColors.success, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 20),
            ),
          ),
        ]),
      ],
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
