import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/pin_service.dart';
import '../services/auth_service.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _pinService = PinService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handlePinComplete();
      }
    }
  }

  Future<void> _handlePinComplete() async {
    final enteredPin = _controllers.map((c) => c.text).join();

    setState(() => _isLoading = true);

    final result = await _pinService.verifyPin(enteredPin);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // PIN correct - navigate to home
      context.go('/home');
    } else {
      // Clear PIN fields
      _clearFields();
      _focusNodes[0].requestFocus();

      if (result['error'] == 'locked') {
        // Account locked - show critical warning
        _showLockedDialog(result['message']);
      } else {
        // Show error with remaining attempts
        _showError(result['message']);
      }
    }
  }

  void _showLockedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Account Locked'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              // Sign out and navigate to login
              await _authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter Your PIN',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock QuantumChat with your 6-digit PIN',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          obscureText: true,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                          onChanged: (value) => _onPinDigitChanged(index, value),
                          onTap: () {
                            _controllers[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _controllers[index].text.length,
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    TextButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (!mounted) return;
                        context.go('/login');
                      },
                      child: const Text('Back to Login'),
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
