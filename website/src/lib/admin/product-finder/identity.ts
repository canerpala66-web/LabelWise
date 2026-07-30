const turkishMap: Record<string, string> = {
  ç: "c",
  ğ: "g",
  ı: "i",
  İ: "i",
  ö: "o",
  ş: "s",
  Ş: "s",
  ü: "u",
};

export function normalizeText(value: string | null | undefined) {
  return (value ?? "")
    .trim()
    .replace(/[çğıİöşŞü]/g, (char) => turkishMap[char] ?? char)
    .toLowerCase()
    .replace(/[%/,+()]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeBrand(value: string | null | undefined) {
  return normalizeText(value).replace(/\b(gida|gıda|sanayi|ticaret|a\.s\.|aş)\b/g, "").replace(/\s+/g, " ").trim();
}

export function detectVariantTokens(value: string | null | undefined) {
  const normalized = normalizeText(value);
  const knownTokens = [
    "zero",
    "sekersiz",
    "şekersiz",
    "light",
    "klasik",
    "bitter",
    "sutlu",
    "sütlü",
    "laktozsuz",
    "glutensiz",
    "max",
    "vanilyali",
    "limonlu",
  ];

  return knownTokens.filter((token) => normalized.includes(normalizeText(token)));
}

export function parseQuantityFromText(value: string | null | undefined) {
  const normalized = normalizeText(value).replace(",", ".");
  const match = normalized.match(/(\d+(?:\.\d+)?)\s*(kg|g|gr|l|lt|ml)\b/);
  if (!match) {
    return null;
  }

  const quantityValue = Number(match[1]);
  const rawUnit = match[2];
  const quantityUnit =
    rawUnit === "gr" ? "g" : rawUnit === "lt" ? "l" : rawUnit;

  return Number.isFinite(quantityValue)
    ? { quantity_value: quantityValue, quantity_unit: quantityUnit }
    : null;
}

export function toBaseQuantity(
  quantityValue: number | null | undefined,
  quantityUnit: string | null | undefined,
) {
  if (quantityValue == null || !quantityUnit) {
    return null;
  }

  const unit = normalizeText(quantityUnit);
  if (unit === "kg") return quantityValue * 1000;
  if (unit === "g") return quantityValue;
  if (unit === "l") return quantityValue * 1000;
  if (unit === "ml") return quantityValue;
  return null;
}

export function compareQuantity(
  leftValue: number | null | undefined,
  leftUnit: string | null | undefined,
  rightValue: number | null | undefined,
  rightUnit: string | null | undefined,
) {
  const leftBase = toBaseQuantity(leftValue, leftUnit);
  const rightBase = toBaseQuantity(rightValue, rightUnit);

  if (leftBase == null || rightBase == null) {
    return { same: false, comparable: false, difference: null };
  }

  const difference = Math.abs(leftBase - rightBase);
  return {
    same: difference < 0.0001,
    comparable: true,
    difference,
  };
}

export function productNameSimilarity(
  left: string | null | undefined,
  right: string | null | undefined,
) {
  const leftTokens = new Set(normalizeText(left).split(" ").filter(Boolean));
  const rightTokens = new Set(normalizeText(right).split(" ").filter(Boolean));

  if (leftTokens.size === 0 || rightTokens.size === 0) {
    return 0;
  }

  let intersection = 0;
  for (const token of leftTokens) {
    if (rightTokens.has(token)) {
      intersection += 1;
    }
  }

  return intersection / Math.max(leftTokens.size, rightTokens.size);
}
