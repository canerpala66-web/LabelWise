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
  ];

  final http.Client _client;

  Future<Product?> fetchProduct(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      'api/v2/product/$barcode.json',
      {'fields': _fields.join(',')},
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      final bodyPreview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint('OpenFoodFacts requested URL: $uri');
      debugPrint('OpenFoodFacts response status: ${response.statusCode}');
      debugPrint('OpenFoodFacts response body: $bodyPreview');
      throw Exception('OpenFoodFacts request failed.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic> || data['status'] != 1) {
      return null;
    }

    final productData = data['product'];
    if (productData is! Map<String, dynamic>) {
      return null;
    }

    return Product.fromJson(productData, barcode: barcode);
  }

  void dispose() {
    _client.close();
  }
}
