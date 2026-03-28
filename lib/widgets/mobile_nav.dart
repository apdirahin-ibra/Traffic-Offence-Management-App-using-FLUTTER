import 'package:flutter/material.dart';
import '../app/theme.dart';

class MobileNavItem {
  final String label;
  final IconData icon;
  final String route;
  const MobileNavItem({required this.label, required this.icon, required this.route});
}

class MobileNav extends StatelessWidget {
  final List<MobileNavItem> items;
  final String currentRoute;
  final void Function(String route) onNavigate;

  const MobileNav({super.key, required this.items, required this.currentRoute, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TomsColors.card,
        border: Border(top: BorderSide(color: TomsColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final active = currentRoute == item.route;
              return GestureDetector(
                onTap: () => onNavigate(item.route),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 20, color: active ? TomsColors.primary : TomsColors.mutedForeground),
                      const SizedBox(height: 2),
                      Text(item.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: active ? TomsColors.primary : TomsColors.mutedForeground)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
