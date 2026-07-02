import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionPhoto {
  const SubmissionPhoto({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String fileExtension;
}

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.cause);

  final Object cause;

  @override
  String toString() => 'Photo upload failed: $cause';
}

class SubmittedProductRepository {
  SubmittedProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitProduct({
    required String barcode,
    required String name,
    String? brand,
    String? ingredientsText,
    double? energyKcal,
    double? fat,
    double? saturatedFat,
    double? sugars,
    double? fiber,
    double? protein,
    double? salt,
    SubmissionPhoto? frontPhoto,
    SubmissionPhoto? nutritionPhoto,
    SubmissionPhoto? ingredientsPhoto,
  }) async {
    final trimmedBarcode = barcode.trim();
    final trimmedName = name.trim();

    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Cannot be empty');
    }

    final timestamp = DateTime.now().toUtc();
    final folderPath =
        'submitted-products/${_safePathSegment(trimmedBarcode)}/'
        '${timestamp.microsecondsSinceEpoch}';
    final uploadedPaths = <String>[];

    String? frontImagePath;
    String? nutritionImagePath;
    String? ingredientsImagePath;

    try {
      frontImagePath = await _uploadPhoto(
        photo: frontPhoto,
        pathWithoutExtension: '$folderPath/front',
        uploadedPaths: uploadedPaths,
      );
      nutritionImagePath = await _uploadPhoto(
        photo: nutritionPhoto,
        pathWithoutExtension: '$folderPath/nutrition',
        uploadedPaths: uploadedPaths,
      );
      ingredientsImagePath = await _uploadPhoto(
        photo: ingredientsPhoto,
        pathWithoutExtension: '$folderPath/ingredients',
        uploadedPaths: uploadedPaths,
      );
    } on Object catch (error) {
      await _removeUploadedPhotos(uploadedPaths);
      throw PhotoUploadException(error);
    }

    try {
      await _client.from('submitted_products').insert({
        'barcode': trimmedBarcode,
        'name': trimmedName,
        'brand': _optionalValue(brand),
        'ingredients_text': _optionalValue(ingredientsText),
        'energy_kcal': energyKcal,
        'fat': fat,
        'saturated_fat': saturatedFat,
        'sugars': sugars,
        'fiber': fiber,
        'protein': protein,
        'salt': salt,
        'front_image_path': frontImagePath,
        'nutrition_image_path': nutritionImagePath,
        'ingredients_image_path': ingredientsImagePath,
        'status': 'pending',
        'source': 'user_submission',
        'created_at': timestamp.toIso8601String(),
      });
    } on Object {
      await _removeUploadedPhotos(uploadedPaths);
      rethrow;
    }
  }

  Future<String?> _uploadPhoto({
    required SubmissionPhoto? photo,
    required String pathWithoutExtension,
    required List<String> uploadedPaths,
  }) async {
    if (photo == null) {
      return null;
    }

    final extension = _safeExtension(photo.fileExtension);
    final path = '$pathWithoutExtension.$extension';
    await _client.storage
        .from('submitted-product-photos')
        .uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: false,
          ),
        );
    uploadedPaths.add(path);
    return path;
  }

  Future<void> _removeUploadedPhotos(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    try {
      await _client.storage.from('submitted-product-photos').remove(paths);
    } on Object {
      // Preserve the original upload or database error.
    }
  }

  String _safePathSegment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _safeExtension(String value) {
    final extension = value.toLowerCase().replaceAll('.', '');
    return switch (extension) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  String? _optionalValue(String? value) {
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty ? null : trimmedValue;
  }
}
