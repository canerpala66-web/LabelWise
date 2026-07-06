import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/scanner/data/submitted_product_repository.dart';

void main() {
  group('SubmittedProductRepository.buildInsertPayload', () {
    test('accepts zero values with dot and comma decimal separators', () {
      expect(SubmittedProductRepository.parseNutritionValue('0'), 0);
      expect(SubmittedProductRepository.parseNutritionValue('0.0'), 0);
      expect(SubmittedProductRepository.parseNutritionValue('0,0'), 0);
      expect(SubmittedProductRepository.parseNutritionValue(''), isNull);
      expect(SubmittedProductRepository.parseNutritionValue('  '), isNull);
    });

    test('omits empty optional nutrition and image fields', () {
      final payload = SubmittedProductRepository.buildInsertPayload(
        barcode: ' 8690000000001 ',
        name: ' Su ',
        brand: ' ',
        ingredientsText: '',
      );

      expect(payload, {
        'barcode': '8690000000001',
        'name': 'Su',
        'status': 'pending',
        'source': 'user_submission',
      });
    });

    test('includes only the selected front photo and category', () {
      final payload = SubmittedProductRepository.buildInsertPayload(
        barcode: '8690000000002',
        name: 'Maden Suyu',
        category: 'İçecekler',
        frontImagePath: 'submitted-products/869/front.jpg',
        nutritionImagePath: '',
      );

      expect(payload['category'], 'İçecekler');
      expect(payload['front_image_path'], 'submitted-products/869/front.jpg');
      expect(payload, isNot(contains('nutrition_image_path')));
      expect(payload, isNot(contains('ingredients_image_path')));
    });

    test('preserves zero nutrition values for water products', () {
      final payload = SubmittedProductRepository.buildInsertPayload(
        barcode: '8690000000003',
        name: 'Su',
        energyKcal: 0,
        fat: 0.0,
        saturatedFat: 0,
        sugars: 0.0,
        fiber: 0,
        protein: 0.0,
        salt: 0,
      );

      for (final column in const [
        'energy_kcal',
        'fat',
        'saturated_fat',
        'sugars',
        'fiber',
        'protein',
        'salt',
      ]) {
        expect(payload[column], 0, reason: '$column must preserve zero');
      }
    });

    test('uses only supported submitted_products insert columns', () {
      final payload = SubmittedProductRepository.buildInsertPayload(
        barcode: '8690000000004',
        name: 'Test Ürünü',
        brand: 'Marka',
        category: 'Atıştırmalık',
        ingredientsText: 'İçindekiler',
        energyKcal: 12,
        fat: 1,
        saturatedFat: 0,
        sugars: 2,
        fiber: 0,
        protein: 1,
        salt: 0,
        frontImagePath: 'front.jpg',
        nutritionImagePath: 'nutrition.jpg',
        ingredientsImagePath: 'ingredients.jpg',
      );
      const validColumns = {
        'barcode',
        'name',
        'brand',
        'category',
        'ingredients_text',
        'energy_kcal',
        'fat',
        'saturated_fat',
        'sugars',
        'fiber',
        'protein',
        'salt',
        'front_image_path',
        'nutrition_image_path',
        'ingredients_image_path',
        'status',
        'source',
      };

      expect(payload.keys.toSet(), validColumns);
      expect(payload, isNot(contains('created_at')));
    });
  });
}
