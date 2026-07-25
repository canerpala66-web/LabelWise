import "server-only";

import { placeholderIngredientValues } from "@/lib/admin/imports/constants";
import { parseDateInput } from "@/lib/admin/imports/helpers";
import type {
  ExistingProductSnapshot,
  ImportRowInput,
  ImportRowStatus,
  PreviewRow,
  ValidationMessage,
} from "@/lib/admin/imports/types";

const now = new Date("2026-07-25T00:00:00.000Z");

function buildMessage(
  severity: "error" | "warning",
  code: ValidationMessage["code"],
  message: string,
  field?: string,
): ValidationMessage {
  return { severity, code, message, field };
}

function hasCoreNutrition(row: ImportRowInput) {
  return Boolean(
    row.energyKcal100g != null ||
      row.energyKj100g != null ||
      row.fat100g != null ||
      row.saturatedFat100g != null ||
      row.carbohydrates100g != null ||
      row.sugars100g != null ||
      row.protein100g != null ||
      row.salt100g != null,
  );
}

function countCoreNutrition(row: ImportRowInput) {
  return [
    row.energyKcal100g ?? row.energyKj100g,
    row.fat100g,
    row.saturatedFat100g,
    row.carbohydrates100g,
    row.sugars100g,
    row.protein100g,
    row.salt100g,
  ].filter((value) => value != null).length;
}

function validateImageUrl(value: string | null) {
  if (!value) {
    return null;
  }

  let parsed: URL;
  try {
    parsed = new URL(value);
  } catch {
    return buildMessage("error", "invalid_image_url", "Ön yüz görseli URL biçiminde değil.", "image_front_url");
  }

  if (!["http:", "https:"].includes(parsed.protocol)) {
    return buildMessage(
      "error",
      "invalid_image_protocol",
      "Ön yüz görseli yalnızca HTTP veya HTTPS olmalıdır.",
      "image_front_url",
    );
  }

  const hostname = parsed.hostname.toLowerCase();
  if (
    hostname === "localhost" ||
    hostname === "127.0.0.1" ||
    hostname === "::1" ||
    /^10\./.test(hostname) ||
    /^192\.168\./.test(hostname) ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(hostname) ||
    /^169\.254\./.test(hostname)
  ) {
    return buildMessage(
      "error",
      "unsafe_image_url",
      "Ön yüz görseli özel ağ veya yerel adres kullanamaz.",
      "image_front_url",
    );
  }

  return null;
}

function addNumericWarnings(row: ImportRowInput, warnings: ValidationMessage[], errors: ValidationMessage[]) {
  const numericFields: Array<[keyof ImportRowInput, string, number]> = [
    ["energyKcal100g", "energy_kcal_100g", 1200],
    ["energyKj100g", "energy_kj_100g", 5000],
    ["fat100g", "fat_100g", 100],
    ["saturatedFat100g", "saturated_fat_100g", 100],
    ["carbohydrates100g", "carbohydrates_100g", 100],
    ["sugars100g", "sugars_100g", 100],
    ["fiber100g", "fiber_100g", 100],
    ["protein100g", "protein_100g", 100],
    ["salt100g", "salt_100g", 100],
    ["sodium100g", "sodium_100g", 100],
  ];

  for (const [key, field, hardLimit] of numericFields) {
    const value = row[key];
    if (typeof value !== "number") {
      continue;
    }

    if (value < 0) {
      errors.push(
        buildMessage("error", "negative_numeric_value", "Negatif besin değeri kabul edilemez.", field),
      );
    } else if (value > hardLimit) {
      warnings.push(
        buildMessage(
          "warning",
          "invalid_numeric_value",
          "Besin değeri beklenenden yüksek görünüyor. Manuel kontrol önerilir.",
          field,
        ),
      );
    }
  }
}

function resolveBaseStatus(args: {
  errors: ValidationMessage[];
  warnings: ValidationMessage[];
  duplicateInFile: boolean;
  existingProduct: ExistingProductSnapshot | null;
  allowDefaultImport: boolean;
  hasChanges: boolean;
  missingNutrition: boolean;
  staleWarning: boolean;
  staleUpdateWarning: boolean;
  incompleteName: boolean;
  manualReview: boolean;
}) {
  if (args.duplicateInFile) return "duplicate_in_file" satisfies ImportRowStatus;
  if (args.errors.length > 0) return "invalid" satisfies ImportRowStatus;
  if (!args.allowDefaultImport) return "warning" satisfies ImportRowStatus;
  if (args.staleUpdateWarning) return "stale_update_attempt" satisfies ImportRowStatus;
  if (args.staleWarning) return "stale_data" satisfies ImportRowStatus;
  if (args.manualReview) return "manual_review" satisfies ImportRowStatus;
  if (args.missingNutrition) return "missing_nutrition_data" satisfies ImportRowStatus;
  if (args.incompleteName) return "incomplete_product_name" satisfies ImportRowStatus;
  if (args.warnings.length > 0) return "warning" satisfies ImportRowStatus;
  if (args.existingProduct && !args.hasChanges) return "valid_current" satisfies ImportRowStatus;
  return args.existingProduct ? ("valid_update" satisfies ImportRowStatus) : ("valid_new" satisfies ImportRowStatus);
}

function findQuantityMismatch(row: ImportRowInput) {
  if (!row.productName || !row.quantityValue || !row.quantityUnit) {
    return false;
  }

  const candidate = `${row.quantityValue}`.replace(/\.0+$/, "");
  const unit = row.quantityUnit.toLowerCase();
  const match = row.productName.toLowerCase().match(/(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l)\b/);
  if (!match) {
    return false;
  }

  const [, nameValue, nameUnit] = match;
  const normalizedNameValue = nameValue.replace(",", ".");
  return normalizedNameValue !== candidate || nameUnit !== unit;
}

function hasMeaningfulDifferences(row: ImportRowInput, existing: ExistingProductSnapshot | null) {
  if (!existing) {
    return true;
  }

  const comparable: Array<[unknown, unknown]> = [
    [row.productName, existing.name],
    [row.brand, existing.brand],
    [row.category, existing.category],
    [row.ingredients, existing.ingredients_text],
    [row.energyKcal100g, existing.energy_kcal],
    [row.energyKj100g, existing.energy_kj],
    [row.fat100g, existing.fat],
    [row.saturatedFat100g, existing.saturated_fat],
    [row.carbohydrates100g, existing.carbohydrates],
    [row.sugars100g, existing.sugars],
    [row.fiber100g, existing.fiber],
    [row.protein100g, existing.protein],
    [row.salt100g, existing.salt],
    [row.sodium100g, existing.sodium],
    [row.imageFrontUrl, existing.image_url],
    [row.dataUpdatedAt, existing.data_updated_at],
    [row.sourceUrl, existing.source_url],
  ];

  return comparable.some(([left, right]) => {
    if (left == null || left === "") return false;
    return `${left}` !== `${right ?? ""}`;
  });
}

export function validateImportRow(
  row: ImportRowInput,
  existingProduct: ExistingProductSnapshot | null,
  duplicateInFile: boolean,
): Omit<PreviewRow, "rowNumber" | "raw"> {
  const errors: ValidationMessage[] = [];
  const warnings: ValidationMessage[] = [];

  if (!row.barcode) {
    errors.push(buildMessage("error", "missing_barcode", "Barkod zorunludur.", "barcode"));
  } else if (!/^\d{8,14}$/.test(row.barcode)) {
    errors.push(
      buildMessage("error", "invalid_barcode", "Barkod yalnızca rakamlardan oluşmalı ve 8-14 karakter olmalıdır.", "barcode"),
    );
  }

  if (!row.productName) {
    errors.push(buildMessage("error", "missing_product_name", "Ürün adı zorunludur.", "product_name"));
  } else if ((row.brand && row.productName.toLowerCase() === row.brand.toLowerCase()) || row.productName.length < 10) {
    warnings.push(
      buildMessage("warning", "incomplete_product_name", "Ürün adı eksik veya fazla kısa görünüyor.", "product_name"),
    );
  }

  if (!row.brand) {
    warnings.push(buildMessage("warning", "missing_brand", "Marka alanı boş bırakılmış.", "brand"));
  }

  if (!row.category) {
    warnings.push(buildMessage("warning", "missing_category", "Kategori alanı boş bırakılmış.", "category"));
  }

  if (!row.ingredients) {
    errors.push(buildMessage("error", "missing_ingredients", "İçindekiler listesi zorunludur.", "ingredients"));
  } else if (placeholderIngredientValues.has(row.ingredients.toLowerCase())) {
    errors.push(
      buildMessage("error", "invalid_ingredients", "İçindekiler alanı placeholder metin içeriyor.", "ingredients"),
    );
  }

  if (!row.dataSource) {
    errors.push(buildMessage("error", "missing_data_source", "Veri kaynağı zorunludur.", "data_source"));
  }

  if (!row.dataUpdatedAt) {
    errors.push(buildMessage("error", "missing_update_date", "Veri tarihi zorunludur.", "data_updated_at"));
  } else {
    const parsedDate = parseDateInput(row.dataUpdatedAt);
    if (!parsedDate) {
      errors.push(buildMessage("error", "invalid_update_date", "Veri tarihi geçerli değil.", "data_updated_at"));
    } else {
      if (parsedDate.getTime() > now.getTime() + 24 * 60 * 60 * 1000) {
        errors.push(buildMessage("error", "future_update_date", "Gelecekteki tarih kabul edilmez.", "data_updated_at"));
      }

      const ageDays = Math.floor((now.getTime() - parsedDate.getTime()) / (24 * 60 * 60 * 1000));
      if (ageDays > 365 * 3) {
        warnings.push(
          buildMessage(
            "warning",
            "stale_data",
            "Veri üç yıldan eski. Varsayılan olarak import dışında tutulur.",
            "data_updated_at",
          ),
        );
      } else if (ageDays > 365 * 2) {
        warnings.push(
          buildMessage(
            "warning",
            "stale_data",
            "Veri iki yıldan eski. Güncellik kontrolü önerilir.",
            "data_updated_at",
          ),
        );
      }

      const existingDate = parseDateInput(existingProduct?.data_updated_at);
      if (existingDate && parsedDate.getTime() < existingDate.getTime()) {
        warnings.push(
          buildMessage(
            "warning",
            "stale_update_attempt",
            "Import verisi mevcut kayıttan daha eski görünüyor.",
            "data_updated_at",
          ),
        );
      }
    }
  }

  if (!row.isCurrent) {
    warnings.push(
      buildMessage(
        "warning",
        "not_current_product",
        "Bu satır güncel ürün olarak işaretlenmemiş. Varsayılan import seçimine dahil edilmez.",
        "is_current",
      ),
    );
  }

  if (!row.sourceUrl && row.dataSource !== "product_packaging") {
    warnings.push(
      buildMessage(
        "warning",
        "unverified_source",
        "Kaynak bağlantısı boş. Admin kontrolü önerilir.",
        "source_url",
      ),
    );
  }

  const imageUrlIssue = validateImageUrl(row.imageFrontUrl);
  if (imageUrlIssue) {
    errors.push(imageUrlIssue);
  }

  addNumericWarnings(row, warnings, errors);

  if (countCoreNutrition(row) < 5) {
    warnings.push(
      buildMessage(
        "warning",
        "missing_nutrition_data",
        "Temel besin değerlerinin önemli bir kısmı eksik.",
      ),
    );
  }

  if (!hasCoreNutrition(row)) {
    warnings.push(
      buildMessage(
        "warning",
        "manual_review",
        "Besin değerleri yetersiz olduğu için manuel kontrol önerilir.",
      ),
    );
  }

  if (findQuantityMismatch(row)) {
    errors.push(
      buildMessage(
        "error",
        "quantity_mismatch",
        "Ürün adı içindeki gramaj ile ayrı gramaj alanları uyuşmuyor.",
        "quantity_value",
      ),
    );
  }

  const status = resolveBaseStatus({
    errors,
    warnings,
    duplicateInFile,
    existingProduct,
    allowDefaultImport: row.isCurrent,
    hasChanges: hasMeaningfulDifferences(row, existingProduct),
    missingNutrition: warnings.some((item) => item.code === "missing_nutrition_data"),
    staleWarning: warnings.some((item) => item.code === "stale_data"),
    staleUpdateWarning: warnings.some((item) => item.code === "stale_update_attempt"),
    incompleteName: warnings.some((item) => item.code === "incomplete_product_name"),
    manualReview: warnings.some((item) => item.code === "manual_review"),
  });

  return {
    normalized: row,
    errors,
    warnings,
    status,
    duplicateInFile,
    existingProduct,
    isNewProduct: !existingProduct,
    isUpdate: Boolean(existingProduct),
    isCurrentProduct: Boolean(existingProduct) && status === "valid_current",
    shouldImportByDefault:
      errors.length === 0 &&
      !duplicateInFile &&
      row.isCurrent &&
      !warnings.some((item) => item.code === "stale_data" || item.code === "stale_update_attempt"),
    requiresStaleOverride: warnings.some(
      (item) => item.code === "stale_data" || item.code === "stale_update_attempt",
    ),
  };
}
