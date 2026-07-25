import { describe, expect, it } from "vitest";
import * as XLSX from "xlsx";
import { buildRowIssuesCsv } from "./export";
import { buildImportTemplateCsv } from "./template";
import { safeString } from "./helpers";
import { normalizeImportRow } from "./normalize";
import { parseCsv, parseJson, parseXlsx } from "./parse";
import { detectDuplicateBarcodes } from "./preview";
import { validateImportRow } from "./validate";

describe("admin import parsing", () => {
  it("parses valid csv rows", () => {
    const rows = parseCsv(
      "barcode,product_name,brand,category,ingredients,data_source,data_updated_at\n0012345678901,Ornek Urun 150 g,Ornek,Atistirmalik,Un seker kakao,product_packaging,2026-07-01",
    );

    expect(rows).toHaveLength(1);
    expect(rows[0]?.source.barcode).toBe("0012345678901");
  });

  it("parses valid json rows", () => {
    const rows = parseJson(
      JSON.stringify([
        {
          barcode: "8690504030012",
          product_name: "Ornek Icecek 1 L",
          brand: "Ornek",
        },
      ]),
    );

    expect(rows).toHaveLength(1);
    expect(rows[0]?.source.product_name).toBe("Ornek Icecek 1 L");
  });

  it("parses valid xlsx rows", async () => {
    const workbook = XLSX.utils.book_new();
    const sheet = XLSX.utils.aoa_to_sheet([
      ["barcode", "product_name", "brand"],
      ["0012345678901", "Ornek Urun 150 g", "Ornek"],
    ]);
    XLSX.utils.book_append_sheet(workbook, sheet, "Sheet1");
    const buffer = XLSX.write(workbook, { bookType: "xlsx", type: "buffer" });

    const rows = await parseXlsx(buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength));

    expect(rows).toHaveLength(1);
    expect(rows[0]?.source.barcode).toBe("0012345678901");
  });
});

describe("admin import normalization and validation", () => {
  it("keeps leading zero in barcode and normalizes decimals", () => {
    const normalized = normalizeImportRow({
      rowNumber: 2,
      source: {
        barcode: "0012345678901",
        product_name: "Ornek Biskuvi 150 g",
        brand: "Ornek",
        category: "Atistirmalik",
        ingredients: "Bugday unu, seker",
        fat_100g: "18,5",
        data_source: "product_packaging",
        data_updated_at: "2026-06-01",
      },
    });

    expect(normalized.barcode).toBe("0012345678901");
    expect(normalized.fat100g).toBe(18.5);
  });

  it("detects duplicate barcodes", () => {
    const duplicates = detectDuplicateBarcodes([
      { normalizedBarcode: "001" },
      { normalizedBarcode: "001" },
      { normalizedBarcode: "002" },
    ]);

    expect(duplicates.has("001")).toBe(true);
    expect(duplicates.has("002")).toBe(false);
  });

  it("flags stale and invalid rows", () => {
    const normalized = normalizeImportRow({
      rowNumber: 2,
      source: {
        barcode: "8690504030012",
        product_name: "Kısa",
        brand: "Ornek",
        category: "Atistirmalik",
        ingredients: "-",
        data_source: "retailer",
        data_updated_at: "2018-01-01",
      },
    });

    const preview = validateImportRow(normalized, null, false);

    expect(preview.errors.some((item) => item.code === "invalid_ingredients")).toBe(true);
    expect(preview.warnings.some((item) => item.code === "stale_data")).toBe(true);
  });

  it("detects stale update attempts against newer existing products", () => {
    const normalized = normalizeImportRow({
      rowNumber: 2,
      source: {
        barcode: "8690504030012",
        product_name: "Ornek Urun 150 g",
        brand: "Ornek",
        category: "Atistirmalik",
        ingredients: "Bugday unu, seker",
        data_source: "product_packaging",
        data_updated_at: "2025-01-01",
      },
    });

    const preview = validateImportRow(
      normalized,
      {
        id: "product-1",
        barcode: "8690504030012",
        name: "Ornek Urun 150 g",
        brand: "Ornek",
        category: "Atistirmalik",
        ingredients_text: "Bugday unu, seker",
        energy_kcal: null,
        energy_kj: null,
        fat: null,
        saturated_fat: null,
        carbohydrates: null,
        sugars: null,
        fiber: null,
        protein: null,
        salt: null,
        sodium: null,
        image_url: null,
        source: "bulk_import",
        data_source: "product_packaging",
        source_url: null,
        data_updated_at: "2026-06-01T00:00:00.000Z",
        packaging_version: null,
        is_current: true,
        verification_notes: null,
        quantity_value: null,
        quantity_unit: null,
        serving_size: null,
        country: "TR",
        language_code: "tr",
        external_id: null,
        notes: null,
        is_verified: false,
        updated_at: "2026-06-10T00:00:00.000Z",
      },
      false,
    );

    expect(preview.warnings.some((item) => item.code === "stale_update_attempt")).toBe(true);
  });
});

describe("admin import exports", () => {
  it("builds template csv with expected headers", () => {
    const csv = buildImportTemplateCsv();
    expect(csv.startsWith("barcode,product_name,brand")).toBe(true);
    expect(csv.includes("ORNEK_BARKODU_SILIN")).toBe(true);
  });

  it("protects csv exports from formula injection", () => {
    const csv = buildRowIssuesCsv([
      {
        rowNumber: 2,
        barcode: "=2+2",
        productName: "Test",
        brand: "Brand",
        errors: [],
        warnings: [],
      },
    ]);

    expect(csv).toContain("\"'=2+2\"");
    expect(safeString("test")).toBe("test");
  });
});
