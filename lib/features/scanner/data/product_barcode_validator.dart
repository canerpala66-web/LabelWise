class ProductBarcodeValidationResult {
  const ProductBarcodeValidationResult._({
    required this.isValid,
    required this.value,
    required this.reason,
  });

  factory ProductBarcodeValidationResult.valid(String value) {
    return ProductBarcodeValidationResult._(
      isValid: true,
      value: value,
      reason: null,
    );
  }

  factory ProductBarcodeValidationResult.invalid(String reason) {
    return ProductBarcodeValidationResult._(
      isValid: false,
      value: null,
      reason: reason,
    );
  }

  final bool isValid;
  final String? value;
  final String? reason;
}

class ProductBarcodeValidator {
  const ProductBarcodeValidator._();

  static ProductBarcodeValidationResult validate(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) {
      return ProductBarcodeValidationResult.invalid('empty value');
    }

    final lowerValue = value.toLowerCase();
    if (lowerValue.startsWith('http://') || lowerValue.startsWith('https://')) {
      return ProductBarcodeValidationResult.invalid('URL value');
    }

    if (lowerValue.contains('www')) {
      return ProductBarcodeValidationResult.invalid('web value');
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return ProductBarcodeValidationResult.invalid('non-numeric value');
    }

    if (value.length != 8 && value.length != 12 && value.length != 13) {
      return ProductBarcodeValidationResult.invalid(
        'unsupported barcode length ${value.length}',
      );
    }

    return ProductBarcodeValidationResult.valid(value);
  }
}
