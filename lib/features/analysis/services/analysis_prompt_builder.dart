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
    String? processingLevel,
    String? processingLabel,
    List<String> processingReasons = const [],
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
LabelWise Score reflects daily-choice quality and daily intake burden, not just calories or one nutrient.
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

Required tone by LabelWise Score V6:
- 90-100: positive but not absolute; nutrition values are strong.
- 80-89: generally balanced.
- 70-79: moderately positive and portion-aware.
- 60-69: cautious; careful consumption is more suitable.
- 45-59: frequent consumption should give way to occasional consumption.
- 25-44: rare consumption may be more suitable.
- 0-19: clearly cautious. Do not casually say occasional use is fine.
- 20-39: weak/limited-consumption language is acceptable.
Daily sugar, salt, saturated fat load, category caps, ingredient risk signals, and processing level should shape the explanation more than token positives.
If the score reasons mention daily sugar, salt, saturated fat, category cap, or ingredient risk, use those as the main explanation axis.
If a product is a candy, marshmallow, gummy, biscuit, wafer, sugary drink, or energy drink, do not let neutral ingredients like gelatin or tiny protein traces sound meaningfully positive.
For Haribo-like candy or marshmallow products, gelatin is not the main negative; high sugar load and category burden should dominate the explanation.
For zero energy drinks, briefly note low sugar/low calorie if relevant, but explain that sweeteners, processing, and category still keep the score limited.
For filled biscuits or cream-filled wafers, daily sugar load plus palm oil / saturated fat load should be treated as a main caution reason.
Do not say "nadir tüketim" for a score of 80 or above unless the supplied category and score reasons clearly require caution.
If low sugar/low calorie is positive but the category and processing profile are weak, mention that positive briefly but explain why the overall score stays low.

Product name: $productName
Brand: $brand
Product category: ${_textValue(productCategory)}
LabelWise Score: ${labelwiseScore ?? 'Unavailable'}
LabelWise Score category: $labelwiseCategory
LabelWise Score reasons: ${scoreReasons.isEmpty ? 'Unavailable' : scoreReasons.take(4).join('; ')}
Processing level: ${_textValue(processingLevel)}
Processing label: ${_textValue(processingLabel)}
Processing reasons: ${processingReasons.isEmpty ? 'Unavailable' : processingReasons.take(3).join('; ')}
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
