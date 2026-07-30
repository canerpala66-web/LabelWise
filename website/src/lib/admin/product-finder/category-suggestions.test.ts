import { describe, expect, it } from "vitest";
import { inferProductFinderCategorySuggestion } from "./category-suggestions";

describe("product finder category suggestions", () => {
  const cases: Array<[string, string, string | null, string]> = [
    ["Pepsi Kola Kutu 330 ml", "ml", null, "Gazlı İçecek"],
    ["Coca-Cola Original Taste 1 L", "l", null, "Gazlı İçecek"],
    ["Uludağ Gazoz 200 ml", "ml", null, "Gazlı İçecek"],
    ["Kızılay Maden Suyu 200 ml", "ml", null, "Maden Suyu"],
    ["Erikli Su 500 ml", "ml", null, "Su"],
    ["Dimes Şeftali Nektarı 1 L", "l", null, "Meyve Suyu"],
    ["Lipton Ice Tea Şeftali 1 L", "l", null, "Soğuk Çay"],
    ["Red Bull Enerji İçeceği 250 ml", "ml", null, "Enerji İçeceği"],
    ["Sütaş Ayran 285 ml", "ml", null, "Ayran"],
    ["Altınkılıç Kefir 1 L", "l", null, "Kefir"],
    ["Alpro Badem Sütü 1 L", "l", null, "Bitkisel İçecek"],
    ["İçim Süt 1 L", "l", null, "Süt"],
    ["Sütaş Yoğurt 750 g", "g", null, "Yoğurt"],
    ["Pınar Labne Peynir 180 g", "g", null, "Peynir"],
    ["Tereyağı 500 g", "g", null, "Tereyağı"],
    ["Sıvı Krema 200 ml", "ml", null, "Krema"],
    ["Kaymak 150 g", "g", null, "Kaymak"],
    ["Ruffles Patates Cipsi 107 g", "g", null, "Cips"],
    ["Tuzlu Kraker 98 g", "g", null, "Kraker"],
    ["Patlamış Mısır 90 g", "g", null, "Patlamış Mısır"],
    ["Tadım Karışık Kuruyemiş 180 g", "g", null, "Kuruyemiş"],
    ["Kavrulmuş Çekirdek 180 g", "g", null, "Çekirdek"],
    ["Nutella Kakaolu Fındık Kreması 400 g", "g", null, "Kakaolu Fındık Kreması"],
    ["Milka Sütlü Çikolata 80 g", "g", null, "Çikolata"],
    ["Ülker Çikolatalı Gofret 36 g", "g", null, "Gofret"],
    ["Eti Burçak Bisküvi 131 g", "g", null, "Bisküvi"],
    ["Browni Baton Kek 200 g", "g", null, "Kek"],
    ["Jelibon Şekerleme 80 g", "g", null, "Şekerleme"],
    ["Naneli Sakız 27 g", "g", null, "Sakız"],
    ["Vanilyalı Dondurma 500 ml", "ml", null, "Dondurma"],
    ["Çikolatalı Puding 120 g", "g", null, "Puding"],
    ["Çilek Reçeli 380 g", "g", null, "Reçel"],
    ["Çiçek Balı 460 g", "g", null, "Bal"],
    ["Kepekli Tahin 300 g", "g", null, "Tahin"],
    ["Üzüm Pekmezi 800 g", "g", null, "Pekmez"],
    ["Tahin Helva 500 g", "g", null, "Helva"],
    ["Siyah Zeytin 400 g", "g", null, "Zeytin"],
    ["Mısır Gevreği Corn Flakes 375 g", "g", null, "Kahvaltılık Gevrek"],
    ["Yulaf Ezmesi 500 g", "g", null, "Yulaf"],
    ["Tam Buğday Tost Ekmeği 400 g", "g", null, "Ekmek"],
    ["Grissini Galeta 125 g", "g", null, "Galeta"],
    ["Penne Makarna 500 g", "g", null, "Makarna"],
    ["Baldo Pirinç 1 kg", "kg", null, "Pirinç"],
    ["Pilavlık Bulgur 1 kg", "kg", null, "Bulgur"],
    ["Kırmızı Mercimek 1 kg", "kg", null, "Bakliyat"],
    ["Buğday Unu 2 kg", "kg", null, "Un"],
    ["Toz Şeker 1 kg", "kg", null, "Şeker"],
    ["Sofra Tuzu 750 g", "g", null, "Tuz"],
    ["Ayçiçek Yağı 1 L", "l", null, "Sıvı Yağ"],
    ["Domates Salçası 830 g", "g", null, "Salça"],
    ["Ketçap 460 g", "g", null, "Sos"],
    ["Elma Sirkesi 500 ml", "ml", null, "Sirke"],
    ["Dondurulmuş Pizza 450 g", "g", null, "Dondurulmuş Pizza"],
    ["Tavuk Nugget 500 g", "g", null, "Dondurulmuş Hazır Ürün"],
    ["Kayseri Mantı 400 g", "g", null, "Mantı"],
    ["Hazır Çorba 65 g", "g", null, "Hazır Çorba"],
    ["Konserve Bezelye 680 g", "g", null, "Konserve"],
    ["Salatalık Turşusu 670 g", "g", null, "Turşu"],
    ["Dana Sucuk 250 g", "g", null, "Şarküteri"],
    ["Konserve Ton Balığı 160 g", "g", null, "Ton Balığı"],
    ["Balık Konservesi 200 g", "g", null, "Balık Konservesi"],
    ["Bebek Maması 400 g", "g", null, "Bebek Gıdası"],
    ["Glutensiz Ekmek 250 g", "g", null, "Glutensiz Ürün"],
    ["Protein Bar 50 g", "g", null, "Sporcu Gıdası"],
  ];

  it.each(cases)("suggests %s -> %s", (name, unit, currentCategory, expected) => {
    const result = inferProductFinderCategorySuggestion({
      productName: name,
      quantityUnit: unit,
      currentCategory,
    });
    expect(result?.value).toBe(expected);
  });

  it("does not override an existing category", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Pepsi Kola Kutu 330 ml",
      quantityUnit: "ml",
      currentCategory: "Gazlı İçecek",
    });
    expect(result).toBeNull();
  });

  it("prefers chocolate over milk in sutlu cikolata", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Sütlü Çikolata 80 g",
      quantityUnit: "g",
    });
    expect(result?.value).toBe("Çikolata");
  });

  it("prefers maden suyu over su", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Doğal Maden Suyu 200 ml",
      quantityUnit: "ml",
    });
    expect(result?.value).toBe("Maden Suyu");
  });

  it("prefers kakaolu findik kremasi over kuruyemis", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Kakaolu Fındık Kreması 400 g",
      quantityUnit: "g",
    });
    expect(result?.value).toBe("Kakaolu Fındık Kreması");
  });

  it("prefers soguk cay over generic cay", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Soğuk Çay Şeftali 1 L",
      quantityUnit: "l",
    });
    expect(result?.value).toBe("Soğuk Çay");
  });

  it("returns null on low-confidence generic names", () => {
    const result = inferProductFinderCategorySuggestion({
      productName: "Özel Ürün 330 ml",
      quantityUnit: "ml",
      ingredients: "Su, aroma vericiler",
    });
    expect(result).toBeNull();
  });
});
