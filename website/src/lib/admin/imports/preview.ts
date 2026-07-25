import "server-only";

import { createPreviewToken } from "@/lib/admin/imports/helpers";
import { normalizeImportRow } from "@/lib/admin/imports/normalize";
import { getExistingProductsByBarcodes } from "@/lib/admin/imports/products";
import { parseImportFile } from "@/lib/admin/imports/parse";
import type { PreviewPayload, PreviewRow } from "@/lib/admin/imports/types";
import { validateImportRow } from "@/lib/admin/imports/validate";

export function detectDuplicateBarcodes(rows: Array<{ normalizedBarcode: string | null }>) {
  const counts = new Map<string, number>();

  rows.forEach((row) => {
    if (!row.normalizedBarcode) return;
    counts.set(row.normalizedBarcode, (counts.get(row.normalizedBarcode) ?? 0) + 1);
  });

  return new Set(
    Array.from(counts.entries())
      .filter(([, count]) => count > 1)
      .map(([barcode]) => barcode),
  );
}

export async function buildImportPreview(file: File): Promise<PreviewPayload> {
  const parsed = await parseImportFile(file);
  const normalizedRows = parsed.rows.map((row) => ({
    row,
    normalized: normalizeImportRow(row),
  }));

  const duplicates = detectDuplicateBarcodes(
    normalizedRows.map((item) => ({ normalizedBarcode: item.normalized.barcode })),
  );

  const barcodes = normalizedRows
    .map((item) => item.normalized.barcode)
    .filter((barcode): barcode is string => Boolean(barcode));

  const existingProducts = await getExistingProductsByBarcodes(Array.from(new Set(barcodes)));

  const rows: PreviewRow[] = normalizedRows.map(({ row, normalized }) => {
    const validation = validateImportRow(
      normalized,
      normalized.barcode ? existingProducts.get(normalized.barcode) ?? null : null,
      normalized.barcode ? duplicates.has(normalized.barcode) : false,
    );

    return {
      rowNumber: row.rowNumber,
      raw: row.source,
      ...validation,
    };
  });

  const summary = {
    totalRows: rows.length,
    validRows: rows.filter((row) => row.errors.length === 0 && row.warnings.length === 0).length,
    warningRows: rows.filter((row) => row.warnings.length > 0 && row.errors.length === 0).length,
    invalidRows: rows.filter((row) => row.errors.length > 0 || row.duplicateInFile).length,
    newRows: rows.filter((row) => row.isNewProduct).length,
    updateRows: rows.filter((row) => row.isUpdate).length,
    currentRows: rows.filter((row) => row.isCurrentProduct).length,
    duplicateRows: rows.filter((row) => row.duplicateInFile).length,
    staleRows: rows.filter((row) => row.warnings.some((item) => item.code === "stale_data")).length,
    staleUpdateRows: rows.filter((row) =>
      row.warnings.some((item) => item.code === "stale_update_attempt"),
    ).length,
    missingNutritionRows: rows.filter((row) =>
      row.warnings.some((item) => item.code === "missing_nutrition_data"),
    ).length,
    rowsWithImages: rows.filter((row) => Boolean(row.normalized.imageFrontUrl)).length,
  };

  return {
    fileName: parsed.fileName,
    fileType: parsed.fileType,
    fileSize: parsed.fileSize,
    generatedAt: new Date().toISOString(),
    previewToken: createPreviewToken(),
    rows,
    summary,
  };
}
