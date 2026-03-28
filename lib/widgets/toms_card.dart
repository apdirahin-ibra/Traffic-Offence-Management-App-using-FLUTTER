import 'package:flutter/material.dart';
import '../app/theme.dart';

enum StatCardVariant { normal, primary, destructive, success, warning }

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final StatCardVariant variant;
  final ({double value, bool positive})? trend;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.variant = StatCardVariant.normal,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == StatCardVariant.primary;
    final colors = _variantColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: isPrimary ? [BoxShadow(color: TomsColors.primary.withValues(alpha: 0.15), blurRadius: 12)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isPrimary ? Colors.white.withValues(alpha: 0.8) : TomsColors.mutedForeground)),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: isPrimary ? Colors.white : TomsColors.foreground)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: TextStyle(fontSize: 11, color: isPrimary ? Colors.white.withValues(alpha: 0.6) : TomsColors.mutedForeground)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colors.iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: colors.iconColor),
              ),
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Text('${trend!.positive ? '↑' : '↓'} ${trend!.value.abs().toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: trend!.positive ? TomsColors.success : TomsColors.destructive)),
              const SizedBox(width: 4),
              Text('vs last week', style: TextStyle(fontSize: 11, color: isPrimary ? Colors.white.withValues(alpha: 0.6) : TomsColors.mutedForeground)),
            ]),
          ],
        ],
      ),
    );
  }

  _VariantColors get _variantColors {
    switch (variant) {
      case StatCardVariant.primary:
        return _VariantColors(TomsColors.primary, TomsColors.primary, Colors.white.withValues(alpha: 0.2), Colors.white);
      case StatCardVariant.destructive:
        return _VariantColors(TomsColors.destructive.withValues(alpha: 0.1), TomsColors.destructive.withValues(alpha: 0.2), TomsColors.destructive.withValues(alpha: 0.2), TomsColors.destructive);
      case StatCardVariant.success:
        return _VariantColors(TomsColors.success.withValues(alpha: 0.1), TomsColors.success.withValues(alpha: 0.2), TomsColors.success.withValues(alpha: 0.2), TomsColors.success);
      case StatCardVariant.warning:
        return _VariantColors(TomsColors.accent.withValues(alpha: 0.1), TomsColors.accent.withValues(alpha: 0.2), TomsColors.accent.withValues(alpha: 0.2), TomsColors.accent);
      case StatCardVariant.normal:
        return _VariantColors(TomsColors.card, TomsColors.border, TomsColors.secondary, TomsColors.foreground);
    }
  }
}

class _VariantColors {
  final Color bg, border, iconBg, iconColor;
  _VariantColors(this.bg, this.border, this.iconBg, this.iconColor);
}
