import { inferProductFinderCategorySuggestion } from "@/lib/admin/product-finder/category-suggestions";
import { parseQuantityFromText } from "@/lib/admin/product-finder/identity";
import type { SourceCandidate } from "@/lib/admin/product-finder/providers";
import type { ProductFinderIssue } from "@/lib/admin/product-finder/types";
import { parseNumeric, safeString } from "@/lib/admin/imports/helpers";

type MigrosSuggestionPayload = {
  nutrition_basis_suggestion?: "100g" | "100ml" | null;
  nutrition_basis_suggestion_reason?: string | null;
  category_suggestion?: string | null;
  category_suggestion_reason?: string | null;
  category_suggestion_confidence?: "high" | "medium" | null;
};

type MigrosParsedData = {
  productName: string | null;
  brand: string | null;
  category: string | null;
  ingredients: string | null;
  nutritionBasis: "100g" | "100ml" | null;
  nutritionBasisSourceText: string | null;
  nutrition: Partial<
    Pick<
      SourceCandidate,
      | "energy_kcal_100g"
      | "energy_kj_100g"
      | "fat_100g"
      | "saturated_fat_100g"
      | "carbohydrates_100g"
      | "sugars_100g"
      | "fiber_100g"
      | "protein_100g"
      | "salt_100g"
      | "sodium_100g"
    >
  >;
  imageUrl: string | null;
  sourceProductId: string | null;
  debug: {
    discovered_product_id: string | null;
    discovered_endpoint_candidates: string[];
    nutrition_endpoint_used: string | null;
    nutrition_endpoint_status: number | null;
    has_nutrition_in_endpoint: boolean;
    has_json_ld: boolean;
    has_embedded_product_json: boolean;
    has_nutrition_text: boolean;
    has_besin_degerleri_text: boolean;
    has_energy_text: boolean;
    has_nutrition_like_numbers: boolean;
    has_embedded_json_candidates: boolean;
    has_ingredients_text: boolean;
    suspected_client_side_nutrition: boolean;
    possible_nutrition_keys_found: string[];
  };
  discardedDirtyFields: string[];
};

const DIRTY_FIELD_PATTERNS = [
  /</,
  />/,
  /class=/i,
  /aria-/i,
  /\bmat-/i,
  /<!--/,
  /link\s+rel=/i,
] as const;

function createIssue(
  code: ProductFinderIssue["code"],
  message: string,
  severity: ProductFinderIssue["severity"] = "warning",
): ProductFinderIssue {
  return { code, message, severity };
}

export function validateMigrosProductUrl(url: string) {
  try {
    const parsed = new URL(url);
    const hostname = parsed.hostname.toLowerCase();
    if (!hostname.endsWith("migros.com.tr")) {
      return null;
    }
    if (!parsed.pathname || parsed.pathname === "/") {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function decodeHtml(value: string) {
  return value
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&#39;/g, "'")
    .replace(/&uuml;/g, "ü")
    .replace(/&Uuml;/g, "Ü")
    .replace(/&ouml;/g, "ö")
    .replace(/&Ouml;/g, "Ö")
    .replace(/&ccedil;/g, "ç")
    .replace(/&Ccedil;/g, "Ç")
    .replace(/&#287;/g, "ğ")
    .replace(/&#304;/g, "İ")
    .replace(/&#305;/g, "ı")
    .replace(/&nbsp;/g, " ");
}

function removeCommentsScriptsAndStyles(html: string) {
  return html
    .replace(/<!--[\s\S]*?-->/g, " ")
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ");
}

function stripTags(value: string) {
  return decodeHtml(value).replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

function sanitizeVisibleText(html: string) {
  return stripTags(removeCommentsScriptsAndStyles(html));
}

function extractScriptContents(html: string) {
  return [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)]
    .map((match) => decodeHtml(match[1] ?? ""))
    .filter(Boolean);
}

function extractJsonScripts(html: string) {
  return [...html.matchAll(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
    .map((match) => match[1])
    .filter(Boolean);
}

function tryParseJson<T = unknown>(value: string): T | null {
  try {
    return JSON.parse(value) as T;
  } catch {
    return null;
  }
}

function flattenJsonLdProducts(value: unknown): Array<Record<string, unknown>> {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value.flatMap((item) => flattenJsonLdProducts(item));
  }
  if (typeof value === "object") {
    const record = value as Record<string, unknown>;
    if (record["@type"] === "Product") return [record];
    if (record["@graph"]) return flattenJsonLdProducts(record["@graph"]);
  }
  return [];
}

function matchMetaContent(html: string, key: string) {
  const regex = new RegExp(
    `<meta[^>]+(?:property|name)=["']${key}["'][^>]+content=["']([^"']+)["'][^>]*>`,
    "i",
  );
  return safeString(regex.exec(html)?.[1] ?? "");
}

function matchFirst(value: string, regex: RegExp) {
  return safeString(regex.exec(value)?.[1] ?? "");
}

function parseNutritionBasis(text: string) {
  const normalized = text.toLowerCase();
  if (/\b100\s*g\s*\/\s*ml\b/.test(normalized)) return null;
  if (/\b100\s*(g|gr)\b/.test(normalized)) return "100g" as const;
  if (/\b100\s*ml\b/.test(normalized)) return "100ml" as const;
  return null;
}

function looksDirty(value: string | null | undefined) {
  const text = safeString(value);
  return Boolean(text) && DIRTY_FIELD_PATTERNS.some((pattern) => pattern.test(text));
}

function cleanField(
  value: string | null | undefined,
  fieldName: string,
  discardedDirtyFields: string[],
) {
  const normalized = safeString(value);
  if (!normalized) return null;
  if (looksDirty(normalized)) {
    discardedDirtyFields.push(fieldName);
    return null;
  }
  return normalized;
}

function cleanProductTitle(value: string | null | undefined, discardedDirtyFields: string[]) {
  const cleaned = cleanField(value, "product_name", discardedDirtyFields);
  if (!cleaned) return null;
  return cleaned.replace(/\s*-\s*Migros\s*$/i, "").trim() || null;
}

function inferBrandFromName(productName: string | null) {
  const value = safeString(productName);
  if (!value) return null;
  const [first] = value.split(/\s+/);
  return first || null;
}

function extractSectionText(html: string, labels: string[]) {
  const cleanHtml = removeCommentsScriptsAndStyles(html);
  const stopTokens =
    "(Besin Değerleri|Enerji|Kullanım Önerileri|Saklama Koşulları|Alerjen|Ürün Bilgileri)";

  for (const label of labels) {
    const pattern = new RegExp(
      `${label}[\\s\\S]{0,80}?(?:<[^>]*>)?[:：]?(?:<[^>]*>)?([\\s\\S]{0,1200}?)${stopTokens}`,
      "i",
    );
    const matched = pattern.exec(cleanHtml);
    const sliced = matched?.[1] ?? "";
    const stripped = stripTags(sliced).trim();
    if (stripped) return stripped;
  }

  return "";
}

function extractCleanCategory(html: string, productJson: Record<string, unknown> | undefined, discardedDirtyFields: string[]) {
  const jsonCategory = cleanField(
    safeString((productJson?.category as string | undefined) ?? ""),
    "category",
    discardedDirtyFields,
  );
  if (jsonCategory) return jsonCategory;

  const breadcrumbText = matchMetaContent(html, "og:category");
  const cleanedMeta = cleanField(breadcrumbText, "category", discardedDirtyFields);
  if (cleanedMeta) return cleanedMeta;

  const visible = extractSectionText(html, ["Kategori", "Category"]);
  const cleanedVisible = cleanField(visible, "category", discardedDirtyFields);
  return cleanedVisible;
}

function parseNutritionFromText(text: string) {
  const basis = parseNutritionBasis(text);
  const labeledValue = (labelPattern: string) =>
    `${labelPattern}[\"']?\\s*[:=]?\\s*[\"']?(-?\\d+(?:[\\.,]\\d+)?)`;

  const metric = (patterns: string[]) => {
    for (const pattern of patterns) {
      const matched = parseNumeric(matchFirst(text, new RegExp(pattern, "i")));
      if (matched != null) return matched;
    }
    return null;
  };

  return {
    basis,
    nutrition: {
      energy_kcal_100g: metric([
        `Enerji[^\\d]{0,20}kcal[^\\d-]{0,20}(-?\\d+(?:[\\.,]\\d+)?)`,
        `Enerji\\s*kcal\\s*[:=]?\\s*(-?\\d+(?:[\\.,]\\d+)?)`,
        `Enerji[^\\d]{0,20}(-?\\d+(?:[\\.,]\\d+)?)\\s*kcal`,
      ]),
      energy_kj_100g: metric([
        `Enerji[^\\d]{0,20}kJ[^\\d-]{0,20}(-?\\d+(?:[\\.,]\\d+)?)`,
        `Enerji\\s*kJ\\s*[:=]?\\s*(-?\\d+(?:[\\.,]\\d+)?)`,
        `Enerji[^\\d]{0,20}(-?\\d+(?:[\\.,]\\d+)?)\\s*kJ`,
      ]),
      fat_100g: metric([labeledValue(`Yağ`)]),
      saturated_fat_100g: metric([labeledValue(`Doymuş\\s*Yağ`)]),
      carbohydrates_100g: metric([labeledValue(`Karbonhidrat`)]),
      sugars_100g: metric([labeledValue(`Şeker(?:ler)?`)]),
      fiber_100g: metric([labeledValue(`Lif`)]),
      protein_100g: metric([labeledValue(`Protein`)]),
      salt_100g: metric([labeledValue(`Tuz`)]),
      sodium_100g: metric([labeledValue(`Sodyum`)]),
    },
  };
}

function findNutritionKeys(text: string) {
  const keyPatterns = [
    ["nutrition", /\bnutrition\b/i],
    ["besin", /\bbesin\b/i],
    ["besin_degerleri", /besin\s*değerleri/i],
    ["nutrition_facts", /nutrition[_\s-]*facts/i],
    ["energy", /\benerji\b/i],
    ["sugars", /şekerler|şeker/i],
    ["carbohydrates", /karbonhidrat/i],
    ["protein", /protein/i],
    ["salt", /\btuz\b/i],
    ["sodium", /sodyum/i],
    ["fat", /\byağ\b/i],
    ["saturated_fat", /doymuş\s*yağ/i],
    ["fiber", /\blif\b/i],
    ["100g", /\b100\s*(g|gr)\b/i],
    ["100ml", /\b100\s*ml\b/i],
  ] as const;

  return keyPatterns
    .filter(([, pattern]) => pattern.test(text))
    .map(([key]) => key);
}

function extractNutritionTableRows(html: string) {
  const panelMatch = html.match(
    /<div class="desktop-only nutrition-wrapper">([\s\S]*?)<\/table>/i,
  );
  const tableHtml = panelMatch?.[1] ? `${panelMatch[1]}</table>` : "";
  if (!tableHtml) {
    return { basisText: null as string | null, rows: [] as Array<{ key: string; value: string }> };
  }

  const headerMatch = tableHtml.match(
    /<th[^>]*class="[^"]*column-value[^"]*"[^>]*>[\s\S]*?<span[^>]*>([\s\S]*?)<\/span>/i,
  );
  const basisText = headerMatch ? stripTags(headerMatch[1]) : null;

  const rows = [...tableHtml.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)]
    .map((match) => {
      const cells = [...match[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((cell) => stripTags(cell[1]));
      if (cells.length < 2) return null;
      return { key: safeString(cells[0]), value: safeString(cells[1]) };
    })
    .filter((row): row is { key: string; value: string } => Boolean(row?.key && row?.value));

  return { basisText, rows };
}

function parseNutritionFromTableRows(rows: Array<{ key: string; value: string }>, basisText: string | null) {
  const valueFor = (pattern: RegExp) => {
    const row = rows.find((entry) => pattern.test(entry.key));
    return row ? parseNumeric(row.value) : null;
  };

  return {
    basis: parseNutritionBasis(basisText ?? ""),
    nutrition: {
      energy_kcal_100g: valueFor(/Enerji\s*\(kcal\)/i),
      energy_kj_100g: valueFor(/Enerji\s*\(kJ\)/i),
      fat_100g: valueFor(/^Yağ\s*\(g\)$/i),
      saturated_fat_100g: valueFor(/Doymuş\s*yağ\s*\(g\)/i),
      carbohydrates_100g: valueFor(/Karbonhidrat\s*\(g\)/i),
      sugars_100g: valueFor(/Şeker\s*\(g\)|Şekerler\s*\(g\)/i),
      fiber_100g: valueFor(/Lif\s*\(g\)/i),
      protein_100g: valueFor(/Protein\s*\(g\)/i),
      salt_100g: valueFor(/Tuz\s*\(g\)/i),
      sodium_100g: valueFor(/Sodyum\s*\(g|mg\)/i),
    },
  };
}

function inferNutritionBasisSuggestion(args: {
  quantityUnit: string | null;
  hasNutrition: boolean;
  nutritionBasis: "100g" | "100ml" | null;
  basisSourceText: string | null;
}) {
  const unit = safeString(args.quantityUnit).toLowerCase();
  const basisText = safeString(args.basisSourceText).toLowerCase();
  if (!args.hasNutrition || args.nutritionBasis) return null;
  if (!/\b100\s*g\s*\/\s*ml\b/.test(basisText)) return null;

  if (unit === "ml" || unit === "l") {
    return {
      value: "100ml" as const,
      reason: "Kaynak başlığı 100 g / ml ve ürün miktar birimi sıvı (ml/l).",
    };
  }

  if (unit === "g" || unit === "kg") {
    return {
      value: "100g" as const,
      reason: "Kaynak başlığı 100 g / ml ve ürün miktar birimi katı (g/kg).",
    };
  }

  return null;
}

function parseSourceProductId(url: URL, html: string) {
  const pathname = url.pathname;
  const slugMatch = pathname.match(/-p-([a-z0-9-]+)/i) ?? pathname.match(/\/([^/]+)$/);
  const dataSku = matchFirst(html, /(?:sku|productId|productCode)["']?\s*[:=]\s*["']?([A-Za-z0-9_-]+)/i);
  return safeString(dataSku || slugMatch?.[1] || "");
}

function hasAnyNutritionValues(nutrition: MigrosParsedData["nutrition"]) {
  return Object.values(nutrition).some((value) => value != null);
}

function parseMigrosHtml(html: string, url: URL): MigrosParsedData {
  const discardedDirtyFields: string[] = [];
  const jsonLdScripts = extractJsonScripts(html);
  const jsonLdProducts = jsonLdScripts
    .map((script) => tryParseJson(script))
    .flatMap((parsed) => flattenJsonLdProducts(parsed));

  const productJson = jsonLdProducts[0];
  const productName = cleanProductTitle(
    safeString((productJson?.name as string | undefined) ?? "") ||
      matchMetaContent(html, "og:title") ||
      matchFirst(html, /<title>([^<]+)<\/title>/i),
    discardedDirtyFields,
  );

  const brand = cleanField(
    safeString(
      typeof productJson?.brand === "object"
        ? ((productJson.brand as Record<string, unknown>)?.name as string | undefined)
        : ((productJson?.brand as string | undefined) ?? ""),
    ) || inferBrandFromName(productName),
    "brand",
    discardedDirtyFields,
  );

  const imageFromJson =
    typeof productJson?.image === "string"
      ? productJson.image
      : Array.isArray(productJson?.image)
        ? safeString(productJson?.image[0] as string)
        : "";

  const category = extractCleanCategory(html, productJson, discardedDirtyFields);
  const ingredients = cleanField(
    extractSectionText(html, ["İçindekiler", "İçerik", "Ürün İçeriği"]) || null,
    "ingredients",
    discardedDirtyFields,
  );

  const visibleText = sanitizeVisibleText(html);
  const scriptContents = extractScriptContents(html);
  const embeddedProductJson = scriptContents.find((script) =>
    /product|nutrition|besin|ingredients|icerik/i.test(script),
  );
  const embeddedText = sanitizeVisibleText(scriptContents.join(" "));

  const visibleNutrition = parseNutritionFromText(visibleText);
  const embeddedNutrition = parseNutritionFromText(embeddedText);
  const nutritionTable = extractNutritionTableRows(html);
  const tableNutrition = parseNutritionFromTableRows(
    nutritionTable.rows,
    nutritionTable.basisText,
  );
  const discoveredProductId = parseSourceProductId(url, html) || null;

  const hasVisibleNutritionText = /(Besin Değerleri|Enerji|Karbonhidrat|Protein|Tuz|Şeker)/i.test(visibleText);
  const hasEmbeddedNutritionText = /(Besin Değerleri|Enerji|Karbonhidrat|Protein|Tuz|Şeker)/i.test(embeddedText);
  const hasBesinDegerleriText = /Besin\s*Değerleri/i.test(visibleText) || /Besin\s*Değerleri/i.test(embeddedText);
  const hasEnergyText = /\bEnerji\b/i.test(visibleText) || /\bEnerji\b/i.test(embeddedText);
  const hasNutritionLikeNumbers =
    /(?:Enerji|Karbonhidrat|Protein|Tuz|Şeker(?:ler)?|Yağ|Doymuş\s*yağ|Sodyum|Lif)[^\d]{0,20}\d+(?:[\.,]\d+)?/i.test(
      visibleText,
    ) ||
    /(?:Enerji|Karbonhidrat|Protein|Tuz|Şeker(?:ler)?|Yağ|Doymuş\s*yağ|Sodyum|Lif)[^\d]{0,20}\d+(?:[\.,]\d+)?/i.test(
      embeddedText,
    );
  const possibleNutritionKeysFound = Array.from(
    new Set([...findNutritionKeys(visibleText), ...findNutritionKeys(embeddedText)]),
  );
  const hasEmbeddedJsonCandidates =
    jsonLdScripts.length > 0 ||
    scriptContents.some((script) => /product|nutrition|besin|ingredients|icerik|attributes|properties/i.test(script));

  const chosenNutrition = hasAnyNutritionValues(tableNutrition.nutrition)
    ? tableNutrition
    : hasAnyNutritionValues(embeddedNutrition.nutrition) || embeddedNutrition.basis
      ? embeddedNutrition
      : visibleNutrition;
  const chosenHasValues = hasAnyNutritionValues(chosenNutrition.nutrition);
  const normalizedNutritionBasis = chosenHasValues ? chosenNutrition.basis : null;

  return {
    productName,
    brand,
    category,
    ingredients,
    nutritionBasis: normalizedNutritionBasis,
    nutritionBasisSourceText: nutritionTable.basisText,
    nutrition: chosenNutrition.nutrition,
    imageUrl: cleanField(
      safeString(imageFromJson || matchMetaContent(html, "og:image")) || null,
      "image_front_url",
      discardedDirtyFields,
    ),
    sourceProductId: discoveredProductId,
    debug: {
      discovered_product_id: discoveredProductId,
      discovered_endpoint_candidates: [],
      nutrition_endpoint_used: null,
      nutrition_endpoint_status: null,
      has_nutrition_in_endpoint: false,
      has_json_ld: jsonLdScripts.length > 0,
      has_embedded_product_json: Boolean(embeddedProductJson),
      has_nutrition_text: hasVisibleNutritionText || hasEmbeddedNutritionText,
      has_besin_degerleri_text: hasBesinDegerleriText,
      has_energy_text: hasEnergyText,
      has_nutrition_like_numbers: hasNutritionLikeNumbers,
      has_embedded_json_candidates: hasEmbeddedJsonCandidates,
      has_ingredients_text: Boolean(ingredients),
      suspected_client_side_nutrition:
        !chosenHasValues &&
        (hasBesinDegerleriText ||
          hasEnergyText ||
          hasEmbeddedJsonCandidates ||
          /(Besin Değerleri|tab|accordion|mat-tab|nutrition)/i.test(html)),
      possible_nutrition_keys_found: possibleNutritionKeysFound,
    },
    discardedDirtyFields,
  };
}

export function parseMigrosProductHtml(html: string, url: string): SourceCandidate {
  const parsedUrl = validateMigrosProductUrl(url);
  if (!parsedUrl) {
    return {
      source_name: "migros",
      source_url: url,
      source_product_id: null,
      barcode: "",
      brand: null,
      product_name: null,
      quantity_value: null,
      quantity_unit: null,
      quantity_display: null,
      variant: null,
      category: null,
      ingredients: null,
      nutrition_basis: null,
      energy_kcal_100g: null,
      energy_kj_100g: null,
      fat_100g: null,
      saturated_fat_100g: null,
      carbohydrates_100g: null,
      sugars_100g: null,
      fiber_100g: null,
      protein_100g: null,
      salt_100g: null,
      sodium_100g: null,
      image_front_url: null,
      image_source_url: null,
      data_updated_at: null,
      match_confidence: 0,
      issue_list: [createIssue("source_not_found", "Geçerli bir Migros ürün URL’si gerekli.", "error")],
      raw_payload: { reason: "invalid_source_url" },
    };
  }

  const parsed = parseMigrosHtml(html, parsedUrl);
  const quantity = parseQuantityFromText(parsed.productName);
  const issues: ProductFinderIssue[] = [];

  if (!parsed.brand) issues.push(createIssue("brand_missing", "Marka bulunamadı."));
  if (!quantity) issues.push(createIssue("quantity_missing", "Miktar bilgisi bulunamadı."));
  if (!parsed.ingredients) {
    issues.push(createIssue("ingredients_missing", "İçindekiler bilgisi bulunamadı."));
  }
  if (!parsed.category) {
    issues.push(createIssue("category_missing", "Kategori güvenle ayrıştırılamadı."));
  }
  if (!parsed.nutritionBasis) {
    issues.push(createIssue("nutrition_basis_missing", "100 g / 100 ml temeli doğrulanamadı."));
  }

  const hasNutrition = hasAnyNutritionValues(parsed.nutrition);
  if (!hasNutrition) {
    issues.push(createIssue("nutrition_missing", "Besin tablosu bulunamadı."));
  }
  if (parsed.debug.suspected_client_side_nutrition && !hasNutrition) {
    issues.push(
      createIssue(
        "nutrition_may_be_client_side",
        "Besin değerleri ilk HTML içinde görünmüyor, içerik client-side yükleniyor olabilir.",
      ),
    );
  }
  if (!parsed.imageUrl) {
    issues.push(createIssue("image_missing", "Ürün görseli bulunamadı."));
  }
  if (parsed.discardedDirtyFields.length > 0) {
    issues.push(
      createIssue(
        "dirty_html_discarded",
        `Kirli HTML içeren alanlar atıldı: ${parsed.discardedDirtyFields.join(", ")}`,
      ),
    );
  }

  const confidence =
    40 +
    (parsed.productName ? 20 : 0) +
    (parsed.brand ? 10 : 0) +
    (quantity ? 10 : 0) +
    (parsed.ingredients ? 10 : 0) +
    (hasNutrition ? 10 : 0);

  if (confidence < 65) {
    issues.push(createIssue("low_match_confidence", "Migros parser güveni düşük."));
  }

  const nutritionBasisSuggestion = inferNutritionBasisSuggestion({
    quantityUnit: quantity?.quantity_unit ?? null,
    hasNutrition,
    nutritionBasis: parsed.nutritionBasis,
    basisSourceText: parsed.nutritionBasisSourceText,
  });
  const categorySuggestion = inferProductFinderCategorySuggestion({
    productName: parsed.productName,
    brand: parsed.brand,
    ingredients: parsed.ingredients,
    quantityUnit: quantity?.quantity_unit ?? null,
    currentCategory: parsed.category,
  });

  return {
    source_name: "migros",
    source_url: parsedUrl.toString(),
    source_product_id: parsed.sourceProductId,
    barcode: "",
    brand: parsed.brand,
    product_name: parsed.productName,
    quantity_value: quantity?.quantity_value ?? null,
    quantity_unit: quantity?.quantity_unit ?? null,
    quantity_display:
      quantity?.quantity_value != null && quantity.quantity_unit
        ? `${quantity.quantity_value} ${quantity.quantity_unit}`
        : null,
    variant: null,
    category: parsed.category,
    ingredients: parsed.ingredients,
    nutrition_basis: parsed.nutritionBasis,
    energy_kcal_100g: parsed.nutrition.energy_kcal_100g ?? null,
    energy_kj_100g: parsed.nutrition.energy_kj_100g ?? null,
    fat_100g: parsed.nutrition.fat_100g ?? null,
    saturated_fat_100g: parsed.nutrition.saturated_fat_100g ?? null,
    carbohydrates_100g: parsed.nutrition.carbohydrates_100g ?? null,
    sugars_100g: parsed.nutrition.sugars_100g ?? null,
    fiber_100g: parsed.nutrition.fiber_100g ?? null,
    protein_100g: parsed.nutrition.protein_100g ?? null,
    salt_100g: parsed.nutrition.salt_100g ?? null,
    sodium_100g: parsed.nutrition.sodium_100g ?? null,
    image_front_url: parsed.imageUrl,
    image_source_url: parsed.imageUrl,
    data_updated_at: new Date().toISOString().slice(0, 10),
    match_confidence: Math.min(100, confidence),
    issue_list: issues,
    raw_payload: {
      source: "migros_single_url_parser",
      source_product_id: parsed.sourceProductId,
      nutrition_basis_suggestion: nutritionBasisSuggestion?.value ?? null,
      nutrition_basis_suggestion_reason: nutritionBasisSuggestion?.reason ?? null,
      category_suggestion: categorySuggestion?.value ?? null,
      category_suggestion_reason: categorySuggestion?.reason ?? null,
      category_suggestion_confidence: categorySuggestion?.confidence ?? null,
      discovered_product_id: parsed.debug.discovered_product_id,
      discovered_endpoint_candidates: parsed.debug.discovered_endpoint_candidates,
      nutrition_endpoint_used: parsed.debug.nutrition_endpoint_used,
      nutrition_endpoint_status: parsed.debug.nutrition_endpoint_status,
      has_nutrition_in_endpoint: parsed.debug.has_nutrition_in_endpoint,
      has_json_ld: parsed.debug.has_json_ld,
      has_embedded_product_json: parsed.debug.has_embedded_product_json,
      has_nutrition_text: parsed.debug.has_nutrition_text,
      has_besin_degerleri_text: parsed.debug.has_besin_degerleri_text,
      has_energy_text: parsed.debug.has_energy_text,
      has_nutrition_like_numbers: parsed.debug.has_nutrition_like_numbers,
      has_embedded_json_candidates: parsed.debug.has_embedded_json_candidates,
      has_ingredients_text: parsed.debug.has_ingredients_text,
      suspected_client_side_nutrition: parsed.debug.suspected_client_side_nutrition,
      possible_nutrition_keys_found: parsed.debug.possible_nutrition_keys_found,
    },
  };
}

export function applyMigrosSuggestions(candidate: SourceCandidate): SourceCandidate {
  const payload =
    candidate.raw_payload && typeof candidate.raw_payload === "object"
      ? (candidate.raw_payload as MigrosSuggestionPayload)
      : {};

  const nextNutritionBasis =
    candidate.nutrition_basis ??
    (payload.nutrition_basis_suggestion === "100g" ||
    payload.nutrition_basis_suggestion === "100ml"
      ? payload.nutrition_basis_suggestion
      : null);
  const nextCategory = candidate.category ?? payload.category_suggestion ?? null;

  return {
    ...candidate,
    nutrition_basis: nextNutritionBasis,
    category: nextCategory,
    issue_list: candidate.issue_list.filter((issue) => {
      if (issue.code === "nutrition_basis_missing" && nextNutritionBasis) return false;
      if (issue.code === "category_missing" && nextCategory) return false;
      return true;
    }),
  };
}

export async function fetchMigrosProductByUrl(url: string): Promise<SourceCandidate> {
  const parsedUrl = validateMigrosProductUrl(url);
  if (!parsedUrl) {
    return parseMigrosProductHtml("", url);
  }

  // Single explicit admin URL only. No loops, no category crawling, no bulk requests.
  const response = await fetch(parsedUrl.toString(), {
    method: "GET",
    headers: {
      "User-Agent": "LabelWiseAdminProductFinder/1.0",
      Accept: "text/html,application/xhtml+xml",
    },
    cache: "no-store",
  });

  if (!response.ok) {
    return {
      source_name: "migros",
      source_url: parsedUrl.toString(),
      source_product_id: null,
      barcode: "",
      brand: null,
      product_name: null,
      quantity_value: null,
      quantity_unit: null,
      quantity_display: null,
      variant: null,
      category: null,
      ingredients: null,
      nutrition_basis: null,
      energy_kcal_100g: null,
      energy_kj_100g: null,
      fat_100g: null,
      saturated_fat_100g: null,
      carbohydrates_100g: null,
      sugars_100g: null,
      fiber_100g: null,
      protein_100g: null,
      salt_100g: null,
      sodium_100g: null,
      image_front_url: null,
      image_source_url: null,
      data_updated_at: null,
      match_confidence: 0,
      issue_list: [createIssue("source_not_found", "Migros ürün sayfası alınamadı.", "error")],
      raw_payload: { status: response.status },
    };
  }

  const html = await response.text();
  return parseMigrosProductHtml(html, parsedUrl.toString());
}
