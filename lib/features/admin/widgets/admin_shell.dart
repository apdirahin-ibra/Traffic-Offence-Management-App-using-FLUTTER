import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'admin_layout.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Get current route to pass to sidebar for highlighting
    final String currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            currentRoute: currentRoute,
            onNavigate: (route) => context.go(route),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
