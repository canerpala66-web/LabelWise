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
    final currentGroup = _alternativeGroup(current);
    final currentScore = _scoreEngine.calculate(current).score;

    debugPrint('AlternativesDebug: current barcode=${current.barcode}');
    debugPrint('AlternativesDebug: current name=${current.productName}');
    debugPrint('AlternativesDebug: current category raw=$rawCategory');
    debugPrint(
      'Alternatives Debug: current product name=${current.productName}',
    );
    debugPrint('Alternatives Debug: current category=$rawCategory');
    debugPrint('Alternatives Debug: inferred group=$currentGroup');
    debugPrint(
      'AlternativesDebug: current category normalized=$normalizedCategory',
    );
    debugPrint('AlternativesDebug: current score=$currentScore');

    if (currentScore == null || currentGroup == null) {
      debugPrint('AlternativesDebug: selected alternatives count=0');
      debugPrint('Alternatives Debug: selected alternatives count=0');
      return const [];
    }

    final queryCategories = _queryCategories(
      canonicalCategory: canonicalCategory,
      group: currentGroup,
    );
    if (queryCategories.isEmpty) {
      debugPrint('AlternativesDebug: selected alternatives count=0');
      debugPrint('Alternatives Debug: selected alternatives count=0');
      return const [];
    }

    final candidatesByBarcode = <String, Product>{};
    try {
      for (final category in queryCategories) {
        final rows = await _fetchProducts(category);
        for (final row in rows) {
          candidatesByBarcode[row.barcode.trim()] = row;
        }
      }
    } on Object catch (error, stackTrace) {
      debugPrint('AlternativesDebug: failed step=Supabase query, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    final candidates = candidatesByBarcode.values.toList(growable: false);
    debugPrint('Alternatives Debug: raw candidate count=${candidates.length}');

    final better = <ProductAlternative>[];
    final exactCategoryBetter = <ProductAlternative>[];
    var compatibleCandidateCount = 0;
    for (final candidate in candidates) {
      debugPrint(
        'AlternativesDebug: candidate barcode=${candidate.barcode}, '
        'name=${candidate.productName}, category=${candidate.category}',
      );
      try {
        final skipReason = _candidateSkipReason(
          current: current,
          candidate: candidate,
          currentGroup: currentGroup,
        );
        if (skipReason != null) {
          debugPrint('AlternativesDebug: skipped candidate reason=$skipReason');
          if (skipReason == 'incompatible_category') {
            debugPrint(
              'Alternatives Debug: rejected candidate=${candidate.productName}, '
              'category=${candidate.category}, reason=incompatible_category',
            );
          }
          continue;
        }
        compatibleCandidateCount++;

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

        final alternative = ProductAlternative(
          product: candidate,
          score: candidateScore,
          reasons: _comparisonReasons(
            current: current,
            candidate: candidate,
            scoreDifference: candidateScore - currentScore,
          ),
        );
        better.add(alternative);
        if (_isExactCategoryMatch(current, candidate)) {
          exactCategoryBetter.add(alternative);
        }
      } on Object catch (error, stackTrace) {
        debugPrint(
          'AlternativesDebug: skipped candidate reason=processing failed, '
          'error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    debugPrint(
      'Alternatives Debug: compatible candidate count=$compatibleCandidateCount',
    );

    better.sort(_compareAlternatives);
    exactCategoryBetter.sort(_compareAlternatives);
    final rankedAlternatives = exactCategoryBetter.length >= 3
        ? exactCategoryBetter
        : better;
    final meaningful = rankedAlternatives
        .where((item) => item.score >= currentScore + 5)
        .toList(growable: false);
    final selected = (meaningful.length >= 3 ? meaningful : rankedAlternatives)
        .take(5)
        .toList(growable: false);
    debugPrint(
      'AlternativesDebug: selected alternatives count=${selected.length}',
    );
    debugPrint(
      'Alternatives Debug: selected alternatives count=${selected.length}',
    );
    return selected;
  }

  String? _candidateSkipReason({
    required Product current,
    required Product candidate,
    required String currentGroup,
  }) {
    if (candidate.barcode.trim().isEmpty) return 'barcode missing';
    if (candidate.barcode.trim() == current.barcode.trim()) {
      return 'same barcode';
    }
    if (candidate.productName.trim().isEmpty) return 'name missing';
    final candidateGroup = _alternativeGroup(candidate);
    if (candidateGroup != currentGroup) return 'incompatible_category';
    return null;
  }

  List<String> _queryCategories({
    required String? canonicalCategory,
    required String group,
  }) {
    final categories = <String>{
      if (canonicalCategory != null &&
          canonicalCategory.isNotEmpty &&
          canonicalCategory != 'Belirsiz')
        canonicalCategory,
      ...switch (group) {
        'processed_meat' => const ['Diğer'],
        'cheese' => const ['Peynir', 'Diğer'],
        'milk' => const ['Süt'],
        'drink' => const ['Gazlı İçecek', 'Meyve Suyu', 'Enerji İçeceği'],
        'coffee' => const ['Diğer'],
        'cips' => const ['Cips'],
        'kraker' => const ['Kraker'],
        'biskuvi' => const ['Bisküvi'],
        'cikolata' => const ['Çikolata'],
        'dondurma' => const ['Dondurma'],
        'gofret' => const ['Gofret'],
        'kek' => const ['Kek'],
        'puding' => const ['Puding'],
        _ => const <String>[],
      },
    }..remove('Belirsiz');

    return categories.toList(growable: false);
  }

  String? _alternativeGroup(Product product) {
    final categoryGroup = _groupFromCategory(product.category);
    if (categoryGroup != null) return categoryGroup;

    return _groupFromText(
      [
        product.productName,
        product.brands,
        product.category,
        product.ingredientsText,
      ].whereType<String>().join(' '),
    );
  }

  String? _groupFromCategory(String? category) {
    final normalized = ProductCategoryMapper.normalizeCategory(category);
    return switch (normalized) {
      'cips' => 'cips',
      'kraker' => 'kraker',
      'biskuvi' => 'biskuvi',
      'cikolata' => 'cikolata',
      'dondurma' => 'dondurma',
      'gofret' => 'gofret',
      'kek' => 'kek',
      'puding' => 'puding',
      'sosis' ||
      'sucuk' ||
      'salam' ||
      'pastirma' ||
      'jambon' ||
      'hindi fume' ||
      'tavuk fume' ||
      'islenmis et' => 'processed_meat',
      'peynir' ||
      'beyaz peynir' ||
      'kasar' ||
      'suzme peynir' ||
      'labne' ||
      'krem peynir' ||
      'lor' => 'cheese',
      'sut' || 'uht sut' => 'milk',
      'gazli icecek' ||
      'meyve suyu' ||
      'enerji icecegi' ||
      'soguk cay' ||
      'icecek' => 'drink',
      'kahve' || 'hazir kahve' || 'soguk kahve' => 'coffee',
      'diger' || 'belirsiz' || '' => null,
      _ => normalized,
    };
  }

  String? _groupFromText(String value) {
    final text = _normalizeText(value);
    if (text.isEmpty) return null;
    if (_matchesAny(text, const [
      'sosis',
      'sucuk',
      'salam',
      'pastirma',
      'jambon',
      'hindi fume',
      'tavuk fume',
      'piliç füme',
      'pilic fume',
      'islenmis et',
    ])) {
      return 'processed_meat';
    }
    if (_matchesAny(text, const [
      'beyaz peynir',
      'suzme peynir',
      'peynir',
      'kasar',
      'labne',
      'krem peynir',
      'lor',
      'tulum',
    ])) {
      return 'cheese';
    }
    if (_matchesAny(text, const ['sut', 'uht milk', 'whole milk'])) {
      return 'milk';
    }
    if (_matchesAny(text, const [
      'kahve',
      'hazir kahve',
      'nescafe',
      'soguk kahve',
      'cold brew',
    ])) {
      return 'coffee';
    }
    if (_matchesAny(text, const [
      'gazli icecek',
      'icecek',
      'kola',
      'cola',
      'gazoz',
      'meyve suyu',
      'soguk cay',
      'ice tea',
      'enerji icecegi',
    ])) {
      return 'drink';
    }
    if (_matchesAny(text, const ['cips', 'chips', 'crisps'])) return 'cips';
    if (_matchesAny(text, const ['kraker', 'cracker'])) return 'kraker';
    if (_matchesAny(text, const ['biskuvi', 'biscuit', 'cookie'])) {
      return 'biskuvi';
    }
    if (_matchesAny(text, const ['cikolata', 'chocolate'])) return 'cikolata';
    if (_matchesAny(text, const ['dondurma', 'ice cream'])) return 'dondurma';
    if (_matchesAny(text, const ['gofret', 'wafer'])) return 'gofret';
    if (_matchesAny(text, const ['puding', 'pudding'])) return 'puding';
    if (_matchesAny(text, const ['kek', 'cake', 'brownie'])) return 'kek';
    return null;
  }

  bool _matchesAny(String normalizedText, List<String> keywords) {
    final paddedText = ' $normalizedText ';
    return keywords.any((keyword) {
      final normalizedKeyword = _normalizeText(keyword);
      return paddedText.contains(' $normalizedKeyword ');
    });
  }

  String _normalizeText(String value) {
    return ProductCategoryMapper.normalizeCategory(value)
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isExactCategoryMatch(Product current, Product candidate) {
    final currentCategory = ProductCategoryMapper.normalizeCategory(
      current.category,
    );
    if (currentCategory.isEmpty || currentCategory == 'belirsiz') {
      return false;
    }
    return ProductCategoryMapper.normalizeCategory(candidate.category) ==
        currentCategory;
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
