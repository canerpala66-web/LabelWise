import 'package:supabase_flutter/supabase_flutter.dart';

class SubmittedProductRepository {
  SubmittedProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitProduct({
    required String barcode,
    required String name,
    String? brand,
    String? ingredientsText,
  }) async {
    final trimmedBarcode = barcode.trim();
    final trimmedName = name.trim();

    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Cannot be empty');
    }

    await _client.from('submitted_products').insert({
      'barcode': trimmedBarcode,
      'name': trimmedName,
      'brand': _optionalValue(brand),
      'ingredients_text': _optionalValue(ingredientsText),
      'status': 'pending',
      'source': 'user_submission',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String? _optionalValue(String? value) {
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty ? null : trimmedValue;
  }
}
