import 'package:flutter/foundation.dart';
import 'package:labelwise/features/analysis/models/processing_profile_result.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class ProcessingProfileEngine {
  const ProcessingProfileEngine();

  ProcessingProfileResult evaluate(Product product) => analyze(product);

  ProcessingProfileResult analyze(Product product) {
    final category = ProductCategoryMapper.canonicalCategory(product.category);
    final ingredients = _cleanIngredients(product.ingredientsText);
    final hasIngredients = ingredients != null;
    final combinedText = _normalizeText(
      [
        product.productName,
        product.brands,
        category,
        product.ingredientsText,
      ].whereType<String>().join(' '),
    );
    final ingredientText = _normalizeText(ingredients ?? '');
    final matchedSignals = _matchedSignals(ingredientText);

    ProcessingProfileResult result;
    if (!hasIngredients) {
      result = _isPlainWater(combinedText)
          ? _aResult(const [
              'Doğal haline yakın kategori',
              'Katkı sinyali sınırlı',
            ])
          : _unknownResult();
    } else if (matchedSignals.isNotEmpty ||
        _additiveLikeSignalCount(ingredientText) >= 2) {
      result = _cResult(_cReasons(matchedSignals));
    } else if (_isSimpleNaturalProduct(
      category: category,
      combinedText: combinedText,
      ingredientText: ingredientText,
    )) {
      result = _aResult(const [
        'Kısa ve sade içerik listesi',
        'Katkı sinyali sınırlı',
        'Doğal haline yakın kategori',
      ]);
    } else {
      result = _bResult();
    }

    debugPrint(
      'ProcessingProfile: product name=${product.productName}, '
      'category=$category, '
      'ingredients exists=$hasIngredients, '
      'matched signals=$matchedSignals, '
      'grade=${result.grade.name}',
    );
    return result;
  }

  ProcessingProfileResult _aResult(List<String> reasons) {
    return ProcessingProfileResult(
      grade: ProcessingProfileGrade.a,
      label: 'Ham haline yakın',
      description:
          'İçeriği daha sade görünüyor ve ürün doğal haline yakın olabilir.',
      reasons: reasons.take(3).toList(growable: false),
    );
  }

  ProcessingProfileResult _bResult() {
    return const ProcessingProfileResult(
      grade: ProcessingProfileGrade.b,
      label: 'Az işlenmiş',
      description:
          'Ürün bazı işlemlerden geçmiş olabilir, ancak katkı sinyali sınırlı görünüyor.',
      reasons: [
        'Bazı işlenmiş bileşenler içeriyor olabilir',
        'Güçlü katkı sinyali bulunmadı',
      ],
    );
  }

  ProcessingProfileResult _cResult(List<String> reasons) {
    return ProcessingProfileResult(
      grade: ProcessingProfileGrade.c,
      label: 'Çok işlenmiş olabilir',
      description:
          'İçerikte katkı, aroma, tatlandırıcı veya benzeri işlenmişlik sinyalleri bulunabilir.',
      reasons: reasons.take(3).toList(growable: false),
    );
  }

  ProcessingProfileResult _unknownResult() {
    return const ProcessingProfileResult(
      grade: ProcessingProfileGrade.unknown,
      label: 'İçerik profili belirlenemedi',
      description:
          'İçindekiler bilgisi bulunmadığı için bu ürünün işlenmişlik profili güvenilir şekilde değerlendirilemedi.',
      reasons: ['İçindekiler bilgisi eksik'],
    );
  }

  List<String> _cReasons(List<String> matchedSignals) {
    final reasons = <String>[];
    if (_signalsContainAny(matchedSignals, const [
      'tatlandirici',
      'aspartam',
      'sukraloz',
      'asesulfam',
      'acesulfame',
      'aroma',
      'aroma verici',
    ])) {
      reasons.add('Tatlandırıcı veya aroma sinyali bulundu');
    }
    if (_signalsContainAny(matchedSignals, const [
      'emulgator',
      'stabilizor',
      'kivam artirici',
      'renklendirici',
      'koruyucu',
    ])) {
      reasons.add('Emülgatör / stabilizör gibi katkı sinyali bulundu');
    }
    if (_signalsContainAny(matchedSignals, const [
      'glikoz surubu',
      'fruktoz surubu',
      'glikoz fruktoz surubu',
      'maltodekstrin',
      'monosodyum glutamat',
      'msg',
      'palm yagi',
      'hidrojenize yag',
    ])) {
      reasons.add('Endüstriyel bileşen sinyali bulundu');
    }
    if (reasons.isEmpty) {
      reasons.add('Endüstriyel bileşen sinyali bulundu');
    }
    return reasons;
  }

  String? _cleanIngredients(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized = _normalizeText(trimmed);
    if (const {
      'icindekiler bilgisi bulunamadi',
      'bilinmiyor',
      'veri yok',
    }.contains(normalized)) {
      return null;
    }
    return trimmed;
  }

  bool _isPlainWater(String text) {
    return _matchesAny(text, const [
          'su',
          'dogal kaynak suyu',
          'icme suyu',
          'maden suyu',
          'mineralli su',
          'soda',
        ]) &&
        !_matchesAny(text, const [
          'meyve suyu',
          'aromali icecek',
          'gazli icecek',
          'enerji icecegi',
        ]);
  }

  bool _isSimpleNaturalProduct({
    required String? category,
    required String combinedText,
    required String ingredientText,
  }) {
    final normalizedCategory = ProductCategoryMapper.normalizeCategory(
      category,
    );
    final ingredientCount = _ingredientCount(ingredientText);
    if (ingredientCount > 3) return false;

    if (normalizedCategory == 'su maden suyu') return true;
    if (normalizedCategory == 'sut') return true;
    if (normalizedCategory == 'yogurt fermente sut') return true;
    if (normalizedCategory == 'kuruyemis') return true;
    if (normalizedCategory == 'tahil bakliyat') return true;
    if (normalizedCategory == 'yag') return true;

    return _matchesAny(combinedText, const [
      'pirinc',
      'bulgur',
      'mercimek',
      'nohut',
      'fasulye',
      'yulaf',
      'badem',
      'ceviz',
      'findik',
      'fistik',
      'kaju',
      'kuru uzum',
      'kuru kayisi',
      'hurma',
    ]);
  }

  int _ingredientCount(String ingredientText) {
    final cleaned = ingredientText
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 0;
    return cleaned
        .split(RegExp(r'[,;•]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .length;
  }

  List<String> _matchedSignals(String ingredientText) {
    if (ingredientText.isEmpty) return const [];
    final matches = <String>[];
    for (final signal in _strongSignals) {
      final normalizedSignal = _normalizeText(signal);
      if (_containsPhrase(ingredientText, normalizedSignal)) {
        matches.add(normalizedSignal);
      }
    }
    return matches.toSet().toList(growable: false);
  }

  int _additiveLikeSignalCount(String ingredientText) {
    return _matchedSignals(ingredientText).length;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any(
      (keyword) => _containsPhrase(text, _normalizeText(keyword)),
    );
  }

  bool _signalsContainAny(List<String> signals, List<String> keywords) {
    final normalizedKeywords = keywords.map(_normalizeText).toSet();
    return signals.any(normalizedKeywords.contains);
  }

  bool _containsPhrase(String text, String phrase) {
    return ' $text '.contains(' $phrase ');
  }

  String _normalizeText(String value) {
    return value
        .replaceAll('İ', 'I')
        .replaceAll('Ç', 'C')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ö', 'O')
        .replaceAll('Ş', 'S')
        .replaceAll('Ü', 'U')
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _strongSignals = [
    'glikoz şurubu',
    'fruktoz şurubu',
    'glikoz-fruktoz şurubu',
    'maltodekstrin',
    'tatlandırıcı',
    'aspartam',
    'sukraloz',
    'asesülfam',
    'acesulfame',
    'renklendirici',
    'koruyucu',
    'emülgatör',
    'stabilizör',
    'kıvam artırıcı',
    'aroma verici',
    'aroma',
    'lezzet artırıcı',
    'monosodyum glutamat',
    'msg',
    'palm yağı',
    'hidrojenize yağ',
  ];
}
