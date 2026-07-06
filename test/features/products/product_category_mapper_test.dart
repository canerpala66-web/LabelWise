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

    test('canonicalizes Turkish category casing and whitespace', () {
      expect(ProductCategoryMapper.canonicalCategory(' CİPS '), 'Cips');
      expect(ProductCategoryMapper.normalizeCategory(' CİPS '), 'cips');
    });

    final expectations = <String, String>{
      'Cipso Deniz Tuzlu': 'Cips',
      'Sade Patates Cipsi': 'Cips',
      'Doritos Nacho': 'Cips',
      'Pringles Original': 'Cips',
      'Cheetos': 'Cips',
      'Çerezza': 'Cips',
      'Biskrem': 'Bisküvi',
      'Ülker Biskrem Kakaolu': 'Bisküvi',
      'Eti Burçak': 'Bisküvi',
      'Ülker Hanımeller': 'Bisküvi',
      'Oreo': 'Bisküvi',
      'Eti Crax Baharatlı': 'Kraker',
      'Ülker Çizi': 'Kraker',
      'Tuc Kraker': 'Kraker',
      'Coca-Cola Zero': 'Gazlı İçecek',
      'Pepsi Max': 'Gazlı İçecek',
      'Uludağ Gazoz': 'Gazlı İçecek',
      'Red Bull': 'Enerji İçeceği',
      'Monster Energy': 'Enerji İçeceği',
      'İçim Süt Tam Yağlı': 'Süt',
      'İçim Tam Yağlı Süt': 'Süt',
      'Pınar Laktozsuz Süt': 'Süt',
      'Sütlü Çikolata': 'Çikolata',
      'Milka Oreo': 'Çikolata',
      'Tadelle': 'Çikolata',
      'Ülker Çokonat': 'Gofret',
      'Eti Hoşbeş': 'Gofret',
      '9 Kat Tat': 'Gofret',
      'Eti Browni': 'Kek',
      'Ülker Dankek': 'Kek',
      'Eti Popkek': 'Kek',
      'Danone Puding': 'Puding',
      'Daphne Muzlu Puding': 'Puding',
      'Danette Çikolatalı': 'Puding',
      'Supangle': 'Puding',
      'Ruffles Soğanlı': 'Cips',
      'Maden Suyu': 'Maden Suyu',
      'Beypazarı Maden Suyu': 'Maden Suyu',
      'Kızılay Soda': 'Maden Suyu',
      'Pınar Labne': 'Peynir',
      'Magnum Badem': 'Dondurma',
      'Nutella': 'Sos',
      'Dardanel Ton Balığı': 'Konserve',
      'Knorr Mercimek Çorbası': 'Hazır Çorba',
      'Barilla Spaghetti': 'Makarna',
      'Züber Protein Bar': 'Protein Bar',
      'Lipton Ice Tea Şeftali': 'Meyve Suyu',
      'Eti Lifalif Granola': 'Kahvaltılık Gevrek',
    };

    for (final entry in expectations.entries) {
      test('${entry.key} maps to ${entry.value}', () {
        expect(
          ProductCategoryMapper.inferCategory(productName: entry.key),
          entry.value,
        );
      });
    }

    test('uses OFF category before a generic product-name fallback', () {
      expect(
        ProductCategoryMapper.inferCategory(
          productName: 'Sütlü Atıştırmalık',
          categoriesTags: const ['en:chocolates'],
        ),
        'Çikolata',
      );
    });

    test('keeps Turkish milk false positives in their explicit categories', () {
      expect(
        ProductCategoryMapper.inferCategory(productName: 'Sütlü Bisküvi'),
        'Bisküvi',
      );
      expect(
        ProductCategoryMapper.inferCategory(productName: 'Sütlü Gofret'),
        'Gofret',
      );
      expect(
        ProductCategoryMapper.inferCategory(productName: 'Sütlü Kek'),
        'Kek',
      );
    });
  });
}
