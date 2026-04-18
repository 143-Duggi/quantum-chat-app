import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String contactUid;
  final String contactUsername;
  final String contactUniqueId;
  final String contactPubKey;
  final DateTime addedAt;
  final bool blocked;
  final DateTime? blockedAt;

  Contact({
    required this.contactUid,
    required this.contactUsername,
    required this.contactUniqueId,
    required this.contactPubKey,
    required this.addedAt,
    this.blocked = false,
    this.blockedAt,
  });

  // Create Contact from Firestore document
  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Contact(
      contactUid: data['contactUid'] ?? '',
      contactUsername: data['contactUsername'] ?? 'Unknown',
      contactUniqueId: data['contactUniqueId'] ?? '',
      contactPubKey: data['contactPubKey'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      blocked: data['blocked'] ?? false,
      blockedAt: (data['blockedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert Contact to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'contactUid': contactUid,
      'contactUsername': contactUsername,
      'contactUniqueId': contactUniqueId,
      'contactPubKey': contactPubKey,
      'addedAt': Timestamp.fromDate(addedAt),
      'blocked': blocked,
      if (blockedAt != null) 'blockedAt': Timestamp.fromDate(blockedAt!),
    };
  }

  // Copy with method for updating fields
  Contact copyWith({
    String? contactUid,
    String? contactUsername,
    String? contactUniqueId,
    String? contactPubKey,
    DateTime? addedAt,
    bool? blocked,
    DateTime? blockedAt,
  }) {
    return Contact(
      contactUid: contactUid ?? this.contactUid,
      contactUsername: contactUsername ?? this.contactUsername,
      contactUniqueId: contactUniqueId ?? this.contactUniqueId,
      contactPubKey: contactPubKey ?? this.contactPubKey,
      addedAt: addedAt ?? this.addedAt,
      blocked: blocked ?? this.blocked,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }
}
