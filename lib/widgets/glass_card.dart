import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final BorderRadius? borderRadius;

  const GlassCard({super.key, required this.child, this.padding, this.elevated = false, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: TomsColors.card.withValues(alpha: 0.95),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(color: TomsColors.border.withValues(alpha: elevated ? 0.4 : 0.6)),
            boxShadow: elevated
                ? [BoxShadow(color: TomsColors.primary.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
