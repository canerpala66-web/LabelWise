import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/recent_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentScansRepository {
  const RecentScansRepository();

  static const _storageKey = 'labelwise_recent_scans';
  static const _maxItems = 20;

  Future<List<RecentScan>> getRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];
    final scans = <RecentScan>[];

    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is! Map<String, dynamic>) continue;
        final scan = RecentScan.fromJson(decoded);
        if (scan.barcode.isEmpty) continue;
        scans.add(scan);
      } on Object catch (error) {
        debugPrint('RecentScans: skipped malformed item error=$error');
      }
    }

    scans.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return scans.take(_maxItems).toList(growable: false);
  }

  Future<void> saveProduct(Product product) async {
    final barcode = product.barcode.trim();
    if (barcode.isEmpty) return;

    final score = const LabelWiseScoreEngine().calculate(product).score;
    final currentScans = await getRecentScans();
    final duplicateFound = currentScans.any((scan) => scan.barcode == barcode);
    debugPrint('RecentScans: saving barcode=$barcode');
    debugPrint('RecentScans: duplicate found=$duplicateFound');
    final updatedScans = <RecentScan>[
      RecentScan(
        barcode: barcode,
        productName: product.productName.trim().isEmpty
            ? 'Bilinmeyen Ürün'
            : product.productName.trim(),
        brand: product.brands.trim().isEmpty
            ? 'Bilinmeyen Marka'
            : product.brands.trim(),
        imageUrl: _optionalText(product.imageUrl),
        category: _optionalText(product.category),
        labelwiseScore: score,
        openedAt: DateTime.now(),
      ),
      ...currentScans.where((scan) => scan.barcode != barcode),
    ].take(_maxItems).toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      updatedScans.map((scan) => jsonEncode(scan.toJson())).toList(),
    );
    debugPrint('RecentScans: total stored count=${updatedScans.length}');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('RecentScans: cleared');
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
