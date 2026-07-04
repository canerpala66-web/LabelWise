import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:labelwise/features/scanner/data/product.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  static const _fields = [
    'product_name_tr',
    'product_name_en',
    'product_name',
    'generic_name_tr',
    'generic_name_en',
    'generic_name',
    'brands',
    'image_url',
    'ingredients_text_tr',
    'ingredients_text_en',
    'ingredients_text',
    'nutriscore_grade',
    'nutriscore_2023_tags',
    'nutriscore_data',
    'nutriments',
    'categories',
    'categories_tags',
    'categories_hierarchy',
  ];

  final http.Client _client;

  Future<Product?> fetchProduct(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      'api/v2/product/$barcode.json',
      {'fields': _fields.join(',')},
    );
    debugPrint('OpenFoodFacts requested URL: $uri');
    final response = await _client.get(uri);
    debugPrint('OpenFoodFacts response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final bodyPreview = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      debugPrint('OpenFoodFacts response body: $bodyPreview');
      throw Exception('OpenFoodFacts request failed.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid OpenFoodFacts response.');
    }

    final status = data['status'];
    if (status == 0 || status == '0') {
      return null;
    }

    final productData = data['product'];
    if (productData is! Map<String, dynamic>) {
      return null;
    }

    if (status != 1 && status != '1') {
      throw const FormatException('Unexpected OpenFoodFacts status.');
    }

    final product = Product.fromJson(productData, barcode: barcode);
    debugPrint(
      'Nutrition parsed: '
      'energyKcal=${product.energyKcal}, '
      'fat=${product.fat}, '
      'saturatedFat=${product.saturatedFat}, '
      'sugars=${product.sugars}, '
      'fiber=${product.fiber}, '
      'protein=${product.protein}, '
      'salt=${product.salt}, '
      'fruitsVegetablesLegumesPercent='
      '${product.fruitsVegetablesLegumesPercent}',
    );

    return product;
  }

  void dispose() {
    _client.close();
  }
}
