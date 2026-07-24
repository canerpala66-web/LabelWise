import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:labelwise/features/premium/data/subscription_verification_result.dart';

class SubscriptionVerificationRepositoryException implements Exception {
  const SubscriptionVerificationRepositoryException(this.message);

  final String message;

  @override
  String toString() =>
      'SubscriptionVerificationRepositoryException(message: $message)';
}

class SubscriptionVerificationRepository {
  SubscriptionVerificationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<SubscriptionVerificationResult> verifyGooglePlaySubscription({
    required String productId,
    required String purchaseToken,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw const SubscriptionVerificationRepositoryException(
        'Aboneliği doğrulamak için giriş yapman gerekiyor.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'verify-google-play-subscription',
        body: {
          'productId': productId.trim(),
          'purchaseToken': purchaseToken.trim(),
          'platform': 'android',
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const SubscriptionVerificationRepositoryException(
          'Abonelik bilgisi şu anda doğrulanamadı. Lütfen kısa süre sonra tekrar deneyin.',
        );
      }

      return SubscriptionVerificationResult.fromMap(data);
    } on FunctionException catch (_) {
      throw const SubscriptionVerificationRepositoryException(
        'Abonelik bilgisi şu anda doğrulanamadı. Lütfen kısa süre sonra tekrar deneyin.',
      );
    } on AuthException {
      throw const SubscriptionVerificationRepositoryException(
        'Oturum bulunamadı. Lütfen tekrar giriş yap.',
      );
    } on SubscriptionVerificationRepositoryException {
      rethrow;
    } on Object {
      throw const SubscriptionVerificationRepositoryException(
        'Abonelik doğrulanamadı. Lütfen kısa süre sonra tekrar deneyin.',
      );
    }
  }
}
