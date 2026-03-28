import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String ownerId;
  final String plateNumber;
  final String make;
  final String model;
  final String color;
  final String? year;
  final DateTime? registrationExpiry;

  const VehicleModel({
    required this.id,
    required this.ownerId,
    required this.plateNumber,
    required this.make,
    required this.model,
    this.color = '',
    this.year,
    this.registrationExpiry,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      plateNumber: d['plateNumber'] ?? '',
      make: d['make'] ?? '',
      model: d['model'] ?? '',
      color: d['color'] ?? '',
      year: d['year'],
      registrationExpiry: (d['registrationExpiry'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'plateNumber': plateNumber,
    'make': make,
    'model': model,
    'color': color,
    if (year != null) 'year': year,
    if (registrationExpiry != null) 'registrationExpiry': Timestamp.fromDate(registrationExpiry!),
  };

  String get displayName => '$color $make $model'.trim();
}
