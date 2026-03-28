import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class AllFinesScreen extends StatelessWidget {
  const AllFinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return StreamBuilder<List<FineModel>>(
      stream: db.allFinesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Failed to load fines: ${snap.error}',
                style: const TextStyle(color: TomsColors.destructive),
              ),
            ),
          );
        }

        final fines = snap.data ?? const <FineModel>[];
        final pendingCount = fines.where((fine) => fine.status == 'pending').length;
        final appealedCount = fines.where((fine) => fine.status == 'appealed').length;
        final paidCount = fines.where((fine) => fine.status == 'paid').length;
        final openBalance = fines
            .where((fine) => fine.status == 'pending' || fine.status == 'overdue')
            .fold<double>(0, (sum, fine) => sum + fine.amount);
        final collectedRevenue =
            fines.where((fine) => fine.status == 'paid').fold<double>(0, (sum, fine) => sum + fine.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Fines',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage and review all traffic fines',
                          style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final cards = [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Open Balance',
                        value: '\$${openBalance.toStringAsFixed(0)}',
                        subtitle: '$pendingCount pending, $appealedCount appealed',
                        icon: Icons.receipt_long_outlined,
                        color: TomsColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Collected Revenue',
                        value: '\$${collectedRevenue.toStringAsFixed(0)}',
                        subtitle: '$paidCount paid fines',
                        icon: Icons.account_balance_wallet_outlined,
                        color: TomsColors.success,
                      ),
                    ),
                  ];

                  if (wide) {
                    return Row(
                      children: [
                        cards[0],
                        const SizedBox(width: 16),
                        cards[1],
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _SummaryCard(
                        title: 'Open Balance',
                        value: '\$${openBalance.toStringAsFixed(0)}',
                        subtitle: '$pendingCount pending, $appealedCount appealed',
                        icon: Icons.receipt_long_outlined,
                        color: TomsColors.accent,
                      ),
                      const SizedBox(height: 16),
                      _SummaryCard(
                        title: 'Collected Revenue',
                        value: '\$${collectedRevenue.toStringAsFixed(0)}',
                        subtitle: '$paidCount paid fines',
                        icon: Icons.account_balance_wallet_outlined,
                        color: TomsColors.success,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (fines.isEmpty)
                const GlassCard(
                  elevated: true,
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No fines recorded yet')),
                )
              else
                GlassCard(
                  elevated: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Fine', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Driver', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Vehicle / Officer', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(child: Align(alignment: Alignment.centerRight, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700)))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      for (final fine in fines) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _FineRow(fine: fine),
                        ),
                        if (fine != fines.last) const Divider(height: 1),
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
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FineRow extends StatelessWidget {
  final FineModel fine;

  const _FineRow({required this.fine});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fine.shortId, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                fine.offenceType,
                style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fine.driverName?.trim().isNotEmpty == true ? fine.driverName! : 'Unknown driver'),
              const SizedBox(height: 4),
              Text(
                fine.driverId,
                style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fine.vehiclePlate),
              const SizedBox(height: 4),
              Text(
                fine.officerName?.trim().isNotEmpty == true ? 'Officer ${fine.officerName}' : 'Officer ${fine.officerId}',
                style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            '\$${fine.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: StatusBadge.fromStatus(fine.status),
          ),
        ),
      ],
    );
  }
}
