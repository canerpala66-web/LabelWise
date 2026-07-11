import 'package:labelwise/features/products/services/product_category_mapper.dart';

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
    this.carbohydrates,
    this.sugars,
    this.salt,
    this.fiber,
    this.protein,
    this.fruitsVegetablesLegumesPercent,
    this.aiSummary,
    this.aiRiskLevel,
    this.aiGeneratedAt,
    this.frontImagePath,
    this.category,
    this.aiAnalysisVersion,
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
  final double? carbohydrates;
  final double? sugars;
  final double? salt;
  final double? fiber;
  final double? protein;
  final double? fruitsVegetablesLegumesPercent;
  final String? aiSummary;
  final String? aiRiskLevel;
  final DateTime? aiGeneratedAt;
  final String? frontImagePath;
  final String? category;
  final String? aiAnalysisVersion;

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
    final categoryTags = <String>{
      ..._stringList(json['categories_tags']),
      ..._stringList(json['categories_hierarchy']),
    }.toList(growable: false);
    final category = ProductCategoryMapper.inferCategory(
      productName: productName,
      brand: _nonEmptyString(json['brands']),
      ingredientsText: ingredientsText,
      categoriesTags: categoryTags,
      categoriesText: _nonEmptyString(json['categories']),
    );

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
      carbohydrates: _number(nutrition['carbohydrates_100g']),
      sugars: _number(nutrition['sugars_100g']),
      salt: _number(nutrition['salt_100g']),
      fiber: _number(nutrition['fiber_100g']),
      protein: _number(nutrition['proteins_100g']),
      fruitsVegetablesLegumesPercent: _number(
        nutrition['fruits-vegetables-legumes-estimate-from-ingredients_100g'],
      ),
      frontImagePath: _nonEmptyString(json['front_image_path']),
      category: category,
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

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) {
          return item.isNotEmpty;
        })
        .toList(growable: false);
  }
}
