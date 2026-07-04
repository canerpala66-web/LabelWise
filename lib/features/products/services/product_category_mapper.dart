import 'package:flutter/foundation.dart';

class ProductCategoryMapper {
  const ProductCategoryMapper._();

  static const categories = <String>[
    'Cips',
    'Kraker',
    'Çikolata',
    'Bisküvi',
    'Kek',
    'Gofret',
    'Gazlı İçecek',
    'Meyve Suyu',
    'Enerji İçeceği',
    'Süt',
    'Yoğurt',
    'Peynir',
    'Dondurma',
    'Kahvaltılık Gevrek',
    'Hazır Çorba',
    'Makarna',
    'Sos',
    'Konserve',
    'Protein Bar',
    'Su',
    'Maden Suyu',
    'Puding',
    'Diğer',
    'Belirsiz',
  ];

  static String inferCategory({
    String? productName,
    String? brand,
    String? ingredientsText,
    List<String>? categoriesTags,
    String? categoriesText,
  }) {
    final nameText = [productName, brand].whereType<String>().join(' ');
    final fromName = _classify(nameText, sodaMeansMineralWater: true);
    if (fromName != null) {
      debugPrint('CategoryMapper: inferred category=$fromName source=name');
      return fromName;
    }

    final offCategoryText = [
      ...?categoriesTags,
      if (categoriesText != null) categoriesText,
    ].join(' ');
    final fromOff = _classify(offCategoryText, sodaMeansMineralWater: false);
    if (fromOff != null) {
      debugPrint('CategoryMapper: inferred category=$fromOff source=off_tags');
      return fromOff;
    }

    final hasAnyInput = [
      offCategoryText,
      nameText,
      ingredientsText ?? '',
    ].any((value) => value.trim().isNotEmpty);
    final fallback = hasAnyInput ? 'Diğer' : 'Belirsiz';
    debugPrint('CategoryMapper: inferred category=$fallback source=fallback');
    return fallback;
  }

  static String? _classify(
    String value, {
    required bool sodaMeansMineralWater,
  }) {
    final text = _normalize(value);
    if (text.isEmpty) return null;

    if (_matches(text, const ['biskrem'])) return 'Bisküvi';
    if (_matches(text, const ['crax'])) return 'Kraker';
    if (_matches(text, const [
      'mineral water',
      'sparkling water',
      'carbonated water',
      'maden suyu',
    ])) {
      return 'Maden Suyu';
    }
    if (sodaMeansMineralWater && _matches(text, const ['soda'])) {
      return 'Maden Suyu';
    }
    if (_matches(text, const [
      'energy drink',
      'energy drinks',
      'enerji içeceği',
      'red bull',
      'monster',
    ])) {
      return 'Enerji İçeceği';
    }
    if (_matches(text, const ['protein bar', 'protein bars'])) {
      return 'Protein Bar';
    }
    if (_matches(text, const [
      'potato crisps',
      'potato chips',
      'crisps',
      'chips',
      'cips',
      'ruffles',
      'lays',
      'doritos',
    ])) {
      return 'Cips';
    }
    if (_matches(text, const [
      'crackers',
      'cracker',
      'kraker',
      'çubuk kraker',
    ])) {
      return 'Kraker';
    }
    if (_matches(text, const [
      'puding',
      'pudding',
      'dessert',
      'desserts',
      'custard',
    ])) {
      return 'Puding';
    }
    if (_matches(text, const [
      'chocolates',
      'chocolate',
      'çikolata',
      'napoliten',
      'bitter',
      'sütlü çikolata',
    ])) {
      return 'Çikolata';
    }
    if (_matches(text, const [
      'biscuits',
      'biscuit',
      'biscotti',
      'cookies',
      'cookie',
      'bisküvi',
    ])) {
      return 'Bisküvi';
    }
    if (_matches(text, const ['cakes', 'cake', 'kek'])) return 'Kek';
    if (_matches(text, const ['wafers', 'wafer', 'gofret'])) return 'Gofret';
    if (_matches(text, const [
      'fruit juices',
      'fruit juice',
      'juice',
      'meyve suyu',
      'nektar',
    ])) {
      return 'Meyve Suyu';
    }
    if (_matches(text, const [
      'soft drinks',
      'soft drink',
      'carbonated drinks',
      'carbonated drink',
      'cola',
      'kola',
      'gazoz',
      'fanta',
      'sprite',
      'pepsi',
      'coca cola',
    ])) {
      return 'Gazlı İçecek';
    }
    if (_matches(text, const ['ice cream', 'ice creams', 'dondurma'])) {
      return 'Dondurma';
    }
    if (_matches(text, const [
      'breakfast cereals',
      'breakfast cereal',
      'corn flakes',
      'cereal',
      'gevrek',
    ])) {
      return 'Kahvaltılık Gevrek';
    }
    if (_matches(text, const [
      'instant soup',
      'instant soups',
      'hazır çorba',
      'soup',
    ])) {
      return 'Hazır Çorba';
    }
    if (_matches(text, const ['yogurt', 'yoghurt', 'yoğurt'])) return 'Yoğurt';
    if (_matches(text, const ['cheese', 'peynir'])) return 'Peynir';
    if (_matches(text, const [
      'uht milk',
      'whole milk',
      'semi skimmed milk',
      'skimmed milk',
      'tam yağlı süt',
      'yarım yağlı süt',
      'laktozsuz süt',
      'milk',
      'süt',
    ])) {
      return 'Süt';
    }
    if (_matches(text, const ['pasta', 'makarna'])) return 'Makarna';
    if (_matches(text, const ['sauces', 'sauce', 'ketçap', 'mayonez', 'sos'])) {
      return 'Sos';
    }
    if (_matches(text, const ['canned', 'konserve'])) return 'Konserve';
    if (_matches(text, const ['water', 'su'])) return 'Su';
    return null;
  }

  static bool _matches(String normalizedText, List<String> keywords) {
    final paddedText = ' $normalizedText ';
    return keywords.any((keyword) {
      final normalizedKeyword = _normalize(keyword);
      return paddedText.contains(' $normalizedKeyword ');
    });
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
