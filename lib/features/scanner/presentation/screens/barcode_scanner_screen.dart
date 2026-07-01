import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _hasDetected = false;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasDetected) {
      return;
    }

    String? barcodeValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        barcodeValue = value;
        break;
      }
    }

    if (barcodeValue == null) {
      return;
    }

    _hasDetected = true;
    await _controller.stop();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(barcodeValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barkod Tara')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _handleDetection,
        errorBuilder: (context, error) {
          if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
            return const Center(child: Text('Kamera izni gerekli.'));
          }

          return const Center(child: Text('Kamera kullanılamıyor.'));
        },
        placeholderBuilder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
