import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  const engine = LabelWiseScoreEngine();

  test('caps a high-sugar pudding at 55', () {
    final result = engine.calculate(
      const Product(
        productName: 'Danone Puding',
        brands: 'Danone',
        imageUrl: null,
        ingredientsText: '',
        category: 'Puding',
        energyKcal: 180,
        fat: 3,
        saturatedFat: 2,
        sugars: 25,
        protein: 4,
        salt: 0.2,
      ),
    );

    expect(result.score, lessThanOrEqualTo(55));
  });

  test('caps combined high sugar and saturated fat at 58', () {
    final result = engine.calculate(
      const Product(
        productName: 'Çikolatalı Bisküvi',
        brands: 'Örnek',
        imageUrl: null,
        ingredientsText: '',
        category: 'Bisküvi',
        energyKcal: 420,
        fat: 16,
        saturatedFat: 6,
        sugars: 22,
        protein: 6,
        salt: 0.4,
      ),
    );

    expect(result.score, 55);
  });

  test('does not treat Turkish mineral water as a soft drink', () {
    final result = engine.calculate(
      const Product(
        productName: 'Doğal Soda Maden Suyu',
        brands: 'Örnek',
        imageUrl: null,
        ingredientsText: 'Doğal mineralli su',
        category: 'Maden Suyu',
        energyKcal: 0,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        protein: 0,
        salt: 0.05,
      ),
    );

    expect(result.score, 100);
  });
}
