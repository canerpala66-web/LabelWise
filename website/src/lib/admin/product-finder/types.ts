import type { ImportRowInput } from "@/lib/admin/imports/types";

export const productFinderStatuses = [
  "pending",
  "searching",
  "ready_for_review",
  "needs_review",
  "approved",
  "rejected",
  "not_found",
  "export_ready",
] as const;

export type ProductFinderStatus = (typeof productFinderStatuses)[number];

export const productFinderQualityStatuses = [
  "partial",
  "needs_review",
  "verified_nutrition_only",
  "verified_full",
] as const;

export type ProductFinderQualityStatus =
  (typeof productFinderQualityStatuses)[number];

export const productFinderIssueCodes = [
  "invalid_barcode",
  "identity_not_found",
  "brand_missing",
  "name_missing",
  "quantity_missing",
  "nutrition_missing",
  "nutrition_basis_missing",
  "ingredients_missing",
  "image_missing",
  "source_not_found",
  "quantity_mismatch",
  "variant_mismatch",
  "low_match_confidence",
  "stale_source_data",
  "unverified_source",
] as const;

export type ProductFinderIssueCode = (typeof productFinderIssueCodes)[number];

export type ProductFinderIssue = {
  code: ProductFinderIssueCode;
  message: string;
  severity: "error" | "warning";
};

export type ProductFinderCandidate = {
  id: string;
  barcode: string;
  product_name: string;
  brand: string;
  category: string;
  ingredients: string;
  quantity_value: number | null;
  quantity_unit: string;
  serving_size: string;
  energy_kcal_100g: number | null;
  energy_kj_100g: number | null;
  fat_100g: number | null;
  saturated_fat_100g: number | null;
  carbohydrates_100g: number | null;
  sugars_100g: number | null;
  fiber_100g: number | null;
  protein_100g: number | null;
  salt_100g: number | null;
  sodium_100g: number | null;
  image_front_url: string;
  data_source: string;
  source_url: string;
  data_updated_at: string;
  packaging_version: string;
  is_current: boolean;
  verification_notes: string;
  country: string;
  language_code: string;
  external_id: string;
  notes: string;
  is_verified: boolean;
  import_action: ImportRowInput["importAction"];
  status: ProductFinderStatus;
  data_quality_status: ProductFinderQualityStatus;
  ingredients_status: "present" | "missing";
  issue_list: ProductFinderIssue[];
  approved_for_export: boolean;
  rejected_reason: string;
  edited_fields: string[];
  nutrition_basis: "100g" | "100ml" | null;
  match_confidence: number | null;
};

export type ProductFinderSummary = {
  total: number;
  valid: number;
  invalid: number;
  approved: number;
  needsReview: number;
  rejected: number;
  exportReady: number;
};
