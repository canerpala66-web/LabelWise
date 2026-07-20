import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:labelwise/core/config/env.dart';
import 'package:labelwise/features/auth/data/auth_user.dart' as app_auth;
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

class AuthRepository {
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

  Future<app_auth.AuthUser> signInWithGoogle() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const AuthRepositoryException(
        'Google ile giriş bu cihazda henüz hazır değil.',
      );
    }

    final serverClientId = Env.googleWebClientId;
    if (serverClientId.isEmpty) {
      throw const AuthRepositoryException(
        'Google ile giriş için GOOGLE_WEB_CLIENT_ID ayarı eksik.',
      );
    }

    try {
      await _initializeGoogleSignIn(serverClientId: serverClientId);

      final googleAccount = await _googleSignIn.authenticate();
      final googleAuthorization = await googleAccount.authorizationClient
          .authorizationForScopes(const <String>[]);
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;
      final accessToken = googleAuthorization?.accessToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthRepositoryException(
          'Google ile giriş şu anda tamamlanamadı.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user ?? response.session?.user;
      final authUser = _mapUser(user);

      if (authUser == null) {
        throw const AuthRepositoryException(
          'Google ile giriş şu anda tamamlanamadı.',
        );
      }

      debugPrint('Auth: signed in');
      return authUser;
    } on GoogleSignInException catch (error) {
      throw AuthRepositoryException(_friendlyMessageForGoogleError(error));
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
        'Google ile giriş şu anda tamamlanamadı.',
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
  }) {
    final message = error.message.trim().toLowerCase();
    final code = error is AuthApiException ? (error.code ?? '').toLowerCase() : '';

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

  Future<void> _initializeGoogleSignIn({
    required String serverClientId,
  }) async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }

  String _friendlyMessageForGoogleError(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => 'Google ile giriş iptal edildi.',
      GoogleSignInExceptionCode.interrupted =>
        'Google ile giriş yarıda kaldı. Lütfen tekrar deneyin.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google ile giriş ayarları şu anda tamamlanmamış görünüyor.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Google ile giriş şu anda açılamadı.',
      _ => 'Google ile giriş şu anda tamamlanamadı.',
    };
  }
}
