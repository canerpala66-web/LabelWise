import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/product_barcode_validator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  static const _acceptedFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  ];

  final MobileScannerController _controller = MobileScannerController(
    formats: _acceptedFormats,
  );

  bool _hasDetected = false;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasDetected) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final format = barcode.format;
      final validation = ProductBarcodeValidator.validate(rawValue);
      final numericValid = validation.isValid;

      debugPrint(
        'Scanner detected: rawValue=$rawValue, format=${format.name}, '
        'numericValid=$numericValid',
      );

      if (!validation.isValid) {
        debugPrint(
          'Scanner ignored invalid code: rawValue=$rawValue, '
          'ignored reason=${validation.reason}',
        );
        continue;
      }

      final barcodeValue = validation.value!;
      _hasDetected = true;
      debugPrint('Scanner accepted barcode=$barcodeValue');
      await _controller.stop();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(barcodeValue);
      return;
    }
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
