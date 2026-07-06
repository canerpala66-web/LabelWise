import 'package:flutter/foundation.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
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
  static const _alternativeFields =
      'barcode, name, brand, image_url, front_image_path, category, '
      'ingredients_text, nutriscore_grade, energy_kcal, fat, saturated_fat, '
      'sugars, fiber, protein, salt, source';
  static const _alternativeFieldsWithoutCategory =
      'barcode, name, brand, image_url, front_image_path, ingredients_text, '
      'nutriscore_grade, energy_kcal, fat, saturated_fat, sugars, fiber, '
      'protein, salt, source';

  Future<Product?> getProductByBarcode(String barcode) async {
    final data = await _fetchProductData(barcode);

    if (data == null) {
      return null;
    }

    return _productFromData(data, fallbackBarcode: barcode);
  }

  Future<List<Product>> fetchProductsByCategory(String category) async {
    final canonicalCategory = ProductCategoryMapper.canonicalCategory(category);
    if (canonicalCategory == null || canonicalCategory.isEmpty) return const [];

    debugPrint(
      'AlternativesDebug: querying Supabase category=$canonicalCategory',
    );
    late final List<Map<String, dynamic>> exactRows;
    var inferMissingCategories = false;
    try {
      final response = await _client
          .from('products')
          .select(_alternativeFields)
          .eq('category', canonicalCategory)
          .limit(30);
      exactRows = List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('products');
      debugPrint(
        'AlternativesDebug: category column unavailable, '
        'using bounded local category matching',
      );
      final response = await _client
          .from('products')
          .select(_alternativeFieldsWithoutCategory)
          .limit(50);
      exactRows = List<Map<String, dynamic>>.from(response);
      inferMissingCategories = true;
    }

    final rowsByBarcode = <String, Map<String, dynamic>>{};
    for (final row in exactRows) {
      if (_rowMatchesCategory(
        row,
        canonicalCategory,
        inferWhenMissing: inferMissingCategories,
      )) {
        rowsByBarcode[_text(row['barcode']) ?? 'row-${rowsByBarcode.length}'] =
            row;
      }
    }
    if (!inferMissingCategories && rowsByBarcode.length < 5) {
      debugPrint(
        'AlternativesDebug: exact category result limited, '
        'using bounded normalized fallback',
      );
      final fallbackRows = await _client
          .from('products')
          .select(_alternativeFields)
          .limit(50);
      for (final row in List<Map<String, dynamic>>.from(fallbackRows)) {
        if (_rowMatchesCategory(row, canonicalCategory)) {
          rowsByBarcode[_text(row['barcode']) ??
                  'fallback-${rowsByBarcode.length}'] =
              row;
        }
      }
    }

    final products = <Product>[];
    for (final row in rowsByBarcode.values) {
      try {
        products.add(
          _productFromData(
            row,
            inferredCategory: inferMissingCategories
                ? _inferredCategoryForRow(row)
                : null,
          ),
        );
      } on Object catch (error) {
        debugPrint(
          'AlternativesDebug: skipped candidate reason=malformed row, '
          'error=$error',
        );
      }
    }
    debugPrint('AlternativesDebug: fetched candidate count=${products.length}');
    return products;
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

  Future<bool> updateAiAnalysis({
    required String barcode,
    required String summary,
    required String riskLevel,
    required String analysisVersion,
  }) async {
    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }

    final data = <String, dynamic>{
      'ai_summary': summary.trim(),
      'ai_risk_level': riskLevel.trim(),
      'ai_generated_at': DateTime.now().toUtc().toIso8601String(),
      'ai_analysis_version': analysisVersion.trim(),
    };
    Map<String, dynamic>? updatedProduct;
    var versionSaved = true;
    try {
      updatedProduct = await _client
          .from('products')
          .update(data)
          .eq('barcode', trimmedBarcode)
          .select('barcode')
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingAnalysisVersionColumn(error)) rethrow;
      _logMissingAnalysisVersionSchema();
      data.remove('ai_analysis_version');
      versionSaved = false;
      updatedProduct = await _client
          .from('products')
          .update(data)
          .eq('barcode', trimmedBarcode)
          .select('barcode')
          .maybeSingle();
    }

    if (updatedProduct == null) {
      throw StateError('Product not found while saving AI analysis.');
    }
    return versionSaved;
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

  bool _isMissingAnalysisVersionColumn(PostgrestException error) {
    final description = '${error.message} ${error.details} ${error.hint}';
    return description.contains('ai_analysis_version');
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
    var includeNutrition = true;
    var includeCategory = true;
    var includeAnalysisVersion = true;
    while (true) {
      final fields = <String>[
        _baseFields,
        if (includeNutrition) _nutritionFields,
        if (includeCategory) 'category',
        if (includeAnalysisVersion) 'ai_analysis_version',
      ].join(', ');
      try {
        return await _selectProduct(barcode, fields: fields);
      } on PostgrestException catch (error) {
        if (includeCategory && _isMissingCategoryColumn(error)) {
          includeCategory = false;
          _logMissingCategorySchema('products');
          continue;
        }
        if (includeNutrition && _isMissingNutritionColumn(error)) {
          includeNutrition = false;
          _logMissingNutritionSchema();
          continue;
        }
        if (includeAnalysisVersion && _isMissingAnalysisVersionColumn(error)) {
          includeAnalysisVersion = false;
          _logMissingAnalysisVersionSchema();
          continue;
        }
        rethrow;
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

  void _logMissingAnalysisVersionSchema() {
    debugPrint(
      'Supabase products table is missing ai_analysis_version. Run: '
      'alter table public.products add column if not exists '
      'ai_analysis_version text;',
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

  Product _productFromData(
    Map<String, dynamic> data, {
    String fallbackBarcode = '',
    String? inferredCategory,
  }) {
    final barcode = _text(data['barcode']) ?? fallbackBarcode;
    final name = _text(data['name']);
    return Product(
      barcode: barcode,
      productName: name ?? '',
      brands: _text(data['brand']) ?? '',
      imageUrl: _text(data['image_url']),
      ingredientsText: _text(data['ingredients_text']) ?? '',
      nutriscoreGrade: _text(data['nutriscore_grade']),
      source: _text(data['source']) ?? 'openfoodfacts',
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
      aiSummary: _text(data['ai_summary']),
      aiRiskLevel: _text(data['ai_risk_level']),
      aiGeneratedAt: _dateTime(data['ai_generated_at']),
      aiAnalysisVersion: _text(data['ai_analysis_version']),
      frontImagePath: _text(data['front_image_path']),
      category: _text(data['category']) ?? inferredCategory,
    );
  }

  bool _rowMatchesCategory(
    Map<String, dynamic> row,
    String category, {
    bool inferWhenMissing = false,
  }) {
    final rowCategory = _text(row['category']);
    final comparableCategory =
        rowCategory ?? (inferWhenMissing ? _inferredCategoryForRow(row) : null);
    return ProductCategoryMapper.normalizeCategory(comparableCategory) ==
        ProductCategoryMapper.normalizeCategory(category);
  }

  String _inferredCategoryForRow(Map<String, dynamic> row) {
    return ProductCategoryMapper.inferCategory(
      productName: _text(row['name']),
      brand: _text(row['brand']),
      ingredientsText: _text(row['ingredients_text']),
    );
  }

  String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  DateTime? _dateTime(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
