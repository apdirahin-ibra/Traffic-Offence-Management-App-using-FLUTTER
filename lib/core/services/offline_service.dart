import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/fine_model.dart';
import 'firestore_service.dart';

/// Manages local Hive cache and offline queue for TOMS data.
class OfflineService {
  static const _finesBoxName = 'cached_fines';
  static const _queueBoxName = 'offline_queue';
  static const _settingsBoxName = 'settings';

  late Box<String> _finesBox;
  late Box<String> _queueBox;
  late Box<String> _settingsBox;

  /// Initialize Hive boxes – call once at startup
  Future<void> init() async {
    await Hive.initFlutter();
    _finesBox = await Hive.openBox<String>(_finesBoxName);
    _queueBox = await Hive.openBox<String>(_queueBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // ─── CONNECTIVITY ──────────────────────────────────────

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  // ─── FINE CACHING ──────────────────────────────────────

  /// Cache a list of fines locally
  Future<void> cacheFines(String userId, List<FineModel> fines) async {
    final jsonList = fines.map((f) => jsonEncode(f.toFirestore())).toList();
    await _finesBox.put(userId, jsonEncode(jsonList));
  }

  /// Get cached fines for a user (when offline)
  List<FineModel> getCachedFines(String userId) {
    final raw = _finesBox.get(userId);
    if (raw == null) return [];
    try {
      final jsonList = (jsonDecode(raw) as List).cast<String>();
      return jsonList.map((j) {
        final map = jsonDecode(j) as Map<String, dynamic>;
        return FineModel(
          id: map['id'] ?? '',
          driverId: map['driverId'] ?? '',
          officerId: map['officerId'] ?? '',
          vehiclePlate: map['vehiclePlate'] ?? '',
          offenceType: map['offenceType'] ?? '',
          amount: (map['amount'] ?? 0).toDouble(),
          demeritPoints: map['demeritPoints'] ?? 0,
          status: map['status'] ?? 'pending',
          driverName: map['driverName'],
          officerName: map['officerName'],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── OFFLINE QUEUE ─────────────────────────────────────

  /// Queue a fine to be created once online
  Future<void> queueFineCreation(FineModel fine) async {
    final key = 'fine_${DateTime.now().millisecondsSinceEpoch}';
    await _queueBox.put(key, jsonEncode(fine.toFirestore()));
  }

  /// Sync all queued operations when connectivity is restored
  Future<int> syncQueue() async {
    if (!(await isOnline)) return 0;

    final db = FirestoreService();
    int synced = 0;

    for (final key in _queueBox.keys.toList()) {
      try {
        final raw = _queueBox.get(key as String);
        if (raw == null) continue;

        final map = jsonDecode(raw) as Map<String, dynamic>;

        if (key.startsWith('fine_')) {
          final fine = FineModel(
            id: '',
            driverId: map['driverId'] ?? '',
            officerId: map['officerId'] ?? '',
            vehiclePlate: map['vehiclePlate'] ?? '',
            offenceType: map['offenceType'] ?? '',
            amount: (map['amount'] ?? 0).toDouble(),
            demeritPoints: map['demeritPoints'] ?? 0,
            status: map['status'] ?? 'pending',
            driverName: map['driverName'],
            officerName: map['officerName'],
          );
          await db.createFine(fine);
        }

        await _queueBox.delete(key);
        synced++;
      } catch (_) {
        // Keep in queue for next sync attempt
      }
    }

    return synced;
  }

  /// Number of pending items in the offline queue
  int get pendingQueueCount => _queueBox.length;

  // ─── SETTINGS ──────────────────────────────────────────

  Future<void> saveSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  String? getSetting(String key) => _settingsBox.get(key);

  /// Clear all cached data
  Future<void> clearAll() async {
    await _finesBox.clear();
    await _queueBox.clear();
    await _settingsBox.clear();
  }
}
