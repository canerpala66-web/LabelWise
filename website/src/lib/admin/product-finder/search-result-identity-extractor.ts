import { normalizeIdentity } from "@/lib/admin/product-finder/identity-normalizer";
import { normalizeText } from "@/lib/admin/product-finder/identity";
import type { ProductIdentityResult } from "@/lib/admin/product-finder/providers";
import type { ProductFinderIssue } from "@/lib/admin/product-finder/types";

export type WebSearchResult = {
  title: string;
  snippet: string;
  url: string;
  domain: string;
  position?: number;
};

type ExtractedIdentityCandidate = ProductIdentityResult & {
  evidenceCount: number;
};

function buildIssue(
  code: ProductFinderIssue["code"],
  message: string,
  severity: ProductFinderIssue["severity"] = "warning",
): ProductFinderIssue {
  return { code, message, severity };
}

function sanitizeSearchText(value: string, barcode: string) {
  const withoutBarcode = barcode ? value.replace(new RegExp(barcode, "g"), " ") : value;
  return withoutBarcode
    .replace(/\b(barkod|urun|ürün|detayi|detayı|kodu)\b/gi, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function inferBrandFromText(value: string) {
  const cleaned = sanitizeSearchText(value, "").trim();
  const [first, second] = cleaned.split(/\s+/);
  if (!first) return null;

  if (normalizeText(`${first} ${second ?? ""}`) === "coca cola") {
    return "Coca-Cola";
  }

  return first;
}

function shouldIgnoreResult(result: WebSearchResult, barcode: string) {
  const haystack = normalizeText(`${result.title} ${result.snippet}`);
  if (!haystack) return true;
  if (!haystack.includes(barcode) && haystack.replace(/\s+/g, "").length < 8) return true;

  const blockedTokens = [
    "kupon",
    "indirim kodu",
    "tracking",
    "kampanya",
    "category",
    "kategori",
  ];

  return blockedTokens.some((token) => haystack.includes(normalizeText(token)));
}

function candidateKey(candidate: Pick<ProductIdentityResult, "brand" | "product_name" | "quantity_display" | "variant">) {
  return [
    normalizeText(candidate.brand),
    normalizeText(candidate.product_name),
    normalizeText(candidate.quantity_display),
    normalizeText(candidate.variant),
  ].join("|");
}

function toEvidence(
  results: Array<{
    title: string;
    domain: string;
    url: string;
  }>,
) {
  return results.slice(0, 3).map((result) => ({
    title: result.title,
    domain: result.domain,
    url: result.url,
  }));
}

export function extractIdentityFromSearchResults(
  barcode: string,
  results: WebSearchResult[],
): ProductIdentityResult | null {
  const relevant = results.filter((result) => !shouldIgnoreResult(result, barcode));
  if (!relevant.length) {
    return null;
  }

  const grouped = new Map<string, ExtractedIdentityCandidate>();

  for (const result of relevant) {
    const cleanedTitle = sanitizeSearchText(result.title, barcode);
    const cleanedSnippet = sanitizeSearchText(result.snippet, barcode);
    const inferredBrand = inferBrandFromText(cleanedTitle || cleanedSnippet);
    const normalized = normalizeIdentity({
      barcode,
      rawName: `${cleanedTitle} ${cleanedSnippet}`.trim(),
      productName: cleanedTitle,
      brand: inferredBrand,
      sourceName: "web_search",
      sourceUrl: result.url,
    });

    const key = candidateKey(normalized);
    const existing = grouped.get(key);

    if (existing) {
      existing.confidence = Math.min(98, existing.confidence + 8);
      existing.evidenceCount += 1;
      existing.evidence_results = toEvidence([
        ...(existing.evidence_results ?? []),
        { title: result.title, domain: result.domain, url: result.url },
      ]);
      continue;
    }

    grouped.set(key, {
      providerId: "web-search-identity",
      ...normalized,
      evidence_results: toEvidence([result]),
      evidenceCount: 1,
    });
  }

  const candidates = [...grouped.values()].sort((a, b) => {
    if (b.evidenceCount !== a.evidenceCount) {
      return b.evidenceCount - a.evidenceCount;
    }
    return b.confidence - a.confidence;
  });

  const best = candidates[0] ?? null;
  const second = candidates[1] ?? null;
  if (!best) return null;

  const issues = [...best.issues];

  if (best.evidenceCount > 1) {
    best.confidence = Math.min(98, best.confidence + 10);
  }

  if (second && candidateKey(best) !== candidateKey(second)) {
    issues.push(
      buildIssue(
        "web_search_conflict",
        "Web arama sonuçları birden fazla farklı ürün kimliği gösteriyor.",
      ),
    );
    best.confidence = Math.min(best.confidence, 68);
  }

  if (best.confidence < 70 && !issues.some((issue) => issue.code === "low_identity_confidence")) {
    issues.push(
      buildIssue(
        "low_identity_confidence",
        "Web arama kimlik güveni düşük, manuel kontrol önerilir.",
      ),
    );
  }

  return {
    ...best,
    issues,
  };
}
