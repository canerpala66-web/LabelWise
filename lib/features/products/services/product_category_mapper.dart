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

  static const _strongNameRules = <String, List<String>>{
    'Sos': [
      'nutella',
      'sarelle',
      'çokokrem',
      'cokokrem',
      'fındık kreması',
      'kakaolu fındık kreması',
    ],
    'Maden Suyu': [
      'maden suyu',
      'doğal mineralli su',
      'mineralli su',
      'beypazarı',
      'beypazari',
      'kızılay soda',
      'kizilay soda',
      'kızılay maden suyu',
      'sırma maden suyu',
      'uludağ maden suyu',
    ],
    'Enerji İçeceği': [
      'red bull',
      'monster',
      'burn',
      'black bruin',
      'hell energy',
      'dark blue',
      'x-ir',
    ],
    'Cips': [
      'cipso',
      'ruffles',
      'lays',
      "lay's",
      'doritos',
      'pringles',
      'cheetos',
      'crunchips',
      'patos',
      'tadım cips',
      'çerezza',
      'cerezza',
    ],
    'Kraker': ['crax', 'çizi', 'cizi', 'tuc'],
    'Puding': [
      'danette',
      'daphne puding',
      'dr oetker puding',
      'sek puding',
      'içim puding',
    ],
    'Çikolata': [
      'milka',
      'nestle damak',
      'damak',
      'tadelle',
      'albeni',
      'metro',
      'snickers',
      'mars',
      'twix',
      'kitkat',
      'kinder',
      'ferrero',
      'ülker napoliten',
    ],
    'Bisküvi': [
      'biskrem',
      'hanımeller',
      'hanimeller',
      'burçak',
      'burcak',
      'petit beurre',
      'petibör',
      'petibor',
      'potibör',
      'potibor',
      'oreo',
      'negro',
      'lotus',
    ],
    'Gofret': ['hoşbeş', 'hosbes', 'çokonat', 'cokonat', '9 kat', 'dokuz kat'],
    'Kek': [
      'topkek',
      'popkek',
      'eti browni',
      'browni',
      'olala',
      'dankek',
      'magnum cake',
    ],
    'Dondurma': [
      'magnum',
      'cornetto',
      'algida',
      'nogger',
      "carte d'or",
      'carte dor',
    ],
    'Meyve Suyu': [
      'dimes',
      'meysu',
      'cappy',
      'dooy',
      'juss',
      'lipton ice tea',
      'fuse tea',
      'fuzetea',
      'arizona',
    ],
    'Gazlı İçecek': [
      'coca cola',
      'coca-cola',
      'pepsi',
      'fanta',
      'sprite',
      'yedigün',
      'yedigun',
      'fruko',
      'uludağ gazoz',
      'çamlıca gazoz',
      'dr pepper',
    ],
    'Peynir': [
      'pınar labne',
      'sütaş peynir',
      'içim peynir',
      'sek peynir',
      'torku peynir',
      'kiri',
    ],
    'Yoğurt': [
      'activia',
      'sütaş yoğurt',
      'içim yoğurt',
      'pınar yoğurt',
      'sek yoğurt',
      'danone yoğurt',
    ],
    'Süt': [
      'içim süt',
      'pınar süt',
      'sek süt',
      'sütaş süt',
      'torku süt',
      'danone süt',
    ],
    'Kahvaltılık Gevrek': [
      'nesquik cereal',
      'nestle corn flakes',
      'eti lifalif granola',
      "kellogg's",
      'kelloggs',
      'cheerios',
    ],
    'Hazır Çorba': ['knorr çorba', 'bizim mutfak çorba', 'yayla hazır çorba'],
    'Makarna': [
      'nuhun ankara',
      "nuh'un ankara",
      'barilla',
      'filiz makarna',
      'indomie',
      'nissin noodle',
    ],
    'Konserve': ['dardanel ton'],
    'Protein Bar': [
      'züber protein',
      'zuber protein',
      'be kind protein',
      'protein ocean bar',
      'weider protein bar',
    ],
  };

  static const _generalRules = <String, List<String>>{
    'Maden Suyu': [
      'mineral water',
      'sparkling water',
      'carbonated water',
      'maden suyu',
      'doğal mineralli su',
      'mineralli su',
    ],
    'Enerji İçeceği': ['energy drink', 'energy drinks', 'enerji içeceği'],
    'Protein Bar': [
      'protein bar',
      'protein bars',
      'proteinli bar',
      'protein barı',
    ],
    'Sos': [
      'sauces',
      'sauce',
      'ketçap',
      'ketchup',
      'mayonez',
      'mayonnaise',
      'hardal',
      'mustard',
      'barbekü sos',
      'bbq sauce',
      'acı sos',
      'hot sauce',
      'salça',
      'fındık kreması',
      'chocolate spread',
      'hazelnut spread',
      'sos',
    ],
    'Cips': [
      'potato crisps',
      'potato chips',
      'patates cipsi',
      'mısır cipsi',
      'tortilla cipsi',
      'nachos',
      'nacho',
      'taco chips',
      'nacho chips',
      'crisps',
      'chips',
      'cips',
    ],
    'Kraker': [
      'crackers',
      'cracker',
      'kraker',
      'çubuk kraker',
      'breadsticks',
      'pretzel',
      'pretzels',
      'susamlı çubuk',
    ],
    'Puding': [
      'puding',
      'pudding',
      'dessert',
      'desserts',
      'custard',
      'muhallebi',
      'supangle',
      'kazandibi',
      'sütlaç',
      'sutlac',
      'profiterol',
    ],
    'Çikolata': [
      'chocolates',
      'chocolate',
      'çikolata',
      'cikolata',
      'sütlü çikolata',
      'bitter çikolata',
      'beyaz çikolata',
      'napoliten',
      'tablet çikolata',
    ],
    'Bisküvi': [
      'biscuits',
      'biscuit',
      'biscotti',
      'cookies',
      'cookie',
      'bisküvi',
      'kremalı bisküvi',
      'sandviç bisküvi',
      'kakaolu bisküvi',
      'yulaflı bisküvi',
    ],
    'Gofret': ['wafers', 'wafer', 'waffle wafer', 'gofret'],
    'Kek': [
      'cakes',
      'cake',
      'kek',
      'muffin',
      'brownie',
      'sufle',
      'suffle',
      'mini kek',
    ],
    'Meyve Suyu': [
      'fruit juices',
      'fruit juice',
      'juice',
      'meyve suyu',
      'nektar',
      'nectar',
      'ice tea',
      'soğuk çay',
      'soguk cay',
    ],
    'Gazlı İçecek': [
      'soft drinks',
      'soft drink',
      'carbonated drinks',
      'carbonated drink',
      'gazlı içecek',
      'cola',
      'kola',
      'gazoz',
    ],
    'Dondurma': ['ice cream', 'icecream', 'dondurma', 'gelato'],
    'Kahvaltılık Gevrek': [
      'breakfast cereals',
      'breakfast cereal',
      'corn flakes',
      'cereal',
      'kahvaltılık gevrek',
      'mısır gevreği',
      'granola',
      'müsli',
      'musli',
    ],
    'Hazır Çorba': [
      'instant soup',
      'instant soups',
      'hazır çorba',
      'hazir corba',
      'soup',
      'çorba',
      'çorbası',
      'corba',
      'corbasi',
    ],
    'Yoğurt': [
      'yogurt',
      'yoghurt',
      'yoğurt',
      'strained yogurt',
      'süzme yoğurt',
      'probiyotik yoğurt',
    ],
    'Peynir': [
      'cheese',
      'peynir',
      'beyaz peynir',
      'kaşar',
      'kasar',
      'labne',
      'krem peynir',
      'lor',
      'tulum peyniri',
    ],
    'Süt': [
      'uht milk',
      'whole milk',
      'semi skimmed milk',
      'skimmed milk',
      'tam yağlı süt',
      'yarım yağlı süt',
      'laktozsuz süt',
      'günlük süt',
      'milk',
      'süt',
      'sut',
    ],
    'Makarna': [
      'pasta',
      'makarna',
      'spaghetti',
      'spagetti',
      'penne',
      'noodle',
      'noodles',
      'erişte',
      'eriste',
    ],
    'Konserve': [
      'canned food',
      'canned',
      'konserve',
      'ton balığı',
      'tuna',
      'mısır konservesi',
      'fasulye konservesi',
      'bezelye konservesi',
    ],
    'Su': ['still water', 'spring water', 'doğal kaynak suyu', 'water', 'su'],
  };

  static String normalizeCategory(String? value) {
    return (value ?? '')
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? canonicalCategory(String? value) {
    final normalized = normalizeCategory(value);
    if (normalized.isEmpty) return null;

    for (final category in categories) {
      if (normalizeCategory(category) == normalized) return category;
    }
    return value?.trim();
  }

  static String inferCategory({
    String? productName,
    String? brand,
    String? ingredientsText,
    List<String>? categoriesTags,
    String? categoriesText,
  }) {
    final nameText = [productName, brand].whereType<String>().join(' ');
    final strongNameCategory = _classifyStrongName(nameText);
    if (strongNameCategory != null) {
      _logResult(strongNameCategory, 'strong_name');
      return strongNameCategory;
    }

    final offCategoryText = [
      ...?categoriesTags,
      if (categoriesText != null) categoriesText,
    ].join(' ');
    final offCategory = _classify(offCategoryText);
    if (offCategory != null) {
      _logResult(offCategory, 'off_tags');
      return offCategory;
    }

    final nameCategory = _classify(nameText, sodaMeansMineralWater: true);
    if (nameCategory != null) {
      _logResult(nameCategory, 'name');
      return nameCategory;
    }

    final hasAnyInput = [
      offCategoryText,
      nameText,
      ingredientsText ?? '',
    ].any((value) => value.trim().isNotEmpty);
    final fallback = hasAnyInput ? 'Diğer' : 'Belirsiz';
    _logResult(fallback, 'fallback');
    return fallback;
  }

  static String? _classifyStrongName(String value) {
    final text = _normalize(value);
    if (text.isEmpty) return null;

    for (final rule in _strongNameRules.entries) {
      if (_matches(text, rule.value)) return rule.key;
    }
    if (_matches(text, const ['schweppes']) &&
        !_matches(text, const ['tonic', 'mineral', 'maden suyu'])) {
      return 'Gazlı İçecek';
    }
    return null;
  }

  static String? _classify(String value, {bool sodaMeansMineralWater = false}) {
    final text = _normalize(value);
    if (text.isEmpty) return null;
    if (sodaMeansMineralWater && _matches(text, const ['soda'])) {
      return 'Maden Suyu';
    }
    for (final rule in _generalRules.entries) {
      if (_matches(text, rule.value)) return rule.key;
    }
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
    return normalizeCategory(value)
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _logResult(String category, String source) {
    debugPrint('CategoryMapper: inferred category=$category source=$source');
  }
}
