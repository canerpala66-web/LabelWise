import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:labelwise/features/auth/data/auth_config.dart';
import 'package:labelwise/features/auth/data/auth_user.dart' as app_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AuthRepositoryException(message: $message)';
}

class AuthActionResult {
  const AuthActionResult({
    this.user,
    this.requiresEmailConfirmation = false,
    this.message,
  });

  final app_auth.AuthUser? user;
  final bool requiresEmailConfirmation;
  final String? message;

  bool get isSignedIn => user != null;
}

class GoogleAuthDiagnostics {
  const GoogleAuthDiagnostics({
    required this.googleWebClientIdPresent,
    required this.googleWebClientIdLooksValid,
    required this.platformSupported,
    required this.googleInitialized,
  });

  final bool googleWebClientIdPresent;
  final bool googleWebClientIdLooksValid;
  final bool platformSupported;
  final bool googleInitialized;
}

class AuthRepository {
  static const List<String> _googleRequestedScopes = <String>[
    'email',
    'profile',
    'openid',
  ];

  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleInitialized = false;

  app_auth.AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    final authUser = _mapUser(user);
    debugPrint('Auth: current user exists=${authUser != null}');
    return authUser;
  }

  Stream<app_auth.AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final authUser = _mapUser(event.session?.user ?? _client.auth.currentUser);
      final eventName = event.event.name;
      if (eventName == 'signedIn') {
        debugPrint('Auth: signed in');
      } else if (eventName == 'signedOut') {
        debugPrint('Auth: signed out');
      } else {
        debugPrint('Auth: state changed event=$eventName');
      }
      return authUser;
    });
  }

  GoogleAuthDiagnostics getGoogleDiagnostics() {
    return GoogleAuthDiagnostics(
      googleWebClientIdPresent: AuthConfig.googleWebClientIdPresent,
      googleWebClientIdLooksValid: AuthConfig.googleWebClientIdLooksValid,
      platformSupported: AuthConfig.supportsGoogleNativeSignIn,
      googleInitialized: _googleInitialized,
    );
  }

  Future<app_auth.AuthUser> signInWithGoogle() async {
    if (kDebugMode) {
      debugPrint('[GoogleAuthReset] start');
      debugPrint('[GoogleAuthReset] package/API mode: v7');
      debugPrint(
        '[GoogleAuthReset] webClientId present: ${AuthConfig.googleWebClientIdPresent}',
      );
      debugPrint(
        '[GoogleAuthReset] webClientId valid format: ${AuthConfig.googleWebClientIdLooksValid}',
      );
    }

    if (!AuthConfig.supportsGoogleNativeSignIn) {
      throw const AuthRepositoryException(
        'Google ile giriş bu cihazda henüz hazır değil.',
      );
    }

    final serverClientId = AuthConfig.googleWebClientId;
    if (serverClientId.isEmpty) {
      throw const AuthRepositoryException(
        'Google giriş yapılandırması eksik. GOOGLE_WEB_CLIENT_ID değerini kontrol et.',
      );
    }

    if (!AuthConfig.googleWebClientIdLooksValid) {
      throw const AuthRepositoryException(
        'Google giriş ayarları eksik veya hatalı. Web Client ID ve SHA bilgilerini kontrol et.',
      );
    }

    try {
      await _initializeGoogleSignIn(serverClientId: serverClientId);
      await _clearGoogleCachedSignIn();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthRepositoryException(
          'Google ile giriş bu cihazda şu anda desteklenmiyor.',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[GoogleAuthReset] requestedScopes count: ${_googleRequestedScopes.length}',
        );
        debugPrint(
          '[GoogleAuthReset] requestedScopes nonEmpty: ${_googleRequestedScopes.isNotEmpty}',
        );
      }

      final googleAccount = await _googleSignIn.authenticate(
        scopeHint: _googleRequestedScopes,
      );
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] account selected: true');
      }

      final googleAuthentication = googleAccount.authentication;
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] authentication object received: true');
      }

      final googleAuthorization = await googleAccount.authorizationClient
          .authorizationForScopes(_googleRequestedScopes);
      final idToken = googleAuthentication.idToken;
      final accessToken = googleAuthorization?.accessToken;
      if (kDebugMode) {
        debugPrint(
          '[GoogleAuthReset] idToken present: ${idToken != null && idToken.trim().isNotEmpty}',
        );
        debugPrint(
          '[GoogleAuthReset] accessToken present: ${accessToken != null && accessToken.trim().isNotEmpty}',
        );
      }

      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthRepositoryException(
          'Google oturumu doğrulanamadı. Lütfen tekrar dene.',
        );
      }

      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] supabase signIn started');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] supabase signIn success');
      }

      final user = response.user ?? response.session?.user;
      final authUser = _mapUser(user);

      if (authUser == null) {
        throw const AuthRepositoryException(
          'Google ile giriş yapılamadı. Lütfen tekrar dene.',
        );
      }

      debugPrint('Auth: signed in');
      return authUser;
    } on GoogleSignInException catch (error) {
      _debugLogGoogleResetException(error);
      throw AuthRepositoryException(_friendlyMessageForGoogleError(error));
    } on PlatformException catch (error) {
      _debugLogGoogleResetException(error);
      throw AuthRepositoryException(
        _friendlyMessageForPlatformError(error),
      );
    } on AuthRetryableFetchException {
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] exception type: AuthRetryableFetchException');
      }
      throw const AuthRepositoryException(
        'Bağlantı sorunu nedeniyle Google girişi tamamlanamadı.',
      );
    } on AuthApiException catch (error) {
      _debugLogGoogleResetException(error);
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] supabase signIn failed');
      }
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(error, isGoogleSignIn: true),
      );
    } on AuthException catch (error) {
      _debugLogGoogleResetException(error);
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] supabase signIn failed');
      }
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(error, isGoogleSignIn: true),
      );
    } on AuthRepositoryException {
      rethrow;
    } on Object catch (error) {
      _debugLogGoogleResetException(error);
      throw const AuthRepositoryException(
        'Google ile giriş yapılamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<app_auth.AuthUser> signInWithApple() async {
    if (!AuthConfig.supportsAppleSignIn) {
      throw const AuthRepositoryException(
        'Apple ile giriş bu cihazda desteklenmiyor.',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthRepositoryException(
          'Apple ile giriş yapılandırması henüz tamamlanmadı.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user ?? response.session?.user;
      final authUser = _mapUser(user);

      if (authUser == null) {
        throw const AuthRepositoryException(
          'Apple ile giriş yapılandırması henüz tamamlanmadı.',
        );
      }

      return authUser;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthRepositoryException('Apple ile giriş iptal edildi.');
      }

      throw const AuthRepositoryException(
        'Apple ile giriş yapılandırması henüz tamamlanmadı.',
      );
    } on SignInWithAppleNotSupportedException {
      throw const AuthRepositoryException(
        'Apple ile giriş bu cihazda desteklenmiyor.',
      );
    } on AuthRetryableFetchException {
      throw const AuthRepositoryException(
        'Baglanti sorunu nedeniyle Apple girisi tamamlanamadi.',
      );
    } on AuthApiException catch (error) {
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(error, isAppleSignIn: true),
      );
    } on AuthException catch (error) {
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(error, isAppleSignIn: true),
      );
    } on AuthRepositoryException {
      rethrow;
    } on Object {
      throw const AuthRepositoryException(
        'Apple ile giriş yapılandırması henüz tamamlanmadı.',
      );
    }
  }

  Future<AuthActionResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    _validateCredentials(email: trimmedEmail, password: password);

    try {
      final response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
      );
      final user = response.user ?? response.session?.user;
      final authUser = _mapUser(user);
      final hasSession = response.session != null;

      if (authUser != null && hasSession) {
        debugPrint('Auth: signed in after sign up');
        return AuthActionResult(user: authUser);
      }

      if (authUser != null && !hasSession) {
        return const AuthActionResult(
          requiresEmailConfirmation: true,
          message:
              'Hesabin olusturuldu. Giris yapmadan once e-posta dogrulamasi gerekebilir.',
        );
      }

      if (authUser == null) {
        throw const AuthRepositoryException(
          'Hesap oluşturulamadı. Lütfen tekrar deneyin.',
        );
      }

      return AuthActionResult(user: authUser);
    } on AuthRetryableFetchException {
      throw const AuthRepositoryException(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      );
    } on AuthApiException catch (error) {
      throw AuthRepositoryException(_friendlyMessageForAuthError(error));
    } on AuthException catch (error) {
      throw AuthRepositoryException(_friendlyMessageForAuthError(error));
    } on AuthRepositoryException {
      rethrow;
    } on Object {
      throw const AuthRepositoryException(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<app_auth.AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    _validateCredentials(email: trimmedEmail, password: password);

    try {
      final response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = response.user ?? response.session?.user;
      final authUser = _mapUser(user);

      if (authUser == null) {
        throw const AuthRepositoryException(
          'E-posta veya şifre hatalı olabilir.',
        );
      }

      debugPrint('Auth: signed in');
      return authUser;
    } on AuthRetryableFetchException {
      throw const AuthRepositoryException(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      );
    } on AuthApiException catch (error) {
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(
          error,
          isSignIn: true,
        ),
      );
    } on AuthException catch (error) {
      throw AuthRepositoryException(
        _friendlyMessageForAuthError(
          error,
          isSignIn: true,
        ),
      );
    } on AuthRepositoryException {
      rethrow;
    } on Object {
      throw const AuthRepositoryException(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await _googleSignIn.signOut();
      }
      await _client.auth.signOut();
      debugPrint('Auth: signed out');
    } on AuthRetryableFetchException {
      throw const AuthRepositoryException(
        'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      );
    } on AuthApiException catch (error) {
      throw AuthRepositoryException(_friendlyMessageForAuthError(error));
    } on AuthException catch (error) {
      throw AuthRepositoryException(_friendlyMessageForAuthError(error));
    } on Object {
      throw const AuthRepositoryException(
        'Çıkış yapılamadı. Lütfen tekrar deneyin.',
      );
    }
  }

  void _validateCredentials({
    required String email,
    required String password,
  }) {
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthRepositoryException(
        'Geçerli bir e-posta adresi girin.',
      );
    }

    if (password.length < 6) {
      throw const AuthRepositoryException('Şifre en az 6 karakter olmalı.');
    }
  }

  app_auth.AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return app_auth.AuthUser(
      id: user.id,
      email: user.email?.trim() ?? '',
      isAnonymous: user.isAnonymous,
    );
  }

  String _friendlyMessageForAuthError(
    AuthException error, {
    bool isSignIn = false,
    bool isGoogleSignIn = false,
    bool isAppleSignIn = false,
  }) {
    final message = error.message.trim().toLowerCase();
    final code = error is AuthApiException ? (error.code ?? '').toLowerCase() : '';

    if (isGoogleSignIn) {
      if (message.contains('audience') ||
          message.contains('aud') ||
          message.contains('client id') ||
          message.contains('client_id') ||
          message.contains('invalid audience')) {
        return 'Google Client ID ayarlari uyumsuz gorunuyor.';
      }
      if (message.contains('provider') ||
          message.contains('unsupported provider') ||
          message.contains('oauth') ||
          code.contains('validation_failed')) {
        return 'Google girişi sunucu tarafında tamamlanamadı. Supabase Google sağlayıcı ayarlarını kontrol et.';
      }
      if (message.contains('network') ||
          message.contains('socket') ||
          message.contains('timeout') ||
          message.contains('failed to fetch')) {
        return 'Bağlantı sorunu nedeniyle Google girişi tamamlanamadı.';
      }
      return 'Google ile giriş yapılamadı. Lütfen tekrar dene.';
    }

    if (isAppleSignIn) {
      if (message.contains('network') ||
          message.contains('socket') ||
          message.contains('timeout') ||
          message.contains('failed to fetch')) {
        return 'Baglanti sorunu nedeniyle Apple girisi tamamlanamadi.';
      }
      return 'Apple ile giriş yapılandırması henüz tamamlanmadı.';
    }

    if (message.contains('email not confirmed') ||
        code.contains('email_not_confirmed')) {
      return 'Giris yapmadan once e-posta adresini dogrulaman gerekebilir.';
    }

    if (message.contains('user not found') ||
        message.contains('no user found') ||
        code.contains('user_not_found')) {
      return 'Bu e-posta ile kayitli bir hesap bulunamadi.';
    }

    if (message.contains('wrong password') ||
        message.contains('incorrect password') ||
        code.contains('wrong_password')) {
      return 'Sifre hatali gorunuyor.';
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return isSignIn
          ? 'E-posta veya sifre hatali olabilir.'
          : 'Islem su anda tamamlanamadi. Lutfen tekrar deneyin.';
    }

    if (message.contains('user already registered') ||
        message.contains('already been registered') ||
        message.contains('already registered')) {
      return 'Bu e-posta ile zaten bir hesap oluşturulmuş olabilir.';
    }

    if (message.contains('password should be at least') ||
        message.contains('password must be at least')) {
      return 'Şifre en az 6 karakter olmalı.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('failed to fetch')) {
      return 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
    }

    if (message.contains('invalid email')) {
      return 'Geçerli bir e-posta adresi girin.';
    }

    return 'İşlem şu anda tamamlanamadı. Lütfen tekrar deneyin.';
  }

  String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _initializeGoogleSignIn({
    required String serverClientId,
  }) async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }

  Future<void> _clearGoogleCachedSignIn() async {
    try {
      await _googleSignIn.signOut();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[GoogleAuthReset] cached sign-out ignored');
        debugPrint(
          '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.toString())}',
        );
      }
    }
  }

  String _friendlyMessageForGoogleError(GoogleSignInException error) {
    final description = (error.description ?? '').toLowerCase();

    if (description.contains('requestedscopes cannot be null or empty') ||
        description.contains('requestedscopes')) {
      return 'Google giriş izinleri eksik yapılandırılmış görünüyor.';
    }

    if (error.code == GoogleSignInExceptionCode.canceled ||
        description.contains('canceled')) {
      return 'Google ile giriş iptal edildi.';
    }

    if (error.code == GoogleSignInExceptionCode.interrupted) {
      return 'Google ile giriş yarıda kaldı. Lütfen tekrar deneyin.';
    }

    if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
        error.code == GoogleSignInExceptionCode.providerConfigurationError ||
        description.contains('developer_error') ||
        description.contains('apiexception: 10') ||
        description.contains('apiexception: 12500') ||
        description.contains('clientconfigurationerror')) {
      return 'Google Client ID ayarlari uyumsuz gorunuyor.';
    }

    if (description.contains('apiexception: 16') ||
        description.contains('sign_in_failed')) {
      return 'Google oturumu doğrulanamadı. Lütfen tekrar dene.';
    }

    if (error.code == GoogleSignInExceptionCode.uiUnavailable) {
      return 'Google ile giriş şu anda açılamadı.';
    }

    return 'Google ile giriş yapılamadı. Lütfen tekrar dene.';
  }

  String _friendlyMessageForPlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('sign_in_canceled') || code.contains('canceled')) {
      return 'Google ile giriş iptal edildi.';
    }

    if (code.contains('network_error') || message.contains('network')) {
      return 'Bağlantı sorunu nedeniyle Google girişi tamamlanamadı.';
    }

    if (code.contains('sign_in_failed') ||
        message.contains('client_id') ||
        message.contains('audience')) {
      return 'Google Client ID ayarlari uyumsuz gorunuyor.';
    }

    return 'Google ile giriş yapılamadı. Lütfen tekrar dene.';
  }

  void _debugLogGoogleResetException(Object error) {
    if (!kDebugMode) return;

    debugPrint('[GoogleAuthReset] exception type: ${error.runtimeType}');

    if (error is GoogleSignInException) {
      debugPrint('[GoogleAuthReset] safe exception code: ${error.code.name}');
      debugPrint(
        '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.description ?? '')}',
      );
      return;
    }

    if (error is AuthApiException) {
      debugPrint('[GoogleAuthReset] safe exception code: ${error.code ?? 'n/a'}');
      debugPrint(
        '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.message)}',
      );
      return;
    }

    if (error is AuthException) {
      debugPrint(
        '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.message)}',
      );
      return;
    }

    if (error is PlatformException) {
      debugPrint('[GoogleAuthReset] safe exception code: ${error.code}');
      debugPrint(
        '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.message ?? '')}',
      );
      return;
    }

    debugPrint(
      '[GoogleAuthReset] safe exception message: ${_sanitizeForDebug(error.toString())}',
    );
  }

  String _sanitizeForDebug(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('eyj') ||
        lower.contains('token') ||
        lower.contains('bearer') ||
        lower.contains('authorization')) {
      return '[redacted-sensitive-value]';
    }
    return value;
  }
}
