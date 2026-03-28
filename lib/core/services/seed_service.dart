import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/offence_model.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _defaultOffences = [
    OffenceModel(id: '', name: 'Speeding - Over 10km/h', category: 'Speed', amount: 150, demeritPoints: 2),
    OffenceModel(id: '', name: 'Speeding - Over 20km/h', category: 'Speed', amount: 250, demeritPoints: 3),
    OffenceModel(id: '', name: 'Speeding - Over 40km/h', category: 'Speed', amount: 500, demeritPoints: 6),
    OffenceModel(id: '', name: 'Running Red Light', category: 'Signal', amount: 200, demeritPoints: 4),
    OffenceModel(id: '', name: 'Illegal Parking', category: 'Parking', amount: 100, demeritPoints: 1),
    OffenceModel(id: '', name: 'Driving Under Influence', category: 'DUI', amount: 500, demeritPoints: 6),
    OffenceModel(id: '', name: 'No Seatbelt', category: 'Safety', amount: 50, demeritPoints: 1),
    OffenceModel(id: '', name: 'Using Phone While Driving', category: 'Safety', amount: 150, demeritPoints: 2),
    OffenceModel(id: '', name: 'Expired Registration', category: 'Document', amount: 200, demeritPoints: 2),
    OffenceModel(id: '', name: 'No Insurance', category: 'Document', amount: 300, demeritPoints: 3),
    OffenceModel(id: '', name: 'Reckless Driving', category: 'Dangerous', amount: 750, demeritPoints: 8),
    OffenceModel(id: '', name: 'Wrong Way Driving', category: 'Dangerous', amount: 600, demeritPoints: 6),
    OffenceModel(id: '', name: 'Overloading', category: 'Vehicle', amount: 200, demeritPoints: 2),
    OffenceModel(id: '', name: 'Tinted Windows', category: 'Vehicle', amount: 100, demeritPoints: 1),
    OffenceModel(id: '', name: 'Failure to Stop', category: 'Signal', amount: 350, demeritPoints: 5),
  ];

  /// Seeds the offences collection if it's empty.
  /// Returns the number of offences added.
  Future<int> seedOffences() async {
    final existing = await _db.collection('offences').limit(1).get();
    if (existing.docs.isNotEmpty) return 0; // Already seeded

    final batch = _db.batch();
    for (final offence in _defaultOffences) {
      final ref = _db.collection('offences').doc();
      batch.set(ref, offence.toFirestore());
    }
    await batch.commit();
    return _defaultOffences.length;
  }

  /// Seeds sample vehicles for the first driver user.
  Future<int> seedVehicles() async {
    final existing = await _db.collection('vehicles').limit(1).get();
    if (existing.docs.isNotEmpty) return 0;

    // Find a driver user
    final drivers = await _db.collection('users').where('role', isEqualTo: 'driver').limit(1).get();
    if (drivers.docs.isEmpty) return 0;
    final driverId = drivers.docs.first.id;

    final vehicles = [
      {'ownerId': driverId, 'plateNumber': 'KAA 234X', 'make': 'Toyota', 'model': 'Corolla', 'color': 'White', 'year': '2022'},
      {'ownerId': driverId, 'plateNumber': 'KBB 567Y', 'make': 'Honda', 'model': 'Civic', 'color': 'Silver', 'year': '2021'},
    ];

    final batch = _db.batch();
    for (final v in vehicles) {
      batch.set(_db.collection('vehicles').doc(), v);
    }
    await batch.commit();
    return vehicles.length;
  }
}
