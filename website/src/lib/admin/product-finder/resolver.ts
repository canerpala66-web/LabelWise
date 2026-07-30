import { calculateMatchConfidence } from "@/lib/admin/product-finder/confidence";
import type {
  BarcodeIdentityProvider,
  ProductDetailProvider,
  ProductFinderResolution,
  ProductIdentityInput,
  ProductIdentityResult,
  ResolvedProductFinderCandidate,
  SourceCandidate,
  SourceAttempt,
} from "@/lib/admin/product-finder/providers";
import { createMockCandidate } from "@/lib/admin/product-finder/mock";
import { revalidateCandidate } from "@/lib/admin/product-finder/validation";
import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";

export function isPlaceholderProductName(value: string | null | undefined) {
  const normalized = (value ?? "").trim().toLowerCase();
  return !normalized || normalized === "ürün adı bekleniyor";
}

function hasMeaningfulHydratedData(candidate: ProductFinderCandidate) {
  const hasResolvedIdentity =
    !isPlaceholderProductName(candidate.product_name) && Boolean(candidate.brand.trim());
  const hasResolvedDetail =
    Boolean(candidate.ingredients.trim()) ||
    candidate.energy_kcal_100g != null ||
    candidate.sugars_100g != null ||
    Boolean(candidate.source_url.trim()) ||
    Boolean(candidate.image_front_url.trim());

  return hasResolvedIdentity && hasResolvedDetail;
}

export function isEligibleForMockResolution(candidate: ProductFinderCandidate) {
  const hasInvalidBarcode = candidate.issue_list.some(
    (item) => item.code === "invalid_barcode",
  );

  if (!/^\d{8,14}$/.test(candidate.barcode)) return false;
  if (hasInvalidBarcode) return false;
  if (candidate.status === "rejected") return false;
  if (candidate.status === "approved" || candidate.status === "export_ready") return false;
  if (hasMeaningfulHydratedData(candidate)) return false;

  return true;
}

function sortByPriority<T extends { priority: number }>(items: T[]) {
  return [...items].sort((left, right) => left.priority - right.priority);
}

function buildIssues(identity: ProductIdentityResult | null, candidate: SourceCandidate | null) {
  const issues = [...(identity?.issues ?? []), ...(candidate?.issue_list ?? [])];

  if (!candidate?.ingredients) {
    issues.push({
      code: "ingredients_missing",
      message: "İçindekiler eksik.",
      severity: "warning",
    });
  }

  if (!candidate?.nutrition_basis) {
    issues.push({
      code: "nutrition_missing",
      message: "Besin değerleri eksik.",
      severity: "warning",
    });
  }

  if (!candidate?.source_url) {
    issues.push({
      code: "source_not_found",
      message: "Kaynak bağlantısı eksik.",
      severity: "warning",
    });
  }

  return issues;
}

function pickBestCandidate(
  identity: ProductIdentityResult,
  candidates: SourceCandidate[],
  detailProviders: ProductDetailProvider[],
) {
  const providerPriority = new Map(detailProviders.map((provider) => [provider.id, provider.priority]));

  const scored = candidates.map((candidate) => {
    const confidence = calculateMatchConfidence(identity, candidate);
    const priorityBonus = 100 - (providerPriority.get(`${candidate.source_name}-detail`) ?? 90);
    return {
      candidate: {
        ...candidate,
        match_confidence: confidence.score,
        issue_list: [
          ...candidate.issue_list,
          ...(confidence.reasons.includes("quantity_mismatch")
            ? [
                {
                  code: "quantity_mismatch" as const,
                  message: "Miktar uyuşmuyor.",
                  severity: "warning" as const,
                },
              ]
            : []),
          ...(confidence.reasons.includes("variant_mismatch")
            ? [
                {
                  code: "variant_mismatch" as const,
                  message: "Varyant uyuşmuyor.",
                  severity: "warning" as const,
                },
              ]
            : []),
          ...(confidence.score < 60
            ? [
                {
                  code: "low_match_confidence" as const,
                  message: "Eşleşme güveni düşük.",
                  severity: "warning" as const,
                },
              ]
            : []),
        ],
      },
      confidence,
      totalScore: confidence.score + priorityBonus,
    };
  });

  scored.sort((left, right) => right.totalScore - left.totalScore);
  return scored[0] ?? null;
}

export async function resolveProductFinderCandidate(
  input: ProductIdentityInput,
  identityProviders: BarcodeIdentityProvider[],
  detailProviders: ProductDetailProvider[],
): Promise<ProductFinderResolution> {
  const sourceAttempts: SourceAttempt[] = [];
  let identity: ProductIdentityResult | null = null;

  for (const provider of sortByPriority(identityProviders)) {
    const result = await provider.lookupBarcode(input);
    sourceAttempts.push({
      providerId: provider.id,
      label: provider.label,
      success: Boolean(result),
      candidateCount: result ? 1 : 0,
    });

    if (result) {
      identity = result;
      if (result.confidence >= 85) {
        break;
      }
    }
  }

  if (!identity) {
    return {
      barcode: input.barcode,
      identity: null,
      selected_candidate: null,
      all_candidates: [],
      status: "not_found",
      issues: [
        {
          code: "identity_not_found",
          message: "Barkod kimliği bulunamadı.",
          severity: "warning",
        },
      ],
      source_attempts: sourceAttempts,
      confidence_summary: null,
    };
  }

  const allCandidates: SourceCandidate[] = [];
  for (const provider of sortByPriority(detailProviders)) {
    const candidates = await provider.searchProduct(identity);
    sourceAttempts.push({
      providerId: provider.id,
      label: provider.label,
      success: candidates.length > 0,
      candidateCount: candidates.length,
    });
    allCandidates.push(...candidates);
  }

  const best = pickBestCandidate(identity, allCandidates, detailProviders);
  const selectedCandidate = best?.candidate ?? null;
  const issues = buildIssues(identity, selectedCandidate);

  return {
    barcode: input.barcode,
    identity,
    selected_candidate: selectedCandidate,
    all_candidates: allCandidates,
    status:
      issues.some((item) => item.code === "quantity_mismatch" || item.code === "variant_mismatch")
        ? "needs_review"
        : selectedCandidate
          ? "ready_for_review"
          : "not_found",
    issues,
    source_attempts: sourceAttempts,
    confidence_summary: best?.confidence ?? null,
  };
}

export function resolutionToProductFinderCandidate(
  resolution: ProductFinderResolution,
): ResolvedProductFinderCandidate {
  const base = createMockCandidate(resolution.barcode);
  const selected = resolution.selected_candidate;

  const candidate: ResolvedProductFinderCandidate = {
    ...base,
    brand: selected?.brand ?? resolution.identity?.brand ?? "",
    product_name: selected?.product_name ?? resolution.identity?.product_name ?? "",
    category: selected?.category ?? "",
    ingredients: selected?.ingredients ?? "",
    quantity_value: selected?.quantity_value ?? resolution.identity?.quantity_value ?? null,
    quantity_unit: selected?.quantity_unit ?? resolution.identity?.quantity_unit ?? "",
    energy_kcal_100g: selected?.energy_kcal_100g ?? null,
    energy_kj_100g: selected?.energy_kj_100g ?? null,
    fat_100g: selected?.fat_100g ?? null,
    saturated_fat_100g: selected?.saturated_fat_100g ?? null,
    carbohydrates_100g: selected?.carbohydrates_100g ?? null,
    sugars_100g: selected?.sugars_100g ?? null,
    fiber_100g: selected?.fiber_100g ?? null,
    protein_100g: selected?.protein_100g ?? null,
    salt_100g: selected?.salt_100g ?? null,
    sodium_100g: selected?.sodium_100g ?? null,
    image_front_url: selected?.image_front_url ?? "",
    data_source: selected?.source_name ?? resolution.identity?.source_name ?? "product_finder",
    source_url: selected?.source_url ?? resolution.identity?.source_url ?? "",
    data_updated_at: selected?.data_updated_at ?? base.data_updated_at,
    nutrition_basis: selected?.nutrition_basis ?? null,
    match_confidence: selected?.match_confidence ?? resolution.confidence_summary?.score ?? null,
    issue_list: resolution.issues,
    status: resolution.status,
    resolution_meta: resolution,
  };

  return revalidateCandidate(candidate) as ResolvedProductFinderCandidate;
}
