import 'package:flutter/material.dart';
import '../app/theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const StatusBadge({super.key, required this.label, this.backgroundColor, this.textColor, this.borderColor});

  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase();
    Color bg, fg, bdr;
    switch (s) {
      case 'pending':
        bg = TomsColors.accent.withValues(alpha: 0.15);
        fg = TomsColors.accent;
        bdr = TomsColors.accent.withValues(alpha: 0.2);
      case 'paid' || 'active' || 'approved':
        bg = TomsColors.success.withValues(alpha: 0.15);
        fg = TomsColors.success;
        bdr = TomsColors.success.withValues(alpha: 0.2);
      case 'overdue' || 'suspended' || 'rejected':
        bg = TomsColors.destructive.withValues(alpha: 0.15);
        fg = TomsColors.destructive;
        bdr = TomsColors.destructive.withValues(alpha: 0.2);
      case 'appealed':
        bg = TomsColors.primary.withValues(alpha: 0.15);
        fg = TomsColors.primary;
        bdr = TomsColors.primary.withValues(alpha: 0.2);
      case 'cancelled':
        bg = TomsColors.secondary;
        fg = TomsColors.mutedForeground;
        bdr = TomsColors.border;
      default:
        bg = TomsColors.secondary;
        fg = TomsColors.mutedForeground;
        bdr = TomsColors.border;
    }
    return StatusBadge(label: status, backgroundColor: bg, textColor: fg, borderColor: bdr);
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? TomsColors.secondary;
    final fg = textColor ?? TomsColors.mutedForeground;
    final bdr = borderColor ?? TomsColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: bdr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
