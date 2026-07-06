import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/analysis_prompt_builder.dart';

void main() {
  const builder = AnalysisPromptBuilder();

  String build({
    double? energyKcal = 200,
    double? fat = 5,
    double? saturatedFat = 2,
    double? sugars = 8,
    double? fiber = 3,
    double? protein = 6,
    double? salt = 0.4,
  }) {
    return builder.buildPrompt(
      productName: 'Örnek ürün',
      brand: 'Örnek',
      ingredients: '',
      labelwiseScore: 70,
      labelwiseCategory: 'İyi Seçim',
      productCategory: 'Bisküvi',
      scoreReasons: const ['Şeker yüksek', 'Kategori nedeniyle sınırlandı'],
      nutriscoreGrade: 'C',
      energyKcal: energyKcal,
      fat: fat,
      saturatedFat: saturatedFat,
      sugars: sugars,
      fiber: fiber,
      protein: protein,
      salt: salt,
    );
  }

  test('does not emphasize one missing secondary value', () {
    final prompt = build(fiber: null);

    expect(prompt, contains('Data completeness: mostly_complete'));
    expect(
      prompt,
      contains('Do not mention missing data or say the evaluation is limited.'),
    );
  });

  test('uses a soft note for partial nutrition data', () {
    final prompt = build(fiber: null, protein: null, energyKcal: null);

    expect(prompt, contains('Data completeness: partial'));
    expect(prompt, contains('yorum genel bir değerlendirmedir'));
  });

  test('marks four missing values as limited', () {
    final prompt = build(
      saturatedFat: null,
      sugars: null,
      fiber: null,
      salt: null,
    );

    expect(prompt, contains('Data completeness: limited'));
    expect(prompt, contains('değerlendirme dikkatli yorumlanmalıdır'));
  });

  test('marks two missing key fields as limited', () {
    final prompt = build(sugars: null, salt: null);

    expect(prompt, contains('Data completeness: limited'));
  });

  test('anchors interpretation to Score v3 without listing values', () {
    final prompt = build();

    expect(prompt, contains('LabelWise Score is the primary deterministic'));
    expect(prompt, contains('Mention at most one number'));
    expect(
      prompt,
      contains(
        'LabelWise Score reasons: Şeker yüksek; Kategori nedeniyle sınırlandı',
      ),
    );
  });
}
