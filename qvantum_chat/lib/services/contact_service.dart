import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/contact.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Add contact by scanning QR code or manual entry
  Future<Map<String, dynamic>> addContact({
    required String contactUniqueId,
    required String contactUsername,
    required String contactPubKey,
    required String contactUid,
  }) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Check if contact is not the user themselves
      if (contactUid == _currentUserId) {
        return {'success': false, 'error': 'You cannot add yourself as a contact'};
      }

      // Check if contact already exists
      final existingContact = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .get();

      if (existingContact.exists) {
        return {'success': false, 'error': 'Contact already exists'};
      }

      // Add contact to current user's contacts collection
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .set({
        'contactUid': contactUid,
        'contactUsername': contactUsername,
        'contactUniqueId': contactUniqueId,
        'contactPubKey': contactPubKey,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Also cache locally for offline access
      await _cacheContactLocally(
        contactUid: contactUid,
        contactUsername: contactUsername,
        contactUniqueId: contactUniqueId,
        contactPubKey: contactPubKey,
      );

      return {
        'success': true,
        'message': 'Contact added successfully',
        'contactUid': contactUid,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to add contact: $e'};
    }
  }

  // Get user by unique ID from Firestore
  Future<Map<String, dynamic>?> getUserByUniqueId(String uniqueUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueUserId', isEqualTo: uniqueUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return {
          'uid': data['uid'],
          'username': data['username'],
          'uniqueUserId': data['uniqueUserId'],
          'pubKey': data['pubKey'],
        };
      }
      return null;
    } catch (e) {
      print('Error fetching user by unique ID: $e');
      return null;
    }
  }

  // Get all contacts for current user
  Stream<List<Contact>> getContacts() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('contacts')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Contact.fromFirestore(doc))
          .toList();
    });
  }

  // Get a single contact by UID
  Future<Contact?> getContact(String contactUid) async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .get();

      if (doc.exists) {
        return Contact.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching contact: $e');
      return null;
    }
  }

  // Remove a contact
  Future<Map<String, dynamic>> removeContact(String contactUid) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .delete();

      // Delete from local cache
      await _secureStorage.delete(key: 'contact_$contactUid');

      return {'success': true, 'message': 'Contact removed successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to remove contact: $e'};
    }
  }

  // Block a contact
  Future<Map<String, dynamic>> blockContact(String contactUid) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Update contact document with blocked status
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .update({
        'blocked': true,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Contact blocked successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to block contact: $e'};
    }
  }

  // Unblock a contact
  Future<Map<String, dynamic>> unblockContact(String contactUid) async {
    try {
      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Update contact document with blocked status
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('contacts')
          .doc(contactUid)
          .update({
        'blocked': false,
        'blockedAt': FieldValue.delete(),
      });

      return {'success': true, 'message': 'Contact unblocked successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to unblock contact: $e'};
    }
  }

  // Cache contact locally
  Future<void> _cacheContactLocally({
    required String contactUid,
    required String contactUsername,
    required String contactUniqueId,
    required String contactPubKey,
  }) async {
    final contactData = {
      'contactUid': contactUid,
      'contactUsername': contactUsername,
      'contactUniqueId': contactUniqueId,
      'contactPubKey': contactPubKey,
    };

    await _secureStorage.write(
      key: 'contact_$contactUid',
      value: contactData.toString(),
    );
  }

  // Parse QR code data
  Map<String, dynamic>? parseQrCode(String qrData) {
    try {
      // Expected format: quantumchat://add?uid=<uniqueUserId>&pk=<base64-public-key>
      if (!qrData.startsWith('quantumchat://add?')) {
        return null;
      }

      final uri = Uri.parse(qrData);
      final uniqueUserId = uri.queryParameters['uid'];
      final publicKey = uri.queryParameters['pk'];

      if (uniqueUserId == null || publicKey == null) {
        return null;
      }

      return {
        'uniqueUserId': uniqueUserId,
        'publicKey': publicKey,
      };
    } catch (e) {
      print('Error parsing QR code: $e');
      return null;
    }
  }
}
