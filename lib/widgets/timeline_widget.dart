import 'package:flutter/material.dart';
import '../app/theme.dart';

enum StepStatus { complete, current, upcoming }

class TimelineStep {
  final String label;
  final String? date;
  final StepStatus status;
  const TimelineStep({required this.label, this.date, required this.status});
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;
  const TimelineWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        final circleColor = step.status == StepStatus.complete
            ? TomsColors.success
            : step.status == StepStatus.current
                ? TomsColors.accent
                : TomsColors.secondary;
        final iconColor = step.status == StepStatus.upcoming ? TomsColors.mutedForeground : Colors.white;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
                  child: Icon(
                    step.status == StepStatus.complete ? Icons.check :
                    step.status == StepStatus.current ? Icons.access_time : Icons.circle_outlined,
                    size: 14, color: iconColor,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2, height: 32,
                    color: step.status == StepStatus.complete ? TomsColors.success.withValues(alpha: 0.4) : TomsColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.label, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: step.status == StepStatus.upcoming ? TomsColors.mutedForeground : TomsColors.foreground,
                    )),
                    if (step.date != null)
                      Text(step.date!, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
