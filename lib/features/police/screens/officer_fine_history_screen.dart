import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';

class OfficerFineHistoryScreen extends StatelessWidget {
  const OfficerFineHistoryScreen({super.key});

  static const _navItems = [
    MobileNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/police/dashboard'),
    MobileNavItem(label: 'Search', icon: Icons.search, route: '/police/search'),
    MobileNavItem(label: 'Issue Fine', icon: Icons.description_outlined, route: '/police/issue-fine'),
    MobileNavItem(label: 'History', icon: Icons.history, route: '/police/history'),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid ?? '';
    final db = FirestoreService();

    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          Container(
            decoration: const BoxDecoration(gradient: TomsColors.policeGradient),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 32),
            child: Row(children: [
              GestureDetector(onTap: () => context.pop(), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, size: 16, color: Colors.white))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Fine History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)), Text('Your issued tickets', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)))]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: StreamBuilder<List<FineModel>>(
              stream: db.finesByOfficerStream(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 36, color: TomsColors.destructive),
                        const SizedBox(height: 8),
                        const Text('Unable to load fine history', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TomsColors.destructive)),
                        const SizedBox(height: 4),
                        Text('${snap.error}', style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
                }
                final fines = snap.data ?? [];
                if (fines.isEmpty) {
                  return GlassCard(padding: const EdgeInsets.all(32), child: Column(children: [
                    Icon(Icons.history, size: 40, color: TomsColors.mutedForeground),
                    const SizedBox(height: 8),
                    const Text('No fines issued yet', style: TextStyle(color: TomsColors.mutedForeground)),
                  ]));
                }

                // Summary bar
                final pending = fines.where((f) => f.isPending).length;
                final paid = fines.where((f) => f.isPaid).length;
                final total = fines.fold<double>(0, (s, f) => s + f.amount);

                return Column(children: [
                  Row(children: [
                    _summaryChip('Total', '${fines.length}', TomsColors.primary),
                    const SizedBox(width: 8),
                    _summaryChip('Pending', '$pending', TomsColors.accent),
                    const SizedBox(width: 8),
                    _summaryChip('Paid', '$paid', TomsColors.success),
                    const SizedBox(width: 8),
                    _summaryChip('Revenue', '\$${total.toStringAsFixed(0)}', TomsColors.primary),
                  ]),
                  const SizedBox(height: 16),
                  ...fines.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: TomsColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description_outlined, size: 20, color: TomsColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.offenceType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${f.driverName ?? f.vehiclePlate} • ${f.shortId}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('\$${f.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        StatusBadge.fromStatus(f.status),
                      ]),
                    ])),
                  )),
                  const SizedBox(height: 60),
                ]);
              },
            ),
          ),
        ]))),
        MobileNav(items: _navItems, currentRoute: '/police/history', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.7)))]),
    ));
  }
}
