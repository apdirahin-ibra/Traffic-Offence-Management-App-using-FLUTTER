import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/offence_model.dart';
import '../../../widgets/glass_card.dart';

class AdminConfigurationScreen extends StatelessWidget {
  const AdminConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Review current system rules, enforcement settings, and active offence definitions.',
            style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;

              final licenseRulesCard = GlassCard(
                elevated: true,
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('License Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 16),
                    _ConfigValue(label: 'Demerit Suspension Threshold', value: '50 points'),
                    SizedBox(height: 12),
                    _ConfigValue(label: 'Rejected Appeal Fine Status', value: 'Returns to pending or overdue'),
                    SizedBox(height: 12),
                    _ConfigValue(label: 'Approved Appeal Fine Status', value: 'Cancelled'),
                  ],
                ),
              );

              final paymentsCard = GlassCard(
                elevated: true,
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payments & Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 16),
                    _ConfigValue(label: 'Driver Login', value: 'License number + password'),
                    SizedBox(height: 12),
                    _ConfigValue(label: 'Police Login', value: 'Badge ID + password'),
                    SizedBox(height: 12),
                    _ConfigValue(label: 'Wallet Providers', value: 'EVC Plus, Sahal, Zaad'),
                  ],
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: licenseRulesCard),
                    const SizedBox(width: 16),
                    Expanded(child: paymentsCard),
                  ],
                );
              }

              return Column(
                children: [
                  licenseRulesCard,
                  const SizedBox(height: 16),
                  paymentsCard,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<OffenceModel>>(
            stream: db.activeOffencesStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snap.hasError) {
                return GlassCard(
                  elevated: true,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load active offences: ${snap.error}',
                    style: const TextStyle(color: TomsColors.destructive),
                  ),
                );
              }

              final offences = snap.data ?? const <OffenceModel>[];
              return GlassCard(
                elevated: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Offence Catalogue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'These are the live offence definitions officers can issue from the app.',
                      style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                    ),
                    const SizedBox(height: 16),
                    if (offences.isEmpty)
                      const Text('No active offences configured.')
                    else
                      for (var index = 0; index < offences.length; index++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(offences[index].name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    offences[index].category,
                                    style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Text('\$${offences[index].amount.toStringAsFixed(0)}')),
                            Expanded(child: Text('${offences[index].demeritPoints} pts')),
                          ],
                        ),
                        if (index != offences.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                      ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfigValue extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: TomsColors.mutedForeground))),
        const SizedBox(width: 16),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
