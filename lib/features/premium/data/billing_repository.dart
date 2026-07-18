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
    final response = await _querySubscriptionProductDetails();

    final products = response.productDetails
        .map(BillingProduct.fromProductDetails)
        .where((product) => product.planCode != 'unknown')
        .toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return products;
  }

  Future<void> startSubscriptionPurchase({
    required String productId,
  }) async {
    final normalizedProductId = productId.trim();

    if (!_productIds.contains(normalizedProductId)) {
      throw const BillingRepositoryException(
        'Abonelik ürünü şu anda bulunamadı.',
      );
    }

    final response = await _querySubscriptionProductDetails();
    final matchingProduct = response.productDetails
        .where((product) => product.id == normalizedProductId)
        .cast<ProductDetails?>()
        .firstWhere(
          (product) => product != null,
          orElse: () => null,
        );

    if (matchingProduct == null) {
      throw const BillingRepositoryException(
        'Abonelik ürünü şu anda bulunamadı.',
      );
    }

    try {
      final purchaseStarted = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: matchingProduct),
      );

      if (!purchaseStarted) {
        throw const BillingRepositoryException(
          'Satın alma başlatılamadı. Lütfen tekrar dene.',
        );
      }
    } on BillingRepositoryException {
      rethrow;
    } on Object {
      throw const BillingRepositoryException(
        'Satın alma başlatılamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> restorePurchases() async {
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
      await _inAppPurchase.restorePurchases();
    } on BillingRepositoryException {
      rethrow;
    } on Object {
      throw const BillingRepositoryException(
        'Satın alımlar geri yüklenemedi.',
      );
    }
  }

  Future<void> completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) {
      return;
    }

    try {
      await _inAppPurchase.completePurchase(purchase);
    } on Object {
      throw const BillingRepositoryException(
        'Satın alma işlemi son adımda tamamlanamadı.',
      );
    }
  }

  Future<ProductDetailsResponse> _querySubscriptionProductDetails() async {
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
      return response;
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
