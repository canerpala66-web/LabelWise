import type { SourceCandidate } from "@/lib/admin/product-finder/providers";
import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";
import { createMockCandidate } from "@/lib/admin/product-finder/mock";
import { revalidateCandidate } from "@/lib/admin/product-finder/validation";

type MapSourceCandidateOptions = {
  candidateId?: string;
};

export function mapSourceCandidateToProductFinderCandidate(
  sourceCandidate: SourceCandidate,
  options: MapSourceCandidateOptions = {},
): ProductFinderCandidate {
  const today = new Date().toISOString().slice(0, 10);
  const base = createMockCandidate(sourceCandidate.barcode || "");

  return revalidateCandidate({
    ...base,
    id: options.candidateId ?? base.id,
    barcode: sourceCandidate.barcode || "",
    product_name: sourceCandidate.product_name ?? "",
    brand: sourceCandidate.brand ?? "",
    category: sourceCandidate.category ?? "",
    ingredients: sourceCandidate.ingredients ?? "",
    quantity_value: sourceCandidate.quantity_value ?? null,
    quantity_unit: sourceCandidate.quantity_unit ?? "",
    serving_size: sourceCandidate.quantity_display ?? "",
    energy_kcal_100g: sourceCandidate.energy_kcal_100g ?? null,
    energy_kj_100g: sourceCandidate.energy_kj_100g ?? null,
    fat_100g: sourceCandidate.fat_100g ?? null,
    saturated_fat_100g: sourceCandidate.saturated_fat_100g ?? null,
    carbohydrates_100g: sourceCandidate.carbohydrates_100g ?? null,
    sugars_100g: sourceCandidate.sugars_100g ?? null,
    fiber_100g: sourceCandidate.fiber_100g ?? null,
    protein_100g: sourceCandidate.protein_100g ?? null,
    salt_100g: sourceCandidate.salt_100g ?? null,
    sodium_100g: sourceCandidate.sodium_100g ?? null,
    image_front_url: sourceCandidate.image_front_url ?? "",
    data_source: sourceCandidate.source_name || "migros",
    source_url: sourceCandidate.source_url ?? "",
    data_updated_at: sourceCandidate.data_updated_at ?? today,
    is_current: true,
    country: "TR",
    language_code: "tr",
    is_verified: false,
    import_action: "upsert",
    nutrition_basis: sourceCandidate.nutrition_basis,
    match_confidence: sourceCandidate.match_confidence ?? null,
    issue_list: sourceCandidate.issue_list,
    status: "needs_review",
    approved_for_export: false,
  });
}
