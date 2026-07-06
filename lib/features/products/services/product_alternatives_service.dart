import 'package:flutter/foundation.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/products/models/product_alternative.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';

typedef ProductCategoryFetcher =
    Future<List<Product>> Function(String category);

class ProductAlternativesService {
  ProductAlternativesService({
    ProductRepository? repository,
    ProductCategoryFetcher? fetchProducts,
    LabelWiseScoreEngine scoreEngine = const LabelWiseScoreEngine(),
  }) : _fetchProducts =
           fetchProducts ??
           (repository ?? ProductRepository()).fetchProductsByCategory,
       _scoreEngine = scoreEngine;

  final ProductCategoryFetcher _fetchProducts;
  final LabelWiseScoreEngine _scoreEngine;

  Future<List<ProductAlternative>> findAlternatives(Product current) async {
    final rawCategory = current.category;
    final normalizedCategory = ProductCategoryMapper.normalizeCategory(
      rawCategory,
    );
    final canonicalCategory = ProductCategoryMapper.canonicalCategory(
      rawCategory,
    );
    final currentScore = _scoreEngine.calculate(current).score;

    debugPrint('AlternativesDebug: current barcode=${current.barcode}');
    debugPrint('AlternativesDebug: current name=${current.productName}');
    debugPrint('AlternativesDebug: current category raw=$rawCategory');
    debugPrint(
      'AlternativesDebug: current category normalized=$normalizedCategory',
    );
    debugPrint('AlternativesDebug: current score=$currentScore');

    if (currentScore == null ||
        canonicalCategory == null ||
        normalizedCategory.isEmpty ||
        canonicalCategory == 'Belirsiz') {
      debugPrint('AlternativesDebug: selected alternatives count=0');
      return const [];
    }

    late final List<Product> candidates;
    try {
      candidates = await _fetchProducts(canonicalCategory);
    } on Object catch (error, stackTrace) {
      debugPrint('AlternativesDebug: failed step=Supabase query, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    final better = <ProductAlternative>[];
    for (final candidate in candidates) {
      debugPrint(
        'AlternativesDebug: candidate barcode=${candidate.barcode}, '
        'name=${candidate.productName}, category=${candidate.category}',
      );
      try {
        final skipReason = _candidateSkipReason(
          current: current,
          candidate: candidate,
          normalizedCategory: normalizedCategory,
        );
        if (skipReason != null) {
          debugPrint('AlternativesDebug: skipped candidate reason=$skipReason');
          continue;
        }

        final candidateScore = _scoreEngine.calculate(candidate).score;
        debugPrint('AlternativesDebug: candidate score=$candidateScore');
        if (candidateScore == null) {
          debugPrint(
            'AlternativesDebug: skipped candidate reason=score unavailable',
          );
          continue;
        }
        if (candidateScore <= currentScore) {
          debugPrint(
            'AlternativesDebug: skipped candidate reason=score not higher',
          );
          continue;
        }

        better.add(
          ProductAlternative(
            product: candidate,
            score: candidateScore,
            reasons: _comparisonReasons(
              current: current,
              candidate: candidate,
              scoreDifference: candidateScore - currentScore,
            ),
          ),
        );
      } on Object catch (error, stackTrace) {
        debugPrint(
          'AlternativesDebug: skipped candidate reason=processing failed, '
          'error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    better.sort(_compareAlternatives);
    final meaningful = better
        .where((item) => item.score >= currentScore + 5)
        .toList(growable: false);
    final selected = (meaningful.length >= 3 ? meaningful : better)
        .take(5)
        .toList(growable: false);
    debugPrint(
      'AlternativesDebug: selected alternatives count=${selected.length}',
    );
    return selected;
  }

  String? _candidateSkipReason({
    required Product current,
    required Product candidate,
    required String normalizedCategory,
  }) {
    if (candidate.barcode.trim().isEmpty) return 'barcode missing';
    if (candidate.barcode.trim() == current.barcode.trim()) {
      return 'same barcode';
    }
    if (candidate.productName.trim().isEmpty) return 'name missing';
    final candidateCategory = ProductCategoryMapper.normalizeCategory(
      candidate.category,
    );
    if (candidateCategory != normalizedCategory) return 'category mismatch';
    return null;
  }

  int _compareAlternatives(ProductAlternative left, ProductAlternative right) {
    final byScore = right.score.compareTo(left.score);
    if (byScore != 0) return byScore;
    final bySugar = _sortableNutrition(
      left.product.sugars,
    ).compareTo(_sortableNutrition(right.product.sugars));
    if (bySugar != 0) return bySugar;
    return _sortableNutrition(
      left.product.salt,
    ).compareTo(_sortableNutrition(right.product.salt));
  }

  double _sortableNutrition(double? value) => value ?? double.infinity;

  List<String> _comparisonReasons({
    required Product current,
    required Product candidate,
    required int scoreDifference,
  }) {
    final reasons = <String>[
      'LabelWise Skoru $scoreDifference puan daha yüksek',
    ];
    if (_isLower(candidate.sugars, current.sugars)) {
      reasons.add('Şeker değeri daha düşük');
    }
    if (_isLower(candidate.salt, current.salt)) {
      reasons.add('Tuz değeri daha düşük');
    }
    if (_isLower(candidate.saturatedFat, current.saturatedFat)) {
      reasons.add('Doymuş yağ değeri daha düşük');
    }
    return reasons.take(2).toList(growable: false);
  }

  bool _isLower(double? candidate, double? current) {
    return candidate != null && current != null && candidate < current;
  }
}
