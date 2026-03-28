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

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  UserModel? _user;

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
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUserProfile();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUid ?? '';
    final initials = (_user?.name ?? 'U').split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          // Green gradient header with license card
          Container(
            decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 80),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                  const SizedBox(height: 2),
                  Text(_user?.name ?? 'Driver', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                ])),
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(initials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))),
              ]),
              const SizedBox(height: 20),
              // License card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [Icon(Icons.directions_car, size: 16, color: Colors.white.withValues(alpha: 0.7)), const SizedBox(width: 8), Text("Driver's License", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7)))]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: (_user?.isSuspended ?? false) ? TomsColors.destructive.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon((_user?.isSuspended ?? false) ? Icons.warning : Icons.check_circle, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text((_user?.licenseStatus ?? 'active').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('NATIONAL ID', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_user?.nationalId ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: Colors.white)),
                    ])),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('EMAIL', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_user?.email ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ])),
                  ]),
                ]),
              ),
            ]),
          ),
          // Content overlapping header
          Transform.translate(offset: const Offset(0, -40), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
            // Live stat tiles from Firestore
            StreamBuilder<List<FineModel>>(
              stream: _db.finesByDriverStream(uid),
              builder: (context, snap) {
                final fines = snap.data ?? [];
                final pending = fines.where((f) => f.isPending || f.isOverdue).length;
                final owed = fines.where((f) => f.isPending || f.isOverdue).fold<double>(0, (s, f) => s + f.amount);
                final paid = fines.where((f) => f.isPaid).length;

                return Row(children: [
                  _statTile(Icons.description_outlined, pending.toString(), 'Pending', TomsColors.accent),
                  const SizedBox(width: 12),
                  _statTile(Icons.attach_money, '\$${owed.toStringAsFixed(0)}', 'Owed', TomsColors.destructive),
                  const SizedBox(width: 12),
                  _statTile(Icons.credit_card, paid.toString(), 'Paid', TomsColors.success),
                ]);
              },
            ),
            const SizedBox(height: 16),
            // Demerit points from user profile
            StreamBuilder<UserModel?>(
              stream: _db.userStream(uid),
              builder: (context, snap) {
                final user = snap.data ?? _user;
                final points = user?.demeritPoints ?? 0;
                final maxPoints = FirestoreService.suspensionThreshold;
                final remaining = (maxPoints - points).clamp(0, maxPoints);

                return GlassCard(elevated: true, padding: const EdgeInsets.all(16), child: Column(children: [
                  if (user?.isSuspended ?? false) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TomsColors.destructive.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.18)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.gpp_bad_outlined, size: 14, color: TomsColors.destructive),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'License automatically suspended after reaching 50 demerit points.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TomsColors.destructive),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Demerit Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: '$points', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: points > 18 ? TomsColors.destructive : points > 12 ? TomsColors.accent : TomsColors.success)),
                      TextSpan(text: ' / $maxPoints', style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                    value: points / maxPoints, minHeight: 12,
                    backgroundColor: TomsColors.secondary,
                    valueColor: AlwaysStoppedAnimation(points > 18 ? TomsColors.destructive : points > 12 ? TomsColors.accent : TomsColors.success),
                  )),
                  if ((user?.isSuspended ?? false) || remaining <= 6) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: TomsColors.destructive.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.15))),
                      child: Row(children: [
                        const Icon(Icons.warning, size: 14, color: TomsColors.destructive),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (user?.isSuspended ?? false)
                                ? 'License suspended after reaching the 50-point threshold.'
                                : 'Warning: $remaining points from license suspension',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TomsColors.destructive),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ]));
              },
            ),
            const SizedBox(height: 16),
            // Quick pay banner
            StreamBuilder<List<FineModel>>(
              stream: _db.finesByDriverStream(uid),
              builder: (context, snap) {
                final fines = snap.data ?? [];
                final unpaid = fines.where((f) => f.isPending || f.isOverdue).toList();
                if (unpaid.isEmpty) return const SizedBox.shrink();
                final total = unpaid.fold<double>(0, (s, f) => s + f.amount);

                return GestureDetector(
                  onTap: () => context.push('/driver/fines'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: TomsColors.policeGradient, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.credit_card, size: 24, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Pay Outstanding Fines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text('${unpaid.length} fines totaling \$${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                      ])),
                      Icon(Icons.chevron_right, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Recent fines
            Row(children: [
              const Expanded(child: Text('RECENT FINES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5))),
              GestureDetector(onTap: () => context.push('/driver/fines'), child: Row(children: [const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TomsColors.primary)), const Icon(Icons.chevron_right, size: 14, color: TomsColors.primary)])),
            ]),
            const SizedBox(height: 12),
            StreamBuilder<List<FineModel>>(
              stream: _db.finesByDriverStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                final fines = (snap.data ?? []).take(3).toList();
                if (fines.isEmpty) return GlassCard(padding: const EdgeInsets.all(24), child: const Center(child: Text('No fines yet', style: TextStyle(color: TomsColors.mutedForeground))));
                return Column(children: fines.map((f) => _fineCard(context, f)).toList());
              },
            ),
            const SizedBox(height: 60),
          ]))),
        ]))),
        MobileNav(items: _navItems, currentRoute: '/driver/dashboard', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Expanded(child: GlassCard(elevated: true, padding: const EdgeInsets.all(16), child: Column(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground, letterSpacing: 1.2)),
    ])));
  }

  Widget _fineCard(BuildContext ctx, FineModel f) {
    final isOverdue = f.isOverdue;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
      onTap: () => ctx.push('/driver/fines/detail?fineId=${Uri.encodeComponent(f.id)}'),
      child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: (isOverdue ? TomsColors.destructive : TomsColors.accent).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.description_outlined, size: 20, color: isOverdue ? TomsColors.destructive : TomsColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.offenceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(f.shortId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${f.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          StatusBadge.fromStatus(f.status),
        ]),
      ])),
    ));
  }
}
