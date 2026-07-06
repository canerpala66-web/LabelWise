import 'package:labelwise/features/scanner/data/product.dart';

class ProductAlternative {
  const ProductAlternative({
    required this.product,
    required this.score,
    required this.reasons,
  });

  final Product product;
  final int score;
  final List<String> reasons;
}
