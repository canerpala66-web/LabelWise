import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/scanner/data/product.dart';

void main() {
  const engine = LabelWiseScoreEngine();

  test('water scores very high', () {
    final result = engine.calculate(
      _product(
        name: 'Doğal Kaynak Suyu',
        category: 'Su & Maden Suyu',
        ingredients: '',
        energy: 0,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        salt: 0,
      ),
    );

    expect(result.score, inInclusiveRange(95, 100));
  });

  test('sugary cola does not exceed 45 and zero cola does not exceed 60', () {
    final cola = engine.calculate(
      _product(
        name: 'Pepsi Cola',
        category: 'Gazlı İçecek',
        ingredients: 'Karbonatlı su, şeker, asitlik düzenleyici, aroma verici',
        energy: 42,
        fat: 0,
        saturatedFat: 0,
        sugars: 10.6,
        salt: 0.02,
      ),
    );

    final zero = engine.calculate(
      _product(
        name: 'Pepsi Cola Zero',
        category: 'Gazlı İçecek',
        ingredients:
            'Karbonatlı su, tatlandırıcılar (asesülfam k, aspartam), aroma verici, asitlik düzenleyici',
        energy: 1,
        fat: 0,
        saturatedFat: 0,
        sugars: 0,
        salt: 0.02,
      ),
    );

    final yogurt = engine.calculate(
      _product(
        name: 'Sade Yoğurt',
        category: 'Yoğurt & Fermente Süt',
        ingredients: 'Süt, yoğurt kültürü',
        energy: 60,
        fat: 3,
        saturatedFat: 2,
        sugars: 4,
        salt: 0.1,
        protein: 4,
      ),
    );

    expect(cola.score, lessThanOrEqualTo(45));
    expect(zero.score, lessThanOrEqualTo(60));
    expect(zero.score, lessThan(yogurt.score!));
  });

  test('clean legume chip scores higher than additive-heavy corn chip', () {
    final doritosLike = engine.calculate(
      _product(
        name: 'Acılı Mısır Cipsi',
        category: 'Cips',
        ingredients:
            'Mısır unu, bitkisel yağ, aroma verici, tatlandırıcı, renklendirici, asitlik düzenleyici',
        energy: 490,
        fat: 24,
        saturatedFat: 3.5,
        sugars: 3.5,
        salt: 1.4,
        fiber: 3,
        protein: 6,
      ),
    );

    final chickpeaLike = engine.calculate(
      _product(
        name: 'Nohut Cipsi',
        category: 'Cips',
        ingredients: 'Nohut unu, zeytinyağı, deniz tuzu',
        energy: 440,
        fat: 15,
        saturatedFat: 1.8,
        sugars: 2,
        salt: 0.8,
        fiber: 7,
        protein: 12,
      ),
    );

    expect(chickpeaLike.score, greaterThan(doritosLike.score!));
    expect(chickpeaLike.score, inInclusiveRange(45, 62));
    expect(chickpeaLike.score, lessThanOrEqualTo(62));
  });

  test('olive is not punished like a snack and olive oil stays high when pure', () {
    final olive = engine.calculate(
      _product(
        name: 'Yeşil Zeytin',
        category: 'Diğer',
        ingredients: 'Zeytin, su, tuz',
        energy: 145,
        fat: 15,
        saturatedFat: 2.3,
        sugars: 0,
        salt: 2.5,
        fiber: 3,
      ),
    );

    final oliveOil = engine.calculate(
      _product(
        name: 'Natürel Sızma Zeytinyağı',
        category: 'Yağ',
        ingredients: 'Natürel sızma zeytinyağı',
        energy: 884,
        fat: 100,
        saturatedFat: 14,
        sugars: 0,
        salt: 0,
      ),
    );

    expect(olive.score, greaterThanOrEqualTo(45));
    expect(oliveOil.score, inInclusiveRange(75, 90));
  });

  test('clean honey is capped but clearly better than cola', () {
    final honey = engine.calculate(
      _product(
        name: 'Süzme Çiçek Balı',
        category: 'Sürülebilir Tatlı',
        ingredients: 'Bal',
        energy: 320,
        fat: 0,
        saturatedFat: 0,
        sugars: 79,
        salt: 0.02,
      ),
    );

    final cola = engine.calculate(
      _product(
        name: 'Pepsi Cola',
        category: 'Gazlı İçecek',
        ingredients: 'Karbonatlı su, şeker, aroma verici',
        energy: 42,
        fat: 0,
        saturatedFat: 0,
        sugars: 10.6,
        salt: 0.02,
      ),
    );

    expect(honey.score, lessThanOrEqualTo(72));
    expect(honey.score, greaterThan(cola.score!));
  });

  test('clean protein bar scores above additive-heavy protein bar', () {
    final cleanBar = engine.calculate(
      _product(
        name: 'Protein Bar Kakao',
        category: 'Sporcu Ürünü',
        ingredients: 'Hurma, badem, bezelye proteini, kakao, yulaf lifi',
        energy: 360,
        fat: 12,
        saturatedFat: 2.5,
        sugars: 12,
        salt: 0.3,
        fiber: 8,
        protein: 22,
      ),
    );

    final heavyBar = engine.calculate(
      _product(
        name: 'Protein Bar Çikolata',
        category: 'Sporcu Ürünü',
        ingredients:
            'Glukoz şurubu, süt proteini, humektan, aroma verici, emülgatör, tatlandırıcı, koruyucu',
        energy: 390,
        fat: 13,
        saturatedFat: 4,
        sugars: 18,
        salt: 0.4,
        fiber: 5,
        protein: 20,
      ),
    );

    expect(cleanBar.score, greaterThan(heavyBar.score!));
    expect(cleanBar.score, inInclusiveRange(50, 70));
    expect(heavyBar.score, lessThanOrEqualTo(60));
  });

  test('missing ingredients lowers confidence and avoids overly high score', () {
    final result = engine.calculate(
      _product(
        name: 'Belirsiz Tahıl Bar',
        category: 'Tahıl & Bakliyat',
        ingredients: '',
        energy: 340,
        fat: 8,
        saturatedFat: 1.2,
        sugars: 9,
        salt: 0.2,
        fiber: 5,
        protein: 6,
      ),
    );

    expect(result.score, lessThanOrEqualTo(78));
    expect(result.reasons, contains('İçerik bilgisi eksik'));
  });

  test('nutrition_table_not_available keeps score moderate and explains confidence', () {
    final result = engine.calculate(
      const Product(
        productName: 'Doğal Zeytin Ezmesi',
        brands: 'Test',
        imageUrl: null,
        ingredientsText: 'Zeytin, zeytinyağı, tuz',
        category: 'Diğer',
        nutritionTableNotAvailable: true,
      ),
    );

    expect(result.score, isNull);
  });
}

Product _product({
  required String name,
  required String category,
  required String ingredients,
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
    ingredientsText: ingredients,
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
