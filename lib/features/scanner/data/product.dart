class Product {
  const Product({
    required this.productName,
    required this.brands,
    required this.imageUrl,
    required this.ingredientsText,
    this.barcode = '',
    this.nutriscoreGrade,
    this.source = 'openfoodfacts',
  });

  final String productName;
  final String brands;
  final String? imageUrl;
  final String ingredientsText;
  final String barcode;
  final String? nutriscoreGrade;
  final String source;

  factory Product.fromJson(Map<String, dynamic> json, {String barcode = ''}) {
    final tags = json['nutriscore_2023_tags'];
    final data = json['nutriscore_data'];
    final productName = _firstNonEmpty([
      json['product_name_tr'],
      json['product_name_en'],
      json['product_name'],
      json['generic_name_tr'],
      json['generic_name_en'],
      json['generic_name'],
    ]);
    final ingredientsText = _firstNonEmpty([
      json['ingredients_text_tr'],
      json['ingredients_text_en'],
      json['ingredients_text'],
    ]);
    final nutriscoreGrade =
        _nonEmptyString(json['nutriscore_grade']) ??
        (tags is List && tags.isNotEmpty
            ? _nonEmptyString(tags.first)
            : null) ??
        (data is Map<String, dynamic> ? _nonEmptyString(data['grade']) : null);

    return Product(
      barcode: barcode,
      productName: productName ?? 'Bilinmeyen Ürün',
      brands: _nonEmptyString(json['brands']) ?? 'Bilinmeyen Marka',
      imageUrl: (json['image_url'] as String?)?.trim(),
      ingredientsText: ingredientsText ?? 'İçindekiler bilgisi bulunamadı',
      nutriscoreGrade: nutriscoreGrade,
    );
  }

  static String? _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = _nonEmptyString(value);
      if (text != null) {
        return text;
      }
    }

    return null;
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
