import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";
import { parseBoolean, parseNumeric, safeString } from "@/lib/admin/imports/helpers";
import { importTemplateHeaders } from "@/lib/admin/imports/constants";

function createCandidateId(barcode: string) {
  return `finder-${barcode}`;
}

export function createMockCandidate(barcode: string): ProductFinderCandidate {
  const today = new Date().toISOString().slice(0, 10);

  return {
    id: createCandidateId(barcode),
    barcode,
    product_name: "",
    brand: "",
    category: "",
    ingredients: "",
    quantity_value: null,
    quantity_unit: "",
    serving_size: "",
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
    image_front_url: "",
    data_source: "product_finder",
    source_url: "",
    data_updated_at: today,
    packaging_version: "",
    is_current: true,
    verification_notes: "",
    country: "TR",
    language_code: "tr",
    external_id: "",
    notes: "",
    is_verified: false,
    import_action: "upsert",
    status: "needs_review",
    data_quality_status: "needs_review",
    ingredients_status: "missing",
    issue_list: [],
    approved_for_export: false,
    rejected_reason: "",
    edited_fields: [],
    nutrition_basis: null,
    match_confidence: null,
    category_suggestion: null,
    category_suggestion_reason: "",
    category_suggestion_confidence: null,
    nutrition_basis_suggestion: null,
    nutrition_basis_suggestion_reason: "",
    nutrition_table_not_available: false,
  };
}

type ImportTemplateRow = Partial<Record<(typeof importTemplateHeaders)[number], unknown>>;

export function createHydratedCandidateFromImportRow(
  row: ImportTemplateRow,
): ProductFinderCandidate {
  const base = createMockCandidate(safeString(row.barcode));

  return {
    ...base,
    product_name: safeString(row.product_name),
    brand: safeString(row.brand),
    category: safeString(row.category),
    ingredients: safeString(row.ingredients),
    quantity_value: parseNumeric(row.quantity_value),
    quantity_unit: safeString(row.quantity_unit),
    serving_size: safeString(row.serving_size),
    energy_kcal_100g: parseNumeric(row.energy_kcal_100g),
    energy_kj_100g: parseNumeric(row.energy_kj_100g),
    fat_100g: parseNumeric(row.fat_100g),
    saturated_fat_100g: parseNumeric(row.saturated_fat_100g),
    carbohydrates_100g: parseNumeric(row.carbohydrates_100g),
    sugars_100g: parseNumeric(row.sugars_100g),
    fiber_100g: parseNumeric(row.fiber_100g),
    protein_100g: parseNumeric(row.protein_100g),
    salt_100g: parseNumeric(row.salt_100g),
    sodium_100g: parseNumeric(row.sodium_100g),
    image_front_url: safeString(row.image_front_url),
    data_source: safeString(row.data_source) || base.data_source,
    source_url: safeString(row.source_url),
    data_updated_at: safeString(row.data_updated_at) || base.data_updated_at,
    packaging_version: safeString(row.packaging_version),
    is_current: parseBoolean(row.is_current, true),
    verification_notes: safeString(row.verification_notes),
    country: safeString(row.country) || base.country,
    language_code: safeString(row.language_code) || base.language_code,
    external_id: safeString(row.external_id),
    notes: safeString(row.notes),
    is_verified: parseBoolean(row.is_verified, false),
    import_action:
      safeString(row.import_action) === "insert" ||
      safeString(row.import_action) === "update"
        ? (safeString(row.import_action) as "insert" | "update")
        : "upsert",
  };
}
