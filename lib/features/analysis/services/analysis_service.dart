import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:labelwise/core/config/env.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/analysis/services/analysis_prompt_builder.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class AnalysisService {
  const AnalysisService();

  static const _endpoint = 'https://api.openai.com/v1/responses';
  static const _model = 'gpt-4.1-mini';

  Future<AnalysisResult> generateAnalysis(Product product) async {
    final apiKey = Env.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY is missing. Please add it to .env and restart the app.',
      );
    }

    final scoreResult = const LabelWiseScoreEngine().calculate(product);
    final prompt = const AnalysisPromptBuilder().buildPrompt(
      productName: product.productName,
      brand: product.brands,
      ingredients: product.ingredientsText == 'İçindekiler bilgisi bulunamadı'
          ? ''
          : product.ingredientsText,
      labelwiseScore: scoreResult.score,
      labelwiseCategory: scoreResult.category,
      nutriscoreGrade: product.nutriscoreGrade,
      energyKcal: product.energyKcal,
      fat: product.fat,
      saturatedFat: product.saturatedFat,
      sugars: product.sugars,
      fiber: product.fiber,
      protein: product.protein,
      salt: product.salt,
    );

    debugPrint('LabelWise Analysis request started.');

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'input': prompt,
        'temperature': 0.2,
        'max_output_tokens': 250,
        'store': false,
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'labelwise_analysis',
            'strict': true,
            'schema': {
              'type': 'object',
              'properties': {
                'summary': {'type': 'string'},
                'risk_level': {
                  'type': 'string',
                  'enum': ['düşük', 'orta', 'yüksek', 'bilinmiyor'],
                },
              },
              'required': ['summary', 'risk_level'],
              'additionalProperties': false,
            },
          },
        },
      }),
    );

    debugPrint('LabelWise Analysis response received: ${response.statusCode}.');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyPreview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint('OpenAI Responses API error body: $bodyPreview');
      throw Exception(
        'OpenAI Responses API request failed (${response.statusCode}).',
      );
    }

    try {
      final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      final outputText = _extractOutputText(responseJson);
      return _parseResult(outputText);
    } on Object catch (error, stackTrace) {
      debugPrint('LabelWise Analysis JSON parsing error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const FormatException('OpenAI analysis response is invalid.');
    }
  }

  static String _extractOutputText(Object? responseJson) {
    if (responseJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid Responses API payload.');
    }

    final output = responseJson['output'];
    if (output is! List) {
      throw const FormatException('Responses API output is missing.');
    }

    for (final item in output) {
      if (item is! Map<String, dynamic> || item['type'] != 'message') {
        continue;
      }

      final content = item['content'];
      if (content is! List) {
        continue;
      }

      for (final part in content) {
        if (part is Map<String, dynamic> && part['type'] == 'output_text') {
          final text = part['text'];
          if (text is String && text.isNotEmpty) {
            return text;
          }
        }
      }
    }

    throw const FormatException('Responses API output text is missing.');
  }

  static AnalysisResult _parseResult(String outputText) {
    final data = jsonDecode(outputText);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Analysis output is not a JSON object.');
    }

    final summary = data['summary'];
    final riskLevel = data['risk_level'];

    if (summary is! String || summary.trim().isEmpty) {
      throw const FormatException('Analysis summary is invalid.');
    }
    final normalizedRiskLevel = riskLevel is String
        ? riskLevel.trim().toLowerCase()
        : '';
    final safeRiskLevel =
        const {
          'düşük',
          'orta',
          'yüksek',
          'bilinmiyor',
        }.contains(normalizedRiskLevel)
        ? normalizedRiskLevel
        : 'bilinmiyor';

    final safeSummary = _limitWords(summary.trim(), 70);
    if (_containsForbiddenLanguage(safeSummary)) {
      throw const FormatException('Analysis summary contains unsafe wording.');
    }

    return AnalysisResult(summary: safeSummary, riskLevel: safeRiskLevel);
  }

  static String _limitWords(String text, int maximumWords) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maximumWords) {
      return text;
    }
    return '${words.take(maximumWords).join(' ')}…';
  }

  static bool _containsForbiddenLanguage(String summary) {
    final normalizedSummary = summary.toLowerCase();
    return const [
      'asla tüketmeyin',
      'kanser yapar',
      'zehirlidir',
      'güvenlidir',
    ].any(normalizedSummary.contains);
  }
}
