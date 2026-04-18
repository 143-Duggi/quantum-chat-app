import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String sessionId;
  final List<String> participants;
  final String? kyberCiphertext;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  ChatSession({
    required this.sessionId,
    required this.participants,
    this.kyberCiphertext,
    required this.createdAt,
    this.lastMessageAt,
  });

  // Create ChatSession from Firestore document
  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatSession(
      sessionId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      kyberCiphertext: data['kyberCiphertext'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert ChatSession to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'participants': participants,
      if (kyberCiphertext != null) 'kyberCiphertext': kyberCiphertext,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
    };
  }

  // Generate session ID from two user IDs (sorted for consistency)
  static String generateSessionId(String uid1, String uid2) {
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  // Get the other participant's UID
  String getOtherParticipant(String myUid) {
    return participants.firstWhere((uid) => uid != myUid, orElse: () => '');
  }
}
