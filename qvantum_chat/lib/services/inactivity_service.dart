import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InactivityService extends ChangeNotifier {
  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  bool _isLocked = false;
  int _timeoutMinutes = 15; // Default timeout in minutes

  bool get isLocked => _isLocked;
  int get timeoutMinutes => _timeoutMinutes;

  // Initialize the service
  Future<void> initialize() async {
    await _loadSettings();
    _lastActivityTime = DateTime.now();
    _startInactivityTimer();
  }

  // Load timeout settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _timeoutMinutes = prefs.getInt('auto_lock_timeout') ?? 15;
    } catch (e) {
      print('Error loading inactivity settings: $e');
      _timeoutMinutes = 15;
    }
  }

  // Save timeout settings
  Future<void> setTimeoutMinutes(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_lock_timeout', minutes);
      _timeoutMinutes = minutes;
      
      // Restart timer with new timeout
      _stopInactivityTimer();
      _startInactivityTimer();
      
      notifyListeners();
    } catch (e) {
      print('Error saving timeout settings: $e');
    }
  }

  // Record user activity
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    
    // If app was locked, keep it locked until PIN is verified
    if (!_isLocked) {
      _restartInactivityTimer();
    }
  }

  // Start the inactivity timer
  void _startInactivityTimer() {
    _stopInactivityTimer();
    
    _inactivityTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (_) => _checkInactivity(),
    );
  }

  // Stop the inactivity timer
  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  // Restart the inactivity timer
  void _restartInactivityTimer() {
    _startInactivityTimer();
  }

  // Check if app should be locked due to inactivity
  void _checkInactivity() {
    if (_lastActivityTime == null) return;

    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastActivityTime!);

    if (inactiveDuration.inMinutes >= _timeoutMinutes && !_isLocked) {
      _lockApp();
    }
  }

  // Lock the app
  void _lockApp() {
    _isLocked = true;
    notifyListeners();
  }

  // Unlock the app after successful PIN verification
  void unlockApp() {
    _isLocked = false;
    _lastActivityTime = DateTime.now();
    _startInactivityTimer();
    notifyListeners();
  }

  // Pause tracking (e.g., when app goes to background)
  void pause() {
    _stopInactivityTimer();
  }

  // Resume tracking (e.g., when app comes to foreground)
  void resume() {
    if (!_isLocked) {
      _lastActivityTime = DateTime.now();
      _startInactivityTimer();
    }
  }

  // Disable auto-lock
  void disable() {
    _stopInactivityTimer();
    _isLocked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopInactivityTimer();
    super.dispose();
  }
}
