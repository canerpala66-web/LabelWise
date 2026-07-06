import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/analysis_risk_guardrails.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  const balancedProduct = Product(
    productName: 'Sade Süt',
    brands: 'Test',
    imageUrl: null,
    ingredientsText: '',
    category: 'Süt',
    energyKcal: 60,
    fat: 3,
    saturatedFat: 2,
    sugars: 4,
    salt: 0.1,
  );

  test('low risk becomes medium below score 60', () {
    expect(
      AnalysisRiskGuardrails.apply(
        'düşük',
        product: balancedProduct,
        labelwiseScore: 45,
      ),
      'orta',
    );
  });

  test('high sugar cannot keep low risk', () {
    const highSugarProduct = Product(
      productName: 'Puding',
      brands: 'Test',
      imageUrl: null,
      ingredientsText: '',
      category: 'Puding',
      sugars: 25,
    );
    expect(
      AnalysisRiskGuardrails.apply(
        'low',
        product: highSugarProduct,
        labelwiseScore: 65,
      ),
      'orta',
    );
  });

  test('invalid risk remains bilinmiyor', () {
    expect(
      AnalysisRiskGuardrails.apply(
        'unexpected',
        product: balancedProduct,
        labelwiseScore: 40,
      ),
      'bilinmiyor',
    );
  });

  test('valid high-score low risk remains low', () {
    expect(
      AnalysisRiskGuardrails.apply(
        'düşük',
        product: balancedProduct,
        labelwiseScore: 92,
      ),
      'düşük',
    );
  });
}
