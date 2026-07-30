import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  group('Product lookup priority helpers', () {
    test('product with nutrition table unavailable marker stays on Supabase data', () {
      final product = Product(
        barcode: '8690000000001',
        productName: 'Bal',
        brands: 'Marka',
        imageUrl: null,
        ingredientsText: 'Bal',
        verificationNotes: 'nutrition_table_not_available:true',
        nutritionTableNotAvailable: true,
      );

      expect(product.hasNutritionData, isFalse);
      expect(product.shouldUseOpenFoodFactsFallback, isFalse);
    });

    test('product without nutrition and without marker may use OpenFoodFacts fallback', () {
      final product = Product(
        barcode: '8690000000002',
        productName: 'Ürün',
        brands: 'Marka',
        imageUrl: null,
        ingredientsText: 'İçerik',
      );

      expect(product.hasNutritionData, isFalse);
      expect(product.shouldUseOpenFoodFactsFallback, isTrue);
    });

    test('fromJson reads nutrition table unavailable marker case-insensitively', () {
      final product = Product.fromJson({
        'name': 'Bal',
        'brand': 'Marka',
        'ingredients_text': 'Bal',
        'verification_notes': 'Nutrition_Table_Not_Available:True',
      }, barcode: '8690000000003');

      expect(product.nutritionTableNotAvailable, isTrue);
      expect(product.shouldUseOpenFoodFactsFallback, isFalse);
    });

    test('carbohydrates counts as nutrition data when it is the only field present', () {
      final product = Product(
        barcode: '8690000000004',
        productName: 'Ürün',
        brands: 'Marka',
        imageUrl: null,
        ingredientsText: 'İçerik',
        carbohydrates: 12,
      );

      expect(product.hasNutritionData, isTrue);
      expect(product.shouldUseOpenFoodFactsFallback, isFalse);
    });
  });
}
