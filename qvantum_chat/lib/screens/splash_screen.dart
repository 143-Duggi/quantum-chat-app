import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();
  final _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is authenticated
    final user = _authService.currentUser;
    
    if (user != null) {
      // Check if PIN is set up
      final pinSetup = await _pinService.isPinSetup();
      
      if (pinSetup) {
        // Check if account is locked
        final isLocked = await _pinService.isAccountLocked();
        
        if (isLocked) {
          // Account locked - go to login and show error
          await _authService.signOut();
          if (!mounted) return;
          context.go('/login');
        } else {
          // Navigate to PIN entry
          context.go('/pin-entry');
        }
      } else {
        // PIN not set up - navigate to PIN setup
        context.go('/pin-setup');
      }
    } else {
      // No user logged in - navigate to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'QuantumChat',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Post-Quantum Secure Messaging',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
