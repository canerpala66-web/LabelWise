import 'package:flutter/foundation.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/analysis/models/processing_profile_result.dart';
import 'package:labelwise/features/analysis/services/analysis_risk_guardrails.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisService {
  const AnalysisService();

  static const analysisVersion = 'v5';
  static const _functionName = 'generate-product-ai-analysis';

  Future<AnalysisResult> generateAnalysis(
    Product product, {
    LabelWiseScoreResult? scoreResult,
    ProcessingProfileResult? processingProfile,
  }) async {
    final barcode = product.barcode.trim();
    if (barcode.isEmpty) {
      throw Exception('Product barcode is missing.');
    }

    debugPrint('AI Edge Function Flutter: calling function barcode=$barcode');

    dynamic data;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'barcode': barcode,
          if (scoreResult != null || processingProfile != null)
            'score_context': {
              'score': scoreResult?.score,
              'score_category': scoreResult?.category,
              'score_reasons': scoreResult?.reasons,
              'product_category': product.category,
              'processing_level': processingProfile?.grade.name,
              'processing_label': processingProfile?.label,
              'processing_reasons': processingProfile?.reasons,
            },
        },
      );
      data = response.data;
      debugPrint('AI Edge Function Flutter: function response raw=$data');
    } on Object catch (error, stackTrace) {
      debugPrint('AI Edge Function Flutter error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    if (data is! Map) {
      debugPrint('AI Edge Function Flutter: function error=invalid response');
      throw const FormatException('AI function response is invalid.');
    }

    final error = data['error'];
    final step = data['step'];
    debugPrint('AI Edge Function Flutter: function error=$error');
    debugPrint('AI Edge Function Flutter: status/details step=$step');
    if (error is String && error.trim().isNotEmpty) {
      throw Exception(
        step is String && step.trim().isNotEmpty
            ? '${error.trim()} [step=$step]'
            : error.trim(),
      );
    }

    final summary = data['summary'];
    final riskLevel = data['risk_level'];

    if (summary is! String || summary.trim().isEmpty) {
      throw const FormatException('AI function summary is invalid.');
    }

    final normalizedRisk = AnalysisRiskGuardrails.apply(
      riskLevel,
      product: product,
      labelwiseScore: scoreResult?.score,
    );
    debugPrint('AI: function normalized riskLevel=$normalizedRisk');

    return AnalysisResult(summary: summary.trim(), riskLevel: normalizedRisk);
  }
}
