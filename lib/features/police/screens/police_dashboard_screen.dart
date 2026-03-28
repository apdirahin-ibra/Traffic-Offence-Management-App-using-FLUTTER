import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/fine_model.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});
  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  UserModel? _user;

  static const _navItems = [
    MobileNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/police/dashboard'),
    MobileNavItem(label: 'Search', icon: Icons.search, route: '/police/search'),
    MobileNavItem(label: 'Issue Fine', icon: Icons.description_outlined, route: '/police/issue-fine'),
    MobileNavItem(label: 'History', icon: Icons.history, route: '/police/history'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUserProfile();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUid ?? '';
    final rawName = _user?.name?.trim();
    final officerTitle = rawName == null || rawName.isEmpty
        ? 'Officer'
        : rawName.startsWith('Officer ')
            ? rawName
            : 'Officer $rawName';
    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(gradient: TomsColors.policeGradient),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, left: 20, right: 20, bottom: 68),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: TomsColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: TomsColors.success)), const SizedBox(width: 6), const Text('On Duty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))]),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) context.push('/');
                    },
                  ),
                ]),
                const SizedBox(height: 6),
                Text('Good ${_greeting()},', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    officerTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                if (_user?.badgeId != null) Text('Badge: ${_user!.badgeId}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          // Overlapping content
          Transform.translate(offset: const Offset(0, -48), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
            // Live stat stream
            StreamBuilder<List<FineModel>>(
              stream: _db.finesByOfficerStream(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _messageCard('Unable to load dashboard stats', '${snap.error}');
                }
                final fines = snap.data ?? [];
                final today = DateTime.now();
                final todayFines = fines.where((f) => f.issuedAt != null && f.issuedAt!.day == today.day && f.issuedAt!.month == today.month && f.issuedAt!.year == today.year).toList();
                final weekFines = fines.where((f) => f.issuedAt != null && f.issuedAt!.isAfter(today.subtract(const Duration(days: 7)))).toList();
                final pendingSync = fines.where((f) => f.isPending).length;

                return Row(children: [
                  _statTile('Today', todayFines.length.toString(), Icons.description_outlined, TomsColors.primary),
                  const SizedBox(width: 12),
                  _statTile('This Week', weekFines.length.toString(), Icons.calendar_today, TomsColors.success),
                  const SizedBox(width: 12),
                  _statTile('Pending', pendingSync.toString(), Icons.sync, TomsColors.accent),
                ]);
              },
            ),
            const SizedBox(height: 16),
            // Quick actions
            Row(children: [
              _actionCard(context, Icons.search, 'Search\nDriver', '/police/search', TomsColors.policeGradient),
              const SizedBox(width: 12),
              _actionCard(context, Icons.description_outlined, 'Issue\nFine', '/police/issue-fine', TomsColors.driverGradient),
              const SizedBox(width: 12),
              _actionCard(context, Icons.history, 'Fine\nHistory', '/police/history', const LinearGradient(colors: [TomsColors.accent, Color(0xFFE65100)])),
            ]),
            const SizedBox(height: 20),
            // Recent fines header
            Row(children: [
              const Expanded(child: Text('RECENT FINES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5))),
              GestureDetector(onTap: () => context.push('/police/history'), child: Row(children: [const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TomsColors.primary)), const Icon(Icons.chevron_right, size: 14, color: TomsColors.primary)])),
            ]),
            const SizedBox(height: 12),
            // Recent fines stream
            StreamBuilder<List<FineModel>>(
              stream: _db.finesByOfficerStream(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _messageCard('Unable to load recent fines', '${snap.error}');
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                final fines = (snap.data ?? []).take(5).toList();
                if (fines.isEmpty) {
                  return GlassCard(padding: const EdgeInsets.all(24), child: Column(children: [
                    Icon(Icons.description_outlined, size: 32, color: TomsColors.mutedForeground),
                    const SizedBox(height: 8),
                    const Text('No fines issued yet', style: TextStyle(color: TomsColors.mutedForeground)),
                  ]));
                }
                return Column(children: fines.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: TomsColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description_outlined, size: 20, color: TomsColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.offenceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(f.driverName ?? f.vehiclePlate, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('\$${f.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      StatusBadge.fromStatus(f.status),
                    ]),
                  ])),
                )).toList());
              },
            ),
            const SizedBox(height: 60),
          ]))),
        ]))),
        MobileNav(items: _navItems, currentRoute: '/police/dashboard', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(child: GlassCard(elevated: true, padding: const EdgeInsets.all(16), child: Column(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground, letterSpacing: 1.2)),
    ])));
  }

  Widget _actionCard(BuildContext ctx, IconData icon, String label, String route, LinearGradient grad) {
    return Expanded(child: GestureDetector(
      onTap: () => ctx.push(route),
      child: GlassCard(elevated: true, padding: const EdgeInsets.all(16), child: Column(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 20, color: Colors.white)),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)),
      ])),
    ));
  }

  Widget _messageCard(String title, String message) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TomsColors.destructive)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
        ],
      ),
    );
  }
}
