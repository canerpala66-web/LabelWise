import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  const engine = LabelWiseScoreEngine();

  test('keeps a typical chips product out of high score ranges', () {
    final result = engine.calculate(
      _product(
        name: 'Ruffles Soğanlı',
        category: ' Cips ',
        energy: 480,
        fat: 25,
        saturatedFat: 2.5,
        sugars: 3,
        fiber: 4,
        protein: 6,
        salt: 1,
      ),
    );

    expect(result.score, inInclusiveRange(0, 62));
    expect(result.score, isNot(inInclusiveRange(80, 100)));
  });

  test('caps a sugary energy drink at 38', () {
    final result = engine.calculate(
      _product(
        name: 'Enerji İçeceği',
        category: 'Enerji İçeceği',
        energy: 45,
        fat: 0,
        saturatedFat: 0,
        sugars: 11,
        salt: 0.1,
      ),
    );

    expect(result.score, lessThanOrEqualTo(38));
  });

  test('scores a high-sugar pudding in the caution range', () {
    final result = engine.calculate(
      _product(
        name: 'Daphne Puding',
        category: 'Puding',
        energy: 130,
        fat: 3,
        saturatedFat: 2,
        sugars: 20,
        protein: 4,
        salt: 0.1,
      ),
    );

    expect(result.score, inInclusiveRange(35, 60));
  });

  test('caps chocolate even when its nutrition penalties are modest', () {
    final result = engine.calculate(
      _product(
        name: 'Sütlü Çikolata',
        category: 'Çikolata',
        energy: 200,
        fat: 8,
        saturatedFat: 3,
        sugars: 12,
        salt: 0.1,
      ),
    );

    expect(result.score, lessThanOrEqualTo(55));
  });

  test('allows balanced plain milk and yogurt to score highly', () {
    final milk = engine.calculate(
      _product(
        name: 'Tam Yağlı Süt',
        category: 'Süt',
        energy: 61,
        fat: 3.3,
        saturatedFat: 2.1,
        sugars: 4.7,
        protein: 3.2,
        salt: 0.1,
      ),
    );
    final yogurt = engine.calculate(
      _product(
        name: 'Sade Yoğurt',
        category: 'Yoğurt',
        energy: 60,
        fat: 3,
        saturatedFat: 2,
        sugars: 4,
        protein: 4,
        salt: 0.1,
      ),
    );

    expect(milk.score, inInclusiveRange(75, 100));
    expect(yogurt.score, inInclusiveRange(75, 100));
  });

  test('scores plain water at 100', () {
    final result = engine.calculate(
      _product(
        name: 'Su',
        category: 'Su',
        energy: 0,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        salt: 0,
      ),
    );

    expect(result.score, 100);
    expect(result.category, 'Çok Dengeli Seçim');
  });

  test('caps regular cola and Cola Zero separately', () {
    final regular = engine.calculate(
      _product(
        name: 'Coca-Cola',
        category: 'Gazlı İçecek',
        energy: 42,
        fat: 0,
        saturatedFat: 0,
        sugars: 10.6,
        salt: 0,
      ),
    );
    final zero = engine.calculate(
      _product(
        name: 'Coca-Cola Zero',
        category: 'Gazlı İçecek',
        energy: 0,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        salt: 0.02,
      ),
    );

    expect(regular.score, inInclusiveRange(20, 40));
    expect(zero.score, inInclusiveRange(55, 68));
  });

  test('returns no score when all key nutrition fields are missing', () {
    final result = engine.calculate(
      const Product(
        productName: 'Eksik Ürün',
        brands: 'Test',
        imageUrl: null,
        ingredientsText: '',
        category: 'Bisküvi',
        fiber: 8,
        protein: 12,
      ),
    );

    expect(result.score, isNull);
  });

  test('caps products with two missing key fields at 70', () {
    final result = engine.calculate(
      _product(
        name: 'Eksik Değerli Ürün',
        category: 'Diğer',
        energy: 50,
        fat: 2,
        saturatedFat: null,
        sugars: null,
        salt: 0.1,
      ),
    );

    expect(result.score, lessThanOrEqualTo(70));
  });

  test('returns at most four useful reasons', () {
    final result = engine.calculate(
      _product(
        name: 'Yoğun Atıştırmalık',
        category: 'Bisküvi',
        energy: 500,
        fat: 25,
        saturatedFat: 8,
        sugars: 25,
        fiber: 6,
        protein: 12,
        salt: 1,
      ),
    );

    expect(result.reasons.length, lessThanOrEqualTo(4));
    expect(result.reasons, contains('Şeker yüksek'));
    expect(result.reasons, contains('Tuz yüksek'));
  });
}

Product _product({
  required String name,
  required String category,
  required double? energy,
  required double? fat,
  required double? saturatedFat,
  required double? sugars,
  required double? salt,
  double? fiber,
  double? protein,
}) {
  return Product(
    productName: name,
    brands: 'Test',
    imageUrl: null,
    ingredientsText: '',
    category: category,
    energyKcal: energy,
    fat: fat,
    saturatedFat: saturatedFat,
    sugars: sugars,
    salt: salt,
    fiber: fiber,
    protein: protein,
  );
}
