import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openBarcodeScanner(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (!context.mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ScannerScreen(initialBarcode: barcode),
      ),
    );
  }

  void _openManualLookup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF175C3B),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LabelWise',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: const Color(0xFF17211B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Gıda etiketlerini saniyeler içinde daha iyi anlayın.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.45,
                      color: const Color(0xFF637068),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B6B46), Color(0xFF124B34)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24124B34),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ürünü incelemeye hazır mısınız?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Barkodu tarayın ve ürün bilgilerini kolayca görüntüleyin.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                height: 1.45,
                                color: const Color(0xFFDCEBE2),
                              ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: FilledButton.icon(
                            onPressed: () => _openBarcodeScanner(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF175C3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.barcode_reader, size: 24),
                            label: const Text('Barkod Taramaya Başla'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8E4)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openManualLookup(context),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_alt_outlined,
                              color: Color(0xFF537060),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'İsterseniz barkod numarasını manuel olarak da girebilirsiniz.',
                                style: TextStyle(
                                  height: 1.4,
                                  color: Color(0xFF526058),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF537060),
                            ),
                          ],
                        ),
                      ),
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
