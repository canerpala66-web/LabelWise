import 'package:labelwise/features/scanner/data/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Product?> getProductByBarcode(String barcode) async {
    final data = await _client
        .from('products')
        .select(
          'barcode, name, brand, image_url, ingredients_text, '
          'nutriscore_grade, source',
        )
        .eq('barcode', barcode)
        .maybeSingle();

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
    );
  }

  Future<void> saveProduct(Product product) async {
    if (product.barcode.isEmpty) {
      throw ArgumentError.value(product.barcode, 'barcode', 'Cannot be empty');
    }

    await _client.from('products').upsert({
      'barcode': product.barcode,
      'name': product.productName,
      'brand': product.brands,
      'image_url': product.imageUrl,
      'ingredients_text': product.ingredientsText,
      'nutriscore_grade': product.nutriscoreGrade,
      'source': product.source,
    }, onConflict: 'barcode');
  }
}
