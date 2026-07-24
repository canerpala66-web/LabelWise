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
      'id, email, display_name, age, gender, height_cm, weight_kg, created_at, updated_at';

  String _sanitizeMessage(String message) {
    return message
        .replaceAll(
          RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
          '[redacted]',
        )
        .replaceAll(
          RegExp(r'\beyj[A-Za-z0-9\-._~+/=]+\b', caseSensitive: false),
          '[redacted]',
        );
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

  Future<UserProfile> updateProfile({
    required String? displayName,
    required int? age,
    required String? gender,
    required int? heightCm,
    required double? weightKg,
  }) async {
    final currentUser = _requireCurrentUser();
    final normalizedDisplayName = _normalizeText(displayName);
    final normalizedGender = _normalizeGender(gender);

    _validateAge(age);
    _validateHeight(heightCm);
    _validateWeight(weightKg);

    if (kDebugMode) {
      debugPrint('[Profile] update started');
    }

    try {
      final payload = {
        'display_name': normalizedDisplayName,
        'age': age,
        'gender': normalizedGender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
      };

      final response = await _client
          .from('profiles')
          .update(payload)
          .eq('id', currentUser.id)
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

  Future<void> deleteCurrentAccount() async {
    _requireCurrentUser();

    try {
      final response = await _client.functions.invoke('delete-account');
      final data = response.data;
      if (response.status != 200 || data is! Map<String, dynamic>) {
        throw const ProfileRepositoryException(
          'Hesap şu anda silinemedi. Lütfen tekrar dene.',
        );
      }

      if (data['success'] != true) {
        throw ProfileRepositoryException(
          (data['message'] as String?)?.trim().isNotEmpty == true
              ? (data['message'] as String).trim()
              : 'Hesap şu anda silinemedi. Lütfen tekrar dene.',
        );
      }
    } on FunctionException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Profile] delete failed: ${_sanitizeMessage(error.toString())}',
        );
      }
      throw const ProfileRepositoryException(
        'Hesap şu anda silinemedi. Lütfen tekrar dene.',
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
          '[Profile] delete failed: ${_sanitizeMessage(error.toString())}',
        );
      }
      throw const ProfileRepositoryException(
        'Hesap şu anda silinemedi. Lütfen tekrar dene.',
      );
    }
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizeGender(String? value) {
    final normalized = _normalizeText(value);
    if (normalized == null) {
      return null;
    }

    const allowedGenders = {'kadın', 'erkek', 'belirtmek istemiyorum'};
    if (!allowedGenders.contains(normalized.toLowerCase())) {
      throw const ProfileRepositoryException(
        'Cinsiyet bilgisi güncellenemedi. Lütfen tekrar dene.',
      );
    }

    return normalized;
  }

  void _validateAge(int? value) {
    if (value != null && (value < 0 || value > 120)) {
      throw const ProfileRepositoryException(
        'Yaş bilgisi 0 ile 120 arasında olmalı.',
      );
    }
  }

  void _validateHeight(int? value) {
    if (value != null && (value < 50 || value > 300)) {
      throw const ProfileRepositoryException(
        'Boy bilgisi 50 ile 300 cm arasında olmalı.',
      );
    }
  }

  void _validateWeight(double? value) {
    if (value != null && (value <= 0 || value > 500)) {
      throw const ProfileRepositoryException(
        'Kilo bilgisi geçerli bir aralıkta olmalı.',
      );
    }
  }
}
