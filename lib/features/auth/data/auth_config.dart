import 'package:flutter/foundation.dart';
import 'package:labelwise/core/config/env.dart';

abstract final class AuthConfig {
  static String get googleWebClientId => Env.googleWebClientId;

  static String get appleServiceId => Env.appleServiceId;

  static bool get googleWebClientIdPresent => googleWebClientId.isNotEmpty;

  static bool get googleWebClientIdLooksValid =>
      googleWebClientId.endsWith('.apps.googleusercontent.com');

  static bool get supportsGoogleNativeSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get supportsAppleSignIn =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
