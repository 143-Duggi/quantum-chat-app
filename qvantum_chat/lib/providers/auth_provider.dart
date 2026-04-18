import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PinService _pinService = PinService();
  
  User? _user;
  bool _isPinVerified = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isPinVerified => _isPinVerified;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      _isInitialized = true;
      
      if (user == null) {
        _isPinVerified = false;
      }
      
      notifyListeners();
    });
  }

  void setPinVerified(bool verified) {
    _isPinVerified = verified;
    notifyListeners();
  }

  Future<void> checkPinVerification() async {
    if (_user != null) {
      _isPinVerified = await _pinService.isPinVerifiedRecently();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _pinService.clearPinVerification();
    await _authService.signOut();
    _isPinVerified = false;
    notifyListeners();
  }
}
