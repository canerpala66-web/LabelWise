import 'package:flutter/foundation.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _baseFields =
      'barcode, name, brand, image_url, ingredients_text, '
      'nutriscore_grade, source, ai_summary, ai_risk_level, '
      'ai_generated_at, front_image_path';
  static const _nutritionFields =
      'energy_kcal, fat, saturated_fat, sugars, fiber, protein, salt, '
      'fruits_vegetables_legumes_percent';

  Future<Product?> getProductByBarcode(String barcode) async {
    final data = await _fetchProductData(barcode);

    if (data == null) {
      return null;
    }

    return Product(
      barcode: data['barcode'] as String? ?? barcode,
      productName: data['name'] as String? ?? '',
      brands: data['brand'] as String? ?? '',
      imageUrl: data['image_url'] as String?,
      ingredientsText: data['ingredients_text'] as String? ?? '',
      nutriscoreGrade: data['nutriscore_grade'] as String?,
      source: data['source'] as String? ?? 'openfoodfacts',
      energyKcal: _number(data['energy_kcal']),
      fat: _number(data['fat']),
      saturatedFat: _number(data['saturated_fat']),
      sugars: _number(data['sugars']),
      fiber: _number(data['fiber']),
      protein: _number(data['protein']),
      salt: _number(data['salt']),
      fruitsVegetablesLegumesPercent: _number(
        data['fruits_vegetables_legumes_percent'],
      ),
      aiSummary: data['ai_summary'] as String?,
      aiRiskLevel: data['ai_risk_level'] as String?,
      aiGeneratedAt: _dateTime(data['ai_generated_at']),
      frontImagePath: data['front_image_path'] as String?,
      category: data['category'] as String?,
    );
  }

  Future<void> saveProduct(Product product) async {
    if (product.barcode.isEmpty) {
      throw ArgumentError.value(product.barcode, 'barcode', 'Cannot be empty');
    }

    final protectedValues = await _protectedValuesForSave(product);
    final categoryForSave = protectedValues.category;
    final baseData = <String, dynamic>{
      'barcode': product.barcode,
      'name': product.productName,
      'brand': product.brands,
      'image_url': product.imageUrl,
      'ingredients_text': product.ingredientsText,
      'nutriscore_grade': product.nutriscoreGrade,
      'source': protectedValues.source,
      'category': categoryForSave,
    };
    if (product.frontImagePath case final frontImagePath?
        when frontImagePath.trim().isNotEmpty) {
      baseData['front_image_path'] = frontImagePath.trim();
    }
    final nutritionData = <String, dynamic>{
      ...baseData,
      'energy_kcal': product.energyKcal,
      'fat': product.fat,
      'saturated_fat': product.saturatedFat,
      'sugars': product.sugars,
      'fiber': product.fiber,
      'protein': product.protein,
      'salt': product.salt,
      'fruits_vegetables_legumes_percent':
          product.fruitsVegetablesLegumesPercent,
    };

    debugPrint('ProductRepository: saving category=$categoryForSave');
    await _upsertWithSchemaFallback(
      nutritionData: nutritionData,
      baseData: baseData,
    );
  }

  Future<void> updateAiAnalysis({
    required String barcode,
    required String summary,
    required String riskLevel,
  }) async {
    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }

    final updatedProduct = await _client
        .from('products')
        .update({
          'ai_summary': summary.trim(),
          'ai_risk_level': riskLevel.trim(),
          'ai_generated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('barcode', trimmedBarcode)
        .select('barcode')
        .maybeSingle();

    if (updatedProduct == null) {
      throw StateError('Product not found while saving AI analysis.');
    }
  }

  Future<String?> createSubmittedProductPhotoSignedUrl(String? path) async {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }

    debugPrint(
      'ProductImage: creating signed URL for front_image_path=$trimmedPath',
    );
    try {
      final signedUrl = await _client.storage
          .from('submitted-product-photos')
          .createSignedUrl(trimmedPath, 3600);
      debugPrint('ProductImage: signed URL created');
      return signedUrl;
    } on Object catch (error) {
      debugPrint('ProductImage: signed URL failed error=$error');
      return null;
    }
  }

  bool _isMissingNutritionColumn(PostgrestException error) {
    final description = '${error.message} ${error.details} ${error.hint}';
    return const [
      'energy_kcal',
      'fat',
      'saturated_fat',
      'sugars',
      'fiber',
      'protein',
      'salt',
      'fruits_vegetables_legumes_percent',
    ].any(description.contains);
  }

  bool _isMissingCategoryColumn(PostgrestException error) {
    final description = '${error.message} ${error.details} ${error.hint}';
    return description.contains('category');
  }

  Future<({String? category, String source})> _protectedValuesForSave(
    Product product,
  ) async {
    if (product.source.trim().toLowerCase() != 'openfoodfacts') {
      return (category: product.category, source: product.source);
    }
    try {
      final existing = await _client
          .from('products')
          .select('source, category')
          .eq('barcode', product.barcode)
          .maybeSingle();
      final existingSource = (existing?['source'] as String?)
          ?.trim()
          .toLowerCase();
      final existingCategory = (existing?['category'] as String?)?.trim();
      final isManuallyManaged =
          existingSource == 'user_submission' ||
          existingSource == 'labelwise_corrected';
      final hasUsefulCategory =
          existingCategory != null &&
          existingCategory.isNotEmpty &&
          existingCategory != 'Belirsiz';
      if (isManuallyManaged && hasUsefulCategory) {
        return (category: existingCategory, source: existingSource!);
      }
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('products');
    }
    return (category: product.category, source: product.source);
  }

  Future<Map<String, dynamic>?> _fetchProductData(String barcode) async {
    try {
      return await _selectProduct(
        barcode,
        fields: '$_baseFields, $_nutritionFields, category',
      );
    } on PostgrestException catch (error) {
      if (_isMissingCategoryColumn(error)) {
        _logMissingCategorySchema('products');
        try {
          return await _selectProduct(
            barcode,
            fields: '$_baseFields, $_nutritionFields',
          );
        } on PostgrestException catch (fallbackError) {
          if (!_isMissingNutritionColumn(fallbackError)) rethrow;
          _logMissingNutritionSchema();
          return _selectProduct(barcode, fields: _baseFields);
        }
      }
      if (!_isMissingNutritionColumn(error)) rethrow;
      _logMissingNutritionSchema();
      try {
        return await _selectProduct(barcode, fields: '$_baseFields, category');
      } on PostgrestException catch (fallbackError) {
        if (!_isMissingCategoryColumn(fallbackError)) rethrow;
        _logMissingCategorySchema('products');
        return _selectProduct(barcode, fields: _baseFields);
      }
    }
  }

  Future<Map<String, dynamic>?> _selectProduct(
    String barcode, {
    required String fields,
  }) {
    return _client
        .from('products')
        .select(fields)
        .eq('barcode', barcode)
        .maybeSingle();
  }

  Future<void> _upsertWithSchemaFallback({
    required Map<String, dynamic> nutritionData,
    required Map<String, dynamic> baseData,
  }) async {
    try {
      await _client
          .from('products')
          .upsert(nutritionData, onConflict: 'barcode');
    } on PostgrestException catch (error) {
      if (_isMissingCategoryColumn(error)) {
        _logMissingCategorySchema('products');
        final withoutCategory = Map<String, dynamic>.of(nutritionData)
          ..remove('category');
        try {
          await _client
              .from('products')
              .upsert(withoutCategory, onConflict: 'barcode');
        } on PostgrestException catch (fallbackError) {
          if (!_isMissingNutritionColumn(fallbackError)) rethrow;
          _logMissingNutritionSchema();
          final baseWithoutCategory = Map<String, dynamic>.of(baseData)
            ..remove('category');
          await _client
              .from('products')
              .upsert(baseWithoutCategory, onConflict: 'barcode');
        }
        return;
      }
      if (!_isMissingNutritionColumn(error)) rethrow;
      _logMissingNutritionSchema();
      try {
        await _client.from('products').upsert(baseData, onConflict: 'barcode');
      } on PostgrestException catch (fallbackError) {
        if (!_isMissingCategoryColumn(fallbackError)) rethrow;
        _logMissingCategorySchema('products');
        final baseWithoutCategory = Map<String, dynamic>.of(baseData)
          ..remove('category');
        await _client
            .from('products')
            .upsert(baseWithoutCategory, onConflict: 'barcode');
      }
    }
  }

  void _logMissingNutritionSchema() {
    debugPrint(
      'Supabase products table is missing nutrition columns. '
      'Nutrition will be refreshed from OpenFoodFacts but cannot be cached '
      'until the required columns are added.',
    );
  }

  void _logMissingCategorySchema(String table) {
    debugPrint(
      'Supabase $table table is missing category. Run: '
      'alter table public.$table add column if not exists category text;',
    );
  }

  double? _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  DateTime? _dateTime(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
