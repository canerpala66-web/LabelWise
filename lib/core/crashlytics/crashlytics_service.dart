import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  CrashlyticsService._();

  static final CrashlyticsService instance = CrashlyticsService._();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  Future<void> setCurrentFlow(String flow) async {
    final normalizedFlow = _normalizedText(flow);
    if (normalizedFlow == null) return;

    await _setCustomKey('current_flow', normalizedFlow);
    await log('flow:$normalizedFlow');
  }

  Future<void> setCurrentScreen(String screen) async {
    final normalizedScreen = _normalizedText(screen);
    if (normalizedScreen == null) return;

    await _setCustomKey('current_screen', normalizedScreen);
    await log('screen:$normalizedScreen');
  }

  Future<void> setSafeContext(String key, Object? value) async {
    final normalizedKey = _normalizedKey(key);
    final normalizedValue = _normalizeValue(value);
    if (normalizedKey == null || normalizedValue == null) return;

    await _setCustomKey(normalizedKey, normalizedValue);
  }

  Future<void> log(String message) async {
    final normalizedMessage = _normalizedText(message, maxLength: 80);
    if (normalizedMessage == null) return;

    if (kDebugMode) {
      debugPrint('Crashlytics log: $normalizedMessage');
    }

    try {
      await _crashlytics.log(normalizedMessage);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Crashlytics log failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    final safeReason = _normalizedText(reason, maxLength: 60);
    if (safeReason != null) {
      await _setCustomKey('error_reason', safeReason);
    }

    if (context != null) {
      for (final entry in context.entries) {
        final normalizedKey = _normalizedKey(entry.key);
        final normalizedValue = _normalizeValue(entry.value);
        if (normalizedKey == null || normalizedValue == null) {
          continue;
        }
        await _setCustomKey(normalizedKey, normalizedValue);
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Crashlytics non-fatal: reason=$safeReason, '
        'context=${_debugSafeContext(context)}',
      );
    }

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: safeReason,
        fatal: false,
      );
    } catch (recordError, recordStackTrace) {
      if (kDebugMode) {
        debugPrint('Crashlytics recordNonFatal failed: $recordError');
        debugPrintStack(stackTrace: recordStackTrace);
      }
    }
  }

  Future<void> _setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Crashlytics setCustomKey failed: key=$key error=$error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  String? _normalizedText(String? value, {int maxLength = 40}) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= maxLength
        ? trimmed
        : trimmed.substring(0, maxLength);
  }

  String? _normalizedKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= 40 ? trimmed : trimmed.substring(0, 40);
  }

  Object? _normalizeValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    if (value is int || value is double) return value;
    return _normalizedText(value.toString(), maxLength: 80);
  }

  Map<String, Object?> _debugSafeContext(Map<String, Object?>? context) {
    if (context == null || context.isEmpty) return const {};

    final sanitized = <String, Object?>{};
    for (final entry in context.entries) {
      final key = _normalizedKey(entry.key);
      final value = _normalizeValue(entry.value);
      if (key != null && value != null) {
        sanitized[key] = value;
      }
    }
    return sanitized;
  }
}
