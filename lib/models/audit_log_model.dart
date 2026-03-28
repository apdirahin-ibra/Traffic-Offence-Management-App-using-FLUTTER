import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String action;
  final String details;
  final DateTime? timestamp;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    this.details = '',
    this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      action: d['action'] ?? '',
      details: d['details'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'action': action,
    'details': details,
    'timestamp': FieldValue.serverTimestamp(),
  };
}
