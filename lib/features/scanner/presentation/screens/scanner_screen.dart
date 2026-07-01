import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/open_food_facts_service.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/submit_product_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.initialBarcode});

  final String? initialBarcode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final OpenFoodFactsService _service = OpenFoodFactsService();
  final ProductRepository _productRepository = ProductRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _missingBarcode;
  String? _failedBarcode;

  @override
  void initState() {
    super.initState();

    final initialBarcode = widget.initialBarcode?.trim();
    if (initialBarcode == null || initialBarcode.isEmpty) {
      return;
    }

    _barcodeController.text = initialBarcode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchProduct();
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (!mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    _barcodeController.text = barcode;
    await _searchProduct();
  }

  void _openSubmission(String barcode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SubmitProductScreen(initialBarcode: barcode),
      ),
    );
  }

  Future<void> _searchProduct() async {
    final barcode = _barcodeController.text.trim();

    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen bir barkod numarası girin.';
        _missingBarcode = null;
        _failedBarcode = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _missingBarcode = null;
      _failedBarcode = null;
    });

    try {
      var product = await _productRepository.getProductByBarcode(barcode);

      if (product == null) {
        debugPrint('Cache miss: fetching from OpenFoodFacts');
        product = await _service.fetchProduct(barcode);

        if (product != null) {
          await _productRepository.saveProduct(product);
        }
      } else if (!product.hasNutritionData) {
        debugPrint(
          'Cache hit: incomplete nutrition, refreshing from OpenFoodFacts',
        );
        product = await _service.fetchProduct(barcode);

        if (product != null) {
          await _productRepository.saveProduct(product);
        }
      } else {
        debugPrint('Cache hit: complete nutrition');
      }

      if (!mounted) {
        return;
      }

      final foundProduct = product;

      if (foundProduct == null) {
        setState(() {
          _isLoading = false;
          _missingBarcode = barcode;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProductResultScreen(product: foundProduct),
        ),
      );
    } on Exception catch (e, stackTrace) {
      debugPrint('Product lookup error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (e is PostgrestException) {
        debugPrint('Supabase error: ${e.message}');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Ürün yüklenemedi. Lütfen tekrar deneyin.';
        _missingBarcode = null;
        _failedBarcode = barcode;
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF175C3B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LabelWise',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: const Color(0xFF17211B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Barkod Numarası Gir',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: const Color(0xFF17211B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ürünün barkod numarasını yazarak hızlıca arama yapabilirsiniz.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: const Color(0xFF637068),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8E4)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F173D2A),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _barcodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Barkod numarası',
                            hintText: 'Örn. 8690504030012',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF7F9F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE5E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE5E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B6B46),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) =>
                              _isLoading ? null : _searchProduct(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _searchProduct,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF175C3B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Ürünü Ara'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2EC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF175C3B),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Ürün aranıyor...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF315743),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_missingBarcode case final barcode?) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8E4)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F2EC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              color: Color(0xFF175C3B),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ürün bulunamadı',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF17211B),
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bu ürün henüz LabelWise veritabanında yok. Bilgilerini göndererek incelememize yardımcı olabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.5,
                              color: Color(0xFF637068),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () => _openSubmission(barcode),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF175C3B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('İncelemeye Gönder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_errorMessage case final message?) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1EF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF5D4CF)),
                      ),
                      child: Column(
                        children: [
                          if (_failedBarcode case final barcode?) ...[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9DDD8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFA84435),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ürün yüklenemedi',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6E3028),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bu ürünü şu anda otomatik olarak bulamadık. İsterseniz bilgilerini göndererek incelemeye alabiliriz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.5,
                                color: Color(0xFF81382E),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _openSubmission(barcode),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF81382E),
                                  side: const BorderSide(
                                    color: Color(0xFFD9A69E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('İncelemeye Gönder'),
                              ),
                            ),
                          ] else
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFA84435),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      height: 1.4,
                                      color: Color(0xFF81382E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    'Barkodu bilmiyorsanız kamerayla tarama yapabilirsiniz.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: const Color(0xFF637068),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _scanBarcode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF175C3B),
                        side: const BorderSide(color: Color(0xFFB9CCC0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.barcode_reader),
                      label: const Text('Barkod Tara'),
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
