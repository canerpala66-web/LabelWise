import 'package:flutter/material.dart';

class LabelWiseScoreResult {
  const LabelWiseScoreResult({
    required this.score,
    required this.category,
    required this.color,
  });

  final int? score;
  final String category;
  final Color color;

  bool get isAvailable => score != null;
}
