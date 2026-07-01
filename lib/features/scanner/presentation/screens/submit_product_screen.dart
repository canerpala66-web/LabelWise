import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/submitted_product_repository.dart';

class SubmitProductScreen extends StatefulWidget {
  const SubmitProductScreen({super.key, required this.initialBarcode});

  final String initialBarcode;

  @override
  State<SubmitProductScreen> createState() => _SubmitProductScreenState();
}

class _SubmitProductScreenState extends State<SubmitProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final SubmittedProductRepository _repository = SubmittedProductRepository();

  late final TextEditingController _barcodeController;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.initialBarcode);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.submitProduct(
        barcode: _barcodeController.text,
        name: _nameController.text,
        brand: _brandController.text,
        ingredientsText: _ingredientsController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün inceleme için gönderildi.')),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint('Product submission error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Ürün gönderilemedi. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F5),
        foregroundColor: const Color(0xFF17211B),
        elevation: 0,
        title: const Text(
          'Ürün Gönder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F0E7),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.add_box_outlined,
                        color: Color(0xFF175C3B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Ürün bilgilerini paylaşın',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17211B),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gönderdiğiniz bilgiler inceleme sonrasında LabelWise’a eklenebilir.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF637068),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        children: [
                          _SubmissionField(
                            controller: _barcodeController,
                            label: 'Barkod numarası',
                            keyboardType: TextInputType.number,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          _SubmissionField(
                            controller: _nameController,
                            label: 'Ürün adı',
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          _SubmissionField(
                            controller: _brandController,
                            label: 'Marka',
                          ),
                          const SizedBox(height: 16),
                          _SubmissionField(
                            controller: _ingredientsController,
                            label: 'İçindekiler',
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage case final message?) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF5D4CF)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(color: Color(0xFF81382E)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: _isSubmitting || _isSubmitted
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF175C3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isSubmitted ? 'Gönderildi' : 'Gönder'),
                      ),
                    ),
                    if (_isSubmitted) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Ürün inceleme için gönderildi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF175C3B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunludur.';
    }
    return null;
  }
}

class _SubmissionField extends StatelessWidget {
  const _SubmissionField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1B6B46), width: 1.5),
        ),
      ),
    );
  }
}
