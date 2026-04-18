import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Hash PIN for storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Set up PIN for user (during registration)
  Future<Map<String, dynamic>> setupPin(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      final hashedPin = _hashPin(pin);

      // Store hashed PIN in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'pinHash': hashedPin,
        'pinSetupAt': FieldValue.serverTimestamp(),
        'failedPinAttempts': 0,
      });

      // Store locally that PIN is set
      await _secureStorage.write(
        key: 'pin_set_${user.uid}',
        value: 'true',
      );

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': 'Failed to set up PIN: $e'};
    }
  }

  // Verify PIN
  Future<Map<String, dynamic>> verifyPin(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        return {'success': false, 'error': 'User data not found'};
      }

      final userData = userDoc.data()!;
      final storedPinHash = userData['pinHash'] as String?;
      final failedAttempts = (userData['failedPinAttempts'] as int?) ?? 0;

      if (storedPinHash == null) {
        return {'success': false, 'error': 'PIN not set up'};
      }

      // Check if account is locked (3 failed attempts)
      if (failedAttempts >= 3) {
        return {
          'success': false,
          'error': 'locked',
          'message': 'Too many failed attempts. This installation is now invalid. Please reinstall the app.',
        };
      }

      final hashedPin = _hashPin(pin);

      if (hashedPin == storedPinHash) {
        // PIN correct - reset failed attempts
        await _firestore.collection('users').doc(user.uid).update({
          'failedPinAttempts': 0,
          'lastPinVerification': FieldValue.serverTimestamp(),
        });

        // Store PIN verification status locally
        await _secureStorage.write(
          key: 'pin_verified_${user.uid}',
          value: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        return {'success': true};
      } else {
        // PIN incorrect - increment failed attempts
        final newFailedAttempts = failedAttempts + 1;
        await _firestore.collection('users').doc(user.uid).update({
          'failedPinAttempts': newFailedAttempts,
        });

        if (newFailedAttempts >= 3) {
          return {
            'success': false,
            'error': 'locked',
            'message': 'Too many failed attempts. This installation is now invalid. Please reinstall the app.',
            'attempts': newFailedAttempts,
          };
        }

        return {
          'success': false,
          'error': 'incorrect',
          'message': 'Incorrect PIN. ${3 - newFailedAttempts} attempts remaining.',
          'attempts': newFailedAttempts,
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to verify PIN: $e'};
    }
  }

  // Check if PIN is set up for current user
  Future<bool> isPinSetup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      return userData['pinHash'] != null;
    } catch (e) {
      return false;
    }
  }

  // Check if PIN is verified locally (for auto-lock feature)
  Future<bool> isPinVerifiedRecently({Duration timeout = const Duration(minutes: 15)}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final verifiedTimestamp = await _secureStorage.read(
        key: 'pin_verified_${user.uid}',
      );

      if (verifiedTimestamp == null) return false;

      final verifiedTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(verifiedTimestamp),
      );

      final now = DateTime.now();
      final difference = now.difference(verifiedTime);

      return difference < timeout;
    } catch (e) {
      return false;
    }
  }

  // Check if account is locked due to failed attempts
  Future<bool> isAccountLocked() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final failedAttempts = (userData['failedPinAttempts'] as int?) ?? 0;

      return failedAttempts >= 3;
    } catch (e) {
      return false;
    }
  }

  // Clear local PIN verification (for logout)
  Future<void> clearPinVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _secureStorage.delete(key: 'pin_verified_${user.uid}');
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Reset failed attempts (for testing purposes - remove in production)
  Future<void> resetFailedAttempts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'failedPinAttempts': 0,
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
