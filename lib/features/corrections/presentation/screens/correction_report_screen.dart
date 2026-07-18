import 'package:flutter/material.dart';
import 'package:labelwise/features/corrections/data/product_correction_repository.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class CorrectionReportScreen extends StatefulWidget {
  const CorrectionReportScreen({required this.product, super.key});

  final Product product;

  @override
  State<CorrectionReportScreen> createState() => _CorrectionReportScreenState();
}

class _CorrectionReportScreenState extends State<CorrectionReportScreen> {
  static const _issueOptions = [
    'Beslenme değeri farklı',
    'Ürün adı/marka hatalı',
    'Fotoğraf eksik veya yanlış',
    'İçindekiler bilgisi farklı',
    'Diğer',
  ];

  final _formKey = GlobalKey<FormState>();
  final ProductCorrectionRepository _repository = ProductCorrectionRepository();
  final _energyController = TextEditingController();
  final _fatController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _sugarsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _proteinController = TextEditingController();
  final _saltController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedIssue;
  String? _issueError;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Future<void> _submit() async {
    debugPrint('CorrectionReport: submit tapped');
    if (_isSubmitting || _isSubmitted) return;

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasIssue = _selectedIssue != null;
    final correctedValues = (
      energyKcal: _parseNumber(_energyController.text),
      fat: _parseNumber(_fatController.text),
      saturatedFat: _parseNumber(_saturatedFatController.text),
      sugars: _parseNumber(_sugarsController.text),
      fiber: _parseNumber(_fiberController.text),
      protein: _parseNumber(_proteinController.text),
      salt: _parseNumber(_saltController.text),
    );
    final hasCorrectionDetails =
        correctedValues.energyKcal != null ||
        correctedValues.fat != null ||
        correctedValues.saturatedFat != null ||
        correctedValues.sugars != null ||
        correctedValues.fiber != null ||
        correctedValues.protein != null ||
        correctedValues.salt != null ||
        _noteController.text.trim().isNotEmpty;
    setState(() {
      _issueError = hasIssue ? null : 'Lütfen bir sorun türü seçin.';
      _errorMessage = hasCorrectionDetails
          ? null
          : 'Lütfen en az bir düzeltme değeri veya açıklama girin.';
    });
    if (!isFormValid || !hasIssue || !hasCorrectionDetails) {
      debugPrint(
        'CorrectionReport: validation failed '
        'isFormValid=$isFormValid, hasIssue=$hasIssue, '
        'hasCorrectionDetails=$hasCorrectionDetails',
      );
      return;
    }
    debugPrint('CorrectionReport: validation passed');

    debugPrint('CorrectionReport: barcode=${widget.product.barcode}');
    debugPrint('CorrectionReport: reportedIssue=$_selectedIssue');
    debugPrint(
      'CorrectionReport: corrected values='
      'energyKcal=${correctedValues.energyKcal}, '
      'fat=${correctedValues.fat}, '
      'saturatedFat=${correctedValues.saturatedFat}, '
      'sugars=${correctedValues.sugars}, '
      'fiber=${correctedValues.fiber}, '
      'protein=${correctedValues.protein}, '
      'salt=${correctedValues.salt}',
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payloadPreview = <String, Object?>{
        'barcode': widget.product.barcode,
        'product_name': widget.product.productName,
        'brand': widget.product.brands,
        'reported_issue': _selectedIssue,
        'corrected_energy_kcal': correctedValues.energyKcal,
        'corrected_fat': correctedValues.fat,
        'corrected_saturated_fat': correctedValues.saturatedFat,
        'corrected_sugars': correctedValues.sugars,
        'corrected_fiber': correctedValues.fiber,
        'corrected_protein': correctedValues.protein,
        'corrected_salt': correctedValues.salt,
        'note': _noteController.text.trim(),
        'status': 'pending',
        'source': 'user_correction',
      };
      debugPrint('CorrectionReport: inserting payload=$payloadPreview');
      debugPrint('CorrectionReport: calling repository insert');
      await _repository.submitCorrectionReport(
        barcode: widget.product.barcode,
        productName: widget.product.productName,
        brand: widget.product.brands,
        reportedIssue: _selectedIssue!,
        correctedEnergyKcal: correctedValues.energyKcal,
        correctedFat: correctedValues.fat,
        correctedSaturatedFat: correctedValues.saturatedFat,
        correctedSugars: correctedValues.sugars,
        correctedFiber: correctedValues.fiber,
        correctedProtein: correctedValues.protein,
        correctedSalt: correctedValues.salt,
        note: _noteController.text,
      );
      debugPrint('CorrectionReport: insert success');

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('CorrectionReport: insert failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Bildirimin şu anda gönderilemedi. İnternetini kontrol edip tekrar dene.';
      });
    }
  }

  @override
  void dispose() {
    _energyController.dispose();
    _fatController.dispose();
    _saturatedFatController.dispose();
    _sugarsController.dispose();
    _fiberController.dispose();
    _proteinController.dispose();
    _saltController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productName = product.productName.trim().isEmpty
        ? 'Bilinmeyen Ürün'
        : product.productName;
    final brand = product.brands.trim().isEmpty
        ? 'Bilinmeyen Marka'
        : product.brands;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Veri Düzeltme Bildir',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F7F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ambalajdaki bilgiler uygulamadaki bilgilerden farklıysa bize bildirebilirsiniz.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: const Color(0xFF637068),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _IdentityCard(
                      productName: productName,
                      brand: brand,
                      barcode: product.barcode,
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Sorun türü',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in _issueOptions)
                              ChoiceChip(
                                label: Text(option),
                                selected: _selectedIssue == option,
                                selectedColor: const Color(0xFFDDEDE3),
                                onSelected: _isSubmitting || _isSubmitted
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          _selectedIssue = selected
                                              ? option
                                              : null;
                                          _issueError = null;
                                        });
                                      },
                              ),
                          ],
                        ),
                        if (_issueError case final error?) ...[
                          const SizedBox(height: 9),
                          Text(
                            error,
                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Doğru beslenme değerleri',
                      helperText:
                          'Besin değerlerini 100 g / 100 ml için girin. Ürünün ambalajındaki ‘100 g için’ veya ‘100 ml için’ değerleri kullanın.',
                      children: [
                        _NutritionField(
                          controller: _energyController,
                          label: 'Enerji (kcal)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _fatController,
                          label: 'Yağ (g)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _saturatedFatController,
                          label: 'Doymuş Yağ (g)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _sugarsController,
                          label: 'Şeker (g)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _fiberController,
                          label: 'Lif (g)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _proteinController,
                          label: 'Protein (g)',
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _saltController,
                          label: 'Tuz (g)',
                          validator: _numberValidator,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Not',
                      children: [
                        TextField(
                          controller: _noteController,
                          enabled: !_isSubmitting && !_isSubmitted,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Örneğin: Ambalajda yağ 33 g yazıyor, uygulamada 31 g görünüyor.',
                            filled: true,
                            fillColor: const Color(0xFFF7F9F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage case final message?) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(color: Color(0xFF81382E)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isSubmitting || _isSubmitted
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF175C3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Gönderiliyor...'),
                                ],
                              )
                            : const Text('Düzeltme Gönder'),
                      ),
                    ),
                    if (_isSubmitted) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F2E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Bildirimin alındı. Ürün bilgilerini kontrol edip gerekli düzenlemeyi yapacağız.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF175C3B),
                            fontWeight: FontWeight.w700,
                          ),
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

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = _parseNumber(value);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Lütfen geçerli bir sayı girin.';
    }
    return null;
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.productName,
    required this.brand,
    required this.barcode,
  });

  final String productName;
  final String brand;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: 'Ürün Bilgileri',
      children: [
        _IdentityRow(label: 'Ürün adı', value: productName),
        _IdentityRow(label: 'Marka', value: brand),
        _IdentityRow(
          label: 'Barkod',
          value: barcode.isEmpty ? 'Bilinmiyor' : barcode,
          isLast: true,
        ),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xFF637068)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF26342C),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE7ECE9)),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    this.helperText,
  });

  final String title;
  final String? helperText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF17211B),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (helperText case final helper?) ...[
              const SizedBox(height: 7),
              Text(
                helper,
                style: const TextStyle(height: 1.4, color: Color(0xFF637068)),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NutritionField extends StatelessWidget {
  const _NutritionField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
