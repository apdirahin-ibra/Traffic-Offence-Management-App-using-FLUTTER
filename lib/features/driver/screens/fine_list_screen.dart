import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';

class FineListScreen extends StatelessWidget {
  const FineListScreen({super.key});

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid ?? '';
    final db = FirestoreService();

    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          _header(context),
          Transform.translate(offset: const Offset(0, -16), child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<FineModel>>(
              stream: db.finesByDriverStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
                }
                final fines = snap.data ?? [];
                final unpaid = fines.where((f) => f.isPending || f.isOverdue).toList();
                final total = unpaid.fold<double>(0, (s, f) => s + f.amount);

                return Column(children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: TomsColors.policeGradient, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('TOTAL OWED', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${unpaid.length} unpaid fines', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                      ]),
                      const Spacer(),
                      if (unpaid.isNotEmpty) ElevatedButton(
                        onPressed: () => context.push('/driver/payment'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: TomsColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Pay All'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Fine list
                  if (fines.isEmpty) GlassCard(padding: const EdgeInsets.all(32), child: const Center(child: Text('No fines found', style: TextStyle(color: TomsColors.mutedForeground))))
                  else ...fines.map((f) => _fineItem(context, f)),
                  const SizedBox(height: 60),
                ]);
              },
            ),
          )),
        ]))),
        MobileNav(items: _navItems, currentRoute: '/driver/fines', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _fineItem(BuildContext ctx, FineModel f) {
    final color = f.isOverdue ? TomsColors.destructive : f.isPaid ? TomsColors.success : TomsColors.accent;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
      onTap: () => ctx.push('/driver/fines/detail?fineId=${Uri.encodeComponent(f.id)}'),
      child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text('\$${f.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.offenceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('${f.shortId} • ${f.vehiclePlate}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
        ])),
        StatusBadge.fromStatus(f.status),
      ])),
    ));
  }

  Widget _header(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
      padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 12, left: 20, right: 20, bottom: 32),
      child: Row(children: [
        GestureDetector(onTap: () => ctx.pop(), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, size: 16, color: Colors.white))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('My Fines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)), Text('View and manage your fines', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)))]),
      ]),
    );
  }
}
