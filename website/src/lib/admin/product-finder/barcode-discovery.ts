import { parseBarcode } from "@/lib/admin/imports/helpers";
import {
  compareQuantity,
  detectVariantTokens,
  normalizeText,
} from "@/lib/admin/product-finder/source-candidates";
import type { SearchProviderResult } from "@/lib/admin/product-finder/search-provider";

export type BarcodeDiscoveryInput = {
  brand?: string | null;
  product_name?: string | null;
  quantity_value?: number | null;
  quantity_unit?: string | null;
  source_url?: string | null;
};

export type BarcodeDiscoveryEvidence = {
  title: string;
  snippet: string;
  url: string;
  domain: string;
};

export type BarcodeDiscoveryCandidate = {
  barcode: string;
  score: number;
  confidence: "high" | "medium" | "low";
  evidence: BarcodeDiscoveryEvidence[];
  reasons: string[];
  warnings: string[];
};

const BARCODE_PATTERN = /\b\d{8,14}\b/g;
const QUANTITY_PATTERN = /\b(\d+(?:[.,]\d+)?)\s*(ml|l|g|kg)\b/i;
const REPUTABLE_DOMAINS = ["migros", "openfoodfacts", "carrefoursa", "a101"];

function isLikelyNoiseNumber(value: string) {
  if (/^(19|20)\d{6}$/.test(value)) return true;
  if (value.startsWith("90") && value.length >= 10) return true;
  if (/^0{5,}/.test(value)) return true;
  return false;
}

function isValidBarcodeCandidate(value: string) {
  const normalized = parseBarcode(value);
  return /^\d{8,14}$/.test(normalized) && !isLikelyNoiseNumber(normalized);
}

function formatQuantity(quantityValue?: number | null, quantityUnit?: string | null) {
  if (quantityValue == null || !quantityUnit?.trim()) return "";
  return `${quantityValue} ${quantityUnit.trim().toLowerCase()}`;
}

function tokenizeQueryBase(input: BarcodeDiscoveryInput) {
  return [input.brand?.trim(), input.product_name?.trim(), formatQuantity(input.quantity_value, input.quantity_unit)]
    .filter(Boolean)
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
}

export function buildBarcodeDiscoveryQueries(input: BarcodeDiscoveryInput) {
  const queryBase = tokenizeQueryBase(input);

  if (!queryBase) return [];

  const queries = [
    `${queryBase} barkod`,
    `${queryBase} barcode`,
    `${queryBase} 869`,
  ];

  if (!formatQuantity(input.quantity_value, input.quantity_unit)) {
    queries.push(
      [input.brand?.trim(), input.product_name?.trim(), "barkod"]
        .filter(Boolean)
        .join(" ")
        .trim(),
    );
  }

  return Array.from(new Set(queries.filter(Boolean)));
}

function buildEvidence(result: SearchProviderResult): BarcodeDiscoveryEvidence {
  return {
    title: result.title,
    snippet: result.snippet,
    url: result.url,
    domain: result.domain,
  };
}

function extractQuantityFromText(text: string) {
  const match = text.match(QUANTITY_PATTERN);
  if (!match) return null;

  const value = Number(match[1].replace(",", "."));
  const unit = match[2].toLowerCase();

  if (!Number.isFinite(value)) return null;

  return { quantity_value: value, quantity_unit: unit };
}

function scoreEvidence(input: BarcodeDiscoveryInput, result: SearchProviderResult) {
  const haystack = normalizeText(`${result.title} ${result.snippet}`);
  const productName = normalizeText(input.product_name);
  const brand = normalizeText(input.brand);
  const candidateVariants = detectVariantTokens(
    [input.brand, input.product_name].filter(Boolean).join(" "),
  );
  const evidenceVariants = detectVariantTokens(haystack);
  const reasons: string[] = [];
  const warnings: string[] = [];
  let score = 0.2;

  if (productName && haystack.includes(productName)) {
    score += 0.34;
    reasons.push("barcode appears with matching product name");
  } else if (
    productName &&
    productName
      .split(" ")
      .filter(Boolean)
      .every((token) => haystack.includes(token))
  ) {
    score += 0.2;
    reasons.push("product name tokens matched");
  }

  if (brand && haystack.includes(brand)) {
    score += 0.18;
    reasons.push("brand matched");
  }

  const evidenceQuantity = extractQuantityFromText(`${result.title} ${result.snippet}`);
  if (input.quantity_value != null && input.quantity_unit && evidenceQuantity) {
    const quantityComparison = compareQuantity(
      input.quantity_value,
      input.quantity_unit,
      evidenceQuantity.quantity_value,
      evidenceQuantity.quantity_unit,
    );

    if (quantityComparison.same) {
      score += 0.18;
      reasons.push("quantity matched");
    } else if (quantityComparison.comparable) {
      score -= 0.15;
      warnings.push("quantity mismatch");
    }
  } else if (formatQuantity(input.quantity_value, input.quantity_unit)) {
    const normalizedQuantity = normalizeText(
      formatQuantity(input.quantity_value, input.quantity_unit),
    );

    if (normalizedQuantity && haystack.includes(normalizedQuantity)) {
      score += 0.12;
      reasons.push("quantity text matched");
    }
  }

  if (REPUTABLE_DOMAINS.some((domain) => result.domain.includes(domain))) {
    score += 0.06;
    reasons.push("reputable evidence domain");
  }

  if (candidateVariants.length > 0) {
    const missingVariants = candidateVariants.filter(
      (variant) => !evidenceVariants.includes(variant),
    );

    if (missingVariants.length > 0) {
      score -= 0.2;
      warnings.push("variant conflict");
    }
  }

  return {
    score: Math.max(0, Math.min(score, 1)),
    reasons,
    warnings,
  };
}

export function extractBarcodeCandidatesFromResults(
  input: BarcodeDiscoveryInput,
  results: SearchProviderResult[],
): BarcodeDiscoveryCandidate[] {
  const grouped = new Map<string, BarcodeDiscoveryEvidence[]>();
  const reasonsByBarcode = new Map<string, Set<string>>();
  const warningsByBarcode = new Map<string, Set<string>>();
  const scoreByBarcode = new Map<string, number>();

  for (const result of results) {
    const evidenceText = `${result.title} ${result.snippet}`;
    const scoreData = scoreEvidence(input, result);
    const matches = Array.from(
      new Set(
        Array.from(evidenceText.matchAll(BARCODE_PATTERN))
          .map((match) => match[0] ?? "")
          .map((value) => parseBarcode(value))
          .filter(isValidBarcodeCandidate),
      ),
    );

    for (const barcode of matches) {
      const existingEvidence = grouped.get(barcode) ?? [];
      grouped.set(barcode, [...existingEvidence, buildEvidence(result)]);

      const reasons = reasonsByBarcode.get(barcode) ?? new Set<string>();
      scoreData.reasons.forEach((reason) => reasons.add(reason));
      reasonsByBarcode.set(barcode, reasons);

      const warnings = warningsByBarcode.get(barcode) ?? new Set<string>();
      scoreData.warnings.forEach((warning) => warnings.add(warning));
      warningsByBarcode.set(barcode, warnings);

      scoreByBarcode.set(barcode, (scoreByBarcode.get(barcode) ?? 0) + scoreData.score + 0.08);
    }
  }

  return Array.from(grouped.entries())
    .map(([barcode, evidence]) => {
      const repeatedBoost = evidence.length > 1 ? 0.1 * (evidence.length - 1) : 0;
      const score = Math.max(
        0,
        Math.min((scoreByBarcode.get(barcode) ?? 0) + repeatedBoost, 1),
      );

      return {
        barcode,
        score: Number(score.toFixed(2)),
        confidence: score >= 0.85 ? "high" : score >= 0.65 ? "medium" : "low",
        evidence: evidence.slice(0, 3),
        reasons: Array.from(reasonsByBarcode.get(barcode) ?? []),
        warnings: Array.from(warningsByBarcode.get(barcode) ?? []),
      } satisfies BarcodeDiscoveryCandidate;
    })
    .filter((candidate) => candidate.evidence.length > 0)
    .sort((left, right) => right.score - left.score);
}
