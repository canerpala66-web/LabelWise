import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
} as const;

const offFields = [
  "code",
  "product_name",
  "product_name_tr",
  "generic_name",
  "brands",
  "image_url",
  "ingredients_text",
  "ingredients_text_tr",
  "nutriscore_grade",
  "nutriments",
  "categories",
  "categories_tags",
  "categories_hierarchy",
].join(",");

const protectedSources = new Set(["user_submission", "labelwise_corrected"]);

type ProductRecord = {
  barcode: string;
  name: string;
  brand: string;
  image_url: string | null;
  ingredients_text: string;
  nutriscore_grade: string | null;
  source: string;
  category: string | null;
  energy_kcal: number | null;
  fat: number | null;
  saturated_fat: number | null;
  carbohydrates: number | null;
  sugars: number | null;
  fiber: number | null;
  protein: number | null;
  salt: number | null;
  fruits_vegetables_legumes_percent: number | null;
  ai_summary: string | null;
  ai_risk_level: string | null;
  ai_generated_at: string | null;
  ai_analysis_version: string | null;
  front_image_path: string | null;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function errorResponse(
  error: string,
  step: string,
  status: number,
  source = "openfoodfacts",
): Response {
  return jsonResponse(
    {
      product: null,
      cached: false,
      source,
      error,
      step,
    },
    status,
  );
}

function isValidBarcode(barcode: unknown): barcode is string {
  if (typeof barcode !== "string") return false;
  const trimmed = barcode.trim();
  if (!/^\d+$/.test(trimmed)) return false;
  return trimmed.length === 8 || trimmed.length === 12 || trimmed.length === 13;
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function numberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.trim().replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function firstText(values: unknown[]): string | null {
  for (const value of values) {
    const normalized = text(value);
    if (normalized) return normalized;
  }
  return null;
}

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function normalizeSearchText(value: string | null): string {
  if (!value) return "";
  return value
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\s&-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function inferCategory({
  productName,
  categoriesText,
  categoriesTags,
  categoriesHierarchy,
}: {
  productName: string | null;
  categoriesText: string | null;
  categoriesTags: string[];
  categoriesHierarchy: string[];
}): string {
  const haystack = [
    normalizeSearchText(productName),
    normalizeSearchText(categoriesText),
    ...categoriesTags.map(normalizeSearchText),
    ...categoriesHierarchy.map(normalizeSearchText),
  ].join(" ");

  const rules: Array<[string, string[]]> = [
    ["Cips", ["cips", "chips", "potato chips", "crisps", "doritos", "lays", "pringles", "cheetos", "ruffles"]],
    ["Kraker", ["kraker", "cracker", "pretzel", "grissini", "crax", "cizi", "cubuk kraker"]],
    ["Bisküvi", ["biskuvi", "biscuit", "cookie", "gofret", "wafer"]],
    ["Çikolata", ["cikolata", "chocolate", "kakao kaplamali"]],
    ["Şekerleme", ["sekerleme", "candy", "bonbon", "jeli", "gum"]],
    ["Kek & Tatlı", ["kek", "cake", "brownie", "muffin", "tatli"]],
    ["Gazlı İçecek", ["cola", "kola", "soft drink", "soda", "gazli icecek", "gazoz", "sprite", "fanta", "pepsi"]],
    ["Meyve Suyu", ["meyve suyu", "fruit juice", "nectar", "nektar"]],
    ["Soğuk Çay", ["soguk cay", "ice tea", "iced tea", "fuse tea", "lipton ice tea"]],
    ["Enerji İçeceği", ["enerji icecegi", "energy drink", "red bull", "monster", "burn"]],
    ["Su & Maden Suyu", ["maden suyu", "mineralli su", "water", "spring water", "icme suyu"]],
    ["Kahve", ["kahve", "coffee", "espresso", "latte", "cappuccino", "nescafe"]],
    ["Çay", ["cay", "tea", "earl grey", "yesil cay"]],
    ["Süt", ["sut", "milk", "uht milk"]],
    ["Yoğurt & Fermente Süt", ["yogurt", "yoghurt", "ayran", "kefir", "fermented milk"]],
    ["Peynir", ["peynir", "cheese", "labne", "kasar"]],
    ["Dondurma", ["dondurma", "ice cream", "gelato", "sorbe"]],
    ["İşlenmiş Et", ["salam", "sosis", "sucuk", "jambon", "processed meat", "sausage"]],
    ["Sos", ["sos", "sauce", "ketchup", "ketcap", "mayonnaise", "mayonez", "mustard"]],
    ["Sürülebilir Tatlı", ["surulebilir", "spread", "fistik ezmesi", "chocolate spread", "jam", "recel"]],
    ["Yağ", ["yag", "oil", "olive oil", "aycicek yagi", "tereyagi"]],
    ["Tahıl & Bakliyat", ["mercimek", "nohut", "fasulye", "pirinc", "bulgur", "cereal", "oat", "makarna", "pasta"]],
    ["Ekmek & Unlu Mamul", ["ekmek", "bread", "toast", "simit", "unlu mamul", "bakery"]],
    ["Hazır Yemek & Konserve", ["konserve", "canned", "hazir yemek", "ready meal", "instant soup"]],
    ["Donuk Ürün", ["donuk", "frozen", "deep frozen"]],
    ["Kuruyemiş", ["kuruyemis", "nuts", "almond", "hazelnut", "pistachio", "seed mix"]],
    ["Sporcu Ürünü", ["protein bar", "whey", "sports nutrition", "isolate"]],
    ["Bebek Gıdası", ["baby food", "bebek mamasi", "bebek gidasi"]],
    ["Baharat & Çeşni", ["baharat", "spice", "seasoning", "cesni"]],
  ];

  for (const [category, keywords] of rules) {
    if (keywords.some((keyword) => haystack.includes(normalizeSearchText(keyword)))) {
      return category;
    }
  }

  return "Belirsiz";
}

function hasUsableCachedProduct(product: Partial<ProductRecord> | null): boolean {
  if (!product) return false;
  const hasName = text(product.name) !== null;
  const hasSource = text(product.source) !== null;
  const hasNutrition = [
    product.energy_kcal,
    product.fat,
    product.saturated_fat,
    product.carbohydrates,
    product.sugars,
    product.fiber,
    product.protein,
    product.salt,
  ].some((value) => numberValue(value) !== null);
  const hasIngredients = text(product.ingredients_text) !== null;
  const hasImage = text(product.image_url) !== null;
  return hasName && hasSource && (hasNutrition || hasIngredients || hasImage);
}

function normalizeExistingProduct(row: Record<string, unknown>): ProductRecord {
  return {
    barcode: text(row.barcode) ?? "",
    name: text(row.name) ?? "Bilinmeyen Ürün",
    brand: text(row.brand) ?? "Bilinmeyen Marka",
    image_url: text(row.image_url),
    ingredients_text: text(row.ingredients_text) ?? "İçindekiler bilgisi bulunamadı",
    nutriscore_grade: text(row.nutriscore_grade),
    source: text(row.source) ?? "products",
    category: text(row.category),
    energy_kcal: numberValue(row.energy_kcal),
    fat: numberValue(row.fat),
    saturated_fat: numberValue(row.saturated_fat),
    carbohydrates: numberValue(row.carbohydrates),
    sugars: numberValue(row.sugars),
    fiber: numberValue(row.fiber),
    protein: numberValue(row.protein),
    salt: numberValue(row.salt),
    fruits_vegetables_legumes_percent: numberValue(row.fruits_vegetables_legumes_percent),
    ai_summary: text(row.ai_summary),
    ai_risk_level: text(row.ai_risk_level),
    ai_generated_at: text(row.ai_generated_at),
    ai_analysis_version: text(row.ai_analysis_version),
    front_image_path: text(row.front_image_path),
  };
}

function normalizeOffProduct(barcode: string, off: Record<string, unknown>): ProductRecord {
  const nutriments = typeof off.nutriments === "object" && off.nutriments !== null
    ? off.nutriments as Record<string, unknown>
    : {};
  const name = firstText([off.product_name_tr, off.product_name, off.generic_name]) ??
    "Bilinmeyen Ürün";
  const brand = text(off.brands) ?? "Bilinmeyen Marka";
  const ingredients = firstText([off.ingredients_text_tr, off.ingredients_text]) ??
    "İçindekiler bilgisi bulunamadı";
  const categoriesText = text(off.categories);
  const categoriesTags = normalizeStringList(off.categories_tags);
  const categoriesHierarchy = normalizeStringList(off.categories_hierarchy);

  return {
    barcode,
    name,
    brand,
    image_url: text(off.image_url),
    ingredients_text: ingredients,
    nutriscore_grade: text(off.nutriscore_grade),
    source: "openfoodfacts",
    category: inferCategory({
      productName: name,
      categoriesText,
      categoriesTags,
      categoriesHierarchy,
    }),
    energy_kcal: numberValue(nutriments["energy-kcal_100g"]),
    fat: numberValue(nutriments["fat_100g"]),
    saturated_fat: numberValue(nutriments["saturated-fat_100g"]),
    carbohydrates: numberValue(nutriments["carbohydrates_100g"]),
    sugars: numberValue(nutriments["sugars_100g"]),
    fiber: numberValue(nutriments["fiber_100g"]),
    protein: numberValue(nutriments["proteins_100g"]),
    salt: numberValue(nutriments["salt_100g"]),
    fruits_vegetables_legumes_percent: numberValue(
      nutriments["fruits-vegetables-legumes-estimate-from-ingredients_100g"],
    ),
    ai_summary: null,
    ai_risk_level: null,
    ai_generated_at: null,
    ai_analysis_version: null,
    front_image_path: null,
  };
}

function mergeProtectedFields(
  normalized: ProductRecord,
  existing: ProductRecord | null,
): ProductRecord {
  if (!existing) return normalized;

  const existingSource = (text(existing.source) ?? "").toLowerCase();
  const shouldPreserveManagedSource = protectedSources.has(existingSource);
  const existingCategory = text(existing.category);
  const hasUsefulExistingCategory = existingCategory !== null &&
    existingCategory !== "Belirsiz";

  return {
    ...normalized,
    source: shouldPreserveManagedSource ? existing.source : normalized.source,
    category:
      shouldPreserveManagedSource && hasUsefulExistingCategory
        ? existing.category
        : normalized.category === "Belirsiz" && hasUsefulExistingCategory
        ? existing.category
        : normalized.category,
    ai_summary: existing.ai_summary,
    ai_risk_level: existing.ai_risk_level,
    ai_generated_at: existing.ai_generated_at,
    ai_analysis_version: existing.ai_analysis_version,
    front_image_path: existing.front_image_path ?? normalized.front_image_path,
  };
}

async function fetchOpenFoodFactsProduct(barcode: string): Promise<Record<string, unknown> | null> {
  const url = new URL(`https://world.openfoodfacts.org/api/v2/product/${barcode}.json`);
  url.searchParams.set("fields", offFields);

  const response = await fetch(url, {
    headers: {
      "User-Agent": "LabelWise/1.0 (contact: canerpala66@gmail.com)",
    },
  });

  const data = await response.json();
  if (!data || typeof data !== "object") {
    throw new Error("OFF response invalid");
  }

  const status = (data as Record<string, unknown>).status;
  const product = (data as Record<string, unknown>).product;
  if (!response.ok && !(status === 0 || status === "0")) {
    throw new Error(`OFF request failed (${response.status})`);
  }
  if (status === 0 || status === "0" || !product || typeof product !== "object") {
    return null;
  }

  return product as Record<string, unknown>;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Method not allowed", "method_check", 405);
  }

  console.log("function_start");

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid request body", "parse_body", 400);
  }

  const barcode = body.barcode;
  const forceRefresh = body.force_refresh === true;
  if (!isValidBarcode(barcode)) {
    return errorResponse("Invalid barcode", "validate_barcode", 400, "openfoodfacts");
  }

  const trimmedBarcode = barcode.trim();
  console.log(`barcode_validated barcode=${trimmedBarcode} force_refresh=${forceRefresh}`);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Server configuration missing", "env_check", 500);
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let existingProduct: ProductRecord | null = null;
  try {
    const { data, error } = await client
      .from("products")
      .select(
        "barcode,name,brand,image_url,ingredients_text,nutriscore_grade,source,category,energy_kcal,fat,saturated_fat,carbohydrates,sugars,fiber,protein,salt,fruits_vegetables_legumes_percent,ai_summary,ai_risk_level,ai_generated_at,ai_analysis_version,front_image_path",
      )
      .eq("barcode", trimmedBarcode)
      .maybeSingle();

    if (error) {
      console.log(`existing_product_checked error=${error.message}`);
    } else if (data) {
      existingProduct = normalizeExistingProduct(data as Record<string, unknown>);
    }
  } catch (error) {
    console.log(`existing_product_checked exception=${String(error)}`);
  }

  console.log(`existing_product_checked found=${existingProduct !== null}`);

  if (!forceRefresh && hasUsableCachedProduct(existingProduct)) {
    console.log("returning_existing_cache");
    return jsonResponse({
      product: existingProduct,
      cached: true,
      source: existingProduct?.source ?? "products",
      force_refresh: forceRefresh,
    });
  }

  console.log("openfoodfacts_fetch_start");
  let offProduct: Record<string, unknown> | null;
  try {
    offProduct = await fetchOpenFoodFactsProduct(trimmedBarcode);
  } catch (error) {
    console.log(`openfoodfacts_fetch_error=${String(error)}`);
    return errorResponse("OpenFoodFacts request failed", "openfoodfacts_fetch", 500);
  }

  if (!offProduct) {
    return errorResponse("Product not found", "openfoodfacts_not_found", 404);
  }
  console.log("openfoodfacts_fetch_success");

  const normalized = normalizeOffProduct(trimmedBarcode, offProduct);
  console.log("product_normalized");

  const merged = mergeProtectedFields(normalized, existingProduct);
  console.log("protected_fields_merged");

  try {
    const { error } = await client
      .from("products")
      .upsert(merged, { onConflict: "barcode" });
    if (error) {
      console.log(`products_upsert_error=${error.message}`);
      return errorResponse("Products cache upsert failed", "products_upsert", 500);
    }
  } catch (error) {
    console.log(`products_upsert_exception=${String(error)}`);
    return errorResponse("Products cache upsert failed", "products_upsert", 500);
  }

  console.log("products_upsert_success");
  console.log("function_success");
  return jsonResponse({
    product: merged,
    cached: false,
    source: merged.source ?? "openfoodfacts",
    force_refresh: forceRefresh,
  });
});
