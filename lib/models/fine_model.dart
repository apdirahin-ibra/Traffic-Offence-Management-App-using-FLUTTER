import 'package:cloud_firestore/cloud_firestore.dart';

class FineModel {
  final String id;
  final String driverId;
  final String officerId;
  final String vehiclePlate;
  final String offenceType;
  final double amount;
  final int demeritPoints;
  final String status; // 'pending' | 'paid' | 'overdue' | 'appealed' | 'cancelled'
  final double? lat;
  final double? lng;
  final List<String> evidenceUrls;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? driverName;   // denormalized for quick display
  final String? officerName;  // denormalized for quick display

  const FineModel({
    required this.id,
    required this.driverId,
    required this.officerId,
    required this.vehiclePlate,
    required this.offenceType,
    required this.amount,
    this.demeritPoints = 0,
    this.status = 'pending',
    this.lat,
    this.lng,
    this.evidenceUrls = const [],
    this.issuedAt,
    this.dueDate,
    this.paidAt,
    this.driverName,
    this.officerName,
  });

  factory FineModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final loc = d['location'] as Map<String, dynamic>?;
    return FineModel(
      id: doc.id,
      driverId: d['driverId'] ?? '',
      officerId: d['officerId'] ?? '',
      vehiclePlate: d['vehiclePlate'] ?? '',
      offenceType: d['offenceType'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      demeritPoints: d['demeritPoints'] ?? 0,
      status: d['status'] ?? 'pending',
      lat: loc?['lat']?.toDouble(),
      lng: loc?['lng']?.toDouble(),
      evidenceUrls: List<String>.from(d['evidenceUrls'] ?? []),
      issuedAt: (d['issuedAt'] as Timestamp?)?.toDate(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
      driverName: d['driverName'],
      officerName: d['officerName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'driverId': driverId,
    'officerId': officerId,
    'vehiclePlate': vehiclePlate,
    'offenceType': offenceType,
    'amount': amount,
    'demeritPoints': demeritPoints,
    'status': status,
    if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    'evidenceUrls': evidenceUrls,
    'issuedAt': issuedAt != null ? Timestamp.fromDate(issuedAt!) : FieldValue.serverTimestamp(),
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    if (driverName != null) 'driverName': driverName,
    if (officerName != null) 'officerName': officerName,
  };

  FineModel copyWith({String? status, DateTime? paidAt}) {
    return FineModel(
      id: id, driverId: driverId, officerId: officerId,
      vehiclePlate: vehiclePlate, offenceType: offenceType,
      amount: amount, demeritPoints: demeritPoints,
      status: status ?? this.status,
      lat: lat, lng: lng, evidenceUrls: evidenceUrls,
      issuedAt: issuedAt, dueDate: dueDate,
      paidAt: paidAt ?? this.paidAt,
      driverName: driverName, officerName: officerName,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
  bool get isAppealed => status == 'appealed';

  String get shortId => id.length > 8 ? 'FN-${id.substring(id.length - 5).toUpperCase()}' : id;
}
