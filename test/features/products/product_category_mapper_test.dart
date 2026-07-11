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

      expect(category, 'Su & Maden Suyu');
    });

    test('returns Belirsiz when no input is available', () {
      expect(ProductCategoryMapper.inferCategory(), 'Belirsiz');
    });

    test('canonicalizes Turkish category casing and whitespace', () {
      expect(ProductCategoryMapper.canonicalCategory(' CİPS '), 'Cips');
      expect(ProductCategoryMapper.normalizeCategory(' CİPS '), 'cips');
      expect(
        ProductCategoryMapper.canonicalCategory('Maden Suyu'),
        'Su & Maden Suyu',
      );
      expect(
        ProductCategoryMapper.canonicalCategory('Protein Bar'),
        'Sporcu Ürünü',
      );
    });

    final expectations = <String, String>{
      'Tütsülenmiş piliç jumbo sosis': 'İşlenmiş Et',
      'Sucuk': 'İşlenmiş Et',
      'Salam': 'İşlenmiş Et',
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
      'Çubuk Kraker': 'Kraker',
      'Ülker Çizi': 'Kraker',
      'Tuc Kraker': 'Kraker',
      'Coca-Cola Zero': 'Gazlı İçecek',
      'Coca Cola': 'Gazlı İçecek',
      'Pepsi Max': 'Gazlı İçecek',
      'Fanta': 'Gazlı İçecek',
      'Uludağ Gazoz': 'Gazlı İçecek',
      'Red Bull': 'Enerji İçeceği',
      'Monster Energy': 'Enerji İçeceği',
      'Pınar Süt': 'Süt',
      'İçim Süt Tam Yağlı': 'Süt',
      'İçim Tam Yağlı Süt': 'Süt',
      'Pınar Laktozsuz Süt': 'Süt',
      'Sütlü Çikolata': 'Çikolata',
      'Milka Oreo': 'Çikolata',
      'Tadelle': 'Çikolata',
      'Ülker Çokonat': 'Bisküvi',
      'Eti Hoşbeş': 'Bisküvi',
      '9 Kat Tat': 'Bisküvi',
      'Eti Browni': 'Kek & Tatlı',
      'Ülker Dankek': 'Kek & Tatlı',
      'Eti Popkek': 'Kek & Tatlı',
      'Danone Puding': 'Sütlü Tatlı',
      'Daphne Muzlu Puding': 'Sütlü Tatlı',
      'Danette Çikolatalı': 'Sütlü Tatlı',
      'Supangle': 'Sütlü Tatlı',
      'Ruffles Soğanlı': 'Cips',
      'Maden Suyu': 'Su & Maden Suyu',
      'Beypazarı Maden Suyu': 'Su & Maden Suyu',
      'Kızılay Soda': 'Su & Maden Suyu',
      'Pınar Labne': 'Peynir',
      'Süzme peynir': 'Peynir',
      'Magnum Badem': 'Dondurma',
      'Nutella': 'Sürülebilir Tatlı',
      'Sarelle': 'Sürülebilir Tatlı',
      'Reçel': 'Sürülebilir Tatlı',
      'Bal': 'Sürülebilir Tatlı',
      'Ketçap': 'Sos',
      'Mayonez': 'Sos',
      'Barbekü sos': 'Sos',
      'Dardanel Ton Balığı': 'Hazır Yemek & Konserve',
      'Konserve': 'Hazır Yemek & Konserve',
      'Knorr Mercimek Çorbası': 'Hazır Yemek & Konserve',
      'Barilla Spaghetti': 'Tahıl & Bakliyat',
      'Yulaf': 'Tahıl & Bakliyat',
      'Granola': 'Tahıl & Bakliyat',
      'Makarna': 'Tahıl & Bakliyat',
      'Pirinç': 'Tahıl & Bakliyat',
      'Züber Protein Bar': 'Sporcu Ürünü',
      'Whey Protein': 'Sporcu Ürünü',
      'Bebek maması': 'Bebek Gıdası',
      'Lipton Ice Tea Şeftali': 'Soğuk Çay',
      'Didi': 'Soğuk Çay',
      'Nescafe': 'Kahve',
      '3ü1 arada': 'Kahve',
      'Cappuccino': 'Kahve',
      'Eti Lifalif Granola': 'Tahıl & Bakliyat',
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
        'Bisküvi',
      );
      expect(
        ProductCategoryMapper.inferCategory(productName: 'Sütlü Kek'),
        'Kek & Tatlı',
      );
    });
  });
}
