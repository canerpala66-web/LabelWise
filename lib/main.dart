import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:labelwise/app/app.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _initializeFirebaseIfNeeded();
  debugPrint(
    'Env check: '
    'SUPABASE_URL=${dotenv.env['SUPABASE_URL']?.isNotEmpty ?? false}, '
    'SUPABASE_ANON_KEY=${dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false}',
  );
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const LabelWiseApp());
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
