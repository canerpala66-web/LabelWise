import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<UserProfile?> getCurrentProfile() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    }

    try {
      final response = await _client
          .from('profiles')
          .select('id, email, display_name, created_at, updated_at')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromMap(response);
    } on PostgrestException {
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
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    }

    final normalized = displayName.trim();

    try {
      final response = await _client
          .from('profiles')
          .update({'display_name': normalized.isEmpty ? null : normalized})
          .eq('id', currentUser.id)
          .select('id, email, display_name, created_at, updated_at')
          .single();

      return UserProfile.fromMap(response);
    } on PostgrestException {
      throw const ProfileRepositoryException(
        'Profil adı güncellenemedi. Lütfen tekrar dene.',
      );
    } on AuthException {
      throw const ProfileRepositoryException(
        'Giriş yapmadan profil bilgileri görüntülenemez.',
      );
    } on ProfileRepositoryException {
      rethrow;
    } on Object {
      throw const ProfileRepositoryException(
        'Profil adı güncellenemedi. Lütfen tekrar dene.',
      );
    }
  }
}
