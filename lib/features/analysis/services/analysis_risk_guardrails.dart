import 'package:flutter/foundation.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class AnalysisRiskGuardrails {
  const AnalysisRiskGuardrails._();

  static String apply(
    Object? rawRiskLevel, {
    required Product product,
    required int? labelwiseScore,
  }) {
    final normalized = normalize(rawRiskLevel);
    if (normalized == 'bilinmiyor') return normalized;

    if (labelwiseScore != null && labelwiseScore < 20 && normalized != 'yüksek') {
      debugPrint('AI: risk guardrail $normalized -> yüksek');
      return 'yüksek';
    }

    if (labelwiseScore != null && labelwiseScore < 40 && normalized == 'düşük') {
      debugPrint('AI: risk guardrail $normalized -> orta');
      return 'orta';
    }

    final cannotBeLow =
        (labelwiseScore != null && labelwiseScore < 60) ||
        (product.sugars ?? 0) >= 20 ||
        (product.saturatedFat ?? 0) >= 10 ||
        (product.salt ?? 0) >= 1.5;
    final guarded = cannotBeLow && normalized == 'düşük' ? 'orta' : normalized;
    if (guarded != normalized) {
      debugPrint('AI: risk guardrail $normalized -> $guarded');
    }
    return guarded;
  }

  static String normalize(Object? rawRiskLevel) {
    if (rawRiskLevel is! String) return 'bilinmiyor';
    return switch (rawRiskLevel.trim().toLowerCase()) {
      'düşük' || 'low' => 'düşük',
      'orta' || 'medium' => 'orta',
      'yüksek' || 'high' => 'yüksek',
      _ => 'bilinmiyor',
    };
  }
}
