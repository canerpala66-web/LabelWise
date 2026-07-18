import 'package:in_app_purchase/in_app_purchase.dart';

class BillingProduct {
  const BillingProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.planCode,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final String planCode;

  factory BillingProduct.fromProductDetails(ProductDetails details) {
    return BillingProduct(
      id: details.id,
      title: details.title,
      description: details.description,
      price: details.price,
      rawPrice: details.rawPrice,
      currencyCode: details.currencyCode,
      planCode: _planCodeForProductId(details.id),
    );
  }

  static String _planCodeForProductId(String productId) {
    switch (productId) {
      case 'labelwise_premium_monthly':
        return 'monthly';
      case 'labelwise_premium_yearly':
        return 'yearly';
      default:
        return 'unknown';
    }
  }
}
