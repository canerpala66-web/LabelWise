import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_service.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  test('V6 wins over stale fallback score when current product data is available', () {
    final result = LabelWiseScoreService.instance.calculate(
      const Product(
        productName: 'Pepsi Zero',
        brands: 'Pepsi',
        imageUrl: null,
        ingredientsText:
            'Karbonatlı su, tatlandırıcılar (asesülfam k, aspartam), aroma verici, asitlik düzenleyici',
        category: 'Gazlı İçecek',
        energyKcal: 1,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        salt: 0.02,
      ),
      fallbackScore: 92,
    );

    expect(LabelWiseScoreService.scoreVersion, 'v6');
    expect(result.score, isNot(92));
    expect(result.score, lessThanOrEqualTo(60));
  });

  test('fallback score is used only when V6 cannot calculate at all', () {
    final result = LabelWiseScoreService.instance.calculate(
      const Product(
        productName: 'Eksik Ürün',
        brands: 'Test',
        imageUrl: null,
        ingredientsText: '',
        category: 'Diğer',
      ),
      fallbackScore: 67,
    );

    expect(result.score, 67);
    expect(result.category, 'Önceki skor');
  });
}
