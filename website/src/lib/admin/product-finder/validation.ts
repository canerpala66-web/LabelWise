import {
  parseBarcode,
  parseBoolean,
  parseNumeric,
  safeString,
} from "@/lib/admin/imports/helpers";
import {
  appendNutritionTableNotAvailableMarker,
  hasNutritionTableNotAvailableMarker,
  removeNutritionTableNotAvailableMarker,
} from "@/lib/admin/product-finder/nutrition-table-flag";
import type {
  ProductFinderCandidate,
  ProductFinderIssue,
  ProductFinderSummary,
} from "@/lib/admin/product-finder/types";

function hasCoreNutrition(candidate: ProductFinderCandidate) {
  return [
    candidate.energy_kcal_100g,
    candidate.fat_100g,
    candidate.saturated_fat_100g,
    candidate.carbohydrates_100g,
    candidate.sugars_100g,
    candidate.protein_100g,
    candidate.salt_100g,
  ].every((value) => value != null);
}

function strictVerifiedReady(candidate: ProductFinderCandidate) {
  return (
    /^\d{8,14}$/.test(candidate.barcode) &&
    Boolean(safeString(candidate.product_name)) &&
    Boolean(safeString(candidate.brand)) &&
    candidate.quantity_value != null &&
    Boolean(safeString(candidate.quantity_unit)) &&
    Boolean(safeString(candidate.ingredients)) &&
    Boolean(candidate.nutrition_basis) &&
    hasCoreNutrition(candidate) &&
    Boolean(safeString(candidate.source_url))
  );
}

function buildIssues(candidate: ProductFinderCandidate): ProductFinderIssue[] {
  const issues: ProductFinderIssue[] = [];
  const nutritionTableNotAvailable =
    candidate.nutrition_table_not_available ||
    hasNutritionTableNotAvailableMarker(candidate.verification_notes, candidate.notes);

  if (!/^\d{8,14}$/.test(candidate.barcode)) {
    issues.push({
      code: "invalid_barcode",
      message: "Barkod geçerli formatta değil.",
      severity: "error",
    });
  }

  if (!safeString(candidate.product_name)) {
    issues.push({
      code: "name_missing",
      message: "Ürün adı eksik.",
      severity: "warning",
    });
  }

  if (!safeString(candidate.brand)) {
    issues.push({
      code: "brand_missing",
      message: "Marka eksik.",
      severity: "warning",
    });
  }

  if (candidate.quantity_value == null || !safeString(candidate.quantity_unit)) {
    issues.push({
      code: "quantity_missing",
      message: "Miktar bilgisi eksik.",
      severity: "warning",
    });
  }

  if (!safeString(candidate.ingredients)) {
    issues.push({
      code: "ingredients_missing",
      message: "İçindekiler eksik.",
      severity: "warning",
    });
  }

  if (!candidate.nutrition_basis) {
    issues.push({
      code: "nutrition_basis_missing",
      message: "Besin tablosu 100 g / 100 ml temeli doğrulanmadı.",
      severity: "warning",
    });
  }

  if (!hasCoreNutrition(candidate)) {
    if (nutritionTableNotAvailable) {
      issues.push({
        code: "nutrition_table_not_available",
        message: "Besin tablosu kaynakta/ambalajda bulunmuyor.",
        severity: "warning",
      });
    } else {
      issues.push({
        code: "nutrition_missing",
        message: "Çekirdek besin değerleri eksik.",
        severity: "warning",
      });
    }
  }

  if (!safeString(candidate.source_url)) {
    issues.push({
      code: "source_not_found",
      message: "Kaynak bağlantısı eksik.",
      severity: "warning",
    });
  }

  if (!safeString(candidate.image_front_url)) {
    issues.push({
      code: "image_missing",
      message: "Ön yüz görseli eksik.",
      severity: "warning",
    });
  }

  return issues;
}

export function revalidateCandidate(
  candidate: ProductFinderCandidate,
): ProductFinderCandidate {
  const nutritionTableNotAvailable =
    candidate.nutrition_table_not_available ||
    hasNutritionTableNotAvailableMarker(candidate.verification_notes, candidate.notes);
  const issue_list = buildIssues(candidate);
  const ingredients_status = safeString(candidate.ingredients)
    ? "present"
    : "missing";
  const strictReady = strictVerifiedReady(candidate);
  const hasNutrition = hasCoreNutrition(candidate);
  const hasInvalidBarcode = issue_list.some((item) => item.code === "invalid_barcode");
  const barcodeWasEdited = candidate.edited_fields.includes("barcode");

  const status =
    candidate.status === "rejected" && !(barcodeWasEdited && !hasInvalidBarcode)
      ? "rejected"
      : candidate.status === "approved" || candidate.status === "export_ready"
        ? hasInvalidBarcode
          ? "needs_review"
          : "export_ready"
        : hasInvalidBarcode
          ? "rejected"
          : "needs_review";

  const data_quality_status = !hasNutrition
    ? "partial"
    : ingredients_status === "missing"
      ? "verified_nutrition_only"
      : strictReady
        ? "verified_full"
        : "needs_review";

  return {
    ...candidate,
    nutrition_table_not_available: nutritionTableNotAvailable,
    verification_notes: nutritionTableNotAvailable
      ? appendNutritionTableNotAvailableMarker(candidate.verification_notes)
      : removeNutritionTableNotAvailableMarker(candidate.verification_notes),
    issue_list,
    ingredients_status,
    is_verified:
      (candidate.status === "approved" || candidate.status === "export_ready") &&
      strictReady,
    approved_for_export:
      status === "export_ready" &&
      Boolean(safeString(candidate.product_name)) &&
      Boolean(safeString(candidate.ingredients)) &&
      Boolean(safeString(candidate.data_source)) &&
      Boolean(safeString(candidate.data_updated_at)),
    status,
    data_quality_status,
  };
}

export function updateCandidateField(
  candidate: ProductFinderCandidate,
  field: keyof ProductFinderCandidate,
  value: unknown,
) {
  const next = { ...candidate };

  if (
    [
      "quantity_value",
      "energy_kcal_100g",
      "energy_kj_100g",
      "fat_100g",
      "saturated_fat_100g",
      "carbohydrates_100g",
      "sugars_100g",
      "fiber_100g",
      "protein_100g",
      "salt_100g",
      "sodium_100g",
    ].includes(field)
  ) {
    (next[field] as unknown) = parseNumeric(value);
  } else if (field === "is_current" || field === "is_verified") {
    (next[field] as unknown) = parseBoolean(value);
  } else if (field === "nutrition_table_not_available") {
    next.nutrition_table_not_available = parseBoolean(value);
  } else if (field === "nutrition_basis") {
    const parsed = safeString(value);
    next.nutrition_basis =
      parsed === "100g" || parsed === "100ml" ? parsed : null;
  } else if (field === "barcode") {
    next.barcode = parseBarcode(value);
  } else {
    (next[field] as unknown) = typeof value === "string" ? value : safeString(value);
  }

  const edited = new Set(next.edited_fields);
  edited.add(String(field));
  next.edited_fields = Array.from(edited);

  return revalidateCandidate(next);
}

export function approveCandidate(candidate: ProductFinderCandidate) {
  const withStatus = {
    ...candidate,
    status: "approved" as const,
    rejected_reason: "",
  };
  return revalidateCandidate(withStatus);
}

export function rejectCandidate(
  candidate: ProductFinderCandidate,
  reason = "",
) {
  return revalidateCandidate({
    ...candidate,
    status: "rejected",
    approved_for_export: false,
    is_verified: false,
    rejected_reason: reason,
  });
}

export function summarizeCandidates(
  candidates: ProductFinderCandidate[],
): ProductFinderSummary {
  return {
    total: candidates.length,
    valid: candidates.filter((item) => item.issue_list.length === 0).length,
    invalid: candidates.filter((item) =>
      item.issue_list.some((issue) => issue.code === "invalid_barcode"),
    ).length,
    approved: candidates.filter(
      (item) => item.status === "approved" || item.status === "export_ready",
    ).length,
    needsReview: candidates.filter((item) => item.status === "needs_review").length,
    rejected: candidates.filter((item) => item.status === "rejected").length,
    exportReady: candidates.filter((item) => item.approved_for_export).length,
  };
}

export function normalizeInputBarcodes(barcodes: string[]) {
  const seen = new Set<string>();
  const unique: string[] = [];

  for (const barcode of barcodes.map((item) => parseBarcode(item)).map(safeString)) {
    if (!barcode || seen.has(barcode)) continue;
    seen.add(barcode);
    unique.push(barcode);
  }

  return unique;
}

export function validateBarcodeBatch(barcodes: string[]) {
  const normalized = normalizeInputBarcodes(barcodes);

  if (normalized.length === 0) {
    return {
      ok: false as const,
      normalized,
      error: "En az bir barkod girin.",
    };
  }

  if (normalized.length > 100) {
    return {
      ok: false as const,
      normalized,
      error: "En fazla 100 benzersiz barkod işlenebilir.",
    };
  }

  return {
    ok: true as const,
    normalized,
    error: null,
  };
}
