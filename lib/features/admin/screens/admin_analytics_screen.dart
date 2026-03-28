import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return StreamBuilder<List<FineModel>>(
      stream: db.allFinesChronologicalStream(),
      builder: (context, finesSnap) {
        return StreamBuilder<List<UserModel>>(
          stream: db.allUsersStream(),
          builder: (context, usersSnap) {
            if (finesSnap.connectionState == ConnectionState.waiting || usersSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (finesSnap.hasError) {
              return _errorView('Unable to load analytics data', '${finesSnap.error}');
            }
            if (usersSnap.hasError) {
              return _errorView('Unable to load user analytics', '${usersSnap.error}');
            }

            final fines = finesSnap.data ?? const <FineModel>[];
            final users = usersSnap.data ?? const <UserModel>[];
            final analytics = _AnalyticsData.from(fines, users);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Revenue trends, offence patterns, and officer performance from live system data.', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _metricCard('Total Revenue', '\$${analytics.totalRevenue.toStringAsFixed(0)}', Icons.attach_money, TomsColors.success),
                      _metricCard('Paid Rate', '${analytics.paidRate.toStringAsFixed(0)}%', Icons.check_circle_outline, TomsColors.primary),
                      _metricCard('Police Active', '${analytics.activePoliceCount}', Icons.badge_outlined, TomsColors.accent),
                      _metricCard('Avg Fine', '\$${analytics.averageFineAmount.toStringAsFixed(0)}', Icons.receipt_long_outlined, TomsColors.primary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _chartCard(
                          title: 'Revenue Last 7 Days',
                          subtitle: 'Paid fines recorded per day',
                          child: analytics.revenueSeries.isEmpty
                              ? _emptyChart('No paid fines yet')
                              : SizedBox(
                                  height: 260,
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: analytics.revenueStep),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            interval: analytics.revenueStep,
                                            getTitlesWidget: (value, meta) => Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground)),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index < 0 || index >= analytics.revenueSeries.length) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(analytics.revenueSeries[index].label, style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground)),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: analytics.revenueSeries
                                              .asMap()
                                              .entries
                                              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                                              .toList(),
                                          isCurved: true,
                                          color: TomsColors.success,
                                          barWidth: 3,
                                          dotData: FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: TomsColors.success.withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _chartCard(
                          title: 'Fines Last 7 Days',
                          subtitle: 'Total citations issued per day',
                          child: analytics.fineVolumeSeries.isEmpty
                              ? _emptyChart('No fines issued yet')
                              : SizedBox(
                                  height: 260,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: analytics.fineVolumeMaxY,
                                      gridData: FlGridData(show: true, drawVerticalLine: false),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground)),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index < 0 || index >= analytics.fineVolumeSeries.length) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(analytics.fineVolumeSeries[index].label, style: const TextStyle(fontSize: 10, color: TomsColors.mutedForeground)),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      barGroups: analytics.fineVolumeSeries
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => BarChartGroupData(
                                              x: entry.key,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: entry.value.value,
                                                  width: 18,
                                                  color: TomsColors.primary,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _chartCard(
                          title: 'Top Offence Types',
                          subtitle: 'Most common violations in the system',
                          child: analytics.offenceBreakdown.isEmpty
                              ? _emptyChart('No offence data available')
                              : SizedBox(
                                  height: 280,
                                  child: Column(
                                    children: analytics.offenceBreakdown.take(5).map((item) {
                                      final maxCount = analytics.offenceBreakdown.first.count.toDouble();
                                      final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                                              child: Text('${item.count}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _chartCard(
                          title: 'Officer Performance',
                          subtitle: 'Most fines issued by officer',
                          child: analytics.officerPerformance.isEmpty
                              ? _emptyChart('No officer-issued fines yet')
                              : SizedBox(
                                  height: 280,
                                  child: Column(
                                    children: analytics.officerPerformance.take(5).map((item) {
                                      final maxCount = analytics.officerPerformance.first.count.toDouble();
                                      final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                            Expanded(
                                              flex: 5,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(100),
                                                child: LinearProgressIndicator(
                                                  value: ratio,
                                                  minHeight: 10,
                                                  backgroundColor: TomsColors.secondary,
                                                  valueColor: const AlwaysStoppedAnimation(TomsColors.primary),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            SizedBox(
                                              width: 36,
                                              child: Text('${item.count}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 190,
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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget child}) {
    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(message, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
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
}

class _AnalyticsData {
  final double totalRevenue;
  final double paidRate;
  final int activePoliceCount;
  final double averageFineAmount;
  final List<_SeriesPoint> revenueSeries;
  final List<_SeriesPoint> fineVolumeSeries;
  final List<_CountItem> offenceBreakdown;
  final List<_CountItem> officerPerformance;
  final double revenueStep;
  final double fineVolumeMaxY;

  const _AnalyticsData({
    required this.totalRevenue,
    required this.paidRate,
    required this.activePoliceCount,
    required this.averageFineAmount,
    required this.revenueSeries,
    required this.fineVolumeSeries,
    required this.offenceBreakdown,
    required this.officerPerformance,
    required this.revenueStep,
    required this.fineVolumeMaxY,
  });

  factory _AnalyticsData.from(List<FineModel> fines, List<UserModel> users) {
    final paidFines = fines.where((fine) => fine.isPaid).toList();
    final totalRevenue = paidFines.fold<double>(0, (sum, fine) => sum + fine.amount);
    final paidRate = fines.isEmpty ? 0.0 : (paidFines.length / fines.length) * 100;
    final activePoliceCount = users.where((user) => user.isPolice && user.isActive).length;
    final averageFineAmount = fines.isEmpty ? 0.0 : fines.fold<double>(0, (sum, fine) => sum + fine.amount) / fines.length;

    final today = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index));
      return date;
    });

    final revenueSeries = last7Days.map((date) {
      final value = paidFines
          .where((fine) => fine.paidAt != null && _isSameDay(fine.paidAt!, date))
          .fold<double>(0, (sum, fine) => sum + fine.amount);
      return _SeriesPoint(_weekdayLabel(date), value);
    }).toList();

    final fineVolumeSeries = last7Days.map((date) {
      final value = fines.where((fine) => fine.issuedAt != null && _isSameDay(fine.issuedAt!, date)).length.toDouble();
      return _SeriesPoint(_weekdayLabel(date), value);
    }).toList();

    final offenceCounts = <String, int>{};
    for (final fine in fines) {
      offenceCounts.update(fine.offenceType, (value) => value + 1, ifAbsent: () => 1);
    }
    final offenceBreakdown = offenceCounts.entries
        .map((entry) => _CountItem(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final officerCounts = <String, int>{};
    for (final fine in fines) {
      final label = (fine.officerName?.trim().isNotEmpty ?? false) ? fine.officerName!.trim() : fine.officerId;
      officerCounts.update(label, (value) => value + 1, ifAbsent: () => 1);
    }
    final officerPerformance = officerCounts.entries
        .map((entry) => _CountItem(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final maxRevenue = revenueSeries.fold<double>(0, (max, point) => math.max(max, point.value).toDouble());
    final revenueStep = maxRevenue <= 0 ? 50.0 : math.max(50.0, (maxRevenue / 4).ceilToDouble()).toDouble();
    final maxFineCount = fineVolumeSeries.fold<double>(0, (max, point) => math.max(max, point.value).toDouble());
    final fineVolumeMaxY = math.max(4.0, maxFineCount + 1).toDouble();

    return _AnalyticsData(
      totalRevenue: totalRevenue,
      paidRate: paidRate,
      activePoliceCount: activePoliceCount,
      averageFineAmount: averageFineAmount,
      revenueSeries: revenueSeries,
      fineVolumeSeries: fineVolumeSeries,
      offenceBreakdown: offenceBreakdown,
      officerPerformance: officerPerformance,
      revenueStep: revenueStep,
      fineVolumeMaxY: fineVolumeMaxY,
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

class _SeriesPoint {
  final String label;
  final double value;

  const _SeriesPoint(this.label, this.value);
}

class _CountItem {
  final String label;
  final int count;

  const _CountItem(this.label, this.count);
}
