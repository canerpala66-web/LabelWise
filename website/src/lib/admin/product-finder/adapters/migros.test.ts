import { describe, expect, it } from "vitest";
import {
  applyMigrosSuggestions,
  fetchMigrosProductByUrl,
  parseMigrosProductHtml,
  validateMigrosProductUrl,
} from "./migros";

const productHtml100ml = `
  <html>
    <head>
      <title>Pepsi Kola Kutu 330 ml | Migros</title>
      <meta property="og:title" content="Pepsi Kola Kutu 330 ml" />
      <meta property="og:image" content="https://cdn.migros.com.tr/pepsi-330.jpg" />
      <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Product",
          "name": "Pepsi Kola Kutu 330 ml",
          "brand": { "@type": "Brand", "name": "Pepsi" },
          "image": "https://cdn.migros.com.tr/pepsi-330.jpg",
          "category": "Gazlı İçecek"
        }
      </script>
    </head>
    <body>
      <section>
        <h2>İçindekiler</h2>
        <p>Su, şeker, karbondioksit, asitlik düzenleyici.</p>
      </section>
      <section>
        <h2>Besin Değerleri</h2>
        <p>100 ml için Enerji 42 kcal 176 kJ Yağ 0 Doymuş yağ 0 Karbonhidrat 10,6 Şekerler 10,6 Lif 0 Protein 0 Tuz 0,03 Sodyum 12</p>
      </section>
    </body>
  </html>
`;

const productHtml100g = `
  <html>
    <head>
      <meta property="og:title" content="Kuru Meyve 400 g" />
      <meta property="og:image" content="https://cdn.migros.com.tr/kuru-meyve.jpg" />
    </head>
    <body>
      <div>Kategori: Atıştırmalık</div>
      <div>İçindekiler: Kuru üzüm, bitkisel yağ.</div>
      <div>Besin Değerleri 100 g için Enerji 320 kcal Yağ 1,2 Doymuş yağ 0,1 Karbonhidrat 72 Şekerler 58 Lif 5 Protein 3 Tuz 0,02</div>
    </body>
  </html>
`;

const dirtyHtmlFixture = `
  <html>
    <head>
      <title>Pepsi Kola Kutu 330 Ml - Migros</title>
      <meta property="og:title" content="Pepsi Kola Kutu 330 Ml - Migros" />
    </head>
    <body>
      <div>Kategori class="tab mat-caption..." aria-selected="true"</div>
      <div>İçindekiler: Su, şeker, aroma <!-- link rel=app --></div>
      <div>mat-tab-group Besin Değerleri sekmesi ürün detayında açılıyor</div>
    </body>
  </html>
`;

const embeddedJsonNutritionFixture = `
  <html>
    <head>
      <meta property="og:title" content="Meyveli İçecek 250 ml" />
      <script>
        window.__PRODUCT_STATE__ = {
          "nutritionFacts": {
            "basis": "100 ml",
            "Enerji kcal": "48,5",
            "Enerji kJ": "203",
            "Karbonhidrat": "11,9",
            "Şekerler": "11,7",
            "Protein": "0",
            "Tuz": "0,01"
          }
        };
      </script>
    </head>
    <body>
      <div>İçindekiler: Su, meyve suyu konsantresi, şeker.</div>
    </body>
  </html>
`;

const liveLikeNutritionTableFixture = `
  <html>
    <head>
      <meta property="og:title" content="Pepsi Kola Kutu 330 Ml" />
      <meta property="og:image" content="https://images.migrosone.com/sanalmarket/product/08010023/08010023_1-ae16d1.jpg" />
      <script type="application/ld+json">
        {"@type":"Product","name":"Pepsi Kola Kutu 330 Ml","category":"Gazlı İçecek/İçecek","brand":{"name":"Pepsi"}}
      </script>
    </head>
    <body>
      <button><span class="fe-tab-label__text">Besin Değerleri</span></button>
      <div class="desktop-only nutrition-wrapper">
        <table>
          <thead>
            <tr>
              <th class="cdk-column-key"><span>Besin Değeri</span></th>
              <th class="cdk-column-value"><span>100 g / ml</span></th>
            </tr>
          </thead>
          <tbody>
            <tr><td>Enerji (kcal)</td><td>28.0</td></tr>
            <tr><td>Enerji (kJ)</td><td>119.0</td></tr>
            <tr><td>Yağ (g)</td><td>0.0</td></tr>
            <tr><td>Doymuş yağ (g)</td><td>0.0</td></tr>
            <tr><td>Karbonhidrat (g)</td><td>7.0</td></tr>
            <tr><td>Şeker (g)</td><td>7.0</td></tr>
            <tr><td>Lif (g)</td><td>0.0</td></tr>
            <tr><td>Protein (g)</td><td>0.0</td></tr>
            <tr><td>Tuz (g)</td><td>0.01</td></tr>
          </tbody>
        </table>
      </div>
      <div>İçindekiler: Su, şeker, karbondioksit, aroma vericiler.</div>
    </body>
  </html>
`;

const solidAmbiguousBasisFixture = `
  <html>
    <head>
      <meta property="og:title" content="Kuru Meyve 400 g" />
    </head>
    <body>
      <div class="desktop-only nutrition-wrapper">
        <table>
          <thead>
            <tr>
              <th class="cdk-column-key"><span>Besin Değeri</span></th>
              <th class="cdk-column-value"><span>100 g / ml</span></th>
            </tr>
          </thead>
          <tbody>
            <tr><td>Enerji (kcal)</td><td>320</td></tr>
            <tr><td>Yağ (g)</td><td>1,2</td></tr>
            <tr><td>Doymuş yağ (g)</td><td>0,1</td></tr>
            <tr><td>Karbonhidrat (g)</td><td>72</td></tr>
            <tr><td>Şeker (g)</td><td>58</td></tr>
            <tr><td>Protein (g)</td><td>3</td></tr>
            <tr><td>Tuz (g)</td><td>0,02</td></tr>
          </tbody>
        </table>
      </div>
    </body>
  </html>
`;

const alternateIngredientsFixture = `
  <html>
    <head>
      <meta property="og:title" content="Kraker 100 g" />
    </head>
    <body>
      <div class="accordion">
        <h3>Ürün İçeriği</h3>
        <div><span>Buğday unu,</span> <span>bitkisel yağ, tuz.</span></div>
      </div>
    </body>
  </html>
`;

const allergenOnlyFixture = `
  <html>
    <head>
      <meta property="og:title" content="Kraker 100 g" />
    </head>
    <body>
      <div>Alerjen Bilgisi: Gluten içerir.</div>
    </body>
  </html>
`;

const zeroFatVariantFixture = `
  <html>
    <head>
      <meta property="og:title" content="Soda 200 ml" />
    </head>
    <body>
      <div class="desktop-only nutrition-wrapper">
        <table>
          <thead>
            <tr>
              <th class="cdk-column-key"><span>Besin Değeri</span></th>
              <th class="cdk-column-value"><span>100 ml</span></th>
            </tr>
          </thead>
          <tbody>
            <tr><td><span>Toplam&nbsp;Yağ (g)</span></td><td><span>0,0</span></td></tr>
            <tr><td><span>Doymuş Yağ Asitleri (g)</span></td><td><span>0</span></td></tr>
            <tr><td><span>Tuz (g)</span></td><td><span>&lt;0.01</span></td></tr>
          </tbody>
        </table>
      </div>
    </body>
  </html>
`;

const attributeListIngredientsFixture = `
  <html>
    <head>
      <meta property="og:title" content="Granola Bar 120 g" />
    </head>
    <body>
      <dl>
        <dt>İçerik Bilgisi</dt>
        <dd>Yulaf ezmesi, bal, kakao nibs, bitkisel yağ.</dd>
      </dl>
    </body>
  </html>
`;

const snickersMultipackFixture = `
  <html>
    <head>
      <meta property="og:title" content="Snickers 2'li 80 g" />
    </head>
    <body>
      <div>İçindekiler: Sütlü çikolata, yer fıstığı, karamel.</div>
    </body>
  </html>
`;

const twoByFortyFixture = `
  <html>
    <head>
      <meta property="og:title" content="Protein Bar 2x40 g" />
    </head>
    <body>
      <div>İçindekiler: Protein karışımı, kakao, aroma vericiler.</div>
    </body>
  </html>
`;

const sixByTwoHundredFixture = `
  <html>
    <head>
      <meta property="og:title" content="Meyve Suyu 6x200 ml" />
    </head>
    <body>
      <div>İçindekiler: Su, meyve suyu konsantresi.</div>
    </body>
  </html>
`;

describe("migros single product parser", () => {
  it("rejects non-Migros urls", () => {
    expect(validateMigrosProductUrl("https://example.com/product")).toBeNull();
  });

  it("parses product title", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.product_name).toBe("Pepsi Kola Kutu 330 ml");
    expect(candidate.source_name).toBe("migros");
  });

  it("parses image url", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.image_front_url).toBe("https://cdn.migros.com.tr/pepsi-330.jpg");
  });

  it("parses ingredients text", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.ingredients).toContain("Su");
  });

  it("parses nutrition table with comma decimals", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.sugars_100g).toBe(10.6);
    expect(candidate.salt_100g).toBe(0.03);
  });

  it("parses 100 ml basis", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.nutrition_basis).toBe("100ml");
  });

  it("parses 100 g basis", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100g,
      "https://www.migros.com.tr/atistirmalik/kuru-meyve-p-def456",
    );
    expect(candidate.nutrition_basis).toBe("100g");
  });

  it("parses quantity from title", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.quantity_value).toBe(330);
    expect(candidate.quantity_unit).toBe("ml");
  });

  it("missing ingredients adds ingredients_missing", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Urun 330 ml' /></head><body></body></html>",
      "https://www.migros.com.tr/test/urun-p-123",
    );
    expect(candidate.issue_list.some((item) => item.code === "ingredients_missing")).toBe(true);
  });

  it("missing nutrition adds nutrition_missing", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Urun 330 ml' /></head><body><div>İçindekiler: Su</div></body></html>",
      "https://www.migros.com.tr/test/urun-p-123",
    );
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(true);
    expect(candidate.nutrition_basis).toBeNull();
  });

  it("missing basis adds nutrition_basis_missing", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Urun 330 ml' /></head><body><div>Besin Değerleri Enerji 42 kcal Yağ 0</div></body></html>",
      "https://www.migros.com.tr/test/urun-p-123",
    );
    expect(candidate.issue_list.some((item) => item.code === "nutrition_basis_missing")).toBe(true);
  });

  it("does not set nutrition basis when basis text exists without parsed nutrition values", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Urun 330 ml' /></head><body><div>Besin Değerleri 100 g için detaylar yakında</div></body></html>",
      "https://www.migros.com.tr/test/urun-p-123",
    );
    expect(candidate.nutrition_basis).toBeNull();
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(true);
    expect(candidate.issue_list.some((item) => item.code === "nutrition_basis_missing")).toBe(true);
  });

  it("invalid source url returns source_not_found issue", () => {
    const candidate = parseMigrosProductHtml(productHtml100ml, "https://example.com/test");
    expect(candidate.issue_list.some((item) => item.code === "source_not_found")).toBe(true);
  });

  it("fetch helper rejects non-Migros url without network", async () => {
    const candidate = await fetchMigrosProductByUrl("https://example.com/test");
    expect(candidate.issue_list.some((item) => item.code === "source_not_found")).toBe(true);
  });

  it("does not return dirty html in category", () => {
    const candidate = parseMigrosProductHtml(
      dirtyHtmlFixture,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.category).toBeNull();
  });

  it("does not return dirty html in ingredients", () => {
    const candidate = parseMigrosProductHtml(
      dirtyHtmlFixture,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.ingredients).toBeNull();
  });

  it("adds dirty_html_discarded issue when dirty fields are discarded", () => {
    const candidate = parseMigrosProductHtml(
      dirtyHtmlFixture,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.issue_list.some((item) => item.code === "dirty_html_discarded")).toBe(true);
  });

  it("adds nutrition_may_be_client_side when nutrition tab appears absent in initial html", () => {
    const candidate = parseMigrosProductHtml(
      dirtyHtmlFixture,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(true);
    expect(
      candidate.issue_list.some((item) => item.code === "nutrition_may_be_client_side"),
    ).toBe(true);
    expect(candidate.nutrition_basis).toBeNull();
  });

  it("keeps clean ingredients when present", () => {
    const candidate = parseMigrosProductHtml(
      productHtml100ml,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.ingredients).toBe("Su, şeker, karbondioksit, asitlik düzenleyici.");
  });

  it("extracts ingredients from alternate Migros labels", () => {
    const candidate = parseMigrosProductHtml(
      alternateIngredientsFixture,
      "https://www.migros.com.tr/kraker-p-abc123",
    );
    expect(candidate.ingredients).toBe("Buğday unu, bitkisel yağ, tuz.");
    expect(candidate.raw_payload?.ingredients_extraction_strategy).toBeTruthy();
    expect(candidate.raw_payload?.ingredients_label_detected).toBe("Ürün İçeriği");
  });

  it("does not treat allergen-only text as full ingredients", () => {
    const candidate = parseMigrosProductHtml(
      allergenOnlyFixture,
      "https://www.migros.com.tr/kraker-p-abc123",
    );
    expect(candidate.ingredients).toBeNull();
    expect(candidate.issue_list.some((item) => item.code === "ingredients_missing")).toBe(true);
    expect(candidate.raw_payload?.ingredients_missing_reason).toBe("only_allergen_text_found");
  });

  it("extracts ingredients from attribute-list style container", () => {
    const candidate = parseMigrosProductHtml(
      attributeListIngredientsFixture,
      "https://www.migros.com.tr/granola-bar-p-attr123",
    );
    expect(candidate.ingredients).toBe("Yulaf ezmesi, bal, kakao nibs, bitkisel yağ.");
    expect(candidate.raw_payload?.ingredients_container_hint).toBe("attribute_list");
  });

  it("parses embedded json nutrition when present", () => {
    const candidate = parseMigrosProductHtml(
      embeddedJsonNutritionFixture,
      "https://www.migros.com.tr/icecek/meyveli-icecek-p-ghi789",
    );
    expect(candidate.nutrition_basis).toBe("100ml");
    expect(candidate.energy_kcal_100g).toBe(48.5);
    expect(candidate.energy_kj_100g).toBe(203);
    expect(candidate.sugars_100g).toBe(11.7);
    expect(candidate.raw_payload?.has_embedded_json_candidates).toBe(true);
  });

  it("parses Migros nutrition table values from initial html without fake endpoint", () => {
    const candidate = parseMigrosProductHtml(
      liveLikeNutritionTableFixture,
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.energy_kcal_100g).toBe(28);
    expect(candidate.energy_kj_100g).toBe(119);
    expect(candidate.fat_100g).toBe(0);
    expect(candidate.saturated_fat_100g).toBe(0);
    expect(candidate.carbohydrates_100g).toBe(7);
    expect(candidate.sugars_100g).toBe(7);
    expect(candidate.salt_100g).toBe(0.01);
    expect(candidate.nutrition_basis).toBeNull();
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(false);
    expect(candidate.raw_payload?.nutrition_endpoint_used).toBeNull();
    expect(candidate.raw_payload?.discovered_product_id).toBe("7a3927");
  });

  it("preserves explicit zero fat and saturated fat values from variant labels", () => {
    const candidate = parseMigrosProductHtml(
      zeroFatVariantFixture,
      "https://www.migros.com.tr/soda-p-xyz123",
    );
    expect(candidate.fat_100g).toBe(0);
    expect(candidate.saturated_fat_100g).toBe(0);
    expect(candidate.salt_100g).toBe(0.01);
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(false);
    expect(candidate.raw_payload?.nutrition_zero_values_detected).toContain("Toplam Yağ (g)");
    expect(candidate.raw_payload?.nutrition_zero_values_detected).toContain("Doymuş Yağ Asitleri (g)");
  });

  it("creates 100ml nutrition basis suggestion for liquid product with ambiguous basis header", () => {
    const candidate = parseMigrosProductHtml(
      liveLikeNutritionTableFixture,
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.nutrition_basis).toBeNull();
    expect(candidate.raw_payload?.nutrition_basis_suggestion).toBe("100ml");
  });

  it("parses quantity for Snickers 2'li 80 g style titles", () => {
    const candidate = parseMigrosProductHtml(
      snickersMultipackFixture,
      "https://www.migros.com.tr/snickers-2li-80-g-p-snk123",
    );
    expect(candidate.quantity_value).toBe(80);
    expect(candidate.quantity_unit).toBe("g");
  });

  it("parses total quantity from 2x40 g style titles", () => {
    const candidate = parseMigrosProductHtml(
      twoByFortyFixture,
      "https://www.migros.com.tr/protein-bar-2x40-g-p-prt123",
    );
    expect(candidate.quantity_value).toBe(80);
    expect(candidate.quantity_unit).toBe("g");
  });

  it("parses total quantity from 6x200 ml style titles", () => {
    const candidate = parseMigrosProductHtml(
      sixByTwoHundredFixture,
      "https://www.migros.com.tr/meyve-suyu-6x200-ml-p-mys123",
    );
    expect(candidate.quantity_value).toBe(1200);
    expect(candidate.quantity_unit).toBe("ml");
  });

  it("creates 100g nutrition basis suggestion for solid product with ambiguous basis header", () => {
    const candidate = parseMigrosProductHtml(
      solidAmbiguousBasisFixture,
      "https://www.migros.com.tr/atistirmalik/kuru-meyve-p-def456",
    );
    expect(candidate.nutrition_basis).toBeNull();
    expect(candidate.raw_payload?.nutrition_basis_suggestion).toBe("100g");
  });

  it("does not create nutrition basis suggestion if nutrition values are missing", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Pepsi 330 ml' /></head><body><div>Besin Değerleri <table><thead><tr><th>100 g / ml</th></tr></thead></table></div></body></html>",
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.raw_payload?.nutrition_basis_suggestion).toBeNull();
  });

  it("creates category suggestion for cola beverage candidates", () => {
    const candidate = parseMigrosProductHtml(
      liveLikeNutritionTableFixture,
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.category).toBe("Gazlı İçecek/İçecek");
    expect(candidate.raw_payload?.category_suggestion).toBeNull();
  });

  it("creates category suggestion when category is missing but signals are strong", () => {
    const candidate = parseMigrosProductHtml(
      `<html><head><meta property="og:title" content="Pepsi Kola Kutu 330 ml" /></head><body><div>İçindekiler: Su, şeker, karbondioksit.</div></body></html>`,
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.category).toBeNull();
    expect(candidate.raw_payload?.category_suggestion).toBe("Gazlı İçecek");
  });

  it("does not create low-confidence category suggestion", () => {
    const candidate = parseMigrosProductHtml(
      `<html><head><meta property="og:title" content="Ürün 330 ml" /></head><body><div>İçindekiler: Su, aroma.</div></body></html>`,
      "https://www.migros.com.tr/test/urun-p-123",
    );
    expect(candidate.raw_payload?.category_suggestion).toBeNull();
  });

  it("applying suggestions removes category_missing and nutrition_basis_missing", () => {
    const candidate = parseMigrosProductHtml(
      `<html><head><meta property="og:title" content="Pepsi Kola Kutu 330 ml" /></head><body><div class="desktop-only nutrition-wrapper"><table><thead><tr><th class="cdk-column-key"><span>Besin Değeri</span></th><th class="cdk-column-value"><span>100 g / ml</span></th></tr></thead><tbody><tr><td>Enerji (kcal)</td><td>28.0</td></tr><tr><td>Karbonhidrat (g)</td><td>7.0</td></tr><tr><td>Şeker (g)</td><td>7.0</td></tr><tr><td>Protein (g)</td><td>0.0</td></tr><tr><td>Tuz (g)</td><td>0.01</td></tr><tr><td>Yağ (g)</td><td>0.0</td></tr><tr><td>Doymuş yağ (g)</td><td>0.0</td></tr></tbody></table></div><div>İçindekiler: Su, şeker, karbondioksit.</div></body></html>`,
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    const applied = applyMigrosSuggestions(candidate);
    expect(applied.nutrition_basis).toBe("100ml");
    expect(applied.category).toBe("Gazlı İçecek");
    expect(applied.issue_list.some((item) => item.code === "nutrition_basis_missing")).toBe(false);
    expect(applied.issue_list.some((item) => item.code === "category_missing")).toBe(false);
  });

  it("keeps nutrition_missing when no endpoint and no visible table are found", () => {
    const candidate = parseMigrosProductHtml(
      "<html><head><meta property='og:title' content='Pepsi 330 ml' /></head><body><div>Besin Değerleri sekmesi</div></body></html>",
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    );
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(true);
    expect(candidate.raw_payload?.discovered_endpoint_candidates).toEqual([]);
    expect(candidate.raw_payload?.has_nutrition_in_endpoint).toBe(false);
  });

  it("adds requested nutrition debug metadata without exposing raw html", () => {
    const candidate = parseMigrosProductHtml(
      dirtyHtmlFixture,
      "https://www.migros.com.tr/icecek/pepsi-kola-kutu-p-abc123",
    );
    expect(candidate.raw_payload?.has_besin_degerleri_text).toBe(true);
    expect(candidate.raw_payload?.has_energy_text).toBe(false);
    expect(candidate.raw_payload?.has_embedded_json_candidates).toBe(false);
    expect(Array.isArray(candidate.raw_payload?.possible_nutrition_keys_found)).toBe(true);
  });
});
