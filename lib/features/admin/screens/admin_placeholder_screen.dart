import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class AdminPlaceholderScreen extends StatelessWidget {
  final String title;
  final String route;
  
  const AdminPlaceholderScreen({super.key, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 48, color: TomsColors.mutedForeground),
              const SizedBox(height: 16),
              Text('$title Screen', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('This section is currently under construction.', style: TextStyle(color: TomsColors.mutedForeground)),
            ],
          ),
    );
  }
}
