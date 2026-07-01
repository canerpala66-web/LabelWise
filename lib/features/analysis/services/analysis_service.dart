import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:labelwise/core/config/env.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/analysis/services/analysis_prompt_builder.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class AnalysisService {
  const AnalysisService();

  static const _endpoint = 'https://api.openai.com/v1/responses';
  static const _model = 'gpt-4.1-mini';
  static const _fallbackResult = AnalysisResult(
    summary: 'Ürün analizi şu anda oluşturulamadı.',
    riskLevel: 'medium',
    labelwiseScore: 50,
  );

  Future<AnalysisResult> generateAnalysis(Product product) async {
    final apiKey = Env.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY is missing. Please add it to .env and restart the app.',
      );
    }

    final prompt = const AnalysisPromptBuilder().buildPrompt(
      productName: product.productName,
      brand: product.brands,
      ingredients: product.ingredientsText,
      nutriscoreGrade: product.nutriscoreGrade,
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
                  'enum': ['low', 'medium', 'high'],
                },
                'labelwise_score': {
                  'type': 'integer',
                  'minimum': 0,
                  'maximum': 100,
                },
              },
              'required': ['summary', 'risk_level', 'labelwise_score'],
              'additionalProperties': false,
            },
          },
        },
      }),
    );

    debugPrint('LabelWise Analysis response received: ${response.statusCode}.');

    if (response.statusCode < 200 || response.statusCode >= 300) {
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
      return _fallbackResult;
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
    final labelwiseScore = data['labelwise_score'];

    if (summary is! String || summary.trim().isEmpty) {
      throw const FormatException('Analysis summary is invalid.');
    }
    if (riskLevel is! String ||
        !const {'low', 'medium', 'high'}.contains(riskLevel)) {
      throw const FormatException('Analysis risk level is invalid.');
    }
    if (labelwiseScore is! int || labelwiseScore < 0 || labelwiseScore > 100) {
      throw const FormatException('LabelWise Score is invalid.');
    }

    return AnalysisResult(
      summary: summary.trim(),
      riskLevel: riskLevel,
      labelwiseScore: labelwiseScore,
    );
  }
}
