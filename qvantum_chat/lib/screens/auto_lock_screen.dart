import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/inactivity_provider.dart';
import '../services/pin_service.dart';

class AutoLockScreen extends StatefulWidget {
  const AutoLockScreen({super.key});

  @override
  State<AutoLockScreen> createState() => _AutoLockScreenState();
}

class _AutoLockScreenState extends State<AutoLockScreen> {
  final _pinController = TextEditingController();
  final _pinService = PinService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_pinController.text.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await _pinService.verifyPin(_pinController.text);

    if (!mounted) return;

    if (result['success']) {
      // Unlock the app
      final inactivityProvider = context.read<InactivityProvider>();
      inactivityProvider.unlockApp();
      
      // Pop this screen
      if (mounted) {
        context.pop();
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['error'] ?? 'Invalid PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB3BA).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Color(0xFFFF9999),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'App Locked',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your PIN to unlock',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 48),
                  // PIN input
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _pinController,
                      decoration: InputDecoration(
                        labelText: 'Enter PIN',
                        hintText: '••••••',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        errorText: _errorMessage.isEmpty ? null : _errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _handleUnlock(),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 280,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUnlock,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Unlock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0BBE4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9370DB).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF9370DB),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'App locked due to inactivity',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9370DB),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
