import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String nationalId;
  final String? badgeId;       // police only
  final String role;           // 'police' | 'driver' | 'admin'
  final String phone;
  final String licenseNumber;
  final bool isActive;
  final int demeritPoints;
  final String licenseStatus;  // 'active' | 'suspended' | 'revoked'
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.nationalId,
    this.badgeId,
    required this.role,
    this.phone = '',
    this.licenseNumber = '',
    this.isActive = true,
    this.demeritPoints = 0,
    this.licenseStatus = 'active',
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final storedBadge = d['badgeNumber'] ?? d['badgeId'];
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      nationalId: d['nationalId'] ?? '',
      badgeId: storedBadge,
      role: d['role'] ?? 'driver',
      phone: d['phone'] ?? '',
      licenseNumber: d['licenseNumber'] ?? '',
      isActive: d['isActive'] ?? true,
      demeritPoints: d['demeritPoints'] ?? 0,
      licenseStatus: d['licenseStatus'] ?? 'active',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'nationalId': nationalId,
    if (badgeId != null) 'badgeNumber': badgeId,
    'role': role,
    'phone': phone,
    'licenseNumber': licenseNumber,
    'isActive': isActive,
    'demeritPoints': demeritPoints,
    'licenseStatus': licenseStatus,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? licenseNumber,
    int? demeritPoints,
    String? licenseStatus,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      nationalId: nationalId,
      badgeId: badgeId,
      role: role,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isActive: isActive ?? this.isActive,
      demeritPoints: demeritPoints ?? this.demeritPoints,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      createdAt: createdAt,
    );
  }

  bool get isPolice => role == 'police';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => licenseStatus == 'suspended';
}
