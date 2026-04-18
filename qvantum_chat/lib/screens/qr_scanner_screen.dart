import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/contact_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ContactService _contactService = ContactService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Parse QR code
    final qrData = _contactService.parseQrCode(code);
    
    if (qrData == null) {
      _showError('Invalid QR code format');
      setState(() => _isProcessing = false);
      return;
    }

    // Get user data from Firestore
    final userData = await _contactService.getUserByUniqueId(qrData['uniqueUserId']);
    
    if (userData == null) {
      _showError('User not found');
      setState(() => _isProcessing = false);
      return;
    }

    // Add contact
    final result = await _contactService.addContact(
      contactUniqueId: userData['uniqueUserId'],
      contactUsername: userData['username'],
      contactPubKey: userData['pubKey'],
      contactUid: userData['uid'],
    );

    if (!mounted) return;

    if (result['success']) {
      _showSuccessDialog(userData['username']);
    } else {
      _showError(result['error'] ?? 'Failed to add contact');
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Contact Added'),
        content: Text('Successfully connected with $username.'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.go('/home'); // Return to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleQrDetection,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Position the QR code within the frame',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final double scanAreaSize = size.width * 0.7;
    final Rect scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw semi-transparent background
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
          ),
      ),
      backgroundPaint,
    );

    // Draw corner borders
    const double cornerLength = 30;
    final double left = scanArea.left;
    final double right = scanArea.right;
    final double top = scanArea.top;
    final double bottom = scanArea.bottom;

    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), borderPaint);

    // Top-right corner
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), borderPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), borderPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), borderPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), borderPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), borderPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
