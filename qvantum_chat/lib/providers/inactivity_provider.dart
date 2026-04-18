import 'package:flutter/material.dart';
import '../services/inactivity_service.dart';

class InactivityProvider extends ChangeNotifier {
  final InactivityService _inactivityService = InactivityService();

  InactivityService get service => _inactivityService;
  bool get isLocked => _inactivityService.isLocked;
  int get timeoutMinutes => _inactivityService.timeoutMinutes;

  InactivityProvider() {
    _inactivityService.addListener(_onInactivityChanged);
  }

  void _onInactivityChanged() {
    notifyListeners();
  }

  Future<void> initialize() async {
    await _inactivityService.initialize();
  }

  void recordActivity() {
    _inactivityService.recordActivity();
  }

  void unlockApp() {
    _inactivityService.unlockApp();
  }

  Future<void> setTimeoutMinutes(int minutes) async {
    await _inactivityService.setTimeoutMinutes(minutes);
  }

  void pause() {
    _inactivityService.pause();
  }

  void resume() {
    _inactivityService.resume();
  }

  void disable() {
    _inactivityService.disable();
  }

  @override
  void dispose() {
    _inactivityService.removeListener(_onInactivityChanged);
    _inactivityService.dispose();
    super.dispose();
  }
}
