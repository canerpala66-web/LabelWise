import { describe, expect, it } from "vitest";
import * as xlsx from "xlsx";
import { importTemplateHeaders } from "@/lib/admin/imports/constants";
import { calculateMatchConfidence } from "./confidence";
import {
  parseBarcodeCsv,
  parseBarcodeCsvDetailed,
  parseProductFinderCsv,
  parseProductFinderRows,
  parseBarcodeRowsDetailed,
  parseBarcodeTextarea,
} from "./csv";
import { buildExportMatrix, mapCandidateToImportRow } from "./export";
import {
  compareQuantity,
  detectVariantTokens,
  normalizeText,
  parseQuantityFromText,
} from "./identity";
import { createHydratedCandidateFromImportRow, createMockCandidate } from "./mock";
import { mockBarcodeIdentityProvider, mockProductDetailProvider } from "./adapters/mock-provider";
import {
  isEligibleForMockResolution,
  resolveProductFinderCandidate,
  resolutionToProductFinderCandidate,
} from "./resolver";
import {
  approveCandidate,
  normalizeInputBarcodes,
  revalidateCandidate,
  summarizeCandidates,
  updateCandidateField,
  validateBarcodeBatch,
} from "./validation";

describe("product finder provider foundation", () => {
  it("normalizes Turkish text safely", () => {
    expect(normalizeText("Gazlı İçecek Şekersiz")).toBe("gazli icecek sekersiz");
  });

  it("parses quantity from text", () => {
    expect(parseQuantityFromText("330 ml")).toEqual({
      quantity_value: 330,
      quantity_unit: "ml",
    });
    expect(parseQuantityFromText("1 L")).toEqual({
      quantity_value: 1,
      quantity_unit: "l",
    });
    expect(parseQuantityFromText("400 g")).toEqual({
      quantity_value: 400,
      quantity_unit: "g",
    });
    expect(parseQuantityFromText("1 kg")).toEqual({
      quantity_value: 1,
      quantity_unit: "kg",
    });
  });

  it("compares equivalent quantities correctly", () => {
    expect(compareQuantity(1000, "ml", 1, "L")).toMatchObject({
      same: true,
      comparable: true,
    });
    expect(compareQuantity(1000, "g", 1, "kg")).toMatchObject({
      same: true,
      comparable: true,
    });
  });

  it("detects quantity mismatch", () => {
    expect(compareQuantity(330, "ml", 1, "L")).toMatchObject({
      same: false,
      comparable: true,
    });
    expect(compareQuantity(400, "g", 630, "g")).toMatchObject({
      same: false,
      comparable: true,
    });
  });

  it("detects variant tokens", () => {
    expect(detectVariantTokens("Pepsi Max")).toContain("max");
    expect(detectVariantTokens("Coca-Cola Zero")).toContain("zero");
    expect(detectVariantTokens("Laktozsuz süt")).toContain("laktozsuz");
    expect(detectVariantTokens("Glutensiz ürün")).toContain("glutensiz");
  });

  it("gives higher match confidence for same brand/name/quantity", async () => {
    const identity = await mockBarcodeIdentityProvider.lookupBarcode({ barcode: "8690574114658" });
    const candidates = identity
      ? await mockProductDetailProvider.searchProduct(identity)
      : [];

    const confidence = identity && candidates[0]
      ? calculateMatchConfidence(identity, candidates[0])
      : { score: 0, reasons: [] };

    expect(confidence.score).toBeGreaterThanOrEqual(80);
  });

  it("lowers confidence for quantity mismatch", async () => {
    const identity = await mockBarcodeIdentityProvider.lookupBarcode({ barcode: "8690574114658" });
    const candidates = identity
      ? await mockProductDetailProvider.searchProduct(identity)
      : [];

    const mismatched = { ...candidates[0], quantity_value: 1000, quantity_unit: "ml" };
    const confidence = identity && mismatched
      ? calculateMatchConfidence(identity, mismatched)
      : { score: 0, reasons: [] };

    expect(confidence.score).toBeLessThan(80);
    expect(confidence.reasons).toContain("quantity_mismatch");
  });

  it("resolver chooses the higher priority source when candidates are otherwise equal", async () => {
    const resolution = await resolveProductFinderCandidate(
      { barcode: "8690574114658" },
      [mockBarcodeIdentityProvider],
      [
        mockProductDetailProvider,
        {
          ...mockProductDetailProvider,
          id: "mock-detail-late",
          label: "Mock Detail Late",
          priority: 50,
        },
      ],
    );

    expect(resolution.selected_candidate?.source_url).toContain("mock.local");
    expect(resolution.source_attempts.length).toBeGreaterThan(1);
  });

  it("resolver marks needs_review on quantity mismatch", async () => {
    const resolution = await resolveProductFinderCandidate(
      { barcode: "8690574114658" },
      [mockBarcodeIdentityProvider],
      [
        {
          ...mockProductDetailProvider,
          async searchProduct(identity) {
            const result = await mockProductDetailProvider.searchProduct(identity);
            return [{ ...result[0], quantity_value: 1000, quantity_unit: "ml" }];
          },
        },
      ],
    );

    expect(resolution.status).toBe("needs_review");
    expect(resolution.issues.some((item) => item.code === "quantity_mismatch")).toBe(true);
  });

  it("mock provider resolves to hydrated product finder candidate", async () => {
    const resolution = await resolveProductFinderCandidate(
      { barcode: "8690574114658" },
      [mockBarcodeIdentityProvider],
      [mockProductDetailProvider],
    );
    const candidate = resolutionToProductFinderCandidate(resolution);

    expect(candidate.product_name).toBe("Pepsi Kola Kutu");
    expect(candidate.brand).toBe("Pepsi");
    expect(candidate.quantity_value).toBe(330);
    expect(candidate.sugars_100g).toBe(10.6);
  });

  it("textarea-created placeholder candidate is eligible for mock resolution", () => {
    const candidate = createMockCandidate("8690574114658");
    expect(isEligibleForMockResolution(candidate)).toBe(true);
  });

  it("needs_review candidate is eligible for mock resolution", () => {
    const candidate = revalidateCandidate(createMockCandidate("5000112664478"));
    expect(candidate.status).toBe("needs_review");
    expect(isEligibleForMockResolution(candidate)).toBe(true);
  });

  it("invalid barcode candidate is not eligible for mock resolution", () => {
    const candidate = revalidateCandidate(createMockCandidate("153"));
    expect(isEligibleForMockResolution(candidate)).toBe(false);
  });

  it("approved or export_ready candidate is not eligible for mock resolution", () => {
    let candidate = createMockCandidate("8690574114658");
    candidate = updateCandidateField(candidate, "product_name", "Pepsi Kola Kutu");
    candidate = updateCandidateField(candidate, "ingredients", "Su, şeker");
    candidate = updateCandidateField(candidate, "brand", "Pepsi");
    candidate = updateCandidateField(candidate, "data_source", "product_packaging");
    candidate = updateCandidateField(candidate, "data_updated_at", "2026-07-30");
    candidate = approveCandidate(candidate);
    expect(isEligibleForMockResolution(candidate)).toBe(false);
  });

  it("full hydrated candidate with meaningful data is not eligible for mock resolution", () => {
    const candidate = createHydratedCandidateFromImportRow({
      barcode: "8690574114658",
      product_name: "Pepsi Kola Kutu",
      brand: "Pepsi",
      ingredients: "Su, şeker",
      quantity_value: "330",
      quantity_unit: "ml",
      energy_kcal_100g: "42",
      sugars_100g: "10.6",
      image_front_url: "https://img.test/1.jpg",
      data_source: "product_packaging",
      source_url: "https://example.com",
      data_updated_at: "2026-07-30",
    });

    expect(isEligibleForMockResolution(candidate)).toBe(false);
  });

  it("mock resolving 8690574114658 fills Pepsi-like fields", async () => {
    const resolution = await resolveProductFinderCandidate(
      { barcode: "8690574114658" },
      [mockBarcodeIdentityProvider],
      [mockProductDetailProvider],
    );
    const candidate = resolutionToProductFinderCandidate(resolution);
    expect(candidate.product_name).toBe("Pepsi Kola Kutu");
    expect(candidate.brand).toBe("Pepsi");
  });

  it("mock resolving 5000112664478 fills Coca-Cola-like fields", async () => {
    const resolution = await resolveProductFinderCandidate(
      { barcode: "5000112664478" },
      [mockBarcodeIdentityProvider],
      [mockProductDetailProvider],
    );
    const candidate = resolutionToProductFinderCandidate(resolution);
    expect(candidate.product_name).toBe("Coca-Cola Original Taste");
    expect(candidate.brand).toBe("Coca-Cola");
  });
});

describe("product finder parsing", () => {
  it("deduplicates and normalizes textarea barcodes", () => {
    const parsed = parseBarcodeTextarea("8690504030012\n8690504030012\n0012345678901\n");
    expect(normalizeInputBarcodes(parsed)).toEqual(["8690504030012", "0012345678901"]);
  });

  it("reads barcode column from csv", () => {
    const parsed = parseBarcodeCsv("barcode,name\n8690504030012,urun\n0012345678901,urun2");
    expect(parsed).toEqual(["8690504030012", "0012345678901"]);
  });

  it("reads semicolon csv with barcode header", () => {
    const parsed = parseBarcodeCsv(
      "barcode;product_name;brand\n8690574114658;Pepsi Kola Kutu;Pepsi",
    );
    expect(parsed).toEqual(["8690574114658"]);
  });

  it("uses first column when csv has no barcode header", () => {
    const parsed = parseBarcodeCsv("kod,name\n8690504030012,urun\n0012345678901,urun2");
    expect(parsed).toEqual(["8690504030012", "0012345678901"]);
  });

  it("uses first column for semicolon csv without header", () => {
    const parsed = parseBarcodeCsv(
      "8690574114658;Pepsi Kola Kutu;Pepsi\n0012345678901;Urun 2;Marka 2",
    );
    expect(parsed).toEqual(["8690574114658", "0012345678901"]);
  });

  it("reads only barcode column from full 31-column semicolon csv", () => {
    const parsed = parseBarcodeCsv(
      "barcode;product_name;brand;category;ingredients\n8690574114658;Pepsi Kola Kutu;Pepsi;Gazlı İçecek;Su, şeker",
    );
    expect(parsed).toEqual(["8690574114658"]);
  });

  it("hydrates product fields from full 31-column semicolon csv", () => {
    const parsed = parseProductFinderCsv(
      "barcode;product_name;brand;category;ingredients;quantity_value;quantity_unit;energy_kcal_100g;sugars_100g;image_front_url;data_source;source_url;data_updated_at\n8690574114658;Pepsi Kola Kutu;Pepsi;Gazlı İçecek;Su, şeker;330;ml;42;10.6;https://img.test/1.jpg;product_packaging;https://example.com;2026-07-01",
    );

    expect(parsed.mode).toBe("full_template");
    if (parsed.mode === "full_template") {
      expect(parsed.rows[0]?.product_name).toBe("Pepsi Kola Kutu");
      expect(parsed.rows[0]?.brand).toBe("Pepsi");
      expect(parsed.rows[0]?.quantity_value).toBe("330");
      expect(parsed.rows[0]?.source_url).toBe("https://example.com");
    }
  });

  it("hydrates product fields from full 31-column comma csv", () => {
    const parsed = parseProductFinderCsv(
      "barcode,product_name,brand,category,ingredients,quantity_value,quantity_unit,energy_kcal_100g,sugars_100g,image_front_url,data_source,source_url,data_updated_at\n8690574114658,Pepsi Kola Kutu,Pepsi,Gazlı İçecek,\"Su, şeker\",330,ml,42,10.6,https://img.test/1.jpg,product_packaging,https://example.com,2026-07-01",
    );

    expect(parsed.mode).toBe("full_template");
  });

  it("never treats a full semicolon row as a barcode", () => {
    const parsed = parseBarcodeCsvDetailed(
      "8690574114658;Pepsi;Gazlı İçecek\n0012345678901;Urun 2;Marka 2",
    );
    expect(parsed.barcodes).toEqual(["8690574114658", "0012345678901"]);
    expect(parsed.barcodes.some((item) => item.includes(";"))).toBe(false);
  });

  it("parses xlsx rows with barcode header", () => {
    const worksheet = xlsx.utils.aoa_to_sheet([
      ["barcode", "name"],
      ["8690504030012", "urun"],
      ["0012345678901", "urun2"],
    ]);
    const rows = xlsx.utils.sheet_to_json(worksheet, {
      header: 1,
      raw: false,
      defval: "",
    }) as unknown[][];

    const parsed = parseBarcodeRowsDetailed(rows);
    expect(parsed.barcodes).toEqual(["8690504030012", "0012345678901"]);
  });

  it("hydrates xlsx rows when full template columns exist", () => {
    const worksheet = xlsx.utils.aoa_to_sheet([
      ["barcode", "product_name", "brand", "ingredients", "quantity_value", "quantity_unit", "data_source", "data_updated_at"],
      ["8690574114658", "Pepsi Kola Kutu", "Pepsi", "Su, şeker", "330", "ml", "product_packaging", "2026-07-01"],
    ]);
    const rows = xlsx.utils.sheet_to_json(worksheet, {
      header: 1,
      raw: false,
      defval: "",
    }) as unknown[][];

    const parsed = parseProductFinderRows(rows);
    expect(parsed.mode).toBe("full_template");
    if (parsed.mode === "full_template") {
      expect(parsed.rows[0]?.product_name).toBe("Pepsi Kola Kutu");
    }
  });

  it("tracks duplicates and invalid values from mixed sources", () => {
    const parsed = parseBarcodeCsvDetailed(
      "barcode\n8690504030012\n8690504030012\n153\n0012345678901",
    );

    expect(parsed.barcodes).toEqual(["8690504030012", "153", "0012345678901"]);
    expect(parsed.duplicatesRemoved).toBe(1);
    expect(parsed.invalidCount).toBe(1);
  });

  it("barcode only csv still stays in barcode-only mode", () => {
    const parsed = parseProductFinderCsv("barcode\n8690504030012\n0012345678901");
    expect(parsed.mode).toBe("barcode_only");
  });

  it("blocks batches above 100 unique barcodes", () => {
    const batch = validateBarcodeBatch(
      Array.from({ length: 101 }, (_, index) => `${8690504030000 + index}`),
    );

    expect(batch.ok).toBe(false);
    expect(batch.error).toBe("En fazla 100 benzersiz barkod işlenebilir.");
  });
});

describe("product finder validation", () => {
  it("marks mock candidates as needs review with missing ingredients", () => {
    const candidate = revalidateCandidate(createMockCandidate("8690504030012"));
    expect(candidate.approved_for_export).toBe(false);
    expect(candidate.issue_list.some((item) => item.code === "ingredients_missing")).toBe(true);
  });

  it("flags invalid barcodes and keeps them out of review-ready flow", () => {
    const candidate = revalidateCandidate(createMockCandidate("abc123"));
    expect(candidate.status).toBe("rejected");
    expect(candidate.issue_list.some((item) => item.code === "invalid_barcode")).toBe(true);
    expect(candidate.approved_for_export).toBe(false);
  });

  it("keeps invalid numeric barcode blocked from approval/export until fixed", () => {
    let candidate = revalidateCandidate(createMockCandidate("153"));
    candidate = updateCandidateField(candidate, "product_name", "Test");
    candidate = updateCandidateField(candidate, "ingredients", "Su");
    candidate = updateCandidateField(candidate, "data_source", "product_finder");
    candidate = approveCandidate(candidate);

    expect(candidate.issue_list.some((item) => item.code === "invalid_barcode")).toBe(true);
    expect(candidate.approved_for_export).toBe(false);
    expect(candidate.is_verified).toBe(false);
  });

  it("revalidates invalid barcode to normal flow after barcode fix", () => {
    let candidate = revalidateCandidate(createMockCandidate("153"));
    candidate = updateCandidateField(candidate, "barcode", "8690504030012");

    expect(candidate.issue_list.some((item) => item.code === "invalid_barcode")).toBe(false);
    expect(candidate.status).toBe("needs_review");
  });

  it("accepts comma and dot decimals through field parser", () => {
    let candidate = createMockCandidate("8690504030012");
    candidate = updateCandidateField(candidate, "salt_100g", "0,03");
    expect(candidate.salt_100g).toBe(0.03);
    candidate = updateCandidateField(candidate, "sugars_100g", "10.6");
    expect(candidate.sugars_100g).toBe(10.6);
  });

  it("keeps empty decimal input as null", () => {
    let candidate = createMockCandidate("8690504030012");
    candidate = updateCandidateField(candidate, "salt_100g", "");
    expect(candidate.salt_100g).toBeNull();
  });

  it("keeps strict verified false until all strict fields exist", () => {
    let candidate = revalidateCandidate(createMockCandidate("8690504030012"));
    candidate = updateCandidateField(candidate, "product_name", "Ornek Urun 330 ml");
    candidate = updateCandidateField(candidate, "brand", "Ornek");
    candidate = updateCandidateField(candidate, "ingredients", "Su, seker");
    candidate = approveCandidate(candidate);
    expect(candidate.is_verified).toBe(false);
  });

  it("sets verified true only when strict fields exist", () => {
    let candidate = revalidateCandidate(createMockCandidate("8690504030012"));
    candidate = updateCandidateField(candidate, "product_name", "Ornek Urun 330 ml");
    candidate = updateCandidateField(candidate, "brand", "Ornek");
    candidate = updateCandidateField(candidate, "ingredients", "Su, seker");
    candidate = updateCandidateField(candidate, "quantity_value", "330");
    candidate = updateCandidateField(candidate, "quantity_unit", "ml");
    candidate = updateCandidateField(candidate, "source_url", "https://example.com");
    candidate = updateCandidateField(candidate, "nutrition_basis", "100ml");
    candidate = updateCandidateField(candidate, "energy_kcal_100g", "42");
    candidate = updateCandidateField(candidate, "fat_100g", "0");
    candidate = updateCandidateField(candidate, "saturated_fat_100g", "0");
    candidate = updateCandidateField(candidate, "carbohydrates_100g", "10");
    candidate = updateCandidateField(candidate, "sugars_100g", "10");
    candidate = updateCandidateField(candidate, "protein_100g", "0");
    candidate = updateCandidateField(candidate, "salt_100g", "0.01");
    candidate = approveCandidate(candidate);
    expect(candidate.is_verified).toBe(true);
    expect(candidate.approved_for_export).toBe(true);
  });
});

describe("product finder export", () => {
  it("maps candidates to exact 31-column order", () => {
    let candidate = revalidateCandidate(createMockCandidate("8690504030012"));
    candidate = updateCandidateField(candidate, "product_name", "Ornek");
    candidate = updateCandidateField(candidate, "ingredients", "Su");
    candidate = updateCandidateField(candidate, "brand", "Marka");
    candidate = updateCandidateField(candidate, "quantity_value", "100");
    candidate = updateCandidateField(candidate, "quantity_unit", "g");
    candidate = updateCandidateField(candidate, "source_url", "https://example.com");
    candidate = updateCandidateField(candidate, "nutrition_basis", "100g");
    candidate = updateCandidateField(candidate, "energy_kcal_100g", "10");
    candidate = updateCandidateField(candidate, "fat_100g", "1");
    candidate = updateCandidateField(candidate, "saturated_fat_100g", "1");
    candidate = updateCandidateField(candidate, "carbohydrates_100g", "1");
    candidate = updateCandidateField(candidate, "sugars_100g", "1");
    candidate = updateCandidateField(candidate, "protein_100g", "1");
    candidate = updateCandidateField(candidate, "salt_100g", "1");
    candidate = approveCandidate(candidate);

    const row = mapCandidateToImportRow(candidate);
    expect(Object.keys(row)).toEqual([...importTemplateHeaders]);

    const matrix = buildExportMatrix([candidate]);
    expect(matrix[0]).toEqual([...importTemplateHeaders]);
    expect(matrix).toHaveLength(2);
  });

  it("exports decimal values cleanly", () => {
    let candidate = createMockCandidate("8690504030012");
    candidate = updateCandidateField(candidate, "product_name", "Pepsi");
    candidate = updateCandidateField(candidate, "ingredients", "Su, şeker");
    candidate = updateCandidateField(candidate, "brand", "Pepsi");
    candidate = updateCandidateField(candidate, "quantity_value", "330");
    candidate = updateCandidateField(candidate, "quantity_unit", "ml");
    candidate = updateCandidateField(candidate, "data_source", "product_packaging");
    candidate = updateCandidateField(candidate, "data_updated_at", "2026-07-01");
    candidate = updateCandidateField(candidate, "salt_100g", "0,03");
    candidate = approveCandidate(candidate);

    const row = mapCandidateToImportRow(candidate);
    expect(row.salt_100g).toBe(0.03);
  });

  it("summarizes status counts", () => {
    const candidates = [
      revalidateCandidate(createMockCandidate("8690504030012")),
      revalidateCandidate(createMockCandidate("0012345678901")),
    ];
    const summary = summarizeCandidates(candidates);
    expect(summary.total).toBe(2);
    expect(summary.needsReview).toBe(2);
  });
});
