import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  sending,
  sent,
  failed,
}

class Message {
  final String messageId;
  final String sender;
  final String ciphertext;
  final String iv;
  final DateTime timestamp;
  final MessageStatus status;
  String? decryptedContent;

  Message({
    required this.messageId,
    required this.sender,
    required this.ciphertext,
    required this.iv,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.decryptedContent,
  });

  // Create Message from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Message(
      messageId: doc.id,
      sender: data['sender'] ?? '',
      ciphertext: data['ciphertext'] ?? '',
      iv: data['iv'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  // Convert Message to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'ciphertext': ciphertext,
      'iv': iv,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updating fields
  Message copyWith({
    String? messageId,
    String? sender,
    String? ciphertext,
    String? iv,
    DateTime? timestamp,
    MessageStatus? status,
    String? decryptedContent,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      sender: sender ?? this.sender,
      ciphertext: ciphertext ?? this.ciphertext,
      iv: iv ?? this.iv,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      decryptedContent: decryptedContent ?? this.decryptedContent,
    );
  }

  bool get isMine => false; // Will be determined by comparing with current user
}
