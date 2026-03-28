import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _checkLockout(String identifier) async {
    final docId = identifier.replaceAll('@', '_').replaceAll('.', '_');
    final doc = await _db.collection('login_attempts').doc(docId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();

    if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
      final remaining = lockedUntil.difference(DateTime.now()).inMinutes;
      throw 'Account locked due to too many failed attempts. Try again in $remaining minutes or contact Administrator.';
    } else if (lockedUntil != null && lockedUntil.isBefore(DateTime.now())) {
      await _clearFailedAttempts(identifier);
    }
  }

  Future<void> _recordFailedAttempt(String identifier) async {
    final docId = identifier.replaceAll('@', '_').replaceAll('.', '_');
    final ref = _db.collection('login_attempts').doc(docId);
    final doc = await ref.get();

    int attempts = 1;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      attempts = (data['attempts'] as int? ?? 0) + 1;
    }

    if (attempts >= 5) {
      await ref.set({
        'attempts': attempts,
        'lockedUntil': FieldValue.serverTimestamp(),
      });
      await ref.update({
        'lockedUntil': DateTime.now().add(const Duration(minutes: 30)),
        'lastAttempt': FieldValue.serverTimestamp(),
      });
      throw 'Account locked for 30 minutes due to 5 consecutive failed login attempts.';
    }

    await ref.set({
      'attempts': attempts,
      'lastAttempt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    throw 'Invalid credentials. Attempt $attempts of 5 before account lock.';
  }

  Future<void> _clearFailedAttempts(String identifier) async {
    final docId = identifier.replaceAll('@', '_').replaceAll('.', '_');
    await _db.collection('login_attempts').doc(docId).delete().catchError((_) {});
  }

  Future<void> _clearFailedAttemptsForIdentifiers(Iterable<String> identifiers) async {
    for (final identifier in identifiers.map((value) => value.trim()).where((value) => value.isNotEmpty)) {
      await _clearFailedAttempts(identifier);
    }
  }

  String _getPoliceEmail(String badgeId) => 'badge_${badgeId.toLowerCase()}@police.toms.com';
  String _getDriverEmail(String nationalId) => 'nat_${nationalId.toLowerCase()}@driver.toms.com';
  String _getDriverProfileEmail(String username) => '${username.trim().toLowerCase()}@driver.toms.com';

  String _normalizeDriverEmailUsername(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    if (trimmed.endsWith('@driver.toms.com')) {
      return trimmed.replaceFirst('@driver.toms.com', '');
    }
    return trimmed;
  }

  Future<UserModel?> signInPolice(String badgeId, String password) async {
    final normalizedBadge = badgeId.trim().toUpperCase();
    var query = await _db.collection('users').where('role', isEqualTo: 'police').where('badgeNumber', isEqualTo: normalizedBadge).limit(1).get();
    if (query.docs.isEmpty) {
      query = await _db.collection('users').where('role', isEqualTo: 'police').where('badgeId', isEqualTo: normalizedBadge).limit(1).get();
    }
    if (query.docs.isEmpty) throw 'Invalid credentials. Attempt 1 of 5 before account lock.';

    final firestoreEmail = (query.docs.first.data()['email'] as String?)?.trim();
    final internalEmail = _getPoliceEmail(normalizedBadge);
    final candidateEmails = <String>[
      internalEmail,
      if (firestoreEmail != null && firestoreEmail.isNotEmpty && firestoreEmail != internalEmail) firestoreEmail,
    ];

    String lastError = 'Invalid credentials. Attempt 1 of 5 before account lock.';
    for (final email in candidateEmails) {
      try {
        return await _signInWithLockout(email, password, 'police');
      } catch (error) {
        lastError = error.toString().replaceFirst('Exception: ', '');
        final normalized = lastError.toLowerCase();
        final shouldTryNext = normalized.contains('invalid credentials') ||
            normalized.contains('user-not-found') ||
            normalized.contains('wrong-password') ||
            normalized.contains('invalid-credential');
        if (!shouldTryNext) rethrow;
      }
    }

    throw lastError;
  }

  Future<UserModel?> signInDriver(String licenseNumber, String password) async {
    final normalizedLicense = licenseNumber.trim().toUpperCase();
    final query = await _db.collection('users').where('role', isEqualTo: 'driver').where('licenseNumber', isEqualTo: normalizedLicense).limit(1).get();
    if (query.docs.isEmpty) throw 'Invalid credentials. Attempt 1 of 5 before account lock.';

    final data = query.docs.first.data();
    final firestoreEmail = (data['email'] as String?)?.trim();
    final nationalId = (data['nationalId'] as String?)?.trim() ?? '';
    final internalEmail = nationalId.isEmpty ? null : _getDriverEmail(nationalId);

    final candidateEmails = <String>[
      if (firestoreEmail != null && firestoreEmail.isNotEmpty) firestoreEmail,
      if (internalEmail != null && internalEmail.isNotEmpty && internalEmail != firestoreEmail) internalEmail,
    ];

    if (candidateEmails.isEmpty) {
      throw 'Invalid account configuration. Missing email.';
    }

    String lastError = 'Invalid credentials. Attempt 1 of 5 before account lock.';
    for (final email in candidateEmails) {
      try {
        return await _signInWithLockout(email, password, 'driver');
      } catch (error) {
        lastError = error.toString().replaceFirst('Exception: ', '');
        final normalized = lastError.toLowerCase();
        final shouldTryNext = normalized.contains('invalid credentials') ||
            normalized.contains('user-not-found') ||
            normalized.contains('wrong-password') ||
            normalized.contains('invalid-credential');
        if (!shouldTryNext) rethrow;
      }
    }

    throw lastError;
  }

  Future<UserModel?> signInAdmin(String email, String password) async {
    return _signInWithLockout(email, password, 'admin');
  }

  Future<UserModel?> _signInWithLockout(String email, String password, String expectedRole) async {
    await _checkLockout(email);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user == null) return null;

      final userProfile = await getUserProfile(cred.user!.uid);
      if (userProfile == null || userProfile.role != expectedRole) {
        await _auth.signOut();
        throw 'Access denied. Incorrect role.';
      }
      if (!userProfile.isActive) {
        await _auth.signOut();
        throw 'This account has been deactivated. Contact an administrator.';
      }

      await _clearFailedAttempts(email);
      return userProfile;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _recordFailedAttempt(email);
      }
      throw e.message ?? 'Authentication failed';
    }
  }

  Future<UserModel?> registerDriver({
    required String nationalId,
    required String password,
    required String name,
    String phone = '',
    String licenseNumber = '',
    String emailUsername = '',
  }) async {
    final normalizedNationalId = nationalId.trim();
    final normalizedLicense = licenseNumber.trim().toUpperCase();
    final normalizedUsername = _normalizeDriverEmailUsername(emailUsername);
    final profileEmail = _getDriverProfileEmail(normalizedUsername);

    if (normalizedLicense.isEmpty) {
      throw 'Registration rejected. License number is required.';
    }
    if (normalizedUsername.isEmpty) {
      throw 'Registration rejected. Email username is required.';
    }
    if (nationalId.length != 13 || int.tryParse(nationalId) == null) {
      throw 'Registration rejected. National ID must be exactly 13 digits.';
    }

    final existingLicense = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('licenseNumber', isEqualTo: normalizedLicense)
        .limit(1)
        .get();
    if (existingLicense.docs.isNotEmpty) {
      throw 'This license number is already registered.';
    }

    final existingNationalId = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('nationalId', isEqualTo: normalizedNationalId)
        .limit(1)
        .get();
    if (existingNationalId.docs.isNotEmpty) {
      throw 'This national ID is already registered.';
    }

    final existingProfileEmail = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('email', isEqualTo: profileEmail)
        .limit(1)
        .get();
    if (existingProfileEmail.docs.isNotEmpty) {
      throw 'This email username is already taken.';
    }

    final internalEmail = _getDriverEmail(normalizedNationalId);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: internalEmail,
        password: password,
      );
      if (cred.user == null) return null;

      final user = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: profileEmail,
        nationalId: normalizedNationalId,
        role: 'driver',
        phone: phone,
        licenseNumber: normalizedLicense,
      );

      await _db.collection('users').doc(user.uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw 'This driver account is already registered.';
      rethrow;
    }
  }

  Future<UserModel?> adminCreateUser({
    required String role,
    required String name,
    required String password,
    String? nationalId,
    String? badgeId,
    String? email,
    String? phone,
    String? licenseNumber,
  }) async {
    final currentUserProf = await getCurrentUserProfile();
    if (currentUserProf == null || !currentUserProf.isAdmin) {
      throw 'Permission denied. Only Administrators can create accounts.';
    }

    String createEmail = '';

    if (role == 'police') {
      if (badgeId == null || badgeId.isEmpty) throw 'Badge ID is required for Police Officers';
      final normalizedBadge = badgeId.trim().toUpperCase();
      final existingBadge = await _db.collection('users')
          .where('role', isEqualTo: 'police')
          .where('badgeNumber', isEqualTo: normalizedBadge)
          .limit(1)
          .get();
      if (existingBadge.docs.isNotEmpty) {
        throw 'This badge ID is already registered.';
      }
      createEmail = _getPoliceEmail(normalizedBadge);
    } else if (role == 'driver') {
      if (nationalId == null || nationalId.isEmpty) throw 'National ID is required for Drivers';
      if (licenseNumber == null || licenseNumber.isEmpty) throw 'License number is required for Drivers';
      if (email == null || email.isEmpty) throw 'Email username is required for Drivers';
      final normalizedLicense = licenseNumber.trim().toUpperCase();
      final normalizedNationalId = nationalId.trim();
      final normalizedProfileEmail = _getDriverProfileEmail(_normalizeDriverEmailUsername(email));

      final existingLicense = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('licenseNumber', isEqualTo: normalizedLicense)
          .limit(1)
          .get();
      if (existingLicense.docs.isNotEmpty) {
        throw 'This license number is already registered.';
      }

      final existingNationalId = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('nationalId', isEqualTo: normalizedNationalId)
          .limit(1)
          .get();
      if (existingNationalId.docs.isNotEmpty) {
        throw 'This national ID is already registered.';
      }

      final existingProfileEmail = await _db.collection('users')
          .where('role', isEqualTo: 'driver')
          .where('email', isEqualTo: normalizedProfileEmail)
          .limit(1)
          .get();
      if (existingProfileEmail.docs.isNotEmpty) {
        throw 'This email username is already taken.';
      }

      createEmail = _getDriverEmail(nationalId);
    } else if (role == 'admin') {
      if (email == null || email.isEmpty) throw 'Email is required for Administrators';
      createEmail = email;
    } else {
      throw 'Unknown role';
    }

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryCreateApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: createEmail,
        password: password,
      );

      if (cred.user == null) return null;

      final newUser = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: role == 'driver'
            ? _getDriverProfileEmail(_normalizeDriverEmailUsername(email!))
            : role == 'police'
                ? createEmail
                : (email ?? createEmail),
        nationalId: nationalId ?? '',
        badgeId: badgeId?.trim().toUpperCase(),
        role: role,
        phone: phone ?? '',
        licenseNumber: role == 'driver' ? licenseNumber!.trim().toUpperCase() : '',
      );

      await _db.collection('users').doc(newUser.uid).set({
        ...newUser.toFirestore(),
        if (badgeId != null) 'badgeId': badgeId,
      });
      return newUser;
    } finally {
      await secondaryApp?.delete();
    }
  }

  Future<void> resetDriverPassword(String licenseNumber) async {
    final normalizedLicense = licenseNumber.trim().toUpperCase();
    if (normalizedLicense.isEmpty) throw 'Enter your license number first.';

    final query = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('licenseNumber', isEqualTo: normalizedLicense)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw 'No driver account was found for that license number.';
    }

    final nationalId = (query.docs.first.data()['nationalId'] as String?)?.trim() ?? '';
    if (nationalId.isEmpty) {
      throw 'This driver account is missing a national ID.';
    }

    await _auth.sendPasswordResetEmail(email: _getDriverEmail(nationalId));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUid == null) return null;
    return getUserProfile(currentUid!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toFirestore());
  }

  Future<void> updateDriverProfile({
    required String uid,
    required String name,
    required String nationalId,
    required String phone,
    required String licenseNumber,
    required String email,
  }) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw 'You must be signed in to update this profile.';
    }

    final currentProfile = await getUserProfile(uid);
    if (currentProfile == null || !currentProfile.isDriver) {
      throw 'Driver profile not found.';
    }

    final nextEmail = email.trim();
    if (nextEmail.isEmpty) {
      throw 'Email username is required.';
    }

    final normalizedEmail = _getDriverProfileEmail(_normalizeDriverEmailUsername(nextEmail));
    final existingEmail = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (existingEmail.docs.any((doc) => doc.id != uid)) {
      throw 'That email username is already in use.';
    }

    final normalizedLicense = licenseNumber.trim().toUpperCase();
    if (normalizedLicense.isEmpty) {
      throw 'License number is required.';
    }

    final existingLicense = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('licenseNumber', isEqualTo: normalizedLicense)
        .limit(1)
        .get();
    if (existingLicense.docs.any((doc) => doc.id != uid)) {
      throw 'That license number is already in use.';
    }

    final normalizedNationalId = nationalId.trim();
    final existingNationalId = await _db.collection('users')
        .where('role', isEqualTo: 'driver')
        .where('nationalId', isEqualTo: normalizedNationalId)
        .limit(1)
        .get();
    if (existingNationalId.docs.any((doc) => doc.id != uid)) {
      throw 'That national ID is already in use.';
    }

    final updatedUser = currentProfile.copyWith(
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      licenseNumber: normalizedLicense,
    );

    await _db.collection('users').doc(uid).update({
      ...updatedUser.toFirestore(),
      'nationalId': normalizedNationalId,
    });
  }

  Future<void> adminDeleteManagedUser(String uid) async {
    final currentUserProf = await getCurrentUserProfile();
    if (currentUserProf == null || !currentUserProf.isAdmin) {
      throw 'Permission denied. Only Administrators can manage accounts.';
    }
    if (currentUid == uid) {
      throw 'You cannot delete your own administrator account.';
    }

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw 'User not found.';
    }

    final target = UserModel.fromFirestore(doc);
    if (!(target.isAdmin || target.isPolice || target.isDriver)) {
      throw 'Only Driver, Police, and Administrator accounts can be managed here.';
    }

    await _db.collection('users').doc(uid).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminClearUserLoginLock(UserModel user) async {
    final currentUserProf = await getCurrentUserProfile();
    if (currentUserProf == null || !currentUserProf.isAdmin) {
      throw 'Permission denied. Only Administrators can manage login locks.';
    }

    final identifiers = <String>{};

    if (user.isDriver) {
      if (user.email.isNotEmpty) {
        identifiers.add(user.email);
      }
      if (user.nationalId.trim().isNotEmpty) {
        identifiers.add(_getDriverEmail(user.nationalId.trim()));
      }
    } else if (user.isPolice) {
      final badge = (user.badgeId ?? '').trim().toUpperCase();
      if (badge.isNotEmpty) {
        identifiers.add(_getPoliceEmail(badge));
      }
      if (user.email.isNotEmpty) {
        identifiers.add(user.email);
      }
    } else {
      if (user.email.isNotEmpty) {
        identifiers.add(user.email);
      }
    }

    if (identifiers.isEmpty) {
      throw 'No lock identifiers were found for this account.';
    }

    await _clearFailedAttemptsForIdentifiers(identifiers);
  }
}
