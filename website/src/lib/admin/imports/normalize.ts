import "server-only";

import {
  normalizedDataSources,
  placeholderIngredientValues,
} from "@/lib/admin/imports/constants";
import {
  compactSpaces,
  normalizeWhitespace,
  parseBarcode,
  parseBoolean,
  parseDateInput,
  parseNumeric,
  safeString,
} from "@/lib/admin/imports/helpers";
import type { ImportRowInput, ParsedImportRow } from "@/lib/admin/imports/types";

const aliases: Record<string, string> = {
  barcode: "barcode",
  barkod: "barcode",
  product_name: "product_name",
  name: "product_name",
  urun_adi: "product_name",
  urunadı: "product_name",
  brand: "brand",
  marka: "brand",
  category: "category",
  kategori: "category",
  ingredients: "ingredients",
  ingredients_text: "ingredients",
  icerikler: "ingredients",
  icerik: "ingredients",
  quantity_value: "quantity_value",
  quantity_unit: "quantity_unit",
  serving_size: "serving_size",
  energy_kcal_100g: "energy_kcal_100g",
  energy_kj_100g: "energy_kj_100g",
  fat_100g: "fat_100g",
  saturated_fat_100g: "saturated_fat_100g",
  carbohydrates_100g: "carbohydrates_100g",
  sugars_100g: "sugars_100g",
  fiber_100g: "fiber_100g",
  protein_100g: "protein_100g",
  salt_100g: "salt_100g",
  sodium_100g: "sodium_100g",
  image_front_url: "image_front_url",
  data_source: "data_source",
  source_url: "source_url",
  data_updated_at: "data_updated_at",
  packaging_version: "packaging_version",
  is_current: "is_current",
  verification_notes: "verification_notes",
  country: "country",
  language_code: "language_code",
  external_id: "external_id",
  notes: "notes",
  is_verified: "is_verified",
  import_action: "import_action",
};

function readField(source: Record<string, unknown>, ...keys: string[]) {
  for (const [rawKey, value] of Object.entries(source)) {
    const normalizedKey = aliases[rawKey.trim().toLowerCase()] ?? rawKey.trim().toLowerCase();
    if (keys.includes(normalizedKey)) {
      return value;
    }
  }
  return null;
}

function normalizeIngredients(value: unknown) {
  const normalized = normalizeWhitespace(safeString(value));
  if (!normalized) {
    return null;
  }

  if (placeholderIngredientValues.has(normalized.toLowerCase())) {
    return normalized;
  }

  return normalized;
}

function normalizeDataSource(value: unknown) {
  const normalized = safeString(value).toLowerCase().replace(/\s+/g, "_");
  if (!normalized) return null;
  return normalizedDataSources.has(normalized) ? normalized : normalized;
}

function normalizeImportAction(value: unknown): "upsert" | "insert" | "update" {
  const normalized = safeString(value).toLowerCase();
  if (normalized === "insert") return "insert";
  if (normalized === "update") return "update";
  return "upsert";
}

function normalizeDate(value: unknown) {
  const date = parseDateInput(value);
  return date ? date.toISOString() : safeString(value) || null;
}

function normalizeText(value: unknown) {
  const text = compactSpaces(safeString(value));
  return text || null;
}

function normalizeNutritionNested(source: Record<string, unknown>, field: string) {
  const nested = source.nutrition_100g;
  if (!nested || typeof nested !== "object" || Array.isArray(nested)) {
    return null;
  }
  return (nested as Record<string, unknown>)[field] ?? null;
}

export function normalizeImportRow(row: ParsedImportRow): ImportRowInput {
  const source = row.source;

  return {
    barcode: parseBarcode(readField(source, "barcode")) || null,
    productName: normalizeText(readField(source, "product_name")),
    brand: normalizeText(readField(source, "brand")),
    category: normalizeText(readField(source, "category")),
    ingredients: normalizeIngredients(readField(source, "ingredients")),
    quantityValue: parseNumeric(readField(source, "quantity_value")),
    quantityUnit: normalizeText(readField(source, "quantity_unit")),
    servingSize: normalizeText(readField(source, "serving_size")),
    energyKcal100g:
      parseNumeric(readField(source, "energy_kcal_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "energy_kcal_100g")),
    energyKj100g:
      parseNumeric(readField(source, "energy_kj_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "energy_kj_100g")),
    fat100g:
      parseNumeric(readField(source, "fat_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "fat_100g")),
    saturatedFat100g:
      parseNumeric(readField(source, "saturated_fat_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "saturated_fat_100g")),
    carbohydrates100g:
      parseNumeric(readField(source, "carbohydrates_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "carbohydrates_100g")),
    sugars100g:
      parseNumeric(readField(source, "sugars_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "sugars_100g")),
    fiber100g:
      parseNumeric(readField(source, "fiber_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "fiber_100g")),
    protein100g:
      parseNumeric(readField(source, "protein_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "protein_100g")),
    salt100g:
      parseNumeric(readField(source, "salt_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "salt_100g")),
    sodium100g:
      parseNumeric(readField(source, "sodium_100g")) ??
      parseNumeric(normalizeNutritionNested(source, "sodium_100g")),
    imageFrontUrl: normalizeText(readField(source, "image_front_url")),
    dataSource: normalizeDataSource(readField(source, "data_source")),
    sourceUrl: normalizeText(readField(source, "source_url")),
    dataUpdatedAt: normalizeDate(readField(source, "data_updated_at")),
    packagingVersion: normalizeText(readField(source, "packaging_version")),
    isCurrent: parseBoolean(readField(source, "is_current"), true),
    verificationNotes: normalizeText(readField(source, "verification_notes")),
    country: normalizeText(readField(source, "country")) ?? "TR",
    languageCode: normalizeText(readField(source, "language_code")) ?? "tr",
    externalId: normalizeText(readField(source, "external_id")),
    notes: normalizeText(readField(source, "notes")),
    isVerified: parseBoolean(readField(source, "is_verified"), false),
    importAction: normalizeImportAction(readField(source, "import_action")),
  };
}
