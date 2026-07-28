import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String? _supabaseUrlOverride;
  static String? _supabaseAnonKeyOverride;
  static String? _googleWebClientIdOverride;

  static void initializeWebConfig({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String? googleWebClientId,
  }) {
    _supabaseUrlOverride = supabaseUrl.trim();
    _supabaseAnonKeyOverride = supabaseAnonKey.trim();
    _googleWebClientIdOverride = googleWebClientId?.trim() ?? '';
  }

  static String get supabaseUrl =>
      _supabaseUrlOverride ?? dotenv.get('SUPABASE_URL');

  static String get supabaseAnonKey =>
      _supabaseAnonKeyOverride ?? dotenv.get('SUPABASE_ANON_KEY');

  static String get googleWebClientId =>
      _googleWebClientIdOverride ??
      dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ??
      '';

  static String get appleServiceId =>
      dotenv.env['APPLE_SERVICE_ID']?.trim() ?? '';
}
