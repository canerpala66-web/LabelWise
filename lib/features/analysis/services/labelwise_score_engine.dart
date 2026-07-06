import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class LabelWiseScoreEngine {
  const LabelWiseScoreEngine();

  static const _categoryCaps = <String, int>{
    'Cips': 62,
    'Kraker': 68,
    'Bisküvi': 62,
    'Kek': 58,
    'Gofret': 55,
    'Çikolata': 55,
    'Puding': 60,
    'Dondurma': 60,
    'Enerji İçeceği': 45,
    'Gazlı İçecek': 45,
    'Meyve Suyu': 65,
  };
  static const _snackAndDessertCategories = {
    'Cips',
    'Kraker',
    'Bisküvi',
    'Kek',
    'Gofret',
    'Çikolata',
    'Puding',
    'Dondurma',
  };
  static const _sugarSensitiveCategories = {
    ..._snackAndDessertCategories,
    'Enerji İçeceği',
    'Gazlı İçecek',
    'Meyve Suyu',
  };
  static const _sugarFreeKeywords = {'zero', 'şekersiz', 'sugar free', 'light'};

  LabelWiseScoreResult calculate(Product product) {
    final category = _effectiveCategory(product);
    final keyValues = [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.salt,
    ];
    final missingKeyCount = keyValues.where((value) => value == null).length;

    debugPrint('ScoreV3: product=${product.productName}, category=$category');
    debugPrint('ScoreV3: baseScore=100');

    if (missingKeyCount == keyValues.length) {
      const reasons = ['Temel beslenme değerleri bulunamadı'];
      debugPrint('ScoreV3: penalties=[]');
      debugPrint('ScoreV3: bonuses=[]');
      debugPrint('ScoreV3: caps=[]');
      debugPrint('ScoreV3: finalScore=null');
      debugPrint('ScoreV3: reasons=$reasons');
      return const LabelWiseScoreResult(
        score: null,
        category: 'Sağlık puanı hesaplanamadı.',
        color: Color(0xFF7A827D),
        reasons: reasons,
      );
    }

    final penalties = <String, int>{
      'şeker': _sugarPenalty(product.sugars),
      'doymuş yağ': _saturatedFatPenalty(product.saturatedFat),
      'tuz': _saltPenalty(product.salt),
      'enerji': _energyPenalty(product.energyKcal),
      'yağ': _fatPenalty(product.fat),
    }..removeWhere((_, value) => value == 0);
    final bonuses = <String, int>{
      'lif': _fiberBonus(product.fiber),
      'protein': _proteinBonus(product.protein),
    }..removeWhere((_, value) => value == 0);

    var score = 100;
    for (final penalty in penalties.values) {
      score -= penalty;
    }
    for (final bonus in bonuses.values) {
      score += bonus;
    }

    if ((product.sugars ?? 0) >= 15 && (product.saturatedFat ?? 0) >= 5) {
      penalties['şeker+doymuş yağ'] = 10;
      score -= 10;
    }
    if ((product.sugars ?? 0) >= 20 &&
        _snackAndDessertCategories.contains(category)) {
      penalties['yüksek şekerli atıştırmalık'] = 10;
      score -= 10;
    }
    if ((product.salt ?? 0) >= 0.8 && (product.fat ?? 0) >= 20) {
      penalties['tuz+yağ'] = 8;
      score -= 8;
    }
    if ((product.energyKcal ?? 0) >= 450 && (product.fat ?? 0) >= 20) {
      penalties['enerji+yağ'] = 8;
      score -= 8;
    }

    final searchableText = _normalizeText(
      '${product.productName} ${product.ingredientsText}',
    );
    final isSugarFree = _sugarFreeKeywords.any((keyword) {
      return ' $searchableText '.contains(' ${_normalizeText(keyword)} ');
    });
    final caps = <String, int>{};
    final baseCategoryCap = category == 'Gazlı İçecek' && isSugarFree
        ? 68
        : _categoryCaps[category];
    if (baseCategoryCap != null) caps['$category kategorisi'] = baseCategoryCap;

    if (category == 'Enerji İçeceği' && (product.sugars ?? 0) >= 5) {
      caps['şekerli enerji içeceği'] = 38;
    }
    if (category == 'Gazlı İçecek' && !isSugarFree) {
      if ((product.sugars ?? 0) >= 10) {
        caps['gazlı içecek şekeri'] = 35;
      } else if ((product.sugars ?? 0) >= 5) {
        caps['gazlı içecek şekeri'] = 42;
      }
    }
    if (category == 'Meyve Suyu' && (product.sugars ?? 0) >= 10) {
      caps['meyve suyu şekeri'] = 58;
    }
    if ((product.salt ?? 0) >= 5) caps['çok yüksek tuz'] = 45;

    if (missingKeyCount >= 3) {
      caps['3+ temel veri eksik'] = 60;
    } else if (missingKeyCount == 2) {
      caps['2 temel veri eksik'] = 70;
    }
    if (product.sugars == null &&
        _sugarSensitiveCategories.contains(category)) {
      caps['şeker verisi eksik'] = 60;
    }
    if (product.salt == null && const {'Cips', 'Kraker'}.contains(category)) {
      caps['tuz verisi eksik'] = 60;
    }

    score = score.clamp(0, 100);
    final scoreBeforeCaps = score;
    for (final cap in caps.values) {
      score = score.clamp(0, cap);
    }
    final finalScore = score.clamp(0, 100);
    final reasons = _buildReasons(
      product: product,
      category: category,
      bonuses: bonuses,
      caps: caps,
      scoreBeforeCaps: scoreBeforeCaps,
      missingKeyCount: missingKeyCount,
    );

    debugPrint('ScoreV3: penalties=$penalties');
    debugPrint('ScoreV3: bonuses=$bonuses');
    debugPrint('ScoreV3: caps=$caps');
    debugPrint('ScoreV3: finalScore=$finalScore');
    debugPrint('ScoreV3: reasons=$reasons');

    return LabelWiseScoreResult(
      score: finalScore,
      category: _scoreLabel(finalScore),
      color: _scoreColor(finalScore),
      reasons: reasons,
    );
  }

  List<String> _buildReasons({
    required Product product,
    required String category,
    required Map<String, int> bonuses,
    required Map<String, int> caps,
    required int scoreBeforeCaps,
    required int missingKeyCount,
  }) {
    final reasons = <String>[];
    if ((product.sugars ?? 0) >= 15) reasons.add('Şeker yüksek');
    if ((product.salt ?? 0) >= 0.8) reasons.add('Tuz yüksek');
    if ((product.saturatedFat ?? 0) >= 5) reasons.add('Doymuş yağ yüksek');
    if ((product.energyKcal ?? 0) >= 400) {
      reasons.add('Enerji yoğunluğu yüksek');
    }
    final categoryCap = caps['$category kategorisi'];
    if (categoryCap != null && scoreBeforeCaps > categoryCap) {
      reasons.add('Kategori nedeniyle sınırlandı');
    }
    if (missingKeyCount >= 2) {
      reasons.add('Bazı temel beslenme değerleri eksik');
    }
    if (product.sugars == null &&
        _sugarSensitiveCategories.contains(category)) {
      reasons.add('Şeker verisi eksik');
    }
    if (product.salt == null && const {'Cips', 'Kraker'}.contains(category)) {
      reasons.add('Tuz verisi eksik');
    }
    if (bonuses.containsKey('protein')) reasons.add('Protein iyi');
    if (bonuses.containsKey('lif')) reasons.add('Lif iyi');
    return reasons.toSet().take(4).toList(growable: false);
  }

  String _effectiveCategory(Product product) {
    final storedCategory = _canonicalCategory(product.category);
    if (storedCategory != null &&
        storedCategory != 'Belirsiz' &&
        storedCategory != 'Diğer') {
      return storedCategory;
    }
    return ProductCategoryMapper.inferCategory(
      productName: product.productName,
      brand: product.brands,
      ingredientsText: product.ingredientsText,
    );
  }

  String? _canonicalCategory(String? value) {
    final normalized = _normalizeCategory(value);
    if (normalized.isEmpty) return null;
    for (final category in ProductCategoryMapper.categories) {
      if (_normalizeCategory(category) == normalized) return category;
    }
    return value?.trim();
  }

  String _normalizeCategory(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int _sugarPenalty(double? value) {
    if (value == null || value < 5) return 0;
    if (value < 10) return 8;
    if (value < 15) return 15;
    if (value < 20) return 22;
    if (value < 30) return 32;
    return 42;
  }

  int _saturatedFatPenalty(double? value) {
    if (value == null || value < 2) return 0;
    if (value < 5) return 8;
    if (value < 10) return 18;
    return 30;
  }

  int _saltPenalty(double? value) {
    if (value == null || value < 0.3) return 0;
    if (value < 0.8) return 8;
    if (value < 1.5) return 18;
    return 30;
  }

  int _energyPenalty(double? value) {
    if (value == null || value < 100) return 0;
    if (value < 250) return 3;
    if (value < 400) return 8;
    if (value < 500) return 15;
    return 22;
  }

  int _fatPenalty(double? value) {
    if (value == null || value < 10) return 0;
    if (value < 20) return 8;
    if (value < 30) return 16;
    return 25;
  }

  int _fiberBonus(double? value) {
    if (value == null || value < 3) return 0;
    if (value < 6) return 3;
    return 6;
  }

  int _proteinBonus(double? value) {
    if (value == null || value < 10) return 0;
    if (value < 20) return 3;
    return 6;
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Çok Dengeli Seçim';
    if (score >= 80) return 'İyi Seçim';
    if (score >= 70) return 'Dengeli Seçim';
    if (score >= 60) return 'Dikkatli Tüketim';
    if (score >= 45) return 'Sınırlı Tüketim';
    if (score >= 25) return 'Nadir Tüketim';
    return 'Zayıf Beslenme Profili';
  }

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF16843B);
    if (score >= 80) return const Color(0xFF2E9650);
    if (score >= 70) return const Color(0xFF65A43A);
    if (score >= 60) return const Color(0xFF9A9A32);
    if (score >= 45) return const Color(0xFFD48620);
    if (score >= 25) return const Color(0xFFC85D35);
    return const Color(0xFFB3261E);
  }

  String _normalizeText(String value) {
    return value
        .replaceAll('İ', 'I')
        .toLowerCase()
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
