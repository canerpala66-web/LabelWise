import 'package:flutter/foundation.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Product?> getProductByBarcode(String barcode) async {
    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('products')
          .select(
            'barcode, name, brand, image_url, ingredients_text, '
            'nutriscore_grade, source, energy_kcal, fat, saturated_fat, '
            'sugars, fiber, protein, salt, '
            'fruits_vegetables_legumes_percent, ai_summary, ai_risk_level, '
            'ai_generated_at',
          )
          .eq('barcode', barcode)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingNutritionColumn(error)) {
        rethrow;
      }

      _logMissingNutritionSchema();
      data = await _client
          .from('products')
          .select(
            'barcode, name, brand, image_url, ingredients_text, '
            'nutriscore_grade, source, ai_summary, ai_risk_level, '
            'ai_generated_at',
          )
          .eq('barcode', barcode)
          .maybeSingle();
    }

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
    );
  }

  Future<void> saveProduct(Product product) async {
    if (product.barcode.isEmpty) {
      throw ArgumentError.value(product.barcode, 'barcode', 'Cannot be empty');
    }

    final baseData = <String, dynamic>{
      'barcode': product.barcode,
      'name': product.productName,
      'brand': product.brands,
      'image_url': product.imageUrl,
      'ingredients_text': product.ingredientsText,
      'nutriscore_grade': product.nutriscoreGrade,
      'source': product.source,
    };
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

    try {
      await _client
          .from('products')
          .upsert(nutritionData, onConflict: 'barcode');
    } on PostgrestException catch (error) {
      if (!_isMissingNutritionColumn(error)) {
        rethrow;
      }

      _logMissingNutritionSchema();
      await _client.from('products').upsert(baseData, onConflict: 'barcode');
    }
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

  void _logMissingNutritionSchema() {
    debugPrint(
      'Supabase products table is missing nutrition columns. '
      'Nutrition will be refreshed from OpenFoodFacts but cannot be cached '
      'until the required columns are added.',
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
