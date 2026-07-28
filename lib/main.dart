import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:labelwise/app/app.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await _initializeWebRuntimeConfig();
  } else {
    await dotenv.load(fileName: '.env');
  }

  await _initializeFirebaseIfNeeded();
  debugPrint(
    'Env check: '
    'SUPABASE_URL=${Env.supabaseUrl.isNotEmpty}, '
    'SUPABASE_ANON_KEY=${Env.supabaseAnonKey.isNotEmpty}',
  );
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const LabelWiseApp());
}

Future<void> _initializeWebRuntimeConfig() async {
  final configUrl = Uri.parse('${Uri.base.origin}/partner-demo-config.json');

  try {
    final response = await http.get(configUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'Partner demo runtime config alınamadı. status=${response.statusCode}',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw Exception('Partner demo runtime config biçimi geçersiz.');
    }

    final supabaseUrl = '${payload['supabaseUrl'] ?? ''}'.trim();
    final supabaseAnonKey = '${payload['supabaseAnonKey'] ?? ''}'.trim();
    final googleWebClientId = '${payload['googleWebClientId'] ?? ''}'.trim();

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Partner demo runtime config eksik.');
    }

    Env.initializeWebConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      googleWebClientId: googleWebClientId,
    );
  } catch (error) {
    debugPrint(
      'Partner demo config error: ${error.runtimeType}',
    );
    rethrow;
  }
}

Future<void> _initializeFirebaseIfNeeded() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  await Firebase.initializeApp();
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  await CrashlyticsService.instance.log(
    'firebase_initialized_android',
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: true,
    );
    return true;
  };
}
