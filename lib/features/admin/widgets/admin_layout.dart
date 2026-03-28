import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;

  const AdminSidebar({super.key, required this.currentRoute, required this.onNavigate});

  static const _navItems = [
    {'label': 'Dashboard', 'icon': Icons.dashboard_outlined, 'route': '/admin/dashboard'},
    {'label': 'Users', 'icon': Icons.people_outline, 'route': '/admin/users'},
    {'label': 'Fines', 'icon': Icons.description_outlined, 'route': '/admin/fines'},
    {'label': 'Appeals', 'icon': Icons.message_outlined, 'route': '/admin/appeals'},
    {'label': 'Analytics', 'icon': Icons.bar_chart, 'route': '/admin/analytics'},
    {'label': 'Reports', 'icon': Icons.download_outlined, 'route': '/admin/reports'},
    {'label': 'Configuration', 'icon': Icons.settings_outlined, 'route': '/admin/config'},
    {'label': 'Audit Logs', 'icon': Icons.shield_outlined, 'route': '/admin/audit'},
    {'label': 'Notifications', 'icon': Icons.notifications_none, 'route': '/admin/notifications'},
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;
    if (!isWide) return const SizedBox.shrink();

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: TomsColors.sidebarBg,
        border: Border(right: BorderSide(color: TomsColors.sidebarBorder)),
      ),
      child: Column(children: [
        // Logo
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shield, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOMS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
              Text('Admin Panel', style: TextStyle(fontSize: 11, color: TomsColors.sidebarMuted)),
            ]),
          ]),
        ),
        Divider(height: 1, color: TomsColors.sidebarBorder),
        const SizedBox(height: 12),
        // Nav items
        ...(_navItems.map((item) {
          final active = currentRoute == item['route'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Material(
              color: active ? TomsColors.sidebarAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onNavigate(item['route'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Icon(item['icon'] as IconData, size: 18, color: active ? Colors.white : TomsColors.sidebarMuted),
                    const SizedBox(width: 12),
                    Text(item['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : TomsColors.sidebarFg)),
                  ]),
                ),
              ),
            ),
          );
        })),
        const Spacer(),
        // Sign out
        Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                await AuthService().signOut();
                onNavigate('/');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: TomsColors.sidebarMuted),
                  const SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(fontSize: 13, color: TomsColors.sidebarMuted)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
