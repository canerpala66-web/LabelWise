class Product {
  const Product({
    required this.productName,
    required this.brands,
    required this.imageUrl,
    required this.ingredientsText,
    this.barcode = '',
    this.nutriscoreGrade,
    this.source = 'openfoodfacts',
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.sugars,
    this.salt,
    this.fiber,
    this.protein,
    this.fruitsVegetablesLegumesPercent,
    this.aiSummary,
    this.aiRiskLevel,
    this.aiGeneratedAt,
    this.frontImagePath,
  });

  final String productName;
  final String brands;
  final String? imageUrl;
  final String ingredientsText;
  final String barcode;
  final String? nutriscoreGrade;
  final String source;
  final double? energyKcal;
  final double? fat;
  final double? saturatedFat;
  final double? sugars;
  final double? salt;
  final double? fiber;
  final double? protein;
  final double? fruitsVegetablesLegumesPercent;
  final String? aiSummary;
  final String? aiRiskLevel;
  final DateTime? aiGeneratedAt;
  final String? frontImagePath;

  bool get hasNutritionData => [
    energyKcal,
    fat,
    saturatedFat,
    sugars,
    fiber,
    protein,
    salt,
    fruitsVegetablesLegumesPercent,
  ].any((value) => value != null);

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
    final nutriments = json['nutriments'];
    final nutrition = nutriments is Map<String, dynamic>
        ? nutriments
        : const <String, dynamic>{};

    return Product(
      barcode: barcode,
      productName: productName ?? 'Bilinmeyen Ürün',
      brands: _nonEmptyString(json['brands']) ?? 'Bilinmeyen Marka',
      imageUrl: (json['image_url'] as String?)?.trim(),
      ingredientsText: ingredientsText ?? 'İçindekiler bilgisi bulunamadı',
      nutriscoreGrade: nutriscoreGrade,
      energyKcal: _number(nutrition['energy-kcal_100g']),
      fat: _number(nutrition['fat_100g']),
      saturatedFat: _number(nutrition['saturated-fat_100g']),
      sugars: _number(nutrition['sugars_100g']),
      salt: _number(nutrition['salt_100g']),
      fiber: _number(nutrition['fiber_100g']),
      protein: _number(nutrition['proteins_100g']),
      fruitsVegetablesLegumesPercent: _number(
        nutrition['fruits-vegetables-legumes-estimate-from-ingredients_100g'],
      ),
      frontImagePath: _nonEmptyString(json['front_image_path']),
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

  static double? _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
