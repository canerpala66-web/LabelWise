import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class LabelWiseScoreEngine {
  const LabelWiseScoreEngine();

  LabelWiseScoreResult calculate(Product product) {
    final category = _effectiveCategory(product);
    final profile = _profileFor(product, category);
    final ingredientText = _normalizedIngredients(product.ingredientsText);
    final productText = _normalizeText(
      '${product.productName} ${product.brands} ${product.ingredientsText}',
    );
    final missingKeyCount = _missingKeyCount(product);

    if (_isPlainWater(profile: profile, product: product, ingredientText: ingredientText)) {
      return const LabelWiseScoreResult(
        score: 100,
        category: 'Çok Dengeli Seçim',
        color: Color(0xFF16843B),
        reasons: ['Kategori gereği çok güçlü bir temel seçim'],
      );
    }

    if (_isNutritionUnavailable(product)) {
      return const LabelWiseScoreResult(
        score: null,
        category: 'Sağlık puanı hesaplanamadı.',
        color: Color(0xFF7A827D),
        reasons: ['Temel beslenme değerleri bulunamadı'],
      );
    }

    final processing = _detectProcessing(
      product: product,
      category: profile.name,
      ingredientText: ingredientText,
      productText: productText,
    );

    final ingredientPenalty = _ingredientPenalty(
      ingredientText: ingredientText,
      productText: productText,
    );
    final nutritionPenalty = _nutritionPenalty(
      product: product,
      profile: profile,
      productText: productText,
    );
    final processingPenalty = _processingPenalty(processing);
    final positiveBonus = _positiveBonus(
      product: product,
      profile: profile,
      ingredientText: ingredientText,
      productText: productText,
    );

    double score = (profile.baseScore -
        nutritionPenalty.total -
        ingredientPenalty.total -
        processingPenalty +
        positiveBonus.total)
      .toDouble();

    final scoreBeforeCaps = score.round();
    final caps = <String, int>{
      '${profile.name} kategori tavanı': profile.maxScore,
    };

    final processingCap = _processingCap(processing);
    if (processingCap != null) {
      caps['işleme seviyesi sınırı'] = processingCap;
    }

    final ingredientQualityCap = _ingredientQualityCap(
      product: product,
      profile: profile,
      ingredientPenalty: ingredientPenalty,
      processing: processing,
      ingredientText: ingredientText,
      productText: productText,
    );
    if (ingredientQualityCap != null) {
      caps['içerik kalitesi sınırı'] = ingredientQualityCap;
    }

    final categoryCap = _categorySpecificCap(
      product: product,
      profile: profile,
      ingredientText: ingredientText,
      productText: productText,
    );
    if (categoryCap != null) {
      caps['kategori özel sınırı'] = categoryCap;
    }

    for (final cap in caps.values) {
      score = score.clamp(0, cap).toDouble();
    }

    score = _applyDataConfidence(
      score: score,
      product: product,
      missingKeyCount: missingKeyCount,
      profile: profile,
    );

    score = _applyLowScoreCalibration(
      score: score,
      product: product,
      profile: profile,
      processing: processing,
      ingredientPenalty: ingredientPenalty,
      productText: productText,
      ingredientText: ingredientText,
    );

    final finalScore = score.clamp(0, 100).round();
    final reasons = _buildReasons(
      profile: profile,
      product: product,
      nutritionPenalty: nutritionPenalty,
      ingredientPenalty: ingredientPenalty,
      processing: processing,
      positiveBonus: positiveBonus,
      missingKeyCount: missingKeyCount,
      scoreBeforeCaps: scoreBeforeCaps,
      finalScore: finalScore,
    );

    debugPrint('ScoreV5: product=${product.productName}, category=${profile.name}');
    debugPrint('ScoreV5: baseScore=${profile.baseScore}');
    debugPrint('ScoreV5: nutritionPenalty=${nutritionPenalty.total} ${nutritionPenalty.reasons}');
    debugPrint('ScoreV5: ingredientPenalty=${ingredientPenalty.total} ${ingredientPenalty.reasons}');
    debugPrint('ScoreV5: processing=${processing.level}${processing.severity} penalty=$processingPenalty');
    debugPrint('ScoreV5: positiveBonus=${positiveBonus.total} ${positiveBonus.reasons}');
    debugPrint('ScoreV5: caps=$caps');
    debugPrint('ScoreV5: finalScore=$finalScore reasons=$reasons');

    return LabelWiseScoreResult(
      score: finalScore,
      category: _scoreLabel(finalScore),
      color: _scoreColor(finalScore),
      reasons: reasons,
    );
  }

  int _missingKeyCount(Product product) {
    final keyValues = [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.salt,
    ];
    return keyValues.where((value) => value == null).length;
  }

  bool _isNutritionUnavailable(Product product) {
    return [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.salt,
    ].every((value) => value == null);
  }

  bool _isPlainWater({
    required _CategoryProfile profile,
    required Product product,
    required String ingredientText,
  }) {
    if (profile.name != 'Su & Maden Suyu') return false;
    final hasOnlyZeroes = [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.salt,
    ].every((value) => value == null || value == 0);
    return hasOnlyZeroes && ingredientText.isEmpty;
  }

  _CategoryProfile _profileFor(Product product, String category) {
    final normalizedName = _normalizeText(product.productName);

    if (_containsAny(normalizedName, const ['su', 'maden suyu', 'soda']) &&
        category == 'Su & Maden Suyu') {
      return const _CategoryProfile('Su & Maden Suyu', baseScore: 95, maxScore: 100);
    }

    if (category == 'Süt' || category == 'Yoğurt & Fermente Süt') {
      return const _CategoryProfile(
        'Yoğurt & Fermente Süt',
        baseScore: 82,
        maxScore: 92,
        naturalFatFriendly: true,
      );
    }

    if (category == 'Peynir') {
      return const _CategoryProfile(
        'Peynir',
        baseScore: 75,
        maxScore: 85,
        naturalFatFriendly: true,
      );
    }

    if (_containsAny(normalizedName, const ['zeytin']) && category != 'Yağ') {
      return const _CategoryProfile(
        'Zeytin',
        baseScore: 70,
        maxScore: 82,
        naturalFatFriendly: true,
      );
    }

    if (_containsAny(normalizedName, const ['zeytinyagi', 'zeytinyağı', 'olive oil']) ||
        (category == 'Yağ' &&
            _containsAny(normalizedName, const ['zeytin', 'olive']))) {
      return const _CategoryProfile(
        'Zeytinyağı',
        baseScore: 82,
        maxScore: 90,
        naturalFatFriendly: true,
      );
    }

    if (category == 'Kuruyemiş') {
      return const _CategoryProfile(
        'Kuruyemiş',
        baseScore: 78,
        maxScore: 90,
        naturalFatFriendly: true,
      );
    }

    if (_containsAny(normalizedName, const [
      'bal',
      'pekmez',
      'molasses',
      'recel',
      'reçel',
      'tahin',
    ])) {
      return const _CategoryProfile(
        'Bal & Sürülebilir Tatlı',
        baseScore: 62,
        maxScore: 72,
        sugarDenseNatural: true,
      );
    }

    if (category == 'Meyve Suyu') {
      return const _CategoryProfile('Meyve Suyu', baseScore: 52, maxScore: 65, liquidSugarSensitive: true);
    }

    if (category == 'Gazlı İçecek') {
      final zeroLike = _containsAny(
        normalizedName,
        const ['zero', 'sekersiz', 'şekersiz', 'sugar free', 'light'],
      );
      return zeroLike
          ? const _CategoryProfile(
              'Gazlı İçecek',
              baseScore: 58,
              maxScore: 60,
              liquidSugarSensitive: true,
            )
          : const _CategoryProfile(
              'Gazlı İçecek',
              baseScore: 46,
              maxScore: 45,
              liquidSugarSensitive: true,
            );
    }

    if (category == 'Enerji İçeceği') {
      return const _CategoryProfile(
        'Enerji İçeceği',
        baseScore: 35,
        maxScore: 50,
        liquidSugarSensitive: true,
      );
    }

    if (category == 'Cips') {
      return const _CategoryProfile('Cips', baseScore: 42, maxScore: 62);
    }

    if (category == 'Kraker') {
      return const _CategoryProfile('Kraker', baseScore: 48, maxScore: 66);
    }

    if (category == 'Çikolata' || category == 'Bisküvi' || category == 'Kek & Tatlı' || category == 'Sütlü Tatlı') {
      return const _CategoryProfile('Tatlı Atıştırmalık', baseScore: 48, maxScore: 58);
    }

    if (category == 'Sporcu Ürünü') {
      return const _CategoryProfile('Sporcu Ürünü', baseScore: 55, maxScore: 75);
    }

    if (category == 'Sos') {
      return const _CategoryProfile('Sos', baseScore: 50, maxScore: 68);
    }

    if (category == 'Donuk Ürün') {
      return const _CategoryProfile('Donuk Ürün', baseScore: 50, maxScore: 68);
    }

    if (category == 'Hazır Yemek & Konserve') {
      final fishLike = _containsAny(
        normalizedName,
        const ['ton', 'tuna', 'balik', 'balık', 'somon', 'sardalya'],
      );
      if (fishLike) {
        return const _CategoryProfile('Konserve Balık', baseScore: 72, maxScore: 88);
      }
      return const _CategoryProfile('Hazır Yemek & Konserve', baseScore: 38, maxScore: 55);
    }

    if (category == 'Tahıl & Bakliyat') {
      return const _CategoryProfile('Tahıl & Bakliyat', baseScore: 55, maxScore: 75);
    }

    if (category == 'İşlenmiş Et') {
      return const _CategoryProfile('İşlenmiş Et', baseScore: 40, maxScore: 58);
    }

    return const _CategoryProfile('Diğer', baseScore: 60, maxScore: 80);
  }

  _ProcessingProfile _detectProcessing({
    required Product product,
    required String category,
    required String ingredientText,
    required String productText,
  }) {
    final isPureOliveOil =
        category == 'Zeytinyağı' &&
        _containsAny(productText, const ['zeytinyagi', 'zeytinyağı', 'olive oil']) &&
        !_containsAny(
          ingredientText,
          const [
            'palm',
            'kanola',
            'aycicek',
            'ayçiçek',
            'soya',
            'aroma',
            'emulgator',
            'emülgatör',
            'renklendirici',
            'koruyucu',
          ],
        );

    final additiveHits = _countContains(
      ingredientText,
      const [
        'emulgator',
        'emülgatör',
        'stabilizor',
        'stabilizör',
        'koruyucu',
        'renklendirici',
        'tatlandirici',
        'tatlandırıcı',
        'aroma verici',
        'aroma',
        'asitlik duzenleyici',
        'asitlik düzenleyici',
        'kivam arttirici',
        'kıvam artırıcı',
      ],
    );
    final syrupHits = _countContains(
      ingredientText,
      const [
        'glukoz surubu',
        'glikoz surubu',
        'fruktoz surubu',
        'glukoz-fruktoz surubu',
        'glukoz fruktoz surubu',
        'misir surubu',
        'invert seker surubu',
        'high fructose',
      ],
    );
    final sweetenerHits = _countContains(
      ingredientText,
      const [
        'aspartam',
        'asesulfam',
        'sukraloz',
        'sucralose',
        'steviol',
        'saccharin',
      ],
    );

    if (isPureOliveOil) {
      return const _ProcessingProfile(level: 'A', severity: 0);
    }

    final isSimpleDairy =
        category == 'Yoğurt & Fermente Süt' &&
        additiveHits == 0 &&
        syrupHits == 0 &&
        sweetenerHits == 0;
    if (isSimpleDairy) {
      return const _ProcessingProfile(level: 'A', severity: 0);
    }

    final highlyProcessedCategory = {
      'Gazlı İçecek',
      'Enerji İçeceği',
      'Hazır Yemek & Konserve',
    }.contains(category);

    if (syrupHits >= 1 && (additiveHits + sweetenerHits) >= 2) {
      return const _ProcessingProfile(level: 'C', severity: 3);
    }
    if (additiveHits >= 3 || sweetenerHits >= 2) {
      return const _ProcessingProfile(level: 'C', severity: 2);
    }
    if (highlyProcessedCategory || additiveHits >= 1 || syrupHits >= 1 || sweetenerHits >= 1) {
      return const _ProcessingProfile(level: 'C', severity: 1);
    }

    final minimallyProcessed = _containsAny(
      productText,
      const [
        'sade',
        'dogal',
        'doğal',
        'plain',
        'extra virgin',
        'tam',
      ],
    );

    if (minimallyProcessed && additiveHits == 0 && syrupHits == 0) {
      return const _ProcessingProfile(level: 'A', severity: 0);
    }

    return const _ProcessingProfile(level: 'B', severity: 0);
  }

  _PenaltyResult _ingredientPenalty({
    required String ingredientText,
    required String productText,
  }) {
    var total = 0;
    final reasons = <String>[];

    final veryStrongHits = _countContains(
      ingredientText,
      const [
        'glukoz surubu',
        'glikoz surubu',
        'fruktoz surubu',
        'glukoz-fruktoz surubu',
        'glukoz fruktoz surubu',
        'misir surubu',
        'invert seker surubu',
        'high fructose',
      ],
    );
    if (veryStrongHits > 0) {
      total += 18 + (veryStrongHits - 1) * 4;
      reasons.add('Şurup bazlı tatlandırıcı var');
    }

    final strongHits = _countContains(
      ingredientText,
      const [
        'palm yagi',
        'palm yağı',
        'hidrojene',
        'renklendirici',
        'koruyucu',
        'emulgator',
        'emülgatör',
        'tatlandirici',
        'tatlandırıcı',
        'aroma verici',
      ],
    );
    if (strongHits > 0) {
      total += 6 + (strongHits - 1) * 3;
      reasons.add('Katkı ve işleme sinyalleri güçlü');
    }

    final mediumHits = _countContains(
      ingredientText,
      const [
        'aroma',
        'asitlik duzenleyici',
        'asitlik düzenleyici',
        'stabilizor',
        'stabilizör',
        'kivam arttirici',
        'kıvam artırıcı',
      ],
    );
    if (mediumHits > 0) {
      total += 4 + (mediumHits - 1) * 2;
      reasons.add('Ek işleme bileşenleri var');
    }

    if (_containsAny(productText, const ['max', 'zero', 'light']) &&
        _countContains(
              ingredientText,
              const ['aspartam', 'asesulfam', 'sukraloz', 'sucralose', 'steviol'],
            ) >
            0) {
      total += 6;
      reasons.add('Tatlandırıcı içeriyor');
    }

    return _PenaltyResult(total: total, reasons: reasons);
  }

  _PenaltyResult _nutritionPenalty({
    required Product product,
    required _CategoryProfile profile,
    required String productText,
  }) {
    var total = 0;
    final reasons = <String>[];

    if (product.sugars != null) {
      final sugar = product.sugars!;
      if (profile.liquidSugarSensitive) {
        if (sugar >= 10) {
          total += 18;
          reasons.add('Şeker yüksek');
        } else if (sugar >= 5) {
          total += 10;
          reasons.add('Şeker yüksek');
        } else if (sugar >= 2) {
          total += 6;
        }
      } else if (!profile.sugarDenseNatural) {
        if (sugar >= 25) {
          total += 18;
          reasons.add('Şeker yüksek');
        } else if (sugar >= 15) {
          total += 12;
          reasons.add('Şeker yüksek');
        } else if (sugar >= 8) {
          total += 8;
        }
      } else if (sugar >= 50) {
        total += 10;
        reasons.add('Doğal olsa da şeker yoğun');
      } else if (sugar >= 25) {
        total += 6;
      }
    }

    if (product.salt != null) {
      final salt = product.salt!;
      if (profile.name == 'Cips') {
        if (salt >= 1.5) {
          total += 16;
          reasons.add('Tuz yüksek');
        } else if (salt >= 0.8) {
          total += 8;
          reasons.add('Tuz yüksek');
        } else if (salt >= 0.3) {
          total += 3;
        }
      } else if (profile.name == 'Sporcu Ürünü') {
        if (salt >= 1.5) {
          total += 14;
          reasons.add('Tuz yüksek');
        } else if (salt >= 0.8) {
          total += 8;
          reasons.add('Tuz yüksek');
        } else if (salt >= 0.3) {
          total += 3;
        }
      } else if (salt >= 1.5) {
        total += 20;
        reasons.add('Tuz yüksek');
      } else if (salt >= 0.8) {
        total += 12;
        reasons.add('Tuz yüksek');
      } else if (salt >= 0.3) {
        total += 5;
      }
    }

    if (product.saturatedFat != null) {
      final saturatedFat = product.saturatedFat!;
      if (profile.naturalFatFriendly) {
        if (profile.name == 'Yoğurt & Fermente Süt') {
          if (saturatedFat >= 3.5) {
            total += 4;
            reasons.add('Doymuş yağ yüksek');
          } else if (saturatedFat >= 2.5) {
            total += 2;
          }
        } else if (profile.name == 'Zeytinyağı') {
          if (saturatedFat >= 20) {
            total += 4;
          }
        } else if (saturatedFat >= 10) {
          total += 8;
          reasons.add('Doymuş yağ yüksek');
        } else if (saturatedFat >= 5) {
          total += 4;
        }
      } else if (saturatedFat >= 10) {
        total += 18;
          reasons.add('Doymuş yağ yüksek');
      } else if (saturatedFat >= 5) {
        total += 10;
      } else if (saturatedFat >= 2) {
        total += 4;
      }
    }

    if (product.energyKcal != null) {
      final energy = product.energyKcal!;
      if (profile.liquidSugarSensitive) {
        if (energy >= 45) {
          total += 6;
        }
      } else if (!profile.naturalFatFriendly && !profile.sugarDenseNatural) {
        if (profile.name == 'Cips') {
          if (energy >= 500) {
            total += 10;
            reasons.add('Enerji yoğunluğu yüksek');
          } else if (energy >= 430) {
            total += 6;
            reasons.add('Enerji yoğunluğu yüksek');
          } else if (energy >= 300) {
            total += 3;
          }
        } else if (profile.name == 'Sporcu Ürünü') {
          if (energy >= 450) {
            total += 8;
            reasons.add('Enerji yoğunluğu yüksek');
          } else if (energy >= 350) {
            total += 4;
          } else if (energy >= 250) {
            total += 2;
          }
        } else if (energy >= 500) {
          total += 18;
          reasons.add('Enerji yoğunluğu yüksek');
        } else if (energy >= 400) {
          total += 12;
          reasons.add('Enerji yoğunluğu yüksek');
        } else if (energy >= 250) {
          total += 6;
        }
      } else if (energy >= 650) {
        total += 4;
      }
    }

    if (product.fat != null && !profile.naturalFatFriendly) {
      final fat = product.fat!;
      if (fat >= 30) {
        total += 14;
      } else if (fat >= 20) {
        total += 8;
      }
    }

    if ((product.sugars ?? 0) >= 15 && (product.saturatedFat ?? 0) >= 5) {
      total += 10;
      reasons.add('Şeker ve doymuş yağ birlikte yüksek');
    }

    return _PenaltyResult(total: total, reasons: reasons);
  }

  int _processingPenalty(_ProcessingProfile processing) {
    if (processing.level == 'A') return 0;
    if (processing.level == 'B') return 6;
    switch (processing.severity) {
      case 3:
        return 20;
      case 2:
        return 14;
      default:
        return 10;
    }
  }

  _PenaltyResult _positiveBonus({
    required Product product,
    required _CategoryProfile profile,
    required String ingredientText,
    required String productText,
  }) {
    var total = 0;
    final reasons = <String>[];

    if ((product.fiber ?? 0) >= 6) {
      total += 8;
      reasons.add('Lif iyi');
    } else if ((product.fiber ?? 0) >= 3) {
      total += 4;
      reasons.add('Lif iyi');
    }

    if ((product.protein ?? 0) >= 20) {
      total += 6;
      reasons.add('Protein iyi');
    } else if ((product.protein ?? 0) >= 10) {
      total += 4;
      reasons.add('Protein iyi');
    }

    if ((product.fruitsVegetablesLegumesPercent ?? 0) >= 60) {
      total += 8;
      reasons.add('Bitkisel içerik oranı yüksek');
    } else if ((product.fruitsVegetablesLegumesPercent ?? 0) >= 40) {
      total += 4;
      reasons.add('Bitkisel içerik destekli');
    }

    if (profile.naturalFatFriendly &&
        _containsAny(productText, const [
          'sade',
          'dogal',
          'doğal',
          'extra virgin',
          'sizma',
          'sızma',
          'kavrulmamis',
          'kavrulmamış',
        ]) &&
        !_containsAny(ingredientText, const ['palm', 'aroma', 'emulgator', 'emülgatör'])) {
      total += 4;
      reasons.add('Temiz içerik profili');
    }

    if (profile.name == 'Konserve Balık' &&
        !_containsAny(ingredientText, const ['sos', 'mayonez', 'aroma'])) {
      total += 4;
      reasons.add('Basit protein kaynağı');
    }

    if (profile.name == 'Cips' &&
        _containsAny(
          ingredientText,
          const ['nohut', 'mercimek', 'baklagil', 'bezelye', 'fasulye'],
        ) &&
        !_containsAny(
          ingredientText,
          const [
            'glukoz surubu',
            'glikoz surubu',
            'renklendirici',
            'koruyucu',
            'tatlandirici',
            'tatlandırıcı',
            'aroma verici',
            'emulgator',
            'emülgatör',
          ],
        )) {
      total += 12;
      reasons.add('Daha temiz atıştırmalık profili');
    }

    final cleanProteinBar = profile.name == 'Sporcu Ürünü' &&
        (product.protein ?? 0) >= 15 &&
        (product.fiber ?? 0) >= 5 &&
        !_containsAny(
          ingredientText,
          const [
            'glukoz surubu',
            'glikoz surubu',
            'fruktoz surubu',
            'misir surubu',
            'palm',
            'koruyucu',
            'renklendirici',
          ],
        );
    if (cleanProteinBar) {
      total += 8;
      reasons.add('Daha temiz sporcu ürünü profili');
    }

    return _PenaltyResult(total: total, reasons: reasons);
  }

  int? _categorySpecificCap({
    required Product product,
    required _CategoryProfile profile,
    required String ingredientText,
    required String productText,
  }) {
    if (profile.name == 'Gazlı İçecek') {
      final zeroLike = _containsAny(
        productText,
        const ['zero', 'sekersiz', 'şekersiz', 'light', 'sugar free'],
      );
      if (zeroLike) return 60;
      return 45;
    }

    if (profile.name == 'Enerji İçeceği') return 50;

    if (profile.name == 'Meyve Suyu' && (product.sugars ?? 0) >= 10) {
      return 58;
    }

    if (profile.name == 'Bal & Sürülebilir Tatlı') {
      if (_containsAny(
        ingredientText,
        const [
          'glukoz surubu',
          'glikoz surubu',
          'fruktoz surubu',
          'misir surubu',
        ],
      )) {
        return 42;
      }
      return profile.maxScore;
    }

    return null;
  }

  int? _processingCap(_ProcessingProfile processing) {
    if (processing.level == 'A') return null;
    if (processing.level == 'B') return 82;
    switch (processing.severity) {
      case 3:
        return 42;
      case 2:
        return 52;
      default:
        return 60;
    }
  }

  int? _ingredientQualityCap({
    required Product product,
    required _CategoryProfile profile,
    required _PenaltyResult ingredientPenalty,
    required _ProcessingProfile processing,
    required String ingredientText,
    required String productText,
  }) {
    if (ingredientPenalty.total >= 24) return 45;
    if (ingredientPenalty.total >= 16 && processing.level == 'C') return 52;

    if (profile.name == 'Gazlı İçecek') {
      final zeroLike = _containsAny(
        productText,
        const ['zero', 'sekersiz', 'şekersiz', 'light', 'sugar free'],
      );
      if (zeroLike &&
          _containsAny(
            ingredientText,
            const ['aspartam', 'asesulfam', 'sukraloz', 'sucralose'],
          )) {
        return 60;
      }
    }

    if (profile.name == 'Cips' &&
        _containsAny(
          ingredientText,
          const ['nohut', 'mercimek', 'baklagil', 'zeytinyagi', 'zeytinyağı'],
        ) &&
        !_containsAny(
          ingredientText,
          const ['aroma', 'renklendirici', 'glukoz surubu', 'tatlandirici'],
        )) {
      return 62;
    }

    return null;
  }

  double _applyDataConfidence({
    required double score,
    required Product product,
    required int missingKeyCount,
    required _CategoryProfile profile,
  }) {
    var adjusted = score;
    final hasIngredients = _normalizedIngredients(product.ingredientsText).isNotEmpty;

    if (missingKeyCount >= 3) {
      adjusted = adjusted.clamp(0, 58).toDouble();
    } else if (missingKeyCount == 2) {
      adjusted = adjusted.clamp(0, 70).toDouble();
    }

    if (product.sugars == null &&
        (profile.liquidSugarSensitive || profile.name == 'Tatlı Atıştırmalık')) {
      adjusted = adjusted.clamp(0, 45).toDouble();
    }

    if (product.salt == null &&
        const {'Cips', 'Kraker', 'Peynir', 'İşlenmiş Et'}.contains(profile.name)) {
      adjusted = adjusted.clamp(0, 65).toDouble();
    }

    if (!hasIngredients && profile.name != 'Su & Maden Suyu') {
      if (const {
        'Yoğurt & Fermente Süt',
        'Peynir',
        'Zeytin',
        'Zeytinyağı',
        'Kuruyemiş',
      }.contains(profile.name)) {
        adjusted = adjusted.clamp(0, 88).toDouble();
      } else {
        adjusted = adjusted.clamp(0, 78).toDouble();
      }
    }

    if (product.nutritionTableNotAvailable && hasIngredients) {
      adjusted = adjusted.clamp(0, 74).toDouble();
    }

    return adjusted;
  }

  double _applyLowScoreCalibration({
    required double score,
    required Product product,
    required _CategoryProfile profile,
    required _ProcessingProfile processing,
    required _PenaltyResult ingredientPenalty,
    required String productText,
    required String ingredientText,
  }) {
    final sugar = product.sugars ?? 0;
    final severeCombination =
        processing.level == 'C' &&
        processing.severity >= 3 &&
        ingredientPenalty.total >= 35 &&
        (sugar >= 15 ||
            _containsAny(
              ingredientText,
              const ['glukoz surubu', 'glikoz surubu', 'fruktoz surubu', 'palm'],
            ));

    if (severeCombination) {
      return score;
    }

    if (profile.name == 'Gazlı İçecek') {
      final zeroLike = _containsAny(
        productText,
        const ['zero', 'sekersiz', 'şekersiz', 'light', 'sugar free'],
      );
      final floor = zeroLike ? 25 : 10;
      return score < floor ? floor.toDouble() : score;
    }

    if (profile.name == 'Enerji İçeceği') {
      final zeroLike = _containsAny(
            productText,
            const ['zero', 'sekersiz', 'şekersiz', 'light', 'sugar free'],
          ) ||
          sugar <= 1;
      final floor = zeroLike ? 28 : 12;
      return score < floor ? floor.toDouble() : score;
    }

    if (profile.name == 'Cips' && ingredientPenalty.total < 30) {
      return score < 15 ? 15 : score;
    }

    if (profile.name == 'Tatlı Atıştırmalık' && ingredientPenalty.total < 30) {
      return score < 10 ? 10 : score;
    }

    if (profile.name == 'Sporcu Ürünü' &&
        !(processing.level == 'C' && processing.severity >= 3 && ingredientPenalty.total >= 40)) {
      return score < 20 ? 20 : score;
    }

    return score;
  }

  List<String> _buildReasons({
    required _CategoryProfile profile,
    required Product product,
    required _PenaltyResult nutritionPenalty,
    required _PenaltyResult ingredientPenalty,
    required _ProcessingProfile processing,
    required _PenaltyResult positiveBonus,
    required int missingKeyCount,
    required int scoreBeforeCaps,
    required int finalScore,
  }) {
    final reasons = <String>[];

    reasons.addAll(nutritionPenalty.reasons);
    reasons.addAll(ingredientPenalty.reasons);

    if (processing.level == 'C') {
      reasons.add('İşleme düzeyi yüksek');
    } else if (processing.level == 'B') {
      reasons.add('İşleme düzeyi orta');
    }

    reasons.addAll(positiveBonus.reasons);

    if (missingKeyCount >= 2) {
      reasons.add('Bazı temel beslenme değerleri eksik');
    }

    if (_normalizedIngredients(product.ingredientsText).isEmpty &&
        profile.name != 'Su & Maden Suyu') {
      reasons.add('İçerik bilgisi eksik');
    }

    if (product.nutritionTableNotAvailable) {
      reasons.add('Besin tablosu bulunamadı');
    }

    if (finalScore < scoreBeforeCaps) {
      reasons.add('Kategori veya içerik sınırı uygulandı');
    }

    return reasons.toSet().take(4).toList(growable: false);
  }

  String _effectiveCategory(Product product) {
    final storedCategory = ProductCategoryMapper.canonicalCategory(
      product.category,
    );

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
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9%/,+(). -]+'), ' ')
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizedIngredients(String value) {
    final normalized = _normalizeText(value);
    if (normalized.contains('bulunamadi') ||
        normalized.contains('bilgisi yok') ||
        normalized.contains('unknown')) {
      return '';
    }
    return normalized;
  }

  bool _containsAny(String text, List<String> tokens) {
    return tokens.any((token) => text.contains(_normalizeText(token)));
  }

  int _countContains(String text, List<String> tokens) {
    return tokens.where((token) => text.contains(_normalizeText(token))).length;
  }
}

class _CategoryProfile {
  const _CategoryProfile(
    this.name, {
    required this.baseScore,
    required this.maxScore,
    this.naturalFatFriendly = false,
    this.sugarDenseNatural = false,
    this.liquidSugarSensitive = false,
  });

  final String name;
  final int baseScore;
  final int maxScore;
  final bool naturalFatFriendly;
  final bool sugarDenseNatural;
  final bool liquidSugarSensitive;
}

class _ProcessingProfile {
  const _ProcessingProfile({
    required this.level,
    required this.severity,
  });

  final String level;
  final int severity;
}

class _PenaltyResult {
  const _PenaltyResult({
    required this.total,
    required this.reasons,
  });

  final int total;
  final List<String> reasons;
}
