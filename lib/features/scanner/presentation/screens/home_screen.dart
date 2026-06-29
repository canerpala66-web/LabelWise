import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/presentation/screens/scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ScannerScreen(),
              ),
            );
          },
          child: const Text('Start Scan'),
        ),
      ),
    );
  }
}
