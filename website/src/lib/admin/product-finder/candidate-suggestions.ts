import type { ProductFinderCandidate } from "@/lib/admin/product-finder/types";
import { revalidateCandidate } from "@/lib/admin/product-finder/validation";

export type CandidateSuggestionState = {
  canApplyCategory: boolean;
  canApplyNutritionBasis: boolean;
  hasAnySuggestion: boolean;
};

export type AppliedSuggestionCounts = {
  categoryApplied: number;
  nutritionBasisApplied: number;
};

export function getCandidateSuggestionState(
  candidate: ProductFinderCandidate,
): CandidateSuggestionState {
  const canApplyCategory = !candidate.category.trim() && Boolean(candidate.category_suggestion?.trim());
  const canApplyNutritionBasis =
    !candidate.nutrition_basis && Boolean(candidate.nutrition_basis_suggestion);

  return {
    canApplyCategory,
    canApplyNutritionBasis,
    hasAnySuggestion: canApplyCategory || canApplyNutritionBasis,
  };
}

export function applyCandidateSuggestions(candidate: ProductFinderCandidate) {
  const state = getCandidateSuggestionState(candidate);
  if (!state.hasAnySuggestion) {
    return {
      candidate,
      counts: { categoryApplied: 0, nutritionBasisApplied: 0 } satisfies AppliedSuggestionCounts,
    };
  }

  const next = revalidateCandidate({
    ...candidate,
    category: state.canApplyCategory ? candidate.category_suggestion ?? "" : candidate.category,
    nutrition_basis: state.canApplyNutritionBasis
      ? candidate.nutrition_basis_suggestion ?? null
      : candidate.nutrition_basis,
  });

  return {
    candidate: next,
    counts: {
      categoryApplied: state.canApplyCategory ? 1 : 0,
      nutritionBasisApplied: state.canApplyNutritionBasis ? 1 : 0,
    } satisfies AppliedSuggestionCounts,
  };
}

export function applySuggestionsToCandidates(candidates: ProductFinderCandidate[]) {
  let categoryApplied = 0;
  let nutritionBasisApplied = 0;

  const nextCandidates = candidates.map((candidate) => {
    const applied = applyCandidateSuggestions(candidate);
    categoryApplied += applied.counts.categoryApplied;
    nutritionBasisApplied += applied.counts.nutritionBasisApplied;
    return applied.candidate;
  });

  return {
    candidates: nextCandidates,
    counts: {
      categoryApplied,
      nutritionBasisApplied,
    } satisfies AppliedSuggestionCounts,
  };
}
