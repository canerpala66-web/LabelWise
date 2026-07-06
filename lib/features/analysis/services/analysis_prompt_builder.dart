class AnalysisPromptBuilder {
  const AnalysisPromptBuilder();

  String buildPrompt({
    required String productName,
    required String brand,
    required String ingredients,
    required int? labelwiseScore,
    required String labelwiseCategory,
    required String? productCategory,
    required List<String> scoreReasons,
    required String? nutriscoreGrade,
    required double? energyKcal,
    required double? fat,
    required double? saturatedFat,
    required double? sugars,
    required double? fiber,
    required double? protein,
    required double? salt,
  }) {
    final dataCompleteness = calculateDataCompleteness(
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
LabelWise Score is the primary deterministic product interpretation. Support and explain it; never contradict its score range or label.
Explain what the values mean instead of listing them.
Answer whether this suits regular consumption, the main point to watch, and a practical way to consume it.
Use at most 2-3 key reasons. Do not list the nutrition table. Mention at most one number, and only when essential.
Be evidence-based and never invent missing values.
Do not make medical or disease claims.
Do not attack or promote brands.
Do not use fear language or absolute safety claims.
Never say "sağlıklıdır", "zararlıdır", "asla tüketmeyin", "kesinlikle tüketmeyin", "kanser", "toksik", "zehir", or "güvenlidir".
Never use daily-consumption wording for chips, crackers, biscuits, cakes, wafers, chocolate, pudding, ice cream, energy drinks, soft drinks, or fruit juice.
Keep the summary under 55 words if possible.

Preferred style examples (do not copy them verbatim):
- For a fatty snack, explain that occasional consumption and a smaller portion may be more suitable.
- For a high-sugar pudding or dessert, focus on occasional consumption and portion awareness.
- For milk, explain the overall balance and note that sugar may naturally come from lactose when the data supports that interpretation.

Data completeness: $dataCompleteness
${_completenessInstruction(dataCompleteness)}

Required tone by LabelWise Score:
- 90-100: positive but not absolute; nutrition values are strong.
- 80-89: generally balanced.
- 70-79: moderately positive and portion-aware.
- 60-69: cautious; careful consumption is more suitable.
- 45-59: frequent consumption should give way to occasional consumption.
- 25-44: rare consumption may be more suitable.
- 0-24: calmly explain that the nutrition profile is weak.
Do not say "nadir tüketim" for a score of 80 or above unless the supplied category and score reasons clearly require caution.

Product name: $productName
Brand: $brand
Product category: ${_textValue(productCategory)}
LabelWise Score: ${labelwiseScore ?? 'Unavailable'}
LabelWise Score category: $labelwiseCategory
LabelWise Score reasons: ${scoreReasons.isEmpty ? 'Unavailable' : scoreReasons.take(4).join('; ')}
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

  String calculateDataCompleteness({
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
    final missingKeyCount = const {
      'energy_kcal',
      'fat',
      'saturated_fat',
      'sugars',
      'salt',
    }.where(missing.contains).length;
    if (missing.length >= 4 || missingKeyCount >= 2) return 'limited';
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
