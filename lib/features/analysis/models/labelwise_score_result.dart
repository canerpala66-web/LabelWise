import 'package:flutter/material.dart';

class LabelWiseScoreResult {
  const LabelWiseScoreResult({
    required this.score,
    required this.category,
    required this.color,
    this.reasons = const [],
  });

  final int? score;
  final String category;
  final Color color;
  final List<String> reasons;

  bool get isAvailable => score != null;
}
