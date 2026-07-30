import type { ProductFinderIssue } from "@/lib/admin/product-finder/types";
import {
  detectVariantTokens,
  normalizeBrand,
  normalizeText,
  parseQuantityFromText,
} from "@/lib/admin/product-finder/identity";

type NormalizeIdentityArgs = {
  barcode: string;
  rawName?: string | null;
  brand?: string | null;
  productName?: string | null;
  quantityText?: string | null;
  sourceName: string;
  sourceUrl?: string | null;
};

type NormalizedIdentity = {
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
};

const variantTokens = [
  "zero",
  "max",
  "light",
  "sekersiz",
  "şekersiz",
  "klasik",
  "bitter",
  "sutlu",
  "sütlü",
  "laktozsuz",
  "glutensiz",
  "protein",
  "tam yagli",
  "tam yağlı",
  "yarim yagli",
  "yarım yağlı",
] as const;

function toTitleCase(value: string) {
  return value
    .split(" ")
    .filter(Boolean)
    .map((token) => token.charAt(0).toLocaleUpperCase("tr-TR") + token.slice(1))
    .join(" ");
}

function cleanupName(value: string | null | undefined) {
  const trimmed = (value ?? "")
    .trim()
    .replace(/[_|]+/g, " ")
    .replace(/\s+/g, " ")
    .replace(/\b(adet|paket|pet)\b/gi, (token) => token.toLocaleLowerCase("tr-TR"))
    .trim();

  if (!trimmed) {
    return null;
  }

  return trimmed
    .replace(/(\d)(ml|g|gr|kg|l)\b/gi, "$1 $2")
    .replace(/\bml\b/gi, "ml")
    .replace(/\bgr\b/gi, "g")
    .replace(/\blt\b/gi, "l")
    .replace(/\bkg\b/gi, "kg")
    .replace(/\bg\b/gi, "g")
    .replace(/\bl\b/gi, "l")
    .replace(/\s+/g, " ")
    .trim();
}

function cleanupBrand(value: string | null | undefined) {
  const cleaned = cleanupName(value);
  if (!cleaned) return null;

  const normalized = normalizeBrand(cleaned);
  if (!normalized) return null;

  if (normalized === "coca cola") return "Coca-Cola";
  if (normalized === "coca-cola") return "Coca-Cola";

  return toTitleCase(cleaned.replace(/\s+/g, " ").trim());
}

function extractQuantityDisplay(quantityValue: number | null, quantityUnit: string | null) {
  if (quantityValue == null || !quantityUnit) return null;
  return `${quantityValue} ${quantityUnit}`;
}

function removeQuantityFromName(value: string | null, quantityDisplay: string | null) {
  if (!value) return null;

  let next = value;
  if (quantityDisplay) {
    const escaped = quantityDisplay.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    next = next.replace(new RegExp(`\\b${escaped}\\b`, "i"), " ");
  }

  next = next
    .replace(/\b\d+(?:[.,]\d+)?\s*(ml|g|gr|kg|l|lt)\b/gi, " ")
    .replace(/\s+/g, " ")
    .trim();

  return next || null;
}

function extractVariant(value: string | null | undefined) {
  const normalized = normalizeText(value);
  if (!normalized) return null;

  const exact = variantTokens.find((token) => normalized.includes(normalizeText(token)));
  if (exact) {
    return exact === "sekersiz" ? "şekersiz" : exact;
  }

  const detected = detectVariantTokens(value);
  return detected[0] ?? null;
}

function buildIssues(args: {
  brand: string | null;
  productName: string | null;
  quantityValue: number | null;
  confidence: number;
}) {
  const issues: ProductFinderIssue[] = [];

  if (!args.brand) {
    issues.push({
      code: "brand_missing",
      message: "Marka bilgisi eksik.",
      severity: "warning",
    });
  }

  if (!args.productName) {
    issues.push({
      code: "name_missing",
      message: "Ürün adı eksik.",
      severity: "warning",
    });
  }

  if (args.quantityValue == null) {
    issues.push({
      code: "quantity_missing",
      message: "Miktar bilgisi eksik.",
      severity: "warning",
    });
  }

  if (args.confidence < 70) {
    issues.push({
      code: "low_identity_confidence",
      message: "Kimlik güveni düşük, manuel kontrol önerilir.",
      severity: "warning",
    });
  }

  return issues;
}

export function normalizeIdentity({
  barcode,
  rawName,
  brand,
  productName,
  quantityText,
  sourceName,
  sourceUrl,
}: NormalizeIdentityArgs): NormalizedIdentity {
  const cleanedRawName = cleanupName(rawName ?? productName) ?? null;
  const parsedQuantity =
    parseQuantityFromText(quantityText) ??
    parseQuantityFromText(productName) ??
    parseQuantityFromText(rawName);

  const quantityValue = parsedQuantity?.quantity_value ?? null;
  const quantityUnit = parsedQuantity?.quantity_unit ?? null;
  const quantityDisplay = extractQuantityDisplay(quantityValue, quantityUnit);

  const cleanedBrand = cleanupBrand(brand);
  const candidateName = cleanupName(productName ?? rawName) ?? null;
  const nameWithoutQuantity = removeQuantityFromName(candidateName, quantityDisplay);

  const normalizedBrand = normalizeText(cleanedBrand);
  let finalName = nameWithoutQuantity;

  if (
    finalName &&
    normalizedBrand &&
    normalizeText(finalName).startsWith(`${normalizedBrand} `)
  ) {
    finalName = finalName.slice(cleanedBrand?.length ?? 0).trim();
    finalName = finalName ? `${cleanedBrand} ${finalName}` : cleanedBrand;
  }

  if (!finalName && cleanedBrand) {
    finalName = cleanedBrand;
  }

  const variant = extractVariant(`${rawName ?? ""} ${productName ?? ""}`);
  const normalizedName = normalizeText(finalName);

  let confidence = 45;
  if (cleanedBrand) confidence += 18;
  if (finalName) confidence += 18;
  if (quantityValue != null && quantityUnit) confidence += 18;
  if (variant) confidence += 6;
  if (cleanedRawName && cleanedRawName.length > 8) confidence += 6;
  if (!finalName || normalizedName === normalizedBrand) confidence -= 14;
  if (!quantityValue) confidence -= 8;

  confidence = Math.max(20, Math.min(98, confidence));

  return {
    barcode,
    raw_name: cleanedRawName,
    brand: cleanedBrand,
    product_name: finalName,
    quantity_value: quantityValue,
    quantity_unit: quantityUnit,
    quantity_display: quantityDisplay,
    variant,
    source_name: sourceName,
    source_url: sourceUrl ?? null,
    confidence,
    issues: buildIssues({
      brand: cleanedBrand,
      productName: finalName,
      quantityValue,
      confidence,
    }),
  };
}
