import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';

void main() {
  group('ProductCategoryMapper', () {
    test('prefers OpenFoodFacts category tags', () {
      final category = ProductCategoryMapper.inferCategory(
        productName: 'Bilinmeyen ürün',
        categoriesTags: const ['en:potato-crisps'],
      );

      expect(category, 'Cips');
    });

    test('uses product name when category tags are unavailable', () {
      final category = ProductCategoryMapper.inferCategory(
        productName: 'ETİ Crax Baharatlı',
      );

      expect(category, 'Kraker');
    });

    test('classifies Turkish mineral water before soft drinks', () {
      final category = ProductCategoryMapper.inferCategory(
        productName: 'Doğal Maden Suyu',
        categoriesTags: const ['en:carbonated-water'],
      );

      expect(category, 'Maden Suyu');
    });

    test('returns Belirsiz when no input is available', () {
      expect(ProductCategoryMapper.inferCategory(), 'Belirsiz');
    });

    final expectations = <String, String>{
      'Biskrem': 'Bisküvi',
      'Ülker Biskrem Kakaolu': 'Bisküvi',
      'Eti Crax Baharatlı': 'Kraker',
      'Coca-Cola Zero': 'Gazlı İçecek',
      'İçim Süt Tam Yağlı': 'Süt',
      'Sütlü Çikolata': 'Çikolata',
      'Danone Puding': 'Puding',
      'Ruffles Soğanlı': 'Cips',
      'Maden Suyu': 'Maden Suyu',
    };

    for (final entry in expectations.entries) {
      test('${entry.key} maps to ${entry.value}', () {
        expect(
          ProductCategoryMapper.inferCategory(productName: entry.key),
          entry.value,
        );
      });
    }
  });
}
