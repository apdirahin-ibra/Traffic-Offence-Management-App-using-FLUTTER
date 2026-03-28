import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/services/seed_service.dart';

// Police screens
import '../features/police/screens/police_login_screen.dart';
import '../features/police/screens/police_dashboard_screen.dart';
import '../features/police/screens/driver_search_screen.dart';
import '../features/police/screens/issue_fine_screen.dart';
import '../features/police/screens/officer_fine_history_screen.dart';

// Driver screens
import '../features/driver/screens/driver_login_screen.dart';
import '../features/driver/screens/driver_dashboard_screen.dart';
import '../features/driver/screens/vehicle_management_screen.dart';
import '../features/driver/screens/fine_list_screen.dart';
import '../features/driver/screens/fine_detail_screen.dart';
import '../features/driver/screens/payment_screen.dart';
import '../features/driver/screens/appeal_submission_screen.dart';
import '../features/driver/screens/driver_profile_screen.dart';

// Admin screens
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/all_fines_screen.dart';
import '../features/admin/screens/appeals_management_screen.dart';
import '../features/admin/screens/admin_placeholder_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const RoleSelectorScreen(),
    '/police/login': (context) => const PoliceLoginScreen(),
    '/police/dashboard': (context) => const PoliceDashboardScreen(),
    '/police/search': (context) => const DriverSearchScreen(),
    '/police/issue-fine': (context) => const IssueFineScreen(),
    '/police/history': (context) => const OfficerFineHistoryScreen(),
    '/driver/login': (context) => const DriverLoginScreen(),
    '/driver/dashboard': (context) => const DriverDashboardScreen(),
    '/driver/vehicles': (context) => const VehicleManagementScreen(),
    '/driver/fines': (context) => const FineListScreen(),
    '/driver/fines/detail': (context) => const FineDetailScreen(fineId: ''),
    '/driver/payment': (context) => const PaymentScreen(),
    '/driver/appeals': (context) => const DriverAppealsScreen(initialFineId: null),
    '/driver/profile': (context) => const DriverProfileScreen(),
    '/admin/dashboard': (context) => const AdminDashboardScreen(),
    '/admin/users': (context) => const AdminPlaceholderScreen(title: 'Users', route: '/admin/users'),
    '/admin/fines': (context) => const AllFinesScreen(),
    '/admin/appeals': (context) => const AppealsManagementScreen(),
    '/admin/analytics': (context) => const AdminPlaceholderScreen(title: 'Analytics', route: '/admin/analytics'),
    '/admin/reports': (context) => const AdminPlaceholderScreen(title: 'Reports', route: '/admin/reports'),
    '/admin/config': (context) => const AdminPlaceholderScreen(title: 'Configuration', route: '/admin/config'),
    '/admin/audit': (context) => const AdminPlaceholderScreen(title: 'Audit Logs', route: '/admin/audit'),
    '/admin/notifications': (context) => const AdminPlaceholderScreen(title: 'Notifications', route: '/admin/notifications'),
  };
}

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});
  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  bool _seeding = false;
  String? _seedResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: TomsColors.policeGradient)),
        Positioned.fill(child: Opacity(opacity: 0.03, child: CustomPaint(painter: _DotPatternPainter()))),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                child: const Icon(Icons.shield, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('TOMS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Traffic Offence Management System', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 40),
              _roleCard(context, Icons.shield_outlined, 'Police Officer', 'Issue fines, search drivers, manage enforcement', TomsColors.policeGradient, '/police/login'),
              const SizedBox(height: 12),
              _roleCard(context, Icons.directions_car, 'Driver', 'View fines, make payments, submit appeals', TomsColors.driverGradient, '/driver/login'),
              const SizedBox(height: 12),
              _roleCard(context, Icons.admin_panel_settings, 'Administrator', 'Dashboard, reports, system configuration', LinearGradient(colors: [TomsColors.accent, TomsColors.accent.withValues(alpha: 0.8)]), '/admin/dashboard'),
              const SizedBox(height: 24),
              // Seed button
              GestureDetector(
                onTap: _seeding ? null : () async {
                  setState(() { _seeding = true; _seedResult = null; });
                  try {
                    final seed = SeedService();
                    final offences = await seed.seedOffences();
                    final vehicles = await seed.seedVehicles();
                    if (mounted) setState(() { _seeding = false; _seedResult = offences > 0 || vehicles > 0 ? '✅ Seeded $offences offences + $vehicles vehicles' : '✅ Already seeded'; });
                  } catch (e) {
                    if (mounted) setState(() { _seeding = false; _seedResult = '❌ Error: $e'; });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _seeding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.dataset, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(_seeding ? 'Seeding...' : 'Seed Database', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                  ]),
                ),
              ),
              if (_seedResult != null) ...[const SizedBox(height: 8), Text(_seedResult!, style: const TextStyle(fontSize: 12, color: Colors.white))],
              const SizedBox(height: 24),
              Text('© 2026 National Traffic Authority', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            ]),
          ),
        ))),
      ]),
    );
  }

  Widget _roleCard(BuildContext context, IconData icon, String title, String desc, LinearGradient gradient, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TomsColors.border.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TomsColors.foreground)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
          ])),
          Icon(Icons.chevron_right, size: 20, color: TomsColors.mutedForeground),
        ]),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
