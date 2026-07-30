import "server-only";

import { extractIdentityFromSearchResults } from "@/lib/admin/product-finder/search-result-identity-extractor";
import { searchWithSerper } from "@/lib/admin/product-finder/search-provider";
import type {
  BarcodeIdentityProvider,
  ProductIdentityInput,
  ProductIdentityResult,
} from "@/lib/admin/product-finder/providers";
import type { ProductFinderIssue } from "@/lib/admin/product-finder/types";

function buildIssue(
  code: ProductFinderIssue["code"],
  message: string,
  severity: ProductFinderIssue["severity"] = "warning",
): ProductFinderIssue {
  return { code, message, severity };
}

const barcodeQueries = (barcode: string) => [
  barcode,
  `${barcode} ürün`,
  `${barcode} barkod`,
];

export const webSearchIdentityProvider: BarcodeIdentityProvider = {
  id: "web-search-identity",
  label: "Web Search Identity (Serper)",
  priority: 30,
  async lookupBarcode(input: ProductIdentityInput): Promise<ProductIdentityResult | null> {
    const collectedResults = [];

    for (const query of barcodeQueries(input.barcode)) {
      const response = await searchWithSerper(query);

      if (response.status === "source_unavailable") {
        throw {
          issue: buildIssue(
            "web_search_not_configured",
            "SERPER_API_KEY eksik. Web search identity provider yapılandırılmamış.",
          ),
        };
      }

      if (response.status === "source_error") {
        throw {
          issue: buildIssue(
            "source_error",
            response.reason || "Serper arama isteği başarısız oldu.",
          ),
        };
      }

      collectedResults.push(...response.results);
    }

    if (!collectedResults.length) {
      throw {
        issue: buildIssue(
          "web_search_no_results",
          "Web arama sonuçlarında barkod kimliği bulunamadı.",
        ),
      };
    }

    const extracted = extractIdentityFromSearchResults(input.barcode, collectedResults);
    if (!extracted) {
      return null;
    }

    return {
      ...extracted,
      source_name: "web_search_serper",
      source_url: extracted.source_url ?? collectedResults[0]?.url ?? null,
    };
  },
};

export { isSerperConfigured as isWebSearchIdentityConfigured } from "@/lib/admin/product-finder/search-provider";
