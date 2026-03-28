import 'package:cloud_firestore/cloud_firestore.dart';

class OffenceModel {
  final String id;
  final String name;
  final String category;
  final double amount;
  final int demeritPoints;
  final bool isActive;

  const OffenceModel({
    required this.id,
    required this.name,
    this.category = 'General',
    required this.amount,
    this.demeritPoints = 0,
    this.isActive = true,
  });

  factory OffenceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OffenceModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? 'General',
      amount: (d['amount'] ?? 0).toDouble(),
      demeritPoints: d['demeritPoints'] ?? 0,
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'category': category,
    'amount': amount,
    'demeritPoints': demeritPoints,
    'isActive': isActive,
  };
}
