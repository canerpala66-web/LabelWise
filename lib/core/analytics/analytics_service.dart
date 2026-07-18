import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsEventNames {
  static const onboardingCompleted = 'onboarding_completed';
  static const scanStarted = 'scan_started';
  static const manualBarcodeSearch = 'manual_barcode_search';
  static const productLookupStarted = 'product_lookup_started';
  static const productFound = 'product_found';
  static const productNotFound = 'product_not_found';
  static const productResultViewed = 'product_result_viewed';
  static const aiAnalysisRequested = 'ai_analysis_requested';
  static const aiAnalysisSuccess = 'ai_analysis_success';
  static const aiAnalysisFailed = 'ai_analysis_failed';
  static const productSubmissionStarted = 'product_submission_started';
  static const productSubmissionCompleted = 'product_submission_completed';
  static const productSubmissionFailed = 'product_submission_failed';
  static const correctionReportStarted = 'correction_report_started';
  static const correctionReportSubmitted = 'correction_report_submitted';
  static const correctionReportFailed = 'correction_report_failed';
  static const premiumScreenViewed = 'premium_screen_viewed';
  static const premiumCtaClicked = 'premium_cta_clicked';
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    final sanitizedParameters = _sanitizeParameters(parameters);

    if (kDebugMode) {
      debugPrint(
        'Analytics event: $name params=$sanitizedParameters',
      );
    }

    try {
      await _analytics.logEvent(
        name: name,
        parameters: sanitizedParameters.isEmpty ? null : sanitizedParameters,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Analytics event failed: $name error=$error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> logOnboardingCompleted() {
    return logEvent(AnalyticsEventNames.onboardingCompleted);
  }

  Future<void> logScanStarted({String? searchType}) {
    return logEvent(
      AnalyticsEventNames.scanStarted,
      parameters: {
        if (searchType != null) 'search_type': searchType,
      },
    );
  }

  Future<void> logManualBarcodeSearch({int? barcodeLength}) {
    return logEvent(
      AnalyticsEventNames.manualBarcodeSearch,
      parameters: {
        'search_type': 'manual',
        if (barcodeLength != null) 'barcode_length': barcodeLength,
      },
    );
  }

  Future<void> logProductLookupStarted({
    int? barcodeLength,
    String? searchType,
  }) {
    return logEvent(
      AnalyticsEventNames.productLookupStarted,
      parameters: {
        if (barcodeLength != null) 'barcode_length': barcodeLength,
        if (searchType != null) 'search_type': searchType,
      },
    );
  }

  Future<void> logProductFound({
    String? source,
    String? category,
    String? scoreBand,
    bool? hasAiCache,
  }) {
    return logEvent(
      AnalyticsEventNames.productFound,
      parameters: {
        if (source != null) 'source': source,
        if (category != null) 'category': category,
        if (scoreBand != null) 'score_band': scoreBand,
        if (hasAiCache != null) 'has_ai_cache': hasAiCache ? 1 : 0,
      },
    );
  }

  Future<void> logProductNotFound({
    int? barcodeLength,
    String? searchType,
  }) {
    return logEvent(
      AnalyticsEventNames.productNotFound,
      parameters: {
        if (barcodeLength != null) 'barcode_length': barcodeLength,
        if (searchType != null) 'search_type': searchType,
      },
    );
  }

  Future<void> logProductResultViewed({
    String? category,
    String? source,
    String? scoreBand,
  }) {
    return logEvent(
      AnalyticsEventNames.productResultViewed,
      parameters: {
        if (category != null) 'category': category,
        if (source != null) 'source': source,
        if (scoreBand != null) 'score_band': scoreBand,
      },
    );
  }

  Future<void> logAiAnalysisRequested({bool? cached}) {
    return logEvent(
      AnalyticsEventNames.aiAnalysisRequested,
      parameters: {
        if (cached != null) 'has_cached_ai': cached ? 1 : 0,
      },
    );
  }

  Future<void> logAiAnalysisRequestedWithVersion({
    bool? hasCachedAi,
    String? analysisVersion,
  }) {
    return logEvent(
      AnalyticsEventNames.aiAnalysisRequested,
      parameters: {
        if (hasCachedAi != null) 'has_cached_ai': hasCachedAi ? 1 : 0,
        if (analysisVersion != null) 'analysis_version': analysisVersion,
      },
    );
  }

  Future<void> logAiAnalysisSuccess({
    String? riskLevel,
    bool? cached,
    String? analysisVersion,
  }) {
    return logEvent(
      AnalyticsEventNames.aiAnalysisSuccess,
      parameters: {
        if (riskLevel != null) 'risk_level': riskLevel,
        if (cached != null) 'cached': cached ? 1 : 0,
        if (analysisVersion != null) 'analysis_version': analysisVersion,
      },
    );
  }

  Future<void> logAiAnalysisFailed({String? failureStep}) {
    return logEvent(
      AnalyticsEventNames.aiAnalysisFailed,
      parameters: {
        if (failureStep != null) 'failure_step': failureStep,
      },
    );
  }

  Future<void> logProductSubmissionStarted({
    bool? hasFrontPhoto,
    bool? hasNutritionPhoto,
    bool? hasIngredientsPhoto,
  }) {
    return logEvent(
      AnalyticsEventNames.productSubmissionStarted,
      parameters: {
        if (hasFrontPhoto != null) 'has_front_photo': hasFrontPhoto ? 1 : 0,
        if (hasNutritionPhoto != null)
          'has_nutrition_photo': hasNutritionPhoto ? 1 : 0,
        if (hasIngredientsPhoto != null)
          'has_ingredients_photo': hasIngredientsPhoto ? 1 : 0,
      },
    );
  }

  Future<void> logProductSubmissionCompleted({
    bool? hasFrontPhoto,
    bool? hasNutritionPhoto,
    bool? hasIngredientsPhoto,
    bool? categorySelected,
  }) {
    return logEvent(
      AnalyticsEventNames.productSubmissionCompleted,
      parameters: {
        if (hasFrontPhoto != null) 'has_front_photo': hasFrontPhoto ? 1 : 0,
        if (hasNutritionPhoto != null)
          'has_nutrition_photo': hasNutritionPhoto ? 1 : 0,
        if (hasIngredientsPhoto != null)
          'has_ingredients_photo': hasIngredientsPhoto ? 1 : 0,
        if (categorySelected != null)
          'category_selected': categorySelected ? 1 : 0,
      },
    );
  }

  Future<void> logProductSubmissionFailed({String? failureStep}) {
    return logEvent(
      AnalyticsEventNames.productSubmissionFailed,
      parameters: {
        if (failureStep != null) 'failure_step': failureStep,
      },
    );
  }

  Future<void> logCorrectionReportStarted({String? issueType}) {
    return logEvent(
      AnalyticsEventNames.correctionReportStarted,
      parameters: {
        if (issueType != null) 'issue_type': issueType,
      },
    );
  }

  Future<void> logCorrectionReportSubmitted({String? issueType}) {
    return logEvent(
      AnalyticsEventNames.correctionReportSubmitted,
      parameters: {
        if (issueType != null) 'issue_type': issueType,
      },
    );
  }

  Future<void> logCorrectionReportSubmittedDetailed({
    String? issueType,
    bool? hasNote,
  }) {
    return logEvent(
      AnalyticsEventNames.correctionReportSubmitted,
      parameters: {
        if (issueType != null) 'issue_type': issueType,
        if (hasNote != null) 'has_note': hasNote ? 1 : 0,
      },
    );
  }

  Future<void> logCorrectionReportFailed({String? failureStep}) {
    return logEvent(
      AnalyticsEventNames.correctionReportFailed,
      parameters: {
        if (failureStep != null) 'failure_step': failureStep,
      },
    );
  }

  Future<void> logPremiumScreenViewed({String? source}) {
    return logEvent(
      AnalyticsEventNames.premiumScreenViewed,
      parameters: {
        if (source != null) 'source': source,
      },
    );
  }

  Future<void> logPremiumCtaClicked({String? source}) {
    return logEvent(
      AnalyticsEventNames.premiumCtaClicked,
      parameters: {
        if (source != null) 'source': source,
      },
    );
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) {
      return const {};
    }

    final sanitized = <String, Object>{};

    parameters.forEach((key, value) {
      if (value == null) {
        return;
      }

      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty) {
        return;
      }

      final normalizedValue = _normalizeValue(value);
      if (normalizedValue == null) {
        return;
      }

      sanitized[normalizedKey] = normalizedValue;
    });

    return sanitized;
  }

  Object? _normalizeValue(Object value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
    }

    if (value is int || value is double) {
      return value;
    }

    if (value is bool) {
      return value ? 1 : 0;
    }

    return value.toString();
  }
}
