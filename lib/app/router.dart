import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../core/services/seed_service.dart';
import '../app/theme.dart';

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
import '../features/admin/screens/admin_login_screen.dart';
import '../features/admin/screens/all_fines_screen.dart';
import '../features/admin/screens/appeals_management_screen.dart';
import '../features/admin/screens/admin_analytics_screen.dart';
import '../features/admin/screens/admin_audit_logs_screen.dart';
import '../features/admin/screens/admin_configuration_screen.dart';
import '../features/admin/screens/admin_notifications_screen.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/widgets/admin_shell.dart';

/// Helper class to convert a Stream into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Global GoRouter instance with auth-aware redirect
final goRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: _globalRedirect,
  routes: [
    // ─── Public routes ──────────────────────────────────
    GoRoute(path: '/', builder: (_, __) => const RoleSelectorScreen()),
    GoRoute(path: '/police/login', builder: (_, __) => const PoliceLoginScreen()),
    GoRoute(path: '/driver/login', builder: (_, __) => const DriverLoginScreen()),
    GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),

    // ─── Police routes (auth required) ──────────────────
    GoRoute(path: '/police/dashboard', builder: (_, __) => const PoliceDashboardScreen()),
    GoRoute(path: '/police/search', builder: (_, __) => const DriverSearchScreen()),
    GoRoute(path: '/police/issue-fine', builder: (_, __) => const IssueFineScreen()),
    GoRoute(path: '/police/history', builder: (_, __) => const OfficerFineHistoryScreen()),

    // ─── Driver routes (auth required) ──────────────────
    GoRoute(path: '/driver/dashboard', builder: (_, __) => const DriverDashboardScreen()),
    GoRoute(path: '/driver/vehicles', builder: (_, __) => const VehicleManagementScreen()),
    GoRoute(path: '/driver/fines', builder: (_, __) => const FineListScreen()),
    GoRoute(
      path: '/driver/fines/detail',
      builder: (_, state) => FineDetailScreen(
        fineId: state.uri.queryParameters['fineId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/driver/payment',
      builder: (_, state) => PaymentScreen(
        fineId: state.uri.queryParameters['fineId'],
      ),
    ),
    GoRoute(
      path: '/driver/appeals',
      builder: (_, state) => DriverAppealsScreen(
        initialFineId: state.uri.queryParameters['fineId'],
      ),
    ),
    GoRoute(path: '/driver/profile', builder: (_, __) => const DriverProfileScreen()),

    // ─── Admin routes (auth required) ───────────────────
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
        GoRoute(path: '/admin/fines', builder: (_, __) => const AllFinesScreen()),
        GoRoute(path: '/admin/appeals', builder: (_, __) => const AppealsManagementScreen()),
        GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
        GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsScreen()),
        GoRoute(path: '/admin/config', builder: (_, __) => const AdminConfigurationScreen()),
        GoRoute(path: '/admin/audit', builder: (_, __) => const AdminAuditLogsScreen()),
        GoRoute(path: '/admin/notifications', builder: (_, __) => const AdminNotificationsScreen()),
      ],
    ),
  ],
);

/// Global redirect: protect police/driver/admin routes
String? _globalRedirect(BuildContext context, GoRouterState state) {
  final user = FirebaseAuth.instance.currentUser;
  final path = state.uri.path;

  // Public routes — always accessible
  if (path == '/' || path == '/police/login' || path == '/driver/login' || path == '/admin/login') {
    return null;
  }

  // If not logged in, redirect to role selector
  if (user == null) {
    return '/';
  }

  return null; // Allow navigation
}

// ─── Role Selector Screen (kept here for router proximity) ──────

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});
  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  bool _seeding = false;
  String? _seedResult;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to auto-redirect
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _redirectUser();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _redirectUser() async {
    final auth = AuthService();
    if (auth.currentUser != null) {
      final profile = await auth.getCurrentUserProfile();
      if (profile != null && mounted) {
        // Double check auth state after async fetch to prevent race conditions during sign-out
        if (auth.currentUser == null) return;
        
        if (profile.isPolice) context.go('/police/dashboard');
        else if (profile.isDriver) context.go('/driver/dashboard');
        else if (profile.isAdmin) context.go('/admin/dashboard');
      }
    }
  }

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
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))), child: const Icon(Icons.shield, size: 40, color: Colors.white)),
              const SizedBox(height: 20),
              const Text('TOMS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Traffic Offence Management System', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 40),
              _roleCard(context, Icons.shield_outlined, 'Police Officer', 'Issue fines, search drivers, manage enforcement', TomsColors.policeGradient, '/police/login'),
              const SizedBox(height: 12),
              _roleCard(context, Icons.directions_car, 'Driver', 'View fines, make payments, submit appeals', TomsColors.driverGradient, '/driver/login'),
              const SizedBox(height: 12),
              _roleCard(context, Icons.admin_panel_settings, 'Administrator', 'Dashboard, reports, system configuration', LinearGradient(colors: [TomsColors.accent, TomsColors.accent.withValues(alpha: 0.8)]), '/admin/login'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _seeding ? null : () async {
                  setState(() { _seeding = true; _seedResult = null; });
                  try {
                    final seed = SeedService();
                    final offences = await seed.seedOffences();
                    final vehicles = await seed.seedVehicles();
                    if (mounted) setState(() { _seeding = false; _seedResult = offences > 0 || vehicles > 0 ? '✅ Seeded $offences offences + $vehicles vehicles' : '✅ Already seeded'; });
                  } catch (e) { if (mounted) setState(() { _seeding = false; _seedResult = '❌ Error: $e'; }); }
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
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), border: Border.all(color: TomsColors.border.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 24, color: Colors.white)),
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
    for (double x = 0; x < size.width; x += 30) { for (double y = 0; y < size.height; y += 30) { canvas.drawCircle(Offset(x, y), 1, paint); } }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
