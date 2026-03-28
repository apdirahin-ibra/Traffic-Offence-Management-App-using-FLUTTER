import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Traffic Offence Management Overview', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/admin/analytics'),
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: const Text('Open Analytics'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: db.getDashboardStats(),
            builder: (context, snap) {
              final s = snap.data ?? {};
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard('Fines Today', '${s['finesToday'] ?? 0}', Icons.description_outlined, TomsColors.primary),
                  _statCard('Revenue Today', '\$${(s['revenueToday'] ?? 0.0).toStringAsFixed(0)}', Icons.attach_money, TomsColors.success),
                  _statCard('Pending Appeals', '${s['pendingAppeals'] ?? 0}', Icons.message_outlined, TomsColors.accent),
                  _statCard('Overdue Fines', '${s['overdueFines'] ?? 0}', Icons.warning_amber, TomsColors.destructive),
                  _statCard('Active Users', '${s['activeUsers'] ?? 0}', Icons.people_outline, TomsColors.primary),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<FineModel>>(
            stream: db.allFinesChronologicalStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final fines = snap.data ?? const <FineModel>[];
              final analytics = _DashboardAnalytics.from(fines);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassCard(
                      elevated: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fines This Week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Live citation volume for the last 7 days', style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                          const SizedBox(height: 20),
                          if (analytics.weeklyFineSeries.isEmpty)
                            _emptyChart('No fine data available yet')
                          else
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: analytics.maxFineCountY,
                                  gridData: FlGridData(show: true, drawVerticalLine: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= analytics.weeklyFineSeries.length) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              analytics.weeklyFineSeries[index].label,
                                              style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: analytics.weeklyFineSeries.asMap().entries.map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.value,
                                          width: 18,
                                          color: TomsColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
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
                          const Text('Offence Types', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Most common offences in current records', style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                          const SizedBox(height: 20),
                          if (analytics.offenceBreakdown.isEmpty)
                            _emptyChart('No offence data available yet')
                          else
                            Column(
                              children: analytics.offenceBreakdown.take(5).map((item) {
                                final maxCount = analytics.offenceBreakdown.first.count.toDouble();
                                final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: LinearProgressIndicator(
                                            value: ratio,
                                            minHeight: 10,
                                            backgroundColor: TomsColors.secondary,
                                            valueColor: const AlwaysStoppedAnimation(TomsColors.accent),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '${item.count}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Recent Fines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GlassCard(
            elevated: true,
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<FineModel>>(
              stream: db.allFinesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                final fines = (snap.data ?? []).take(10).toList();
                if (fines.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No fines yet')));
                }
                return DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Driver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Offence', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  ],
                  rows: fines.map((f) {
                    return DataRow(cells: [
                      DataCell(Text(f.driverName ?? f.vehiclePlate, style: const TextStyle(fontSize: 13))),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(f.offenceType, style: const TextStyle(fontSize: 12)),
                            Text(f.shortId, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: TomsColors.mutedForeground)),
                          ],
                        ),
                      ),
                      DataCell(Text('\$${f.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      DataCell(StatusBadge.fromStatus(f.status)),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyChart(String message) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
      ),
    );
  }
}

class _DashboardAnalytics {
  final List<_DaySeriesPoint> weeklyFineSeries;
  final List<_CountItem> offenceBreakdown;
  final double maxFineCountY;

  const _DashboardAnalytics({
    required this.weeklyFineSeries,
    required this.offenceBreakdown,
    required this.maxFineCountY,
  });

  factory _DashboardAnalytics.from(List<FineModel> fines) {
    final today = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index));
    });

    final weeklyFineSeries = last7Days.map((date) {
      final count = fines.where((fine) => fine.issuedAt != null && _isSameDay(fine.issuedAt!, date)).length.toDouble();
      return _DaySeriesPoint(_weekdayLabel(date), count);
    }).toList();

    final offenceCounts = <String, int>{};
    for (final fine in fines) {
      offenceCounts.update(fine.offenceType, (value) => value + 1, ifAbsent: () => 1);
    }
    final offenceBreakdown = offenceCounts.entries.map((entry) => _CountItem(entry.key, entry.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final maxFineCount = weeklyFineSeries.fold<double>(0, (max, point) => math.max(max, point.value));

    return _DashboardAnalytics(
      weeklyFineSeries: weeklyFineSeries,
      offenceBreakdown: offenceBreakdown,
      maxFineCountY: math.max(4, maxFineCount + 1),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _weekdayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }
}

class _DaySeriesPoint {
  final String label;
  final double value;

  const _DaySeriesPoint(this.label, this.value);
}

class _CountItem {
  final String label;
  final int count;

  const _CountItem(this.label, this.count);
}
