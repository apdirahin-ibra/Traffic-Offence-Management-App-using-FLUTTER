import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fine_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/appeal_model.dart';
import '../../models/offence_model.dart';
import '../../models/user_model.dart';
import '../../models/audit_log_model.dart';

class DemeritUpdateResult {
  final int previousPoints;
  final int currentPoints;
  final bool autoSuspended;
  final String licenseStatus;

  const DemeritUpdateResult({
    required this.previousPoints,
    required this.currentPoints,
    required this.autoSuspended,
    required this.licenseStatus,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int suspensionThreshold = 50;

  List<FineModel> _sortFinesByIssuedAtDesc(Iterable<FineModel> fines) {
    final sorted = fines.toList();
    sorted.sort((a, b) {
      final aIssued = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bIssued = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bIssued.compareTo(aIssued);
    });
    return sorted;
  }

  List<FineModel> _sortFinesByIssuedAtAsc(Iterable<FineModel> fines) {
    final sorted = fines.toList();
    sorted.sort((a, b) {
      final aIssued = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bIssued = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aIssued.compareTo(bIssued);
    });
    return sorted;
  }

  List<AppealModel> _sortAppealsByCreatedAtDesc(Iterable<AppealModel> appeals) {
    final sorted = appeals.toList();
    sorted.sort((a, b) {
      final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });
    return sorted;
  }

  // ─── USERS ──────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
    );
  }

  Future<UserModel?> getUserByNationalId(String nid) async {
    final snap = await _db.collection('users')
        .where('nationalId', isEqualTo: nid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }

  Future<DemeritUpdateResult> updateDemeritPoints(
    String uid,
    int points, {
    String? actorUserId,
  }) async {
    final result = await _db.runTransaction((tx) async {
      final ref = _db.collection('users').doc(uid);
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw 'Driver not found.';
      }

      final user = UserModel.fromFirestore(snap);
      final previousPoints = user.demeritPoints;
      final currentPoints = (previousPoints + points).clamp(0, 9999);
      final reachedThreshold = user.isDriver && currentPoints >= suspensionThreshold;
      final autoSuspended = reachedThreshold && !user.isSuspended;

      final update = <String, dynamic>{
        'demeritPoints': currentPoints,
      };

      if (autoSuspended) {
        update['licenseStatus'] = 'suspended';
        update['suspendedAt'] = FieldValue.serverTimestamp();
        update['suspensionReason'] = 'demerit_threshold';
      }

      tx.update(ref, update);

      return DemeritUpdateResult(
        previousPoints: previousPoints,
        currentPoints: currentPoints,
        autoSuspended: autoSuspended,
        licenseStatus: autoSuspended ? 'suspended' : user.licenseStatus,
      );
    });

    if (result.autoSuspended) {
      await logAction(
        actorUserId ?? uid,
        'driver_auto_suspended',
        'Driver $uid was automatically suspended after reaching ${result.currentPoints} demerit points.',
      );
    }

    return result;
  }

  Stream<List<UserModel>> allUsersStream() {
    return _db.collection('users').snapshots().map(
      (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
    );
  }

  Future<void> adminUpdateManagedUser(UserModel user) async {
    if (user.isDriver) {
      final normalizedLicense = user.licenseNumber.trim().toUpperCase();
      if (normalizedLicense.isEmpty) {
        throw 'License number is required for drivers.';
      }

      final existingLicense = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('licenseNumber', isEqualTo: normalizedLicense)
          .limit(1)
          .get();
      if (existingLicense.docs.any((doc) => doc.id != user.uid)) {
        throw 'This license number is already registered.';
      }

      final normalizedNationalId = user.nationalId.trim();
      final existingNationalId = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('nationalId', isEqualTo: normalizedNationalId)
          .limit(1)
          .get();
      if (existingNationalId.docs.any((doc) => doc.id != user.uid)) {
        throw 'This national ID is already registered.';
      }

      final normalizedEmail = user.email.trim().toLowerCase();
      final existingEmail = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existingEmail.docs.any((doc) => doc.id != user.uid)) {
        throw 'This email username is already taken.';
      }
    }

    final update = <String, dynamic>{
      'name': user.name,
      'phone': user.phone,
      'isActive': user.isActive,
    };

    if (user.isPolice) {
      update['badgeNumber'] = user.badgeId;
      update['badgeId'] = user.badgeId;
    }

    if (user.isAdmin) {
      update['email'] = user.email;
    }
    if (user.isDriver) {
      update['email'] = user.email;
      update['licenseNumber'] = user.licenseNumber.trim().toUpperCase();
      update['nationalId'] = user.nationalId.trim();
      update['licenseStatus'] = user.licenseStatus;
    }

    await _db.collection('users').doc(user.uid).update(update);
  }

  Future<void> adminRestoreDriverLicense(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw 'Driver not found.';

    final user = UserModel.fromFirestore(doc);
    if (!user.isDriver) {
      throw 'Only driver licenses can be restored here.';
    }

    await _db.collection('users').doc(uid).update({
      'licenseStatus': 'active',
      'suspendedAt': FieldValue.delete(),
      'suspensionReason': FieldValue.delete(),
    });
  }

  Future<void> adminSuspendDriverLicense(String uid, {String reason = 'admin_action'}) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw 'Driver not found.';

    final user = UserModel.fromFirestore(doc);
    if (!user.isDriver) {
      throw 'Only driver licenses can be suspended here.';
    }

    await _db.collection('users').doc(uid).update({
      'licenseStatus': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspensionReason': reason,
    });
  }

  // ─── FINES ──────────────────────────────────────────────

  Future<String> createFine(FineModel fine) async {
    final ref = await _db.collection('fines').add(fine.toFirestore());
    return ref.id;
  }

  Future<FineModel?> getFine(String id) async {
    final doc = await _db.collection('fines').doc(id).get();
    if (!doc.exists) return null;
    return FineModel.fromFirestore(doc);
  }

  Future<void> updateFineStatus(String fineId, String status, {DateTime? paidAt}) async {
    final data = <String, dynamic>{'status': status};
    if (paidAt != null) data['paidAt'] = Timestamp.fromDate(paidAt);
    await _db.collection('fines').doc(fineId).update(data);
  }

  Stream<List<FineModel>> finesByDriverStream(String driverId) {
    return _db.collection('fines')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) => _sortFinesByIssuedAtDesc(
          snap.docs.map((d) => FineModel.fromFirestore(d)),
        ));
  }

  Stream<List<FineModel>> finesByOfficerStream(String officerId) {
    return _db.collection('fines')
        .where('officerId', isEqualTo: officerId)
        .snapshots()
        .map((snap) => _sortFinesByIssuedAtDesc(
          snap.docs.map((d) => FineModel.fromFirestore(d)),
        ));
  }

  Stream<List<FineModel>> allFinesStream() {
    return _db.collection('fines')
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FineModel.fromFirestore(d)).toList());
  }

  Stream<List<FineModel>> allFinesChronologicalStream() {
    return _db.collection('fines')
        .snapshots()
        .map((snap) => _sortFinesByIssuedAtAsc(
          snap.docs.map((d) => FineModel.fromFirestore(d)),
        ));
  }

  Future<List<FineModel>> getRecentFines({int limit = 5}) async {
    final snap = await _db.collection('fines')
        .orderBy('issuedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => FineModel.fromFirestore(d)).toList();
  }

  // ─── VEHICLES ───────────────────────────────────────────

  Future<String> addVehicle(VehicleModel vehicle) async {
    final ref = await _db.collection('vehicles').add(vehicle.toFirestore());
    return ref.id;
  }

  Stream<List<VehicleModel>> vehiclesByOwnerStream(String ownerId) {
    return _db.collection('vehicles')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList());
  }

  Stream<List<VehicleModel>> allVehiclesStream() {
    return _db.collection('vehicles')
        .snapshots()
        .map((snap) => snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList());
  }

  Future<VehicleModel?> getVehicleByPlate(String plate) async {
    final snap = await _db.collection('vehicles')
        .where('plateNumber', isEqualTo: plate)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return VehicleModel.fromFirestore(snap.docs.first);
  }

  Stream<List<VehicleModel>> vehiclesByPlatesStream(List<String> plates) {
    if (plates.isEmpty) return Stream.value(const []);

    return _db.collection('vehicles')
        .where('plateNumber', whereIn: plates.take(10).toList())
        .snapshots()
        .map((snap) => snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList());
  }

  Future<void> deleteVehicle(String id) async {
    await _db.collection('vehicles').doc(id).delete();
  }

  // ─── APPEALS ────────────────────────────────────────────

  Future<String> createAppeal(AppealModel appeal) async {
    final ref = await _db.collection('appeals').add(appeal.toFirestore());
    // Also update the fine status
    await updateFineStatus(appeal.fineId, 'appealed');
    return ref.id;
  }

  Stream<List<AppealModel>> appealsByDriverStream(String driverId) {
    return _db.collection('appeals')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) => _sortAppealsByCreatedAtDesc(
              snap.docs.map((d) => AppealModel.fromFirestore(d)),
            ));
  }

  Stream<List<AppealModel>> allAppealsStream() {
    return _db.collection('appeals')
        .snapshots()
        .map((snap) => _sortAppealsByCreatedAtDesc(
              snap.docs.map((d) => AppealModel.fromFirestore(d)),
            ));
  }

  Future<void> updateAppealStatus(String appealId, String status, {String? actorUserId}) async {
    final appealRef = _db.collection('appeals').doc(appealId);
    final appealSnap = await appealRef.get();
    if (!appealSnap.exists) {
      throw 'Appeal not found.';
    }

    final appeal = AppealModel.fromFirestore(appealSnap);
    final fine = await getFine(appeal.fineId);

    await appealRef.update({'status': status});

    if (fine != null) {
      if (status == 'approved') {
        await updateFineStatus(appeal.fineId, 'cancelled');
      } else if (status == 'rejected') {
        final now = DateTime.now();
        final nextFineStatus = fine.dueDate != null && fine.dueDate!.isBefore(now) ? 'overdue' : 'pending';
        await updateFineStatus(appeal.fineId, nextFineStatus);
      }
    }

    if (actorUserId != null) {
      await logAction(actorUserId, 'appeal_status_update', 'Updated appeal $appealId status to $status.');
    }
  }

  Future<void> addAppealMessage(String appealId, AppealMessage message, {String? actorUserId}) async {
    await _db.collection('appeals').doc(appealId).update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
    });
    if (actorUserId != null) {
      await logAction(actorUserId, 'appeal_message', 'Added a message to appeal $appealId.');
    }
  }

  // ─── OFFENCES (CONFIG) ──────────────────────────────────

  Stream<List<OffenceModel>> activeOffencesStream() {
    return _db.collection('offences')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OffenceModel.fromFirestore(d)).toList());
  }

  Future<List<OffenceModel>> getActiveOffences() async {
    final snap = await _db.collection('offences').where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) => OffenceModel.fromFirestore(d)).toList();
  }

  Future<void> addOffence(OffenceModel offence) async {
    await _db.collection('offences').add(offence.toFirestore());
  }

  Future<void> updateOffence(String id, Map<String, dynamic> data) async {
    await _db.collection('offences').doc(id).update(data);
  }

  // ─── AUDIT LOGS ─────────────────────────────────────────

  Future<void> logAction(String userId, String action, String details) async {
    await _db.collection('auditLogs').add(AuditLogModel(
      id: '',
      userId: userId,
      action: action,
      details: details,
    ).toFirestore());
  }

  Stream<List<AuditLogModel>> auditLogsStream({int limit = 50}) {
    return _db.collection('auditLogs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AuditLogModel.fromFirestore(d)).toList());
  }

  // ─── DASHBOARD STATS ───────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayFines = await _db.collection('fines')
        .where('issuedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    final pendingAppeals = await _db.collection('appeals')
        .where('status', isEqualTo: 'pending')
        .get();

    final overdueFines = await _db.collection('fines')
        .where('status', isEqualTo: 'overdue')
        .get();

    final activeUsers = await _db.collection('users')
        .where('isActive', isEqualTo: true)
        .get();

    double todayRevenue = 0;
    for (final doc in todayFines.docs) {
      final data = doc.data();
      if (data['status'] == 'paid') {
        todayRevenue += (data['amount'] ?? 0).toDouble();
      }
    }

    return {
      'finesToday': todayFines.docs.length,
      'revenueToday': todayRevenue,
      'pendingAppeals': pendingAppeals.docs.length,
      'overdueFines': overdueFines.docs.length,
      'activeUsers': activeUsers.docs.length,
    };
  }
}
