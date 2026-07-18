import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:labelwise/features/premium/data/billing_product.dart';

class BillingRepositoryException implements Exception {
  const BillingRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'BillingRepositoryException(message: $message)';
}

class BillingRepository {
  BillingRepository({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static const Set<String> _productIds = {
    'labelwise_premium_monthly',
    'labelwise_premium_yearly',
  };

  final InAppPurchase _inAppPurchase;

  Stream<List<PurchaseDetails>> get purchaseUpdatedStream {
    if (!_supportsBillingOnCurrentPlatform) {
      return const Stream<List<PurchaseDetails>>.empty();
    }

    return _inAppPurchase.purchaseStream;
  }

  Future<bool> isBillingAvailable() async {
    if (!_supportsBillingOnCurrentPlatform) {
      return false;
    }

    try {
      return await _inAppPurchase.isAvailable();
    } on Object {
      throw const BillingRepositoryException(
        'Google Play satın alma servisine bağlanılamadı.',
      );
    }
  }

  Future<List<BillingProduct>> loadSubscriptionProducts() async {
    if (!_supportsBillingOnCurrentPlatform) {
      throw const BillingRepositoryException(
        'Bu cihazda satın alma servisi şu anda kullanılamıyor.',
      );
    }

    final available = await isBillingAvailable();
    if (!available) {
      throw const BillingRepositoryException(
        'Google Play satın alma servisine bağlanılamadı.',
      );
    }

    try {
      final response = await _inAppPurchase.queryProductDetails(_productIds);
      if (response.error != null) {
        throw const BillingRepositoryException(
          'Abonelik ürünleri şu anda yüklenemedi.',
        );
      }

      final products = response.productDetails
          .map(BillingProduct.fromProductDetails)
          .where((product) => product.planCode != 'unknown')
          .toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

      return products;
    } on BillingRepositoryException {
      rethrow;
    } on Object {
      throw const BillingRepositoryException(
        'Abonelik ürünleri şu anda yüklenemedi.',
      );
    }
  }

  bool get _supportsBillingOnCurrentPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
