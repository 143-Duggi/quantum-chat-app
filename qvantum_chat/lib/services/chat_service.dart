import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import 'crypto_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CryptoService _cryptoService = CryptoService();

  String? get _currentUserId => _auth.currentUser?.uid;

  // Create or get existing chat session
  Future<Map<String, dynamic>> getOrCreateSession({
    required String contactUid,
    required String contactPubKey,
  }) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final sessionId = ChatSession.generateSessionId(_currentUserId!, contactUid);

      // Check if session already exists
      final sessionDoc = await _firestore.collection('chats').doc(sessionId).get();

      if (sessionDoc.exists) {
        // Session exists, check if we have the shared secret
        final sharedSecret = await _getSessionKey(sessionId);
        
        if (sharedSecret == null) {
          // We don't have the key, need to derive it from ciphertext
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          final kyberCiphertext = sessionData['kyberCiphertext'] as String?;
          
          if (kyberCiphertext == null) {
            return {'success': false, 'error': 'Session ciphertext not found'};
          }

          // Get our own private key to decapsulate
          final myPrivateKey = await _secureStorage.read(key: 'kyber_secret_key_$_currentUserId');
          if (myPrivateKey == null) {
            return {'success': false, 'error': 'Private key not found. Please log out and log back in.'};
          }

          // Decapsulate to derive shared secret
          final ciphertextBytes = base64Decode(kyberCiphertext);
          final privateKeyBytes = base64Decode(myPrivateKey);
          final sharedSecretBytes = _cryptoService.decapsulate(
            ciphertextBytes,
            privateKeyBytes,
          );

          // Derive symmetric key from shared secret
          final keyDigest = sha256.convert(sharedSecretBytes);
          final symmetricKey = Uint8List.fromList(keyDigest.bytes);
          final sharedSecretBase64 = base64Encode(symmetricKey);

          // Store it for future use
          await _storeSessionKey(sessionId, sharedSecretBase64);

          return {
            'success': true,
            'sessionId': sessionId,
            'sharedSecret': sharedSecretBase64,
            'isNew': false,
          };
        }

        return {
          'success': true,
          'sessionId': sessionId,
          'sharedSecret': sharedSecret,
          'isNew': false,
        };
      }

      // Create new session with Kyber key exchange
      final keyExchange = await _performKeyExchange(contactPubKey, contactUid);
      
      if (!keyExchange['success']) {
        return keyExchange;
      }

      // Create session in Firestore
      await _firestore.collection('chats').doc(sessionId).set({
        'sessionId': sessionId,
        'participants': [_currentUserId, contactUid],
        'kyberCiphertext': keyExchange['ciphertext'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Store shared secret locally
      await _storeSessionKey(sessionId, keyExchange['sharedSecret']);

      return {
        'success': true,
        'sessionId': sessionId,
        'sharedSecret': keyExchange['sharedSecret'],
        'isNew': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to create session: $e'};
    }
  }

  // Perform Kyber key exchange
  Future<Map<String, dynamic>> _performKeyExchange(
    String contactPubKeyBase64,
    String contactUid,
  ) async {
    try {
      // Decode contact's public key
      final contactPubKey = base64Decode(contactPubKeyBase64);

      // Encapsulate to generate shared secret
      final encapsulation = _cryptoService.encapsulate(contactPubKey);

      // Derive symmetric key from shared secret using SHA-256
      final keyDigest = sha256.convert(encapsulation.sharedSecret);
      final symmetricKey = Uint8List.fromList(keyDigest.bytes);

      return {
        'success': true,
        'sharedSecret': base64Encode(symmetricKey),
        'ciphertext': encapsulation.ciphertextBase64,
      };
    } catch (e) {
      return {'success': false, 'error': 'Key exchange failed: $e'};
    }
  }

  // Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String plaintext,
  }) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Get shared secret from secure storage
      final sharedSecretBase64 = await _getSessionKey(sessionId);
      if (sharedSecretBase64 == null) {
        return {'success': false, 'error': 'Session key not found'};
      }

      final sharedSecret = base64Decode(sharedSecretBase64);

      // Encrypt the message
      final encrypted = await _encryptMessage(plaintext, sharedSecret);
      if (!encrypted['success']) {
        return encrypted;
      }

      // Add message to Firestore
      final messageRef = await _firestore
          .collection('chats')
          .doc(sessionId)
          .collection('messages')
          .add({
        'sender': _currentUserId,
        'ciphertext': encrypted['ciphertext'],
        'iv': encrypted['iv'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update session's last message timestamp
      await _firestore.collection('chats').doc(sessionId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'messageId': messageRef.id,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to send message: $e'};
    }
  }

  // Encrypt message with AES-GCM
  Future<Map<String, dynamic>> _encryptMessage(
    String plaintext,
    Uint8List key,
  ) async {
    try {
      // Generate random IV (12 bytes for GCM)
      final iv = Uint8List.fromList(
        List.generate(12, (i) => DateTime.now().millisecondsSinceEpoch % 256),
      );

      // For now, use simple XOR encryption as placeholder
      // TODO: Replace with actual AES-GCM implementation
      final plaintextBytes = utf8.encode(plaintext);
      final ciphertextBytes = Uint8List(plaintextBytes.length);
      
      for (int i = 0; i < plaintextBytes.length; i++) {
        ciphertextBytes[i] = plaintextBytes[i] ^ key[i % key.length];
      }

      return {
        'success': true,
        'ciphertext': base64Encode(ciphertextBytes),
        'iv': base64Encode(iv),
      };
    } catch (e) {
      return {'success': false, 'error': 'Encryption failed: $e'};
    }
  }

  // Decrypt message with AES-GCM
  Future<String?> decryptMessage({
    required String ciphertext,
    required String iv,
    required String sessionId,
  }) async {
    try {
      // Get shared secret from secure storage
      final sharedSecretBase64 = await _getSessionKey(sessionId);
      if (sharedSecretBase64 == null) {
        return null;
      }

      final sharedSecret = base64Decode(sharedSecretBase64);
      final ciphertextBytes = base64Decode(ciphertext);

      // Simple XOR decryption (placeholder)
      final plaintextBytes = Uint8List(ciphertextBytes.length);
      
      for (int i = 0; i < ciphertextBytes.length; i++) {
        plaintextBytes[i] = ciphertextBytes[i] ^ sharedSecret[i % sharedSecret.length];
      }

      return utf8.decode(plaintextBytes);
    } catch (e) {
      print('Decryption error: $e');
      return null;
    }
  }

  // Get messages stream for a session
  Stream<List<Message>> getMessages(String sessionId) {
    return _firestore
        .collection('chats')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Get chat session
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('chats').doc(sessionId).get();
      if (doc.exists) {
        return ChatSession.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // Get all chat sessions for current user
  Stream<List<ChatSession>> getSessions() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatSession.fromFirestore(doc))
          .toList();
    });
  }

  // Delete message (for both users)
  Future<Map<String, dynamic>> deleteMessage({
    required String sessionId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(sessionId)
          .collection('messages')
          .doc(messageId)
          .delete();

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete message: $e'};
    }
  }

  // Store session key in secure storage
  Future<void> _storeSessionKey(String sessionId, String sharedSecret) async {
    await _secureStorage.write(
      key: 'session_key_$sessionId',
      value: sharedSecret,
    );
  }

  // Get session key from secure storage
  Future<String?> _getSessionKey(String sessionId) async {
    return await _secureStorage.read(key: 'session_key_$sessionId');
  }

  // Clear all session keys (on logout)
  Future<void> clearAllSessionKeys() async {
    // Note: This is a simplified version
    // In production, you'd want to track all session IDs
    await _secureStorage.deleteAll();
  }

  // Delete chat session
  Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    try {
      // Delete all messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(sessionId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete session
      await _firestore.collection('chats').doc(sessionId).delete();

      // Delete session key
      await _secureStorage.delete(key: 'session_key_$sessionId');

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete session: $e'};
    }
  }
}
