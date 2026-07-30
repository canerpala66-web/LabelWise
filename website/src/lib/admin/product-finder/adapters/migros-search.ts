import "server-only";

import {
  calculateMatchConfidence,
  detectVariantTokens,
  normalizeText,
  parseQuantityFromText,
} from "@/lib/admin/product-finder/source-candidates";
import { searchWithSerper, type SearchProviderResult } from "@/lib/admin/product-finder/search-provider";
import type { ProductIdentityResult, SourceCandidate } from "@/lib/admin/product-finder/providers";

export type MigrosSearchCandidate = {
  source_url: string;
  source_name: "migros";
  product_name: string | null;
  brand: string | null;
  quantity_value: number | null;
  quantity_unit: string | null;
  quantity_display: string | null;
  variant: string | null;
  match_confidence: number;
  match_reasons: string[];
};

export type MigrosSearchResult =
  | {
      status: "ok";
      query: string;
      candidates: MigrosSearchCandidate[];
      blocked: false;
    }
  | {
      status: "source_error" | "not_found";
      query: string;
      candidates: MigrosSearchCandidate[];
      blocked: boolean;
      reason: string;
    };

function dedupeWords(parts: string[]) {
  const seen = new Set<string>();
  const output: string[] = [];

  for (const part of parts) {
    const normalized = normalizeText(part);
    if (!normalized || seen.has(normalized)) continue;
    seen.add(normalized);
    output.push(part.trim());
  }

  return output;
}

export function buildMigrosSearchQuery(identity: Pick<
  ProductIdentityResult,
  "brand" | "product_name" | "quantity_value" | "quantity_unit" | "quantity_display" | "variant"
>) {
  const brand = identity.brand?.trim() ?? "";
  const productName = identity.product_name?.trim() ?? "";
  const normalizedBrand = normalizeText(brand);
  const normalizedProductName = normalizeText(productName);
  const mergedName =
    normalizedBrand && normalizedProductName.startsWith(`${normalizedBrand} `)
      ? productName
      : [brand, productName].filter(Boolean).join(" ").trim();

  const parts = dedupeWords([
    mergedName,
    identity.variant ?? "",
    identity.quantity_display ??
      (identity.quantity_value != null && identity.quantity_unit
        ? `${identity.quantity_value} ${identity.quantity_unit}`
        : ""),
  ]);

  return parts.join(" ").replace(/\s+/g, " ").trim();
}

function isLikelyMigrosProductUrl(url: string) {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.replace(/^www\./, "");
    if (host !== "migros.com.tr") return false;
    const path = parsed.pathname.toLowerCase();
    if (!path || path === "/" || path === "/arama") return false;
    if (!path.includes("-p-")) return false;
    if (path.includes("/kategori/") || path.includes("/kampanya")) return false;
    return true;
  } catch {
    return false;
  }
}

function slugToTitle(value: string) {
  return value
    .split("-")
    .filter(Boolean)
    .map((token) => token.charAt(0).toLocaleUpperCase("tr-TR") + token.slice(1))
    .join(" ")
    .trim();
}

function buildIdentityLikeCandidate(url: string): SourceCandidate {
  const path = new URL(url).pathname;
  const slug = path.split("/").pop()?.replace(/-p-[a-z0-9]+$/i, "") ?? "";
  const title = slugToTitle(slug);
  const quantity = parseQuantityFromText(title);
  const variants = detectVariantTokens(title);

  return {
    source_name: "migros",
    source_url: url,
    source_product_id: path.match(/-p-([a-z0-9]+)$/i)?.[1] ?? null,
    barcode: "",
    brand: title.split(" ")[0] ?? null,
    product_name: title || null,
    quantity_value: quantity?.quantity_value ?? null,
    quantity_unit: quantity?.quantity_unit ?? null,
    quantity_display:
      quantity?.quantity_value != null && quantity.quantity_unit
        ? `${quantity.quantity_value} ${quantity.quantity_unit}`
        : null,
    variant: variants[0] ?? null,
    category: null,
    ingredients: null,
    nutrition_basis: null,
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
    image_front_url: null,
    image_source_url: null,
    data_updated_at: null,
    match_confidence: null,
    issue_list: [],
  };
}

export function scoreMigrosSearchCandidates(
  identity: ProductIdentityResult,
  urls: string[],
): MigrosSearchCandidate[] {
  const uniqueUrls = Array.from(new Set(urls)).slice(0, 10);

  return uniqueUrls
    .map((url) => {
      const identityLike = buildIdentityLikeCandidate(url);
      const confidence = calculateMatchConfidence(identity, identityLike);
      return {
        source_url: url,
        source_name: "migros" as const,
        product_name: identityLike.product_name,
        brand: identityLike.brand,
        quantity_value: identityLike.quantity_value,
        quantity_unit: identityLike.quantity_unit,
        quantity_display: identityLike.quantity_display,
        variant: identityLike.variant,
        match_confidence: confidence.score,
        match_reasons: confidence.reasons,
      };
    })
    .sort((a, b) => b.match_confidence - a.match_confidence);
}

export function parseMigrosSearchHtml(
  html: string,
  identity: ProductIdentityResult,
): MigrosSearchResult {
  const query = buildMigrosSearchQuery(identity);
  const normalizedHtml = html.toLowerCase();

  if (
    normalizedHtml.includes("just a moment") ||
    normalizedHtml.includes("enable javascript and cookies to continue") ||
    normalizedHtml.includes("cf_chl_opt")
  ) {
    return {
      status: "source_error",
      query,
      candidates: [],
      blocked: true,
      reason: "Migros arama sayfası Cloudflare korumasına takıldı.",
    };
  }

  const urlMatches = [
    ...html.matchAll(/https:\/\/www\.migros\.com\.tr\/[a-z0-9\-]+-p-[a-z0-9]+/gi),
    ...html.matchAll(/href=["'](\/[a-z0-9\-]+-p-[a-z0-9]+)["']/gi),
  ]
    .map((match) => match[1] ?? match[0])
    .filter(Boolean)
    .map((value) =>
      value.startsWith("http") ? value : `https://www.migros.com.tr${value}`,
    );

  if (urlMatches.length === 0) {
    return {
      status: "not_found",
      query,
      candidates: [],
      blocked: false,
      reason: "Migros arama sonucunda ürün URL’si bulunamadı.",
    };
  }

  return {
    status: "ok",
    query,
    candidates: scoreMigrosSearchCandidates(identity, urlMatches),
    blocked: false,
  };
}

export function filterMigrosSearchResults(results: SearchProviderResult[]) {
  return results.filter((result) => isLikelyMigrosProductUrl(result.url));
}

export async function searchMigrosProducts(
  identity: ProductIdentityResult,
): Promise<MigrosSearchResult> {
  const baseQuery = buildMigrosSearchQuery(identity);
  const query = `${baseQuery} site:migros.com.tr`;

  const response = await searchWithSerper(query);

  if (response.status !== "ok") {
    return {
      status: "source_error",
      query,
      candidates: [],
      blocked: false,
      reason:
        response.status === "source_unavailable"
          ? "SERPER_API_KEY eksik."
          : response.reason,
    };
  }

  const migrosResults = filterMigrosSearchResults(response.results);
  if (!migrosResults.length) {
    return {
      status: "not_found",
      query,
      candidates: [],
      blocked: false,
      reason: "Serper sonuçlarında uygun Migros ürün URL’si bulunamadı.",
    };
  }

  return {
    status: "ok",
    query,
    candidates: scoreMigrosSearchCandidates(
      identity,
      migrosResults.map((result) => result.url),
    ),
    blocked: false,
  };
}
