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
const QUANTITY_PATTERN = /\b(\d+(?:[.,]\d+)?)\s*(ml|l|lt|litre|liter|g|gr|kg)\b/i;
const REPUTABLE_DOMAINS = ["migros", "openfoodfacts", "carrefoursa", "a101"];
const MAX_QUERY_COUNT = 8;

type AliasToken = {
  canonical: string;
  aliases: string[];
};

function isLikelyNoiseNumber(value: string) {
  if (/^(19|20)\d{6}$/.test(value)) return true;
  if (value.startsWith("90") && value.length >= 10) return true;
  if (/^0{5,}/.test(value)) return true;
  return false;
}

export function isValidBarcodeCandidate(value: string) {
  const normalized = parseBarcode(value);
  return /^\d{8,14}$/.test(normalized) && !isLikelyNoiseNumber(normalized);
}

function normalizeUnit(unit?: string | null) {
  const normalized = (unit || "").trim().toLowerCase();
  if (!normalized) return "";
  if (["lt", "litre", "liter"].includes(normalized)) return "l";
  if (normalized === "gr") return "g";
  return normalized;
}

function formatDecimal(value: number) {
  return Number.isInteger(value) ? String(value) : String(value);
}

function buildQuantityAliases(quantityValue?: number | null, quantityUnit?: string | null) {
  if (quantityValue == null || !quantityUnit?.trim()) return [];

  const unit = normalizeUnit(quantityUnit);
  const aliases = new Set<string>();

  if (unit === "l") {
    aliases.add(`${formatDecimal(quantityValue)} L`);
    aliases.add(`${String(quantityValue).replace(".", ",")} L`);
    aliases.add(`${formatDecimal(quantityValue)} Lt`);
    aliases.add(`${String(quantityValue).replace(".", ",")} Lt`);

    const mlValue = quantityValue * 1000;
    if (Number.isFinite(mlValue)) {
      aliases.add(`${formatDecimal(mlValue)} ml`);
      aliases.add(`${formatDecimal(mlValue)}ML`);
    }
  } else if (unit === "ml") {
    aliases.add(`${formatDecimal(quantityValue)} ml`);
    aliases.add(`${formatDecimal(quantityValue)}ML`);

    const literValue = quantityValue / 1000;
    if (literValue > 0) {
      aliases.add(`${formatDecimal(literValue)} L`);
      aliases.add(`${String(literValue).replace(".", ",")} L`);
    }
  } else if (unit === "g") {
    aliases.add(`${formatDecimal(quantityValue)} g`);
    aliases.add(`${formatDecimal(quantityValue)}gr`);
  } else if (unit === "kg") {
    aliases.add(`${formatDecimal(quantityValue)} kg`);
    aliases.add(`${formatDecimal(quantityValue)} KG`);
    const gramValue = quantityValue * 1000;
    if (Number.isFinite(gramValue)) {
      aliases.add(`${formatDecimal(gramValue)} g`);
      aliases.add(`${formatDecimal(gramValue)}gr`);
    }
  }

  return Array.from(aliases);
}

function buildVariantAliasGroups(input: BarcodeDiscoveryInput) {
  const normalizedName = normalizeText([input.brand, input.product_name].filter(Boolean).join(" "));
  const groups: AliasToken[] = [];

  if (normalizedName.includes("zero")) {
    groups.push({
      canonical: "zero",
      aliases: ["zero", "zero sugar", "şekersiz", "sekersiz", "sugar free"],
    });
  }

  if (normalizedName.includes("max")) {
    groups.push({
      canonical: "max",
      aliases: ["max"],
    });
  }

  if (normalizedName.includes("light")) {
    groups.push({
      canonical: "light",
      aliases: ["light"],
    });
  }

  if (normalizedName.includes("cola") || normalizedName.includes("kola")) {
    groups.push({
      canonical: "cola",
      aliases: ["cola", "kola"],
    });
  }

  return groups;
}

function buildProductNameVariants(input: BarcodeDiscoveryInput) {
  const brand = input.brand?.trim();
  const productName = input.product_name?.trim();
  const combined = [brand, productName].filter(Boolean).join(" ").replace(/\s+/g, " ").trim();

  if (!combined) return [];

  const variants = new Set<string>([combined]);
  const normalizedCombined = normalizeText(combined);

  if (normalizedCombined.includes("cola")) {
    variants.add(combined.replace(/cola/gi, "Kola"));
  }

  if (normalizedCombined.includes("kola")) {
    variants.add(combined.replace(/kola/gi, "Cola"));
  }

  if (normalizedCombined.includes("zero")) {
    const withoutCola = combined.replace(/\bcola\b/gi, "").replace(/\bkola\b/gi, "").replace(/\s+/g, " ").trim();
    variants.add(withoutCola.replace(/\bzero\b/gi, "Zero Sugar").replace(/\s+/g, " ").trim());
    variants.add(withoutCola.replace(/\bzero\b/gi, "Zero Şekersiz").replace(/\s+/g, " ").trim());
    variants.add(withoutCola.replace(/\bzero\b/gi, "Zero").replace(/\s+/g, " ").trim());
  }

  return Array.from(variants).filter(Boolean);
}

function buildQueryBaseVariants(input: BarcodeDiscoveryInput) {
  const productVariants = buildProductNameVariants(input);
  const quantityAliases = buildQuantityAliases(input.quantity_value, input.quantity_unit);

  if (productVariants.length === 0) return [];

  if (productVariants.length === 1) {
    if (quantityAliases.length === 0) return productVariants;
    return [`${productVariants[0]} ${quantityAliases[0]}`.replace(/\s+/g, " ").trim()];
  }

  const bases = new Set<string>();

  const preferredQuantityIndexes = [0, 1, 0, 3, 4];
  for (let index = 0; index < productVariants.length; index += 1) {
    const productVariant = productVariants[index];
    if (quantityAliases.length === 0) {
      bases.add(productVariant);
      continue;
    }

    const quantityAlias =
      quantityAliases[preferredQuantityIndexes[index] ?? 0] ?? quantityAliases[0];
    bases.add(`${productVariant} ${quantityAlias}`.replace(/\s+/g, " ").trim());
  }

  if (bases.size < MAX_QUERY_COUNT) {
    for (const productVariant of productVariants) {
      for (const quantityAlias of quantityAliases) {
        bases.add(`${productVariant} ${quantityAlias}`.replace(/\s+/g, " ").trim());
        if (bases.size >= MAX_QUERY_COUNT) break;
      }
      if (bases.size >= MAX_QUERY_COUNT) break;
    }
  }

  return Array.from(bases);
}

export function buildBarcodeDiscoveryQueries(input: BarcodeDiscoveryInput) {
  const queryBases = buildQueryBaseVariants(input);
  if (queryBases.length === 0) return [];

  const queries: string[] = [];

  for (const base of queryBases) {
    const query = `${base} barkod`.replace(/\s+/g, " ").trim();
    if (!queries.includes(query)) {
      queries.push(query);
    }
    if (queries.length >= MAX_QUERY_COUNT - 3) break;
  }

  const primaryBase = queryBases[0];
  for (const suffix of ["barcode", "EAN", "869"]) {
    const query = `${primaryBase} ${suffix}`.replace(/\s+/g, " ").trim();
    if (!queries.includes(query)) {
      queries.push(query);
    }
    if (queries.length >= MAX_QUERY_COUNT) break;
  }

  return queries.slice(0, MAX_QUERY_COUNT);
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
  const unit = normalizeUnit(match[2]);

  if (!Number.isFinite(value)) return null;

  return { quantity_value: value, quantity_unit: unit };
}

function textContainsAnyAlias(text: string, aliases: string[]) {
  return aliases.some((alias) => normalizeText(text).includes(normalizeText(alias)));
}

function getInputAliasSignals(input: BarcodeDiscoveryInput) {
  return {
    quantityAliases: buildQuantityAliases(input.quantity_value, input.quantity_unit),
    variantGroups: buildVariantAliasGroups(input),
  };
}

function scoreEvidence(input: BarcodeDiscoveryInput, result: SearchProviderResult) {
  const sourceText = `${result.title} ${result.snippet}`;
  const haystack = normalizeText(sourceText);
  const productName = normalizeText(input.product_name);
  const brand = normalizeText(input.brand);
  const candidateVariants = detectVariantTokens(
    [input.brand, input.product_name].filter(Boolean).join(" "),
  );
  const evidenceVariants = detectVariantTokens(haystack);
  const { quantityAliases, variantGroups } = getInputAliasSignals(input);
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

  const evidenceQuantity = extractQuantityFromText(sourceText);
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
      score -= 0.32;
      warnings.push("quantity mismatch");
    }
  } else if (quantityAliases.length > 0 && textContainsAnyAlias(sourceText, quantityAliases)) {
    score += 0.22;
    reasons.push("quantity alias matched");
  }

  if (REPUTABLE_DOMAINS.some((domain) => result.domain.includes(domain))) {
    score += 0.06;
    reasons.push("reputable evidence domain");
  }

  let variantMatched = false;
  for (const group of variantGroups) {
    const aliasMatched = group.aliases.some((alias) =>
      normalizeText(sourceText).includes(normalizeText(alias)),
    );

    if (aliasMatched) {
      variantMatched = true;
      score += 0.22;
      reasons.push(`${group.canonical} variant matched`);
      continue;
    }

    if (
      group.canonical === "zero" &&
      (evidenceVariants.includes("max") || evidenceVariants.includes("light"))
    ) {
      score -= 0.24;
      warnings.push("variant conflict");
    } else if (
      group.canonical === "max" &&
      (evidenceVariants.includes("zero") || evidenceVariants.includes("sekersiz"))
    ) {
      score -= 0.24;
      warnings.push("variant conflict");
    }
  }

  if (!variantMatched && candidateVariants.length > 0) {
    const missingVariants = candidateVariants.filter(
      (variant) => !evidenceVariants.includes(variant),
    );

    if (missingVariants.length > 0) {
      score -= 0.16;
      warnings.push("variant conflict");
    }
  }

  return {
    score:
      warnings.includes("quantity mismatch") || warnings.includes("variant conflict")
        ? Math.max(0, Math.min(score, 0.79))
        : Math.max(0, Math.min(score, 1)),
    reasons: Array.from(new Set(reasons)),
    warnings: Array.from(new Set(warnings)),
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

      scoreByBarcode.set(
        barcode,
        (scoreByBarcode.get(barcode) ?? 0) + scoreData.score + 0.08,
      );
    }
  }

  return Array.from(grouped.entries())
    .map(([barcode, evidence]) => {
      const repeatedBoost = evidence.length > 1 ? 0.1 * (evidence.length - 1) : 0;
      const score = Math.max(
        0,
        Math.min((scoreByBarcode.get(barcode) ?? 0) + repeatedBoost, 1),
      );
      const warnings = Array.from(warningsByBarcode.get(barcode) ?? []);
      const hasConflictWarning =
        warnings.includes("quantity mismatch") || warnings.includes("variant conflict");
      const confidence =
        hasConflictWarning
          ? score >= 0.65
            ? "medium"
            : "low"
          : score >= 0.85
            ? "high"
            : score >= 0.65
              ? "medium"
              : "low";

      return {
        barcode,
        score: Number(score.toFixed(2)),
        confidence,
        evidence: evidence.slice(0, 3),
        reasons: Array.from(reasonsByBarcode.get(barcode) ?? []),
        warnings,
      } satisfies BarcodeDiscoveryCandidate;
    })
    .filter((candidate) => candidate.evidence.length > 0)
    .sort((left, right) => right.score - left.score);
}
