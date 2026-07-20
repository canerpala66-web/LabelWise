import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:labelwise/features/profile/data/user_profile.dart';

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ProfileRepositoryException(message: $message)';
}

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _profileFields =
      'id, email, display_name, created_at, updated_at';

  String _sanitizeMessage(String message) {
    return message
        .replaceAll(RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false), '[redacted]')
        .replaceAll(RegExp(r'\beyj[A-Za-z0-9\-._~+/=]+\b', caseSensitive: false), '[redacted]');
  }

  User _requireCurrentUser() {
    final currentUser = _client.auth.currentUser;
    if (kDebugMode) {
      debugPrint('[Profile] currentUser exists: ${currentUser != null}');
    }
    if (currentUser == null) {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    }
    return currentUser;
  }

  Future<UserProfile?> getCurrentProfile() async {
    final currentUser = _requireCurrentUser();

    try {
      final response = await _client
          .from('profiles')
          .select(_profileFields)
          .eq('id', currentUser.id)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('[Profile] profile exists: ${response != null}');
      }

      if (response == null) {
        return null;
      }

      return UserProfile.fromMap(response);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Profile] update failed: ${_sanitizeMessage(error.message)}',
        );
      }
      throw const ProfileRepositoryException('Profil bilgileri yüklenemedi.');
    } on AuthException {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } on Object {
      throw const ProfileRepositoryException('Profil bilgileri yüklenemedi.');
    }
  }

  Future<UserProfile> updateDisplayName(String displayName) async {
    final currentUser = _requireCurrentUser();
    final normalized = displayName.trim();

    if (normalized.isEmpty) {
      throw const ProfileRepositoryException('Kullanıcı adı boş olamaz.');
    }

    if (kDebugMode) {
      debugPrint('[Profile] update started');
    }

    try {
      final existingProfile = await _client
          .from('profiles')
          .select(_profileFields)
          .eq('id', currentUser.id)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('[Profile] profile exists: ${existingProfile != null}');
      }

      final payload = {
        'id': currentUser.id,
        'email': (currentUser.email ?? '').trim(),
        'display_name': normalized,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('profiles')
          .upsert(payload, onConflict: 'id')
          .select(_profileFields)
          .single();

      if (kDebugMode) {
        debugPrint('[Profile] update success');
      }

      return UserProfile.fromMap(response);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Profile] update failed: ${_sanitizeMessage(error.message)}',
        );
      }
      throw const ProfileRepositoryException(
        'Profil güncellenemedi. Lütfen tekrar dene.',
      );
    } on AuthException {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Profile] update failed: ${_sanitizeMessage(error.toString())}',
        );
      }
      throw const ProfileRepositoryException(
        'Profil güncellenemedi. Lütfen tekrar dene.',
      );
    }
  }
}
