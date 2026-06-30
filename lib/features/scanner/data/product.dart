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
    final nutriscoreGrade =
        _nonEmptyString(json['nutriscore_grade']) ??
        (tags is List && tags.isNotEmpty
            ? _nonEmptyString(tags.first)
            : null) ??
        (data is Map<String, dynamic> ? _nonEmptyString(data['grade']) : null);

    return Product(
      barcode: barcode,
      productName: (json['product_name'] as String?)?.trim() ?? '',
      brands: (json['brands'] as String?)?.trim() ?? '',
      imageUrl: (json['image_url'] as String?)?.trim(),
      ingredientsText: (json['ingredients_text'] as String?)?.trim() ?? '',
      nutriscoreGrade: nutriscoreGrade,
    );
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}
