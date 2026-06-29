import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:labelwise/features/scanner/data/product.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Product?> fetchProduct(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
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

    return Product.fromJson(productData);
  }

  void dispose() {
    _client.close();
  }
}
