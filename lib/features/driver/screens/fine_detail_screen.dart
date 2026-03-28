import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../widgets/fine_location_map.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/timeline_widget.dart';

class FineDetailScreen extends StatelessWidget {
  final String fineId;

  const FineDetailScreen({super.key, required this.fineId});

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<FineModel?>(
              future: fineId.isEmpty ? Future.value(null) : FirestoreService().getFine(fineId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final fine = snap.data;
                if (fine == null) {
                  return _stateView(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Fine not found',
                    subtitle: 'This fine record could not be loaded.',
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _header(context, fine),
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              GlassCard(
                                elevated: true,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _statusColor(fine).withValues(alpha: 0.12),
                                            _statusColor(fine).withValues(alpha: 0.04),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(fine.offenceType, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '\$${fine.amount.toStringAsFixed(0)}',
                                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: _statusColor(fine)),
                                              ),
                                              const SizedBox(width: 12),
                                              StatusBadge.fromStatus(fine.status),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _detailItem(Icons.person, 'Officer', fine.officerName ?? 'Assigned Officer')),
                                              const SizedBox(width: 12),
                                              Expanded(child: _detailItem(Icons.calendar_today, 'Date', _formatDate(fine.issuedAt))),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(child: _detailItem(Icons.access_time, 'Due Date', _formatDate(fine.dueDate))),
                                              const SizedBox(width: 12),
                                              Expanded(child: _detailItem(Icons.directions_car, 'Vehicle', fine.vehiclePlate)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Location'),
                                    const SizedBox(height: 12),
                                    if (fine.lat != null && fine.lng != null)
                                      FineLocationMap(
                                        latitude: fine.lat!,
                                        longitude: fine.lng!,
                                        helperText: 'Violation recorded at ${fine.lat!.toStringAsFixed(5)}, ${fine.lng!.toStringAsFixed(5)}',
                                      )
                                    else
                                      _emptySection(
                                        icon: Icons.location_off_outlined,
                                        message: 'No map location was saved for this fine.',
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Evidence Photos'),
                                    const SizedBox(height: 12),
                                    if (fine.evidenceUrls.isEmpty)
                                      _emptySection(
                                        icon: Icons.image_not_supported_outlined,
                                        message: 'No evidence photos were attached to this fine.',
                                      )
                                    else
                                      SizedBox(
                                        height: 96,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: fine.evidenceUrls.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                                          itemBuilder: (context, index) {
                                            final url = fine.evidenceUrls[index];
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: SizedBox(
                                                width: 120,
                                                child: Image.network(
                                                  url,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: TomsColors.secondary,
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.broken_image_outlined, color: TomsColors.mutedForeground),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Timeline'),
                                    const SizedBox(height: 12),
                                    TimelineWidget(steps: _buildTimeline(fine)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: fine.isPaid ? null : () => context.push('/driver/payment?fineId=${Uri.encodeComponent(fine.id)}'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: TomsColors.success,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 4,
                                          shadowColor: TomsColors.success.withValues(alpha: 0.3),
                                        ),
                                        child: Text(
                                          fine.isPaid ? 'Already Paid' : 'Pay Now',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: () => context.push('/driver/appeals?fineId=${Uri.encodeComponent(fine.id)}'),
                                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                        child: const Text('Appeal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          MobileNav(items: _navItems, currentRoute: '/driver/fines', onNavigate: (r) => context.push(r)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, FineModel fine) {
    return Container(
      decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 32),
      child: Row(
        children: [
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fine Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(fine.shortId, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TomsColors.secondary.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TomsColors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground, letterSpacing: 0.5)),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySection({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TomsColors.secondary, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 26, color: TomsColors.mutedForeground),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
        ],
      ),
    );
  }

  Widget _stateView(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          elevated: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: TomsColors.mutedForeground),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }

  List<TimelineStep> _buildTimeline(FineModel fine) {
    final issuedText = _formatDateTime(fine.issuedAt);
    final dueText = _formatDate(fine.dueDate);
    final paidText = _formatDateTime(fine.paidAt);

    if (fine.isPaid) {
      return [
        TimelineStep(label: 'Fine Issued', date: issuedText, status: StepStatus.complete),
        TimelineStep(label: 'Driver Notified', date: issuedText, status: StepStatus.complete),
        TimelineStep(label: 'Paid via WaafiPay', date: paidText, status: StepStatus.complete),
      ];
    }

    return [
      TimelineStep(label: 'Fine Issued', date: issuedText, status: StepStatus.complete),
      TimelineStep(label: 'Driver Notified', date: issuedText, status: StepStatus.complete),
      TimelineStep(
        label: fine.isAppealed ? 'Appeal Submitted' : 'Awaiting Payment',
        date: fine.isAppealed ? dueText : issuedText,
        status: StepStatus.current,
      ),
      TimelineStep(label: 'Due Date', date: dueText, status: StepStatus.upcoming),
    ];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('MMM d, y - h:mm a').format(date);
  }

  Color _statusColor(FineModel fine) {
    if (fine.isPaid) return TomsColors.success;
    if (fine.isOverdue) return TomsColors.destructive;
    return TomsColors.accent;
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5));
}
