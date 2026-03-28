import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../app/router.dart';

class SessionManager extends StatefulWidget {
  final Widget child;
  const SessionManager({super.key, required this.child});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager> {
  Timer? _timer;
  final int _timeoutSeconds = 8 * 60 * 60; // 8 hours

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer([_]) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _timeoutSeconds), _logOutUser);
  }

  void _logOutUser() async {
    _timer?.cancel();
    final auth = AuthService();
    if (auth.currentUser != null) {
      await auth.signOut();
      if (mounted) {
        // We use goRouter.go since context.go might not work if outside of Navigator, 
        // but goRouter is our global instance
        goRouter.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired due to inactivity. Please log in again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _resetTimer,
      onPointerMove: _resetTimer,
      onPointerUp: _resetTimer,
      child: widget.child,
    );
  }
}
