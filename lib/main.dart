import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/services/offline_service.dart';
import 'widgets/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Hive for offline caching
  final offline = OfflineService();
  await offline.init();
  runApp(const TomsApp());
}

class TomsApp extends StatelessWidget {
  const TomsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionManager(
      child: MaterialApp.router(
        title: 'TOMS — Traffic Offence Management System',
        debugShowCheckedModeBanner: false,
        theme: TomsTheme.lightTheme,
        routerConfig: goRouter,
        builder: (context, appChild) {
          return Column(children: [
            // Offline banner
            _ConnectivityBanner(),
            Expanded(child: appChild ?? const SizedBox.shrink()),
          ]);
        },
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // connectivity_plus stream may fail on web — handle gracefully
    Stream<bool> stream;
    try {
      stream = OfflineService().connectivityStream;
    } catch (_) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<bool>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        if (snap.data == false) {
          return Material(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: TomsColors.accent,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.wifi_off, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('You\'re offline — data may be outdated', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
              ]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
