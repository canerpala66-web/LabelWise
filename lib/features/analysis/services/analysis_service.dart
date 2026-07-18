import 'package:flutter/foundation.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisService {
  const AnalysisService();

  static const analysisVersion = 'v4';
  static const _functionName = 'generate-product-ai-analysis';

  Future<AnalysisResult> generateAnalysis(Product product) async {
    final barcode = product.barcode.trim();
    if (barcode.isEmpty) {
      throw Exception('Product barcode is missing.');
    }

    debugPrint('AI Edge Function Flutter: calling function barcode=$barcode');

    dynamic data;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {'barcode': barcode},
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

    final normalizedRisk = _normalizeRiskLevel(riskLevel);
    debugPrint('AI: function normalized riskLevel=$normalizedRisk');

    return AnalysisResult(summary: summary.trim(), riskLevel: normalizedRisk);
  }

  String _normalizeRiskLevel(Object? riskLevel) {
    final normalized = riskLevel is String
        ? riskLevel.trim().toLowerCase()
        : '';
    return switch (normalized) {
      'düşük' || 'low' => 'düşük',
      'yüksek' || 'high' => 'yüksek',
      _ => 'orta',
    };
  }
}
