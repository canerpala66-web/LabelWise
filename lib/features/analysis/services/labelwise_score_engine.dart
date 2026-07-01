import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class LabelWiseScoreEngine {
  const LabelWiseScoreEngine();

  static const _beverageKeywords = [
    'kola',
    'cola',
    'gazlı',
    'soda',
    'soft drink',
    'energy drink',
    'enerji içeceği',
  ];
  static const _sugarFreeKeywords = ['zero', 'şekersiz', 'sugar free', 'light'];
  static const _sweetenerKeywords = [
    'tatlandırıcı',
    'sukraloz',
    'asesülfam',
    'aspartam',
    'acesulfame',
    'sucralose',
    'sweetener',
  ];
  static const _ultraProcessedSignals = [
    'aroma',
    'renklendirici',
    'koruyucu',
    'emülgatör',
    'stabilizör',
    'kıvam artırıcı',
    'maltodekstrin',
    'glikoz şurubu',
    'fruktoz şurubu',
    'modifiye nişasta',
  ];

  LabelWiseScoreResult calculate(Product product) {
    if (!product.hasNutritionData) {
      debugPrint(
        'Score v2: baseScore=null, caps=[], finalScore=null, '
        'reasons=[Besin değerleri bulunamadı]',
      );
      return const LabelWiseScoreResult(
        score: null,
        category: 'Sağlık puanı hesaplanamadı.',
        color: Color(0xFF7A827D),
      );
    }

    var score = 100;
    score -= _sugarDeduction(product.sugars);
    score -= _saturatedFatDeduction(product.saturatedFat);
    score -= _saltDeduction(product.salt);
    score -= _energyDeduction(product.energyKcal);
    score += _fiberAddition(product.fiber);
    score += _proteinAddition(product.protein);
    score += _produceAddition(product.fruitsVegetablesLegumesPercent);
    score = score.clamp(0, 100);
    final baseScore = score;

    final caps = <_ScoreCap>[];
    final reasons = <String>[];
    final searchableText = _normalize(
      '${product.productName} ${product.ingredientsText}',
    );
    final ingredients = _normalize(product.ingredientsText);

    final isBeverage = _containsAny(searchableText, _beverageKeywords);
    if (isBeverage) {
      reasons.add('Gazlı içecek kategorisinde');
      final isSugarFree = _containsAny(searchableText, _sugarFreeKeywords);
      caps.add(
        _ScoreCap(
          maximum: isSugarFree ? 78 : 45,
          label: isSugarFree ? 'şekersiz içecek' : 'içecek kategorisi',
        ),
      );
    }

    if (_containsAny(ingredients, _sweetenerKeywords)) {
      caps.add(const _ScoreCap(maximum: 78, label: 'tatlandırıcı'));
      reasons.add('Tatlandırıcı içeriyor');
    }

    final ultraProcessedSignalCount = _ultraProcessedSignals
        .where(ingredients.contains)
        .length;
    final ultraProcessedDeduction = _ultraProcessedDeduction(
      ultraProcessedSignalCount,
    );
    if (ultraProcessedDeduction > 0) {
      score -= ultraProcessedDeduction;
      reasons.add(
        '$ultraProcessedSignalCount işlenmiş içerik sinyali: '
        '-$ultraProcessedDeduction',
      );
    }

    final nutriScoreGrade = product.nutriscoreGrade?.trim().toUpperCase();
    if (nutriScoreGrade == 'D') {
      caps.add(const _ScoreCap(maximum: 65, label: 'Nutri-Score D'));
      reasons.add('Nutri-Score D nedeniyle sınırlandı');
    } else if (nutriScoreGrade == 'E') {
      caps.add(const _ScoreCap(maximum: 45, label: 'Nutri-Score E'));
      reasons.add('Nutri-Score E nedeniyle sınırlandı');
    }

    if (product.salt case final salt? when salt >= 5) {
      caps.add(const _ScoreCap(maximum: 70, label: 'tuz >= 5g'));
      reasons.add('Tuz çok yüksek');
    }

    if (product.saturatedFat case final saturatedFat? when saturatedFat >= 10) {
      caps.add(const _ScoreCap(maximum: 65, label: 'doymuş yağ >= 10g'));
      reasons.add('Doymuş yağ çok yüksek');
    }

    score = score.clamp(0, 100);
    for (final cap in caps) {
      if (score > cap.maximum) {
        score = cap.maximum;
      }
    }

    debugPrint(
      'Score v2: baseScore=$baseScore, '
      'caps=${caps.map((cap) => '${cap.label}:${cap.maximum}').toList()}, '
      'finalScore=$score, reasons=$reasons',
    );

    return LabelWiseScoreResult(
      score: score,
      category: _category(score),
      color: _color(score),
    );
  }

  bool _containsAny(String text, Iterable<String> keywords) {
    return keywords.any(text.contains);
  }

  String _normalize(String value) {
    return value
        .replaceAll('İ', 'I')
        .toLowerCase()
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _ultraProcessedDeduction(int signalCount) {
    if (signalCount >= 5) return 15;
    if (signalCount >= 3) return 10;
    if (signalCount >= 1) return 5;
    return 0;
  }

  int _sugarDeduction(double? value) {
    if (value == null) return 0;
    if (value >= 20) return 25;
    if (value >= 10) return 15;
    if (value >= 5) return 8;
    return 0;
  }

  int _saturatedFatDeduction(double? value) {
    if (value == null) return 0;
    if (value >= 10) return 20;
    if (value >= 5) return 10;
    if (value >= 2) return 5;
    return 0;
  }

  int _saltDeduction(double? value) {
    if (value == null) return 0;
    if (value >= 1.5) return 20;
    if (value >= 0.8) return 10;
    if (value >= 0.3) return 5;
    return 0;
  }

  int _energyDeduction(double? value) {
    if (value == null) return 0;
    if (value >= 500) return 10;
    if (value >= 300) return 5;
    return 0;
  }

  int _fiberAddition(double? value) {
    if (value == null) return 0;
    if (value >= 6) return 10;
    if (value >= 3) return 5;
    return 0;
  }

  int _proteinAddition(double? value) {
    if (value == null) return 0;
    if (value >= 20) return 10;
    if (value >= 10) return 5;
    return 0;
  }

  int _produceAddition(double? value) {
    if (value == null) return 0;
    if (value >= 80) return 10;
    if (value >= 40) return 5;
    return 0;
  }

  String _category(int score) {
    if (score >= 90) return 'Mükemmel Seçim';
    if (score >= 80) return 'Çok İyi';
    if (score >= 70) return 'İyi Seçim';
    if (score >= 60) return 'Dengeli Tüketim';
    if (score >= 50) return 'Dikkatli Tüket';
    if (score >= 40) return 'Sınırlı Tüketim';
    if (score >= 20) return 'Düşük Sağlık Değeri';
    return 'Önerilmez';
  }

  Color _color(int score) {
    if (score >= 90) return const Color(0xFF16843B);
    if (score >= 80) return const Color(0xFF2E9650);
    if (score >= 70) return const Color(0xFF65A43A);
    if (score >= 60) return const Color(0xFF8A9F37);
    if (score >= 50) return const Color(0xFFD49B18);
    if (score >= 40) return const Color(0xFFE47D22);
    if (score >= 20) return const Color(0xFFC85D35);
    return const Color(0xFFB3261E);
  }
}

class _ScoreCap {
  const _ScoreCap({required this.maximum, required this.label});

  final int maximum;
  final String label;
}
