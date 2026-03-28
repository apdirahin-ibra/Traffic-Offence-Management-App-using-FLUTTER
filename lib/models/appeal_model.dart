import 'package:cloud_firestore/cloud_firestore.dart';

class AppealMessage {
  final String senderId;
  final String text;
  final DateTime? timestamp;

  const AppealMessage({required this.senderId, required this.text, this.timestamp});

  factory AppealMessage.fromMap(Map<dynamic, dynamic> m) {
    final rawTimestamp = m['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    }

    return AppealMessage(
      senderId: (m['senderId'] ?? '').toString(),
      text: (m['text'] ?? '').toString(),
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
  };
}

class AppealModel {
  final String id;
  final String fineId;
  final String driverId;
  final String reason;
  final String? documentUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final List<AppealMessage> messages;
  final DateTime? createdAt;

  const AppealModel({
    required this.id,
    required this.fineId,
    required this.driverId,
    required this.reason,
    this.documentUrl,
    this.status = 'pending',
    this.messages = const [],
    this.createdAt,
  });

  factory AppealModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawMessages = d['messages'] as List<dynamic>? ?? const [];
    return AppealModel(
      id: doc.id,
      fineId: d['fineId'] ?? '',
      driverId: d['driverId'] ?? '',
      reason: d['reason'] ?? '',
      documentUrl: d['documentUrl'],
      status: d['status'] ?? 'pending',
      messages: rawMessages
          .whereType<Map>()
          .map((m) => AppealMessage.fromMap(Map<dynamic, dynamic>.from(m)))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fineId': fineId,
    'driverId': driverId,
    'reason': reason,
    if (documentUrl != null) 'documentUrl': documentUrl,
    'status': status,
    'messages': messages.map((m) => m.toMap()).toList(),
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };

  AppealModel copyWith({String? status, List<AppealMessage>? messages}) {
    return AppealModel(
      id: id, fineId: fineId, driverId: driverId,
      reason: reason, documentUrl: documentUrl,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get shortId => id.length > 5 ? 'AP-${id.substring(id.length - 3).toUpperCase()}' : id;
}
