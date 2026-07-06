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
  });
}

Product _product({
  required String barcode,
  required String category,
  double? energy,
  double? fat,
  double? saturatedFat,
  double? sugars,
  double? salt,
}) {
  return Product(
    barcode: barcode,
    productName: 'Test Product $barcode',
    brands: 'Test',
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
