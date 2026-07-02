class AnalysisPromptBuilder {
  const AnalysisPromptBuilder();

  String buildPrompt({
    required String productName,
    required String brand,
    required String ingredients,
    required int? labelwiseScore,
    required String labelwiseCategory,
    required String? nutriscoreGrade,
    required double? energyKcal,
    required double? fat,
    required double? saturatedFat,
    required double? sugars,
    required double? fiber,
    required double? protein,
    required double? salt,
  }) {
    final nutritionValues = [
      energyKcal,
      fat,
      saturatedFat,
      sugars,
      fiber,
      protein,
      salt,
    ];
    final missingNutritionCount = nutritionValues
        .where((value) => value == null)
        .length;
    final hasLimitedNutrition = missingNutritionCount >= 4;
    final availableIngredients = ingredients.trim();

    return '''
You are LabelWise.
You help Turkish users understand packaged foods.

Write a short analysis in simple, calm, neutral Turkish using only the product data below.
Be evidence-based and do not invent missing values.
If data is missing, clearly say the evaluation is limited.
Do not make medical or disease claims.
Do not attack or promote brands.
Do not use fear language or absolute safety claims.
Never say "asla tüketmeyin", "kanser yapar", "zehirlidir", or "güvenlidir".
Keep the summary at no more than 70 words.
${hasLimitedNutrition ? 'Beslenme verileri eksik olduğu için değerlendirme sınırlıdır.' : ''}

Product name: $productName
Brand: $brand
LabelWise Score: ${labelwiseScore ?? 'Unavailable'}
LabelWise category: $labelwiseCategory
Nutri-Score: ${_textValue(nutriscoreGrade)}
Energy: ${_nutritionValue(energyKcal, 'kcal')}
Fat: ${_nutritionValue(fat, 'g')}
Saturated fat: ${_nutritionValue(saturatedFat, 'g')}
Sugar: ${_nutritionValue(sugars, 'g')}
Fiber: ${_nutritionValue(fiber, 'g')}
Protein: ${_nutritionValue(protein, 'g')}
Salt: ${_nutritionValue(salt, 'g')}
Ingredients: ${availableIngredients.isEmpty ? 'Unavailable' : availableIngredients}

Return JSON only:
{
  "summary": "Turkish summary, maximum 70 words",
  "risk_level": "düşük | orta | yüksek | bilinmiyor"
}
'''
        .trim();
  }

  String _nutritionValue(double? value, String unit) {
    return value == null ? 'Unavailable' : '$value $unit';
  }

  String _textValue(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Unavailable' : text;
  }
}
