import { importTemplateHeaders } from "@/lib/admin/imports/constants";
import { appendNutritionTableNotAvailableMarker } from "@/lib/admin/product-finder/nutrition-table-flag";
import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";

export function mapCandidateToImportRow(candidate: ProductFinderCandidate) {
  return {
    barcode: candidate.barcode,
    product_name: candidate.product_name,
    brand: candidate.brand,
    category: candidate.category,
    ingredients: candidate.ingredients,
    quantity_value: candidate.quantity_value ?? "",
    quantity_unit: candidate.quantity_unit,
    serving_size: candidate.serving_size,
    energy_kcal_100g: candidate.energy_kcal_100g ?? "",
    energy_kj_100g: candidate.energy_kj_100g ?? "",
    fat_100g: candidate.fat_100g ?? "",
    saturated_fat_100g: candidate.saturated_fat_100g ?? "",
    carbohydrates_100g: candidate.carbohydrates_100g ?? "",
    sugars_100g: candidate.sugars_100g ?? "",
    fiber_100g: candidate.fiber_100g ?? "",
    protein_100g: candidate.protein_100g ?? "",
    salt_100g: candidate.salt_100g ?? "",
    sodium_100g: candidate.sodium_100g ?? "",
    image_front_url: candidate.image_front_url,
    data_source: candidate.data_source,
    source_url: candidate.source_url,
    data_updated_at: candidate.data_updated_at,
    packaging_version: candidate.packaging_version,
    is_current: candidate.is_current ? "true" : "false",
    verification_notes: candidate.nutrition_table_not_available
      ? appendNutritionTableNotAvailableMarker(candidate.verification_notes)
      : candidate.verification_notes,
    country: candidate.country,
    language_code: candidate.language_code,
    external_id: candidate.external_id,
    notes: candidate.notes,
    is_verified: candidate.is_verified ? "true" : "false",
    import_action: candidate.import_action,
  };
}

export function buildExportMatrix(candidates: ProductFinderCandidate[]) {
  const approvedRows = candidates
    .filter((item) => item.approved_for_export)
    .map(mapCandidateToImportRow);

  return [
    [...importTemplateHeaders],
    ...approvedRows.map((row) => importTemplateHeaders.map((header) => row[header] ?? "")),
  ];
}
