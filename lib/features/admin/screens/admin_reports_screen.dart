import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Operational summaries for fines, users, and enforcement activity.',
            style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: db.getDashboardStats(),
            builder: (context, statsSnap) {
              return StreamBuilder<List<FineModel>>(
                stream: db.allFinesStream(),
                builder: (context, finesSnap) {
                  return StreamBuilder<List<UserModel>>(
                    stream: db.allUsersStream(),
                    builder: (context, usersSnap) {
                      if (statsSnap.connectionState == ConnectionState.waiting ||
                          finesSnap.connectionState == ConnectionState.waiting ||
                          usersSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (statsSnap.hasError || finesSnap.hasError || usersSnap.hasError) {
                        return GlassCard(
                          elevated: true,
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Failed to load reports data.',
                            style: const TextStyle(color: TomsColors.destructive),
                          ),
                        );
                      }

                      final stats = statsSnap.data ?? const <String, dynamic>{};
                      final fines = finesSnap.data ?? const <FineModel>[];
                      final users = usersSnap.data ?? const <UserModel>[];
                      final drivers = users.where((user) => user.isDriver).length;
                      final police = users.where((user) => user.isPolice).length;
                      final admins = users.where((user) => user.isAdmin).length;
                      final pending = fines.where((fine) => fine.status == 'pending').length;
                      final appealed = fines.where((fine) => fine.status == 'appealed').length;
                      final overdue = fines.where((fine) => fine.status == 'overdue').length;
                      final topOffence = _topOffence(fines);

                      return Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cards = [
                                _ReportMetricCard(
                                  title: 'Fines Today',
                                  value: '${stats['finesToday'] ?? 0}',
                                  subtitle: '$pending pending right now',
                                  icon: Icons.receipt_long_outlined,
                                  color: TomsColors.primary,
                                ),
                                _ReportMetricCard(
                                  title: 'Revenue Today',
                                  value: '\$${(stats['revenueToday'] ?? 0).toStringAsFixed(0)}',
                                  subtitle: '$overdue overdue fines',
                                  icon: Icons.paid_outlined,
                                  color: TomsColors.success,
                                ),
                                _ReportMetricCard(
                                  title: 'Open Appeals',
                                  value: '${stats['pendingAppeals'] ?? 0}',
                                  subtitle: '$appealed appealed fines',
                                  icon: Icons.forum_outlined,
                                  color: TomsColors.accent,
                                ),
                                _ReportMetricCard(
                                  title: 'Active Users',
                                  value: '${stats['activeUsers'] ?? 0}',
                                  subtitle: '$drivers drivers, $police police',
                                  icon: Icons.groups_outlined,
                                  color: TomsColors.primarySoft,
                                ),
                              ];

                              final wide = constraints.maxWidth >= 1100;
                              final medium = constraints.maxWidth >= 700;
                              final crossAxisCount = wide ? 4 : (medium ? 2 : 1);
                              const spacing = 16.0;
                              final itemWidth =
                                  (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: cards.map((card) => SizedBox(width: itemWidth, child: card)).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GlassCard(
                                  elevated: true,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('User Mix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 16),
                                      _BreakdownRow(label: 'Drivers', value: '$drivers'),
                                      const SizedBox(height: 12),
                                      _BreakdownRow(label: 'Police Officers', value: '$police'),
                                      const SizedBox(height: 12),
                                      _BreakdownRow(label: 'Administrators', value: '$admins'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GlassCard(
                                  elevated: true,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Fine Snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 16),
                                      _BreakdownRow(label: 'Top Offence', value: topOffence),
                                      const SizedBox(height: 12),
                                      _BreakdownRow(label: 'Pending Fines', value: '$pending'),
                                      const SizedBox(height: 12),
                                      _BreakdownRow(label: 'Appealed Fines', value: '$appealed'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GlassCard(
                            elevated: true,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recent Fine Outcomes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                if (fines.isEmpty)
                                  const Text('No fines available yet.')
                                else
                                  for (var index = 0; index < fines.take(8).length; index++) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(fines[index].offenceType, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${fines[index].driverName ?? 'Unknown'} • ${fines[index].vehiclePlate}',
                                                style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text('\$${fines[index].amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 16),
                                        StatusBadge.fromStatus(fines[index].status),
                                      ],
                                    ),
                                    if (index != fines.take(8).length - 1)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),
                                  ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _topOffence(List<FineModel> fines) {
    if (fines.isEmpty) return 'No data';
    final counts = <String, int>{};
    for (final fine in fines) {
      counts.update(fine.offenceType, (value) => value + 1, ifAbsent: () => 1);
    }
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${top.key} (${top.value})';
  }
}

class _ReportMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportMetricCard({
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
            width: 50,
            height: 50,
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
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
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

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: TomsColors.mutedForeground))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
