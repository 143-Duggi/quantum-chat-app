import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CryptoService _cryptoService = CryptoService();

  AuthService() {
    // Disable app verification for development (reCAPTCHA issues)
    _auth.setSettings(appVerificationDisabledForTesting: true);
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String password,
  }) async {
    try {
      // Create a fake email from username (Firebase requires email)
      final email = '$username@quantumchat.app';

      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Generate Kyber keypair
      final keypair = _cryptoService.generateKeyPair();

      // Store secret key locally (encrypted)
      await _secureStorage.write(
        key: 'kyber_secret_key_$uid',
        value: keypair.secretKeyBase64,
      );

      // Generate unique user ID (12-16 characters)
      final uniqueUserId = _generateUniqueUserId();

      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'uniqueUserId': uniqueUserId,
        'pubKey': keypair.publicKeyBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'uid': uid,
        'username': username,
        'uniqueUserId': uniqueUserId,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This username is already taken.';
      }
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Sign in with username and password
  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    try {
      // Convert username to email format
      final email = '$username@quantumchat.app';

      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {'success': false, 'error': 'User data not found.'};
      }

      final userData = userDoc.data()!;

      // Check if secret key exists locally, if not regenerate
      final secretKey = await _secureStorage.read(key: 'kyber_secret_key_$uid');
      if (secretKey == null) {
        // Regenerate keypair
        final keypair = _cryptoService.generateKeyPair();
        
        // Store secret key locally
        await _secureStorage.write(
          key: 'kyber_secret_key_$uid',
          value: keypair.secretKeyBase64,
        );

        // Update public key in Firestore
        await _firestore.collection('users').doc(uid).update({
          'pubKey': keypair.publicKeyBase64,
        });
      }

      return {
        'success': true,
        'uid': uid,
        'username': userData['username'],
        'uniqueUserId': userData['uniqueUserId'],
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this username.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid username or password.';
      }
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account (for re-installation scenario)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete secret key from secure storage
      await _secureStorage.delete(key: 'kyber_secret_key_${user.uid}');
      
      // Delete Firebase Auth account
      await user.delete();
    }
  }

  // Generate unique user ID (Base58 format)
  String _generateUniqueUserId() {
    const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz';
    final random = DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < 14; i++) {
      final index = (random.codeUnitAt(i % random.length) + i) % chars.length;
      buffer.write(chars[index]);
    }

    return buffer.toString();
  }

  // Get user public key
  Future<String?> getUserPublicKey(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['pubKey'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user by unique ID
  Future<Map<String, dynamic>?> getUserByUniqueId(String uniqueUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueUserId', isEqualTo: uniqueUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
