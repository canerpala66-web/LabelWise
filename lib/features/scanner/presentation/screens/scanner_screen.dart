import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/open_food_facts_service.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final OpenFoodFactsService _service = OpenFoodFactsService();
  final ProductRepository _productRepository = ProductRepository();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _searchProduct() async {
    final barcode = _barcodeController.text.trim();

    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a barcode.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var product = await _productRepository.getProductByBarcode(barcode);

      if (product == null) {
        product = await _service.fetchProduct(barcode);

        if (product != null) {
          await _productRepository.saveProduct(product);
        }
      }

      if (!mounted) {
        return;
      }

      final foundProduct = product;

      if (foundProduct == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Product not found';
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
        _errorMessage = 'Could not load product. Please try again.';
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _isLoading ? null : _searchProduct(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchProduct,
                child: const Text('Search Product'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
