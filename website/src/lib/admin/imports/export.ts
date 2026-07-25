import type { PreviewRow, ValidationMessage } from "@/lib/admin/imports/types";
import { csvEscape } from "@/lib/admin/imports/helpers";

function joinMessages(items: ValidationMessage[]) {
  return items.map((item) => item.message).join(" | ");
}

export function buildRowIssuesCsv(rows: Array<PreviewRow | {
  rowNumber: number;
  barcode: string | null;
  productName: string | null;
  brand: string | null;
  errors: ValidationMessage[];
  warnings: ValidationMessage[];
}>) {
  const lines = [
    [
      "row_number",
      "barcode",
      "product_name",
      "brand",
      "validation_errors",
      "validation_warnings",
    ].join(","),
  ];

  for (const row of rows) {
    const barcode = "normalized" in row ? row.normalized.barcode : row.barcode;
    const productName = "normalized" in row ? row.normalized.productName : row.productName;
    const brand = "normalized" in row ? row.normalized.brand : row.brand;
    const errors = "errors" in row ? row.errors : [];
    const warnings = "warnings" in row ? row.warnings : [];

    lines.push(
      [
        csvEscape(row.rowNumber),
        csvEscape(barcode ?? ""),
        csvEscape(productName ?? ""),
        csvEscape(brand ?? ""),
        csvEscape(joinMessages(errors)),
        csvEscape(joinMessages(warnings)),
      ].join(","),
    );
  }

  return lines.join("\n");
}
