import type {
  ConfidenceSummary,
  ProductIdentityResult,
  SourceCandidate,
} from "@/lib/admin/product-finder/providers";
import {
  compareQuantity,
  detectVariantTokens,
  normalizeBrand,
  productNameSimilarity,
} from "@/lib/admin/product-finder/identity";

export function calculateMatchConfidence(
  identity: ProductIdentityResult,
  candidate: SourceCandidate,
): ConfidenceSummary {
  let score = 0;
  const reasons: string[] = [];

  if (normalizeBrand(identity.brand) && normalizeBrand(identity.brand) === normalizeBrand(candidate.brand)) {
    score += 35;
    reasons.push("brand_match");
  } else if (normalizeBrand(identity.brand) && normalizeBrand(candidate.brand)) {
    score -= 15;
    reasons.push("brand_mismatch");
  }

  const nameSimilarity = productNameSimilarity(identity.product_name, candidate.product_name);
  score += Math.round(nameSimilarity * 30);
  if (nameSimilarity >= 0.6) reasons.push("name_match");
  if (nameSimilarity < 0.3) reasons.push("name_weak");

  const quantityComparison = compareQuantity(
    identity.quantity_value,
    identity.quantity_unit,
    candidate.quantity_value,
    candidate.quantity_unit,
  );
  if (quantityComparison.comparable && quantityComparison.same) {
    score += 20;
    reasons.push("quantity_match");
  } else if (quantityComparison.comparable) {
    score -= 20;
    reasons.push("quantity_mismatch");
  }

  const identityVariants = detectVariantTokens(identity.variant ?? identity.product_name);
  const candidateVariants = detectVariantTokens(candidate.variant ?? candidate.product_name);
  if (identityVariants.length === 0 || candidateVariants.length === 0) {
    score += 5;
  } else if (identityVariants.some((token) => candidateVariants.includes(token))) {
    score += 10;
    reasons.push("variant_match");
  } else {
    score -= 15;
    reasons.push("variant_mismatch");
  }

  if (candidate.ingredients) {
    score += 5;
    reasons.push("ingredients_present");
  }

  if (candidate.nutrition_basis) {
    score += 5;
    reasons.push("nutrition_present");
  }

  if (candidate.image_front_url) {
    score += 5;
    reasons.push("image_present");
  }

  return {
    score: Math.max(0, Math.min(100, score)),
    reasons,
  };
}
