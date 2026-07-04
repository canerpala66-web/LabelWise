class AnalysisPromptBuilder {
  const AnalysisPromptBuilder();

  String buildPrompt({
    required String productName,
    required String brand,
    required String ingredients,
    required int? labelwiseScore,
    required String labelwiseCategory,
    required String? productCategory,
    required String? nutriscoreGrade,
    required double? energyKcal,
    required double? fat,
    required double? saturatedFat,
    required double? sugars,
    required double? fiber,
    required double? protein,
    required double? salt,
  }) {
    final dataCompleteness = _dataCompleteness(
      energyKcal: energyKcal,
      fat: fat,
      saturatedFat: saturatedFat,
      sugars: sugars,
      fiber: fiber,
      protein: protein,
      salt: salt,
    );
    final availableIngredients = ingredients.trim();

    return '''
You are LabelWise.
You help Turkish users understand packaged foods.

Write a practical interpretation in simple, calm, neutral Turkish using only the product data below.
Explain what the values mean instead of listing them.
Answer whether this suits regular consumption, the main point to watch, and a practical way to consume it.
Use at most 2-3 key reasons. Do not repeat every nutrition number; mention a number only when essential.
Be evidence-based and never invent missing values.
Do not make medical or disease claims.
Do not attack or promote brands.
Do not use fear language or absolute safety claims.
Never say "sağlıklıdır", "zararlıdır", "asla tüketmeyin", "kesinlikle tüketmeyin", "kanser", "toksik", "zehir", or "güvenlidir".
Do not recommend daily consumption for high-sugar or high-saturated-fat snacks, puddings, desserts, chocolate, biscuits, cakes, wafers, chips, or ice cream.
Keep the summary under 55 words if possible.

Preferred style examples (do not copy them verbatim):
- For a fatty snack, explain that occasional consumption and a smaller portion may be more suitable.
- For a high-sugar pudding or dessert, focus on occasional consumption and portion awareness.
- For milk, explain the overall balance and note that sugar may naturally come from lactose when the data supports that interpretation.

Data completeness: $dataCompleteness
${_completenessInstruction(dataCompleteness)}

Product name: $productName
Brand: $brand
Product category: ${_textValue(productCategory)}
LabelWise Score: ${labelwiseScore ?? 'Unavailable'}
LabelWise Score category: $labelwiseCategory
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
  "summary": "Practical Turkish interpretation, maximum 55 words",
  "risk_level": "düşük | orta | yüksek | bilinmiyor"
}
'''
        .trim();
  }

  String _dataCompleteness({
    required double? energyKcal,
    required double? fat,
    required double? saturatedFat,
    required double? sugars,
    required double? fiber,
    required double? protein,
    required double? salt,
  }) {
    final values = <String, double?>{
      'energy_kcal': energyKcal,
      'fat': fat,
      'saturated_fat': saturatedFat,
      'sugars': sugars,
      'fiber': fiber,
      'protein': protein,
      'salt': salt,
    };
    final missing = values.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toSet();
    if (missing.isEmpty) return 'complete';
    if (missing.length <= 1 ||
        missing.difference(const {'fiber', 'protein'}).isEmpty) {
      return 'mostly_complete';
    }
    final criticalFieldsMissingTogether = const {
      'sugars',
      'salt',
      'saturated_fat',
    }.every(missing.contains);
    if (missing.length >= 4 || criticalFieldsMissingTogether) return 'limited';
    return 'partial';
  }

  String _completenessInstruction(String dataCompleteness) {
    return switch (dataCompleteness) {
      'complete' || 'mostly_complete' =>
        'Do not mention missing data or say the evaluation is limited.',
      'partial' =>
        'Briefly and softly state: "Bazı beslenme değerleri eksik olduğu için yorum genel bir değerlendirmedir."',
      _ =>
        'State: "Beslenme verileri sınırlı olduğu için değerlendirme dikkatli yorumlanmalıdır."',
    };
  }

  String _nutritionValue(double? value, String unit) {
    return value == null ? 'Unavailable' : '$value $unit';
  }

  String _textValue(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Unavailable' : text;
  }
}
