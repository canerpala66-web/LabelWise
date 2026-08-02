import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class LabelWiseScoreEngine {
  const LabelWiseScoreEngine();

  static const double _idealSugarDaily = 25;
  static const double _upperSugarDaily = 50;
  static const double _saltDaily = 5;
  static const double _saturatedFatDaily = 20;
  static const double _proteinDaily = 56;

  LabelWiseScoreResult calculate(Product product) {
    final category = _effectiveCategory(product);
    final text = _normalizeText(
      '${product.productName} ${product.brands} ${product.ingredientsText} ${product.category ?? ''}',
    );
    final ingredients = _normalizedIngredients(product.ingredientsText);
    final profile = _profileFor(product: product, category: category, text: text, ingredients: ingredients);

    if (_isPlainWater(profile: profile, product: product, ingredients: ingredients)) {
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

    final missingKeyCount = _missingKeyCount(product);
    final dailyLoad = _dailyLoad(product);
    final ingredientRisk = _ingredientRisk(
      product: product,
      profile: profile,
      ingredients: ingredients,
      text: text,
    );
    final processing = _processingProfile(
      product: product,
      profile: profile,
      ingredients: ingredients,
      text: text,
      ingredientRisk: ingredientRisk,
    );
    final nutritionPenalty = _nutritionPenalty(
      product: product,
      profile: profile,
      dailyLoad: dailyLoad,
      ingredients: ingredients,
      text: text,
    );
    final positiveBonus = _positiveBonus(
      product: product,
      profile: profile,
      dailyLoad: dailyLoad,
      ingredientRisk: ingredientRisk,
      ingredients: ingredients,
      text: text,
    );

    double score = profile.baseScore.toDouble();
    score -= nutritionPenalty.total;
    score -= ingredientRisk.totalPenalty;
    score -= processing.penalty;
    score += positiveBonus.total;

    final scoreBeforeCaps = score.round();
    final caps = _collectCaps(
      product: product,
      profile: profile,
      dailyLoad: dailyLoad,
      ingredientRisk: ingredientRisk,
      processing: processing,
      ingredients: ingredients,
      text: text,
    );

    for (final cap in caps.values) {
      score = score.clamp(0, cap).toDouble();
    }

    score = _applyDataConfidence(
      score: score,
      product: product,
      profile: profile,
      missingKeyCount: missingKeyCount,
      hasIngredients: ingredients.isNotEmpty,
    );
    score = _applyScoreFloor(
      score: score,
      product: product,
      profile: profile,
      dailyLoad: dailyLoad,
      ingredientRisk: ingredientRisk,
      processing: processing,
      ingredients: ingredients,
      text: text,
    );

    final finalScore = score.clamp(0, 100).round();
    final reasons = _buildReasons(
      product: product,
      profile: profile,
      dailyLoad: dailyLoad,
      ingredientRisk: ingredientRisk,
      nutritionPenalty: nutritionPenalty,
      positiveBonus: positiveBonus,
      processing: processing,
      missingKeyCount: missingKeyCount,
      hadCap: finalScore < scoreBeforeCaps,
      ingredients: ingredients,
    );

    debugPrint('ScoreV6: product=${product.productName}, category=${profile.name}');
    debugPrint('ScoreV6: base=${profile.baseScore}, caps=$caps');
    debugPrint(
      'ScoreV6: dailyLoad sugarIdeal=${dailyLoad.sugarPercentOfIdeal.toStringAsFixed(0)}% '
      'sugarUpper=${dailyLoad.sugarPercentOfUpper.toStringAsFixed(0)}% '
      'salt=${dailyLoad.saltPercent.toStringAsFixed(0)}% '
      'satFat=${dailyLoad.saturatedFatPercent.toStringAsFixed(0)}%',
    );
    debugPrint('ScoreV6: ingredientPenalty=${ingredientRisk.totalPenalty} severe=${ingredientRisk.severeFlags}');
    debugPrint('ScoreV6: nutritionPenalty=${nutritionPenalty.total} ${nutritionPenalty.reasons}');
    debugPrint('ScoreV6: processing=${processing.level}${processing.severity} penalty=${processing.penalty}');
    debugPrint('ScoreV6: positiveBonus=${positiveBonus.total} ${positiveBonus.reasons}');
    debugPrint('ScoreV6: finalScore=$finalScore reasons=$reasons');

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
    required String ingredients,
  }) {
    if (profile.name != 'Su') return false;
    return [
          product.energyKcal,
          product.fat,
          product.saturatedFat,
          product.sugars,
          product.salt,
        ].every((value) => value == null || value == 0) &&
        ingredients.isEmpty;
  }

  _CategoryProfile _profileFor({
    required Product product,
    required String category,
    required String text,
    required String ingredients,
  }) {
    final isZeroLike = _containsAny(
      text,
      const ['zero', 'sekersiz', 'şekersiz', 'sugar free', 'light'],
    );

    if (_containsAny(text, const ['su', 'maden suyu']) && category == 'Su & Maden Suyu') {
      return const _CategoryProfile('Su', baseScore: 98, maxScore: 100);
    }
    if (category == 'Süt' || category == 'Yoğurt & Fermente Süt') {
      return const _CategoryProfile(
        'Süt & Yoğurt',
        baseScore: 84,
        maxScore: 92,
        naturalFatFriendly: true,
        naturalSugarContext: true,
      );
    }
    if (category == 'Peynir') {
      return const _CategoryProfile(
        'Peynir',
        baseScore: 68,
        maxScore: 82,
        naturalFatFriendly: true,
      );
    }
    if ((category == 'Yağ' || category == 'Diğer') &&
        _containsAny(text, const ['zeytinyagi', 'zeytinyağı', 'olive oil'])) {
      return const _CategoryProfile(
        'Zeytinyağı',
        baseScore: 82,
        maxScore: 90,
        naturalFatFriendly: true,
      );
    }
    if ((category == 'Diğer' || category == 'Belirsiz') &&
        _containsAny(text, const ['zeytin']) &&
        category != 'Yağ') {
      return const _CategoryProfile(
        'Zeytin',
        baseScore: 65,
        maxScore: 82,
        naturalFatFriendly: true,
      );
    }
    if (_containsAny(text, const ['bal', 'pekmez', 'recel', 'reçel', 'jam', 'molasses'])) {
      return const _CategoryProfile(
        'Bal & Reçel',
        baseScore: 50,
        maxScore: 70,
        naturalSugarContext: true,
      );
    }
    if (category == 'Gazlı İçecek') {
      return _CategoryProfile(
        isZeroLike ? 'Zero Gazlı İçecek' : 'Şekerli Gazlı İçecek',
        baseScore: isZeroLike ? 35 : 25,
        maxScore: isZeroLike ? 55 : 45,
        liquidSugarSensitive: !isZeroLike,
      );
    }
    if (category == 'Enerji İçeceği') {
      return _CategoryProfile(
        isZeroLike || (product.sugars ?? 0) <= 1 ? 'Zero Enerji İçeceği' : 'Şekerli Enerji İçeceği',
        baseScore: isZeroLike || (product.sugars ?? 0) <= 1 ? 32 : 25,
        maxScore: isZeroLike || (product.sugars ?? 0) <= 1 ? 45 : 45,
      );
    }
    if (category == 'Cips' || category == 'Kraker') {
      final cleanLegumeSnack = _containsAny(
        ingredients,
        const ['nohut', 'mercimek', 'bezelye', 'fasulye', 'baklagil'],
      );
      return _CategoryProfile(
        cleanLegumeSnack ? 'Baklagil Atıştırmalığı' : 'Cips & Kraker',
        baseScore: cleanLegumeSnack ? 44 : 38,
        maxScore: cleanLegumeSnack ? 60 : 62,
      );
    }
    if (_containsAny(
      text,
      const ['haribo', 'marshmallow', 'gummy', 'gummy candy', 'jelibon', 'sekerleme', 'şekerleme'],
    )) {
      return const _CategoryProfile('Şekerleme', baseScore: 30, maxScore: 45, sweetCategory: true);
    }
    if (category == 'Bisküvi' || _containsAny(text, const ['biskuvi', 'bisküvi', 'wafer', 'gofret', 'cookie'])) {
      return const _CategoryProfile('Bisküvi & Gofret', baseScore: 38, maxScore: 55, sweetCategory: true);
    }
    if (category == 'Çikolata') {
      return const _CategoryProfile('Çikolata', baseScore: 42, maxScore: 58, sweetCategory: true);
    }
    if (category == 'Sporcu Ürünü' || _containsAny(text, const ['protein bar', 'protein'])) {
      return const _CategoryProfile('Protein Bar', baseScore: 50, maxScore: 75);
    }
    if (_containsAny(text, const ['cereal', 'misir gevregi', 'mısır gevreği', 'granola'])) {
      return const _CategoryProfile('Kahvaltılık Gevrek', baseScore: 48, maxScore: 72, sweetCategory: true);
    }
    if (category == 'İşlenmiş Et' ||
        _containsAny(text, const ['sosis', 'salam', 'sucuk', 'jambon', 'hot dog'])) {
      return const _CategoryProfile('İşlenmiş Et', baseScore: 35, maxScore: 50);
    }
    if (category == 'Meyve Suyu') {
      return const _CategoryProfile('Meyve Suyu', baseScore: 42, maxScore: 55);
    }

    return const _CategoryProfile('Diğer', baseScore: 55, maxScore: 75);
  }

  _DailyLoad _dailyLoad(Product product) {
    final sugar = product.sugars ?? 0;
    final salt = product.salt ?? 0;
    final saturatedFat = product.saturatedFat ?? 0;
    final protein = product.protein ?? 0;
    final fiber = product.fiber ?? 0;

    return _DailyLoad(
      sugarPercentOfIdeal: (sugar / _idealSugarDaily) * 100,
      sugarPercentOfUpper: (sugar / _upperSugarDaily) * 100,
      saltPercent: (salt / _saltDaily) * 100,
      saturatedFatPercent: (saturatedFat / _saturatedFatDaily) * 100,
      proteinContributionPercent: (protein / _proteinDaily) * 100,
      fiberContribution: fiber,
    );
  }

  _IngredientRisk _ingredientRisk({
    required Product product,
    required _CategoryProfile profile,
    required String ingredients,
    required String text,
  }) {
    final severeFlags = <String>[];
    final reasons = <String>[];
    int penalty = 0;

    final severeHits = _countContains(
      ingredients,
      const [
        'trans yag',
        'trans yağ',
        'kismen hidrojene',
        'kısmen hidrojene',
        'partially hydrogenated',
        'e249',
        'e250',
        'e251',
        'e252',
        'nitrit',
        'nitrite',
        'nitrat',
        'nitrate',
      ],
    );
    if (severeHits > 0) {
      penalty += 28 + (severeHits - 1) * 6;
      severeFlags.add('severe_red_flag');
      reasons.add('Severe içerik riski bulundu');
    }

    final syrupHits = _countContains(
      ingredients,
      const [
        'glukoz surubu',
        'glikoz surubu',
        'fruktoz surubu',
        'glukoz fruktoz surubu',
        'glukoz-fruktoz surubu',
        'misir surubu',
        'invert seker surubu',
        'invert seker',
        'high fructose corn syrup',
        'glucose syrup',
        'fructose syrup',
      ],
    );
    if (syrupHits > 0) {
      penalty += 16 + (syrupHits - 1) * 4;
      reasons.add('Şurup bazlı tatlandırıcı yükü yüksek');
    }

    final strongSugarHits = _countContains(
      ingredients,
      const [
        'seker',
        'şeker',
        'sukroz',
        'sükroz',
        'glukoz',
        'fruktoz',
        'dekstroz',
        'maltodekstrin',
      ],
    );
    if (strongSugarHits > 0 && profile.sweetCategory) {
      penalty += 8 + (strongSugarHits - 1) * 2;
    }

    final highRiskHits = _countContains(
      ingredients,
      const [
        'palm yagi',
        'palm yağı',
        'palm olein',
        'palm kernel',
        'hindistan cevizi yagi',
        'hindistan cevizi yağı',
        'e338',
        'e339',
        'e340',
        'e341',
        'e450',
        'e451',
        'e452',
      ],
    );
    if (highRiskHits > 0) {
      penalty += 10 + (highRiskHits - 1) * 3;
      reasons.add('İçerikte güçlü kalite düşürücü sinyaller var');
    }

    final moderateHits = _countContains(
      ingredients,
      const [
        'aspartam',
        'e951',
        'asesulfam',
        'acesulfame',
        'e950',
        'sukraloz',
        'sucralose',
        'e955',
        'sakkarin',
        'saccharin',
        'e954',
        'siklamat',
        'cyclamate',
        'e952',
        'tartrazin',
        'e102',
        'e110',
        'e122',
        'e124',
        'e129',
        'e133',
        'e104',
        'modifiye nisasta',
        'modifiye nişasta',
        'aroma verici',
        'maltodekstrin',
        'dekstroz',
      ],
    );
    if (moderateHits > 0) {
      penalty += 5 + (moderateHits - 1) * 2;
      reasons.add('İşlenmiş içerik sinyalleri belirgin');
    }

    final lowRiskHits = _countContains(
      ingredients,
      const [
        'emulgator',
        'emülgatör',
        'lesitin',
        'e202',
        'e211',
        'pektin',
        'guar gam',
        'ksantan gam',
        'seluloz',
        'selüloz',
        'gliserin',
        'e422',
        'askorbik asit',
        'tokoferol',
        'sitrik asit',
      ],
    );
    if (lowRiskHits > 0) {
      penalty += lowRiskHits > 3 ? 4 : 2;
    }

    final hasGelatin = _containsAny(ingredients, const ['jelatin', 'gelatin']);
    final meaningfulPositiveTerms = _countContains(
      ingredients,
      const [
        'tam tahil',
        'tam tahıl',
        'yulaf',
        'nohut',
        'mercimek',
        'fasulye',
        'bezelye',
        'findik',
        'fındık',
        'badem',
        'ceviz',
        'kaju',
        'chia',
        'keten tohumu',
        'zeytinyagi',
        'zeytinyağı',
      ],
    );

    return _IngredientRisk(
      totalPenalty: penalty,
      severeFlags: severeFlags,
      reasons: reasons,
      hasGelatin: hasGelatin,
      positiveIngredientSignals: meaningfulPositiveTerms,
    );
  }

  _ProcessingProfile _processingProfile({
    required Product product,
    required _CategoryProfile profile,
    required String ingredients,
    required String text,
    required _IngredientRisk ingredientRisk,
  }) {
    final industrialHits = _countContains(
      ingredients,
      const [
        'aroma',
        'renklendirici',
        'koruyucu',
        'emulgator',
        'emülgatör',
        'stabilizor',
        'stabilizör',
        'asitlik duzenleyici',
        'asitlik düzenleyici',
        'kivam arttirici',
        'kıvam artırıcı',
        'modifiye nisasta',
        'modifiye nişasta',
        'tatlandirici',
        'tatlandırıcı',
      ],
    );

    final categoryUltraProcessed = _containsAny(
      profile.name,
      const [
        'Şekerleme',
        'Bisküvi',
        'Gofret',
        'Gazlı İçecek',
        'Enerji İçeceği',
        'Protein Bar',
      ],
    );

    if (profile.name == 'Su' ||
        (profile.name == 'Süt & Yoğurt' &&
            industrialHits == 0 &&
            ingredientRisk.totalPenalty <= 2 &&
            !_containsAny(ingredients, const ['seker', 'şeker', 'surup', 'şurup']))) {
      return const _ProcessingProfile(level: 'A', severity: 0, penalty: 0);
    }

    if (ingredientRisk.severeFlags.isNotEmpty ||
        (categoryUltraProcessed && industrialHits >= 3) ||
        ingredientRisk.totalPenalty >= 24) {
      return const _ProcessingProfile(level: 'C', severity: 3, penalty: 18);
    }
    if ((categoryUltraProcessed && industrialHits >= 1) ||
        ingredientRisk.totalPenalty >= 12 ||
        industrialHits >= 2) {
      return const _ProcessingProfile(level: 'C', severity: 2, penalty: 12);
    }
    if (industrialHits >= 1 || ingredientRisk.totalPenalty >= 6) {
      return const _ProcessingProfile(level: 'B', severity: 1, penalty: 6);
    }

    return const _ProcessingProfile(level: 'A', severity: 0, penalty: 0);
  }

  _PenaltyResult _nutritionPenalty({
    required Product product,
    required _CategoryProfile profile,
    required _DailyLoad dailyLoad,
    required String ingredients,
    required String text,
  }) {
    int total = 0;
    final reasons = <String>[];
    final sugar = product.sugars ?? 0;
    final satFat = product.saturatedFat ?? 0;
    final salt = product.salt ?? 0;
    final kcal = product.energyKcal ?? 0;
    final isNaturalSugarContext = profile.naturalSugarContext && !_containsAny(
      ingredients,
      const ['glukoz', 'fruktoz', 'surup', 'şurup', 'misir surubu', 'mısır şurubu'],
    );

    if (product.sugars != null) {
      final sugarPenalty = switch (sugar) {
        >= 30 => 24,
        >= 20 => 18,
        >= 10 => 12,
        >= 5 => 5,
        _ => 0,
      };

      if (profile.name == 'Şekerli Gazlı İçecek' || profile.name == 'Şekerli Enerji İçeceği') {
        total += sugar >= 10 ? 18 : sugar >= 5 ? 10 : 4;
      } else if (profile.name == 'Meyve Suyu') {
        total += sugar >= 10 ? 16 : sugar >= 5 ? 8 : 3;
      } else if (isNaturalSugarContext) {
        total += sugar >= 60 ? 12 : sugar >= 40 ? 8 : sugar >= 20 ? 4 : 0;
      } else {
        total += sugarPenalty;
      }

      if (dailyLoad.sugarPercentOfIdeal >= 100 &&
          (profile.sweetCategory ||
              _containsAny(profile.name, const ['Gazlı İçecek', 'Enerji İçeceği', 'Meyve Suyu']))) {
        total += 10;
        reasons.add(
          '100g üründe şeker miktarı günlük ideal sınırın aşan kısmını oluşturuyor.',
        );
      } else if (dailyLoad.sugarPercentOfIdeal >= 60) {
        reasons.add(
          '100g üründe şeker miktarı günlük ideal sınırın önemli bir kısmını oluşturuyor.',
        );
      } else if (sugar >= 20) {
        reasons.add('Şeker yükü yüksek');
      }
    }

    if (product.saturatedFat != null) {
      final fatSensitive = !profile.naturalFatFriendly ||
          _containsAny(ingredients, const ['palm', 'hindistan cevizi']);
      if (fatSensitive) {
        if (satFat >= 12) {
          total += 18;
          reasons.add('Palm yağı ve yüksek doymuş yağ yükü puanı düşürdü.');
        } else if (satFat >= 8) {
          total += 12;
          reasons.add('Doymuş yağ yükü yüksek');
        } else if (satFat >= 4) {
          total += 5;
        }
      } else if (profile.name == 'Zeytinyağı') {
        total += satFat >= 20 ? 3 : 0;
      } else if (satFat >= 10) {
        total += 6;
      }
    }

    if (product.salt != null) {
      if (salt >= 1.5) {
        total += 14;
        reasons.add('Tuz yükü yüksek');
      } else if (salt >= 0.8) {
        total += 8;
        reasons.add('Tuz yükü yüksek');
      } else if (salt >= 0.3) {
        total += 3;
      }
    }

    if (product.energyKcal != null) {
      final highEnergySweetSnack = kcal >= 450 &&
          (profile.sweetCategory || _containsAny(profile.name, const ['Cips', 'Kraker', 'Protein Bar']));
      if (highEnergySweetSnack) {
        total += 8;
        reasons.add('Enerji yoğunluğu yüksek');
      } else if (kcal >= 350 &&
          (profile.sweetCategory || _containsAny(profile.name, const ['Cips', 'Kraker']))) {
        total += 4;
      }
    }

    if (sugar >= 20 && satFat >= 8 && profile.sweetCategory) {
      total += 10;
      reasons.add('Şeker ve doymuş yağ birlikte yüksek');
    }

    return _PenaltyResult(total: total, reasons: reasons);
  }

  _PenaltyResult _positiveBonus({
    required Product product,
    required _CategoryProfile profile,
    required _DailyLoad dailyLoad,
    required _IngredientRisk ingredientRisk,
    required String ingredients,
    required String text,
  }) {
    int total = 0;
    final reasons = <String>[];
    final sugarBad = dailyLoad.sugarPercentOfIdeal >= 60;
    final saltBad = dailyLoad.saltPercent >= 30;
    final severeNegative = ingredientRisk.totalPenalty >= 18 || sugarBad;

    if (!severeNegative && (product.fiber ?? 0) >= 6) {
      total += 8;
      reasons.add('Lif desteği anlamlı');
    } else if (!severeNegative && (product.fiber ?? 0) >= 3) {
      total += 4;
    }

    final protein = product.protein ?? 0;
    if (!severeNegative && protein >= 15) {
      total += 8;
      reasons.add('Protein katkısı anlamlı');
    } else if (!severeNegative && protein >= 10) {
      total += 4;
    } else if (protein > 0 &&
        protein < 10 &&
        (profile.sweetCategory || profile.name == 'Şekerleme')) {
      reasons.add('Protein miktarı bu ürün için anlamlı bir olumlu katkı oluşturacak düzeyde değil.');
    }

    if ((profile.name == 'Baklagil Atıştırmalığı' || ingredientRisk.positiveIngredientSignals >= 2) &&
        !sugarBad &&
        !saltBad &&
        ingredientRisk.totalPenalty < 12) {
      total += 8;
      reasons.add('Daha temiz atıştırmalık profili');
    }

    if (profile.name == 'Protein Bar' &&
        protein >= 15 &&
        (product.fiber ?? 0) >= 5 &&
        ingredientRisk.totalPenalty < 14 &&
        !sugarBad) {
      total += 10;
      reasons.add('Protein ve lif dengesi güçlü');
    }

    if (profile.name == 'Süt & Yoğurt' &&
        ingredientRisk.totalPenalty <= 2 &&
        !_containsAny(ingredients, const ['seker', 'şeker', 'aroma verici', 'surup', 'şurup'])) {
      total += 4;
      reasons.add('Temel içerik yapısı dengeli');

      final satFat = product.saturatedFat ?? 0;
      final kcal = product.energyKcal ?? 0;
      if (satFat > 0 && satFat <= 1.5 && kcal > 0 && kcal <= 55) {
        total += 2;
        reasons.add('Daha hafif süt profili');
      }
    }

    return _PenaltyResult(total: total, reasons: reasons);
  }

  Map<String, int> _collectCaps({
    required Product product,
    required _CategoryProfile profile,
    required _DailyLoad dailyLoad,
    required _IngredientRisk ingredientRisk,
    required _ProcessingProfile processing,
    required String ingredients,
    required String text,
  }) {
    final caps = <String, int>{'kategori': profile.maxScore};

    if (processing.level == 'C') {
      caps['işleme seviyesi'] = processing.severity >= 3 ? 35 : 50;
    } else if (processing.level == 'B') {
      caps['işleme seviyesi'] = 82;
    }

    if (profile.name == 'Şekerleme') {
      if ((product.sugars ?? 0) > 25) {
        caps['şekerleme şekeri'] = 35;
      }
      if (ingredientRisk.totalPenalty >= 16 ||
          _containsAny(ingredients, const ['renklendirici', 'aroma verici', 'glukoz surubu', 'glikoz surubu'])) {
        caps['şekerleme katkı sınırı'] = 30;
      }
    }

    if (profile.name == 'Bisküvi & Gofret') {
      if ((product.sugars ?? 0) > 25) {
        caps['yüksek şekerli bisküvi'] = 42;
      }
      if ((product.saturatedFat ?? 0) >= 12 &&
          _containsAny(ingredients, const ['palm yagi', 'palm yağı', 'palm'])) {
        caps['palm ve doymuş yağ'] = 35;
      }
    }

    if (profile.name == 'Şekerli Gazlı İçecek') {
      caps['şekerli içecek'] = 45;
    }
    if (profile.name == 'Zero Gazlı İçecek') {
      caps['zero içecek'] = 55;
    }
    if (profile.name == 'Şekerli Enerji İçeceği') {
      caps['şekerli enerji içeceği'] = 45;
    }
    if (profile.name == 'Zero Enerji İçeceği') {
      caps['zero enerji içeceği'] = 45;
    }

    if (profile.name == 'Protein Bar' && ingredientRisk.totalPenalty >= 16) {
      caps['ağır işlenmiş protein bar'] = 45;
    }

    if (profile.name == 'Bal & Reçel') {
      caps['şeker yoğun kategori'] = 60;
      if (dailyLoad.sugarPercentOfIdeal >= 250) {
        caps['bal şeker yükü tavanı'] = 55;
      }
    }

    if (profile.name == 'İşlenmiş Et' &&
        _containsAny(ingredients, const ['nitrit', 'nitrat', 'e250', 'e251', 'e252'])) {
      caps['işlenmiş et katkı sınırı'] = 20;
    }

    if (ingredientRisk.severeFlags.isNotEmpty) {
      caps['severe red flag'] = 15;
    }

    if (dailyLoad.sugarPercentOfIdeal >= 120 &&
        (profile.sweetCategory || _containsAny(profile.name, const ['Gazlı İçecek', 'Enerji İçeceği']))) {
      caps['günlük şeker yükü'] = profile.name == 'Şekerleme' ? 25 : 35;
    }

    return caps;
  }

  double _applyDataConfidence({
    required double score,
    required Product product,
    required _CategoryProfile profile,
    required int missingKeyCount,
    required bool hasIngredients,
  }) {
    var adjusted = score;

    if (missingKeyCount >= 3) {
      adjusted = adjusted.clamp(0, 60).toDouble();
    } else if (missingKeyCount >= 2) {
      adjusted = adjusted.clamp(0, 72).toDouble();
    }

    if (product.sugars == null &&
        (profile.sweetCategory || _containsAny(profile.name, const ['Gazlı İçecek', 'Enerji İçeceği']))) {
      adjusted = adjusted.clamp(0, 45).toDouble();
    }

    if (!hasIngredients && profile.name != 'Su') {
      adjusted = adjusted.clamp(0, 78).toDouble();
    }

    if (product.nutritionTableNotAvailable) {
      return adjusted.clamp(0, 74).toDouble();
    }

    return adjusted;
  }

  double _applyScoreFloor({
    required double score,
    required Product product,
    required _CategoryProfile profile,
    required _DailyLoad dailyLoad,
    required _IngredientRisk ingredientRisk,
    required _ProcessingProfile processing,
    required String ingredients,
    required String text,
  }) {
    final severe = ingredientRisk.severeFlags.isNotEmpty ||
        (processing.level == 'C' && processing.severity >= 3 && ingredientRisk.totalPenalty >= 28);
    if (severe) {
      return score;
    }

    if (profile.name == 'Şekerli Gazlı İçecek') return score < 10 ? 10 : score;
    if (profile.name == 'Zero Gazlı İçecek') return score < 25 ? 25 : score;
    if (profile.name == 'Şekerli Enerji İçeceği') return score < 10 ? 10 : score;
    if (profile.name == 'Zero Enerji İçeceği') return score < 25 ? 25 : score;
    if (profile.name == 'Cips & Kraker' && ingredientRisk.totalPenalty < 22) return score < 15 ? 15 : score;
    if (profile.name == 'Baklagil Atıştırmalığı' && score < 40 && dailyLoad.saltPercent < 30) {
      return 40;
    }
    if (profile.name == 'Protein Bar' &&
        ingredientRisk.totalPenalty < 18 &&
        dailyLoad.sugarPercentOfIdeal < 100 &&
        score < 20) {
      return 20;
    }

    return score;
  }

  List<String> _buildReasons({
    required Product product,
    required _CategoryProfile profile,
    required _DailyLoad dailyLoad,
    required _IngredientRisk ingredientRisk,
    required _PenaltyResult nutritionPenalty,
    required _PenaltyResult positiveBonus,
    required _ProcessingProfile processing,
    required int missingKeyCount,
    required bool hadCap,
    required String ingredients,
  }) {
    final reasons = <String>[];

    reasons.addAll(nutritionPenalty.reasons);
    reasons.addAll(ingredientRisk.reasons);

    if (hadCap) {
      reasons.add('Kategori ${profile.name.toLowerCase()} olduğu için puan tavanı uygulandı.');
    }

    if (ingredientRisk.hasGelatin && profile.name == 'Şekerleme') {
      reasons.add(
        'Jelatin tek başına yüksek riskli değildir; ancak bu üründe ana belirleyici yüksek şeker ve şekerleme kategorisidir.',
      );
    }

    if (processing.level == 'C') {
      reasons.add('İşlenmişlik düzeyi günlük kullanım için zayıf kalıyor.');
    }

    reasons.addAll(positiveBonus.reasons);

    if (missingKeyCount >= 2) {
      reasons.add('Bazı temel beslenme değerleri eksik');
    }

    if (_normalizedIngredients(product.ingredientsText).isEmpty && profile.name != 'Su') {
      reasons.add('İçerik bilgisi eksik');
    }

    if (product.nutritionTableNotAvailable) {
      reasons.add('Besin tablosu bulunamadı');
    }

    return reasons.toSet().take(4).toList(growable: false);
  }

  String _effectiveCategory(Product product) {
    final storedCategory = ProductCategoryMapper.canonicalCategory(product.category);
    if (storedCategory != null && storedCategory != 'Belirsiz' && storedCategory != 'Diğer') {
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
    this.naturalSugarContext = false,
    this.liquidSugarSensitive = false,
    this.sweetCategory = false,
  });

  final String name;
  final int baseScore;
  final int maxScore;
  final bool naturalFatFriendly;
  final bool naturalSugarContext;
  final bool liquidSugarSensitive;
  final bool sweetCategory;
}

class _DailyLoad {
  const _DailyLoad({
    required this.sugarPercentOfIdeal,
    required this.sugarPercentOfUpper,
    required this.saltPercent,
    required this.saturatedFatPercent,
    required this.proteinContributionPercent,
    required this.fiberContribution,
  });

  final double sugarPercentOfIdeal;
  final double sugarPercentOfUpper;
  final double saltPercent;
  final double saturatedFatPercent;
  final double proteinContributionPercent;
  final double fiberContribution;
}

class _IngredientRisk {
  const _IngredientRisk({
    required this.totalPenalty,
    required this.severeFlags,
    required this.reasons,
    required this.hasGelatin,
    required this.positiveIngredientSignals,
  });

  final int totalPenalty;
  final List<String> severeFlags;
  final List<String> reasons;
  final bool hasGelatin;
  final int positiveIngredientSignals;
}

class _ProcessingProfile {
  const _ProcessingProfile({
    required this.level,
    required this.severity,
    required this.penalty,
  });

  final String level;
  final int severity;
  final int penalty;
}

class _PenaltyResult {
  const _PenaltyResult({
    required this.total,
    required this.reasons,
  });

  final int total;
  final List<String> reasons;
}
