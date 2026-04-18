import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/pin_service.dart';
import '../services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _pinService = PinService();
  final _authService = AuthService();
  String _pin = '';
  String? _confirmPin;
  bool _isConfirming = false;
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
    
    if (!_isConfirming) {
      // First entry
      setState(() {
        _pin = enteredPin;
        _isConfirming = true;
      });
      _clearFields();
      _focusNodes[0].requestFocus();
    } else {
      // Confirmation
      if (enteredPin == _pin) {
        setState(() => _isLoading = true);

        // Save PIN to Firebase
        final result = await _pinService.setupPin(_pin);

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (result['success']) {
          // Show success dialog and ask to re-login
          _showSuccessDialog();
        } else {
          _showError(result['error']);
          setState(() {
            _isConfirming = false;
            _pin = '';
          });
          _clearFields();
          _focusNodes[0].requestFocus();
        }
      } else {
        _showError('PINs do not match. Please try again.');
        setState(() {
          _isConfirming = false;
          _pin = '';
        });
        _clearFields();
        _focusNodes[0].requestFocus();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PIN Setup Complete'),
        content: const Text(
          'Your PIN has been set up successfully. Please log in again to start using QuantumChat.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Sign out and navigate to login
              await _authService.signOut();
              if (!mounted) return;
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
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
                    Icons.pin_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isConfirming ? 'Confirm Your PIN' : 'Set Up Your PIN',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConfirming
                        ? 'Re-enter your 6-digit PIN'
                        : 'Create a 6-digit PIN to secure your app',
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
                  else if (_isConfirming)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isConfirming = false;
                          _pin = '';
                        });
                        _clearFields();
                        _focusNodes[0].requestFocus();
                      },
                      child: const Text('Start Over'),
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
