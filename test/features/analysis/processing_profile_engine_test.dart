import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/models/processing_profile_result.dart';
import 'package:labelwise/features/analysis/services/processing_profile_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  group('ProcessingProfileEngine', () {
    const engine = ProcessingProfileEngine();

    test('classifies plain water and mineral water as A', () {
      expect(
        engine
            .analyze(
              _product(
                name: 'Doğal Kaynak Suyu',
                category: 'Su & Maden Suyu',
                ingredients: '',
              ),
            )
            .grade,
        ProcessingProfileGrade.a,
      );
      expect(
        engine
            .analyze(
              _product(
                name: 'Maden Suyu',
                category: 'Su & Maden Suyu',
                ingredients: 'Doğal mineralli su',
              ),
            )
            .grade,
        ProcessingProfileGrade.a,
      );
    });

    test('classifies simple milk, yogurt, nuts and grains as A', () {
      final products = [
        _product(name: 'Pınar Süt', category: 'Süt', ingredients: 'Süt'),
        _product(
          name: 'Sade Yoğurt',
          category: 'Yoğurt & Fermente Süt',
          ingredients: 'Süt, yoğurt kültürü',
        ),
        _product(
          name: 'Çiğ Badem',
          category: 'Kuruyemiş',
          ingredients: 'Badem',
        ),
        _product(
          name: 'Kırmızı Mercimek',
          category: 'Tahıl & Bakliyat',
          ingredients: 'Kırmızı mercimek',
        ),
      ];

      for (final product in products) {
        expect(engine.analyze(product).grade, ProcessingProfileGrade.a);
      }
    });

    test(
      'classifies cheese, bread and processed meat without additives as B',
      () {
        final products = [
          _product(
            name: 'Beyaz Peynir',
            category: 'Peynir',
            ingredients: 'Pastörize süt, tuz, peynir mayası',
          ),
          _product(
            name: 'Tost Ekmeği',
            category: 'Ekmek & Unlu Mamul',
            ingredients: 'Buğday unu, su, maya, tuz',
          ),
          _product(
            name: 'Sucuk',
            category: 'İşlenmiş Et',
            ingredients: 'Dana eti, tuz, baharat',
          ),
        ];

        for (final product in products) {
          expect(engine.analyze(product).grade, ProcessingProfileGrade.b);
        }
      },
    );

    test('classifies cola zero with sweeteners as C', () {
      final result = engine.analyze(
        _product(
          name: 'Cola Zero',
          category: 'Gazlı İçecek',
          ingredients:
              'Su, karbondioksit, renklendirici, tatlandırıcılar: aspartam, asesülfam K, aroma',
        ),
      );

      expect(result.grade, ProcessingProfileGrade.c);
      expect(
        result.reasons,
        contains('Tatlandırıcı veya aroma sinyali bulundu'),
      );
    });

    test('classifies glucose fructose syrup as C', () {
      final result = engine.analyze(
        _product(
          name: 'Kakaolu Bisküvi',
          category: 'Bisküvi',
          ingredients: 'Buğday unu, şeker, glikoz-fruktoz şurubu, kakao',
        ),
      );

      expect(result.grade, ProcessingProfileGrade.c);
      expect(result.reasons, contains('Endüstriyel bileşen sinyali bulundu'));
    });

    test('classifies emulsifier stabilizer colorant or sweetener as C', () {
      final products = [
        _product(
          name: 'Kremalı Ürün',
          category: 'Bisküvi',
          ingredients: 'Şeker, bitkisel yağ, emülgatör, aroma',
        ),
        _product(
          name: 'Meyveli İçecek',
          category: 'Meyve Suyu',
          ingredients: 'Su, şeker, stabilizör, renklendirici',
        ),
        _product(
          name: 'Şekersiz Ürün',
          category: 'Gazlı İçecek',
          ingredients: 'Su, tatlandırıcı, aroma verici',
        ),
      ];

      for (final product in products) {
        expect(engine.analyze(product).grade, ProcessingProfileGrade.c);
      }
    });

    test(
      'does not classify category alone as C when ingredients are simple',
      () {
        final result = engine.analyze(
          _product(
            name: 'Sade Cips',
            category: 'Cips',
            ingredients: 'Patates, ayçiçek yağı, tuz',
          ),
        );

        expect(result.grade, ProcessingProfileGrade.b);
      },
    );

    test('returns unknown when ingredients are missing', () {
      final result = engine.analyze(
        _product(
          name: 'Bilinmeyen Bisküvi',
          category: 'Bisküvi',
          ingredients: 'İçindekiler bilgisi bulunamadı',
        ),
      );

      expect(result.grade, ProcessingProfileGrade.unknown);
      expect(result.reasons, ['İçindekiler bilgisi eksik']);
    });
  });
}

Product _product({
  required String name,
  required String category,
  required String ingredients,
}) {
  return Product(
    barcode: '1234567890123',
    productName: name,
    brands: 'Test',
    imageUrl: null,
    ingredientsText: ingredients,
    category: category,
  );
}
