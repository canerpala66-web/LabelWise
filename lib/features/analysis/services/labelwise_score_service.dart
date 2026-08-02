import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class LabelWiseScoreService {
  const LabelWiseScoreService({
    LabelWiseScoreEngine engine = const LabelWiseScoreEngine(),
  }) : _engine = engine;

  static const instance = LabelWiseScoreService();
  static const scoreVersion = 'v6';

  final LabelWiseScoreEngine _engine;

  LabelWiseScoreResult calculate(Product product, {int? fallbackScore}) {
    // Scores are recalculated locally with V6 to avoid stale cached scores.
    final v6Result = _engine.calculate(product);
    if (v6Result.score != null) {
      return v6Result;
    }

    if (fallbackScore == null) {
      return v6Result;
    }

    return LabelWiseScoreResult(
      score: fallbackScore.clamp(0, 100),
      category: 'Önceki skor',
      color: _fallbackColor(fallbackScore),
      reasons: const [
        'Güncel V6 skoru hesaplanamadığı için önceki skor gösteriliyor',
      ],
    );
  }

  Color _fallbackColor(int score) {
    if (score >= 90) return const Color(0xFF238447);
    if (score >= 80) return const Color(0xFF63A94B);
    if (score >= 70) return const Color(0xFF8EAD3D);
    if (score >= 60) return const Color(0xFFA6AA3D);
    if (score >= 45) return const Color(0xFFD58B2A);
    if (score >= 25) return const Color(0xFFD86138);
    return const Color(0xFFC33F39);
  }
}
