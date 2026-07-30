import type {
  ProductFinderCandidate,
  ProductFinderIssue,
  ProductFinderStatus,
} from "@/lib/admin/product-finder/types";

export type ProductIdentityInput = {
  barcode: string;
  raw_name?: string | null;
  source_name?: string | null;
  source_url?: string | null;
  brand?: string | null;
  product_name?: string | null;
  quantity_value?: number | null;
  quantity_unit?: string | null;
  variant?: string | null;
  confidence?: number | null;
  issues?: ProductFinderIssue[];
};

export type ProductIdentityResult = {
  providerId: string;
  barcode: string;
  raw_name: string | null;
  brand: string | null;
  product_name: string | null;
  quantity_value: number | null;
  quantity_unit: string | null;
  quantity_display: string | null;
  variant: string | null;
  source_name: string;
  source_url: string | null;
  confidence: number;
  issues: ProductFinderIssue[];
  evidence_results?: Array<{
    title: string;
    domain: string;
    url: string;
  }>;
};

export type SourceCandidate = {
  source_name: "migros" | "carrefoursa" | "a101" | "openfoodfacts" | "mock" | string;
  source_url: string | null;
  source_product_id: string | null;
  barcode: string;
  brand: string | null;
  product_name: string | null;
  quantity_value: number | null;
  quantity_unit: string | null;
  quantity_display: string | null;
  variant: string | null;
  category: string | null;
  ingredients: string | null;
  nutrition_basis: "100g" | "100ml" | null;
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
  image_front_url: string | null;
  image_source_url: string | null;
  data_updated_at: string | null;
  match_confidence: number | null;
  issue_list: ProductFinderIssue[];
  raw_payload?: unknown;
};

export type SourceAttempt = {
  providerId: string;
  label: string;
  success: boolean;
  candidateCount: number;
  message?: string;
};

export type ConfidenceSummary = {
  score: number;
  reasons: string[];
};

export type ProductFinderResolution = {
  barcode: string;
  identity: ProductIdentityResult | null;
  selected_candidate: SourceCandidate | null;
  all_candidates: SourceCandidate[];
  status: ProductFinderStatus;
  issues: ProductFinderIssue[];
  source_attempts: SourceAttempt[];
  confidence_summary: ConfidenceSummary | null;
};

export type BarcodeIdentityProvider = {
  id: string;
  label: string;
  priority: number;
  lookupBarcode(input: ProductIdentityInput): Promise<ProductIdentityResult | null>;
};

export type ProductDetailProvider = {
  id: string;
  label: string;
  priority: number;
  searchProduct(identity: ProductIdentityResult): Promise<SourceCandidate[]>;
  getProductDetail?(candidate: SourceCandidate): Promise<SourceCandidate>;
};

export type ResolvedProductFinderCandidate = ProductFinderCandidate & {
  resolution_meta?: ProductFinderResolution;
};
