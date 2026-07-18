import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:labelwise/features/premium/data/user_entitlement.dart';

class EntitlementRepositoryException implements Exception {
  const EntitlementRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'EntitlementRepositoryException(message: $message)';
}

class EntitlementRepository {
  EntitlementRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserEntitlement?> getCurrentEntitlement() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      final response = await _client
          .from('user_entitlements')
          .select(
            'user_id, is_premium, plan_code, entitlement_source, valid_until, updated_at',
          )
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserEntitlement.fromMap(response);
    } on PostgrestException {
      throw const EntitlementRepositoryException(
        'Premium durumu yüklenemedi.',
      );
    } on AuthException {
      throw const EntitlementRepositoryException(
        'Giriş yapmadan premium durumu görüntülenemez.',
      );
    } on EntitlementRepositoryException {
      rethrow;
    } on Object {
      throw const EntitlementRepositoryException(
        'Premium durumu yüklenemedi.',
      );
    }
  }
}
