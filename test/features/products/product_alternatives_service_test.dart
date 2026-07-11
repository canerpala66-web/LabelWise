import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/products/services/product_alternatives_service.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  group('ProductAlternativesService', () {
    test('normalizes category and skips invalid candidates', () async {
      String? queriedCategory;
      final current = _product(
        barcode: 'current',
        category: ' CİPS ',
        energy: 600,
        fat: 40,
        saturatedFat: 15,
        sugars: 20,
        salt: 2,
      );
      final service = ProductAlternativesService(
        fetchProducts: (category) async {
          queriedCategory = category;
          return [
            current,
            _product(
              barcode: 'better',
              category: 'cips',
              energy: 300,
              fat: 10,
              saturatedFat: 2,
              sugars: 1,
              salt: 0.2,
            ),
            _product(barcode: 'missing-score', category: 'Cips'),
            _product(
              barcode: 'wrong-category',
              category: 'Kraker',
              energy: 200,
              fat: 5,
              saturatedFat: 1,
              sugars: 1,
              salt: 0.1,
            ),
          ];
        },
      );

      final alternatives = await service.findAlternatives(current);

      expect(queriedCategory, 'Cips');
      expect(alternatives, hasLength(1));
      expect(alternatives.single.product.barcode, 'better');
    });

    test(
      'returns empty without querying when current score is unavailable',
      () async {
        var queryCalled = false;
        final service = ProductAlternativesService(
          fetchProducts: (_) async {
            queryCalled = true;
            return const [];
          },
        );

        final alternatives = await service.findAlternatives(
          _product(barcode: 'current', category: 'Cips'),
        );

        expect(alternatives, isEmpty);
        expect(queryCalled, isFalse);
      },
    );

    test(
      'keeps processed meat alternatives separate from drinks and coffee',
      () async {
        final current = _product(
          barcode: 'current-sosis',
          category: 'Diğer',
          name: 'Tütsülenmiş piliç jumbo sosis',
          energy: 420,
          fat: 32,
          saturatedFat: 11,
          sugars: 1,
          salt: 2.1,
        );
        final service = ProductAlternativesService(
          fetchProducts: (category) async {
            expect(category, 'Diğer');
            return [
              _product(
                barcode: 'better-meat',
                category: 'Diğer',
                name: 'Hindi füme',
                energy: 150,
                fat: 4,
                saturatedFat: 1,
                sugars: 1,
                salt: 0.8,
              ),
              _product(
                barcode: 'lipton',
                category: 'Meyve Suyu',
                name: 'Lipton şeftali aromalı içecek',
                energy: 20,
                fat: 0,
                saturatedFat: 0,
                sugars: 1,
                salt: 0,
              ),
              _product(
                barcode: 'nescafe',
                category: 'Diğer',
                name: 'Nescafe',
                energy: 10,
                fat: 0,
                saturatedFat: 0,
                sugars: 1,
                salt: 0,
              ),
            ];
          },
        );

        final alternatives = await service.findAlternatives(current);

        expect(alternatives.map((item) => item.product.barcode), [
          'better-meat',
        ]);
      },
    );

    test('allows cheese-like products but rejects milk for cheese', () async {
      final queriedCategories = <String>[];
      final current = _product(
        barcode: 'current-cheese',
        category: 'Peynir',
        name: 'Süzme peynir',
        energy: 310,
        fat: 26,
        saturatedFat: 16,
        sugars: 2,
        salt: 1.5,
      );
      final service = ProductAlternativesService(
        fetchProducts: (category) async {
          queriedCategories.add(category);
          return [
            _product(
              barcode: 'labne',
              category: 'Diğer',
              name: 'Pınar Labne',
              energy: 190,
              fat: 12,
              saturatedFat: 7,
              sugars: 2,
              salt: 0.7,
            ),
            _product(
              barcode: 'milk',
              category: 'Süt',
              name: 'Pınar Süt 1 lt',
              energy: 60,
              fat: 3,
              saturatedFat: 2,
              sugars: 4,
              salt: 0.1,
            ),
          ];
        },
      );

      final alternatives = await service.findAlternatives(current);

      expect(queriedCategories, containsAll(['Peynir', 'Diğer']));
      expect(alternatives.map((item) => item.product.barcode), ['labne']);
    });

    test('keeps milk alternatives limited to milk products', () async {
      final current = _product(
        barcode: 'current-milk',
        category: 'Süt',
        name: 'Tam yağlı süt',
        energy: 95,
        fat: 6,
        saturatedFat: 4,
        sugars: 4,
        salt: 0.2,
      );
      final service = ProductAlternativesService(
        fetchProducts: (category) async {
          expect(category, 'Süt');
          return [
            _product(
              barcode: 'light-milk',
              category: 'Süt',
              name: 'Yarım yağlı süt',
              energy: 45,
              fat: 1.5,
              saturatedFat: 1,
              sugars: 4,
              salt: 0.1,
            ),
            _product(
              barcode: 'cheese',
              category: 'Peynir',
              name: 'Beyaz peynir',
              energy: 120,
              fat: 8,
              saturatedFat: 5,
              sugars: 2,
              salt: 0.8,
            ),
          ];
        },
      );

      final alternatives = await service.findAlternatives(current);

      expect(alternatives.map((item) => item.product.barcode), ['light-milk']);
    });

    test(
      'does not query random alternatives for unknown other products',
      () async {
        var queryCalled = false;
        final service = ProductAlternativesService(
          fetchProducts: (_) async {
            queryCalled = true;
            return const [];
          },
        );

        final alternatives = await service.findAlternatives(
          _product(
            barcode: 'unknown',
            category: 'Diğer',
            name: 'Kategori anlaşılmayan ürün',
            energy: 200,
            fat: 5,
            saturatedFat: 1,
            sugars: 4,
            salt: 0.3,
          ),
        );

        expect(alternatives, isEmpty);
        expect(queryCalled, isFalse);
      },
    );

    test('keeps chips alternatives in chips category only', () async {
      final current = _product(
        barcode: 'current-cips',
        category: 'Cips',
        name: 'Baharatlı cips',
        energy: 520,
        fat: 32,
        saturatedFat: 4,
        sugars: 3,
        salt: 1.4,
      );
      final service = ProductAlternativesService(
        fetchProducts: (category) async {
          expect(category, 'Cips');
          return [
            _product(
              barcode: 'better-cips',
              category: 'Cips',
              name: 'Fırınlanmış cips',
              energy: 350,
              fat: 12,
              saturatedFat: 1,
              sugars: 2,
              salt: 0.5,
            ),
            _product(
              barcode: 'drink',
              category: 'Gazlı İçecek',
              name: 'Gazlı içecek',
              energy: 5,
              fat: 0,
              saturatedFat: 0,
              sugars: 0,
              salt: 0,
            ),
            _product(
              barcode: 'milk',
              category: 'Süt',
              name: 'Süt',
              energy: 50,
              fat: 1,
              saturatedFat: 0.5,
              sugars: 3,
              salt: 0.1,
            ),
          ];
        },
      );

      final alternatives = await service.findAlternatives(current);

      expect(alternatives.map((item) => item.product.barcode), ['better-cips']);
    });
  });
}

Product _product({
  required String barcode,
  required String category,
  String? name,
  String brand = 'Test',
  double? energy,
  double? fat,
  double? saturatedFat,
  double? sugars,
  double? salt,
}) {
  return Product(
    barcode: barcode,
    productName: name ?? 'Test Product $barcode',
    brands: brand,
    imageUrl: null,
    ingredientsText: '',
    category: category,
    energyKcal: energy,
    fat: fat,
    saturatedFat: saturatedFat,
    sugars: sugars,
    salt: salt,
  );
}
