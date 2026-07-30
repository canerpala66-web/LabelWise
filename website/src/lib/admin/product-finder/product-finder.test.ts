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
import { normalizeIdentity } from "./identity-normalizer";
import { createHydratedCandidateFromImportRow, createMockCandidate } from "./mock";
import {
  applyCandidateSuggestions,
  applySuggestionsToCandidates,
  getCandidateSuggestionState,
} from "./candidate-suggestions";
import { mapSourceCandidateToProductFinderCandidate } from "./source-candidate-mapper";
import { parseProductUrlTextarea } from "./url-input";
import { mockBarcodeIdentityProvider, mockProductDetailProvider } from "./adapters/mock-provider";
import { webSearchIdentityProvider } from "./adapters/web-search-identity";
import { resolveBarcodeIdentity, resolveBarcodeIdentityBatch } from "./barcode-identity-resolver";
import {
  isEligibleForMockResolution,
  resolveProductFinderCandidate,
  resolutionToProductFinderCandidate,
} from "./resolver";
import type { SourceCandidate } from "./providers";
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

  it("normalizes messy identity fields into reviewable output", () => {
    const normalized = normalizeIdentity({
      barcode: "8690574114658",
      rawName: "Pepsi Kola 330ML",
      productName: "Pepsi Kola 330ML",
      brand: "Pepsi",
      quantityText: "330ML",
      sourceName: "openfoodfacts",
      sourceUrl: "https://world.openfoodfacts.org/product/8690574114658",
    });

    expect(normalized.brand).toBe("Pepsi");
    expect(normalized.product_name).toBe("Pepsi Kola");
    expect(normalized.quantity_value).toBe(330);
    expect(normalized.quantity_unit).toBe("ml");
    expect(normalized.quantity_display).toBe("330 ml");
  });

  it("marks low-confidence identity when quantity and brand are weak", () => {
    const normalized = normalizeIdentity({
      barcode: "12345678",
      rawName: "Marka",
      productName: "Marka",
      brand: "",
      quantityText: "",
      sourceName: "openfoodfacts",
    });

    expect(normalized.issues.some((issue) => issue.code === "brand_missing")).toBe(true);
    expect(normalized.issues.some((issue) => issue.code === "quantity_missing")).toBe(true);
    expect(
      normalized.issues.some((issue) => issue.code === "low_identity_confidence"),
    ).toBe(true);
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

  it("resolves barcode identity from providers without product detail fetch", async () => {
    const result = await resolveBarcodeIdentity(
      { barcode: "8690574114658" },
      [mockBarcodeIdentityProvider],
    );

    expect(result.status).toBe("resolved");
    expect(result.identity?.product_name).toBe("Pepsi Kola Kutu");
    expect(result.identity?.quantity_display).toBe("330 ml");
  });

  it("returns invalid status for malformed barcodes in identity resolver", async () => {
    const result = await resolveBarcodeIdentity({ barcode: "153" }, [mockBarcodeIdentityProvider]);
    expect(result.status).toBe("invalid");
    expect(result.issues.some((issue) => issue.code === "invalid_barcode")).toBe(true);
  });

  it("builds identity batch summary safely", async () => {
    const batch = await resolveBarcodeIdentityBatch(
      ["8690574114658", "153"],
      [mockBarcodeIdentityProvider],
    );

    expect(batch.summary.total).toBe(2);
    expect(batch.summary.resolved).toBe(1);
    expect(batch.summary.invalid).toBe(1);
  });

  it("web search provider returns not configured issue cleanly when no key exists", async () => {
    const result = await resolveBarcodeIdentity(
      { barcode: "8690574114658" },
      [webSearchIdentityProvider],
    );

    expect(result.status).toBe("not_found");
    expect(
      result.issues.some((issue) => issue.code === "web_search_not_configured"),
    ).toBe(true);
    expect(
      result.source_attempts?.some((attempt) => attempt.providerId === "web-search-identity"),
    ).toBe(true);
  });

  it("maps source candidate to product finder candidate", () => {
    const sourceCandidate: SourceCandidate = {
      source_name: "migros",
      source_url: "https://www.migros.com.tr/test",
      source_product_id: "migros-123",
      barcode: "",
      brand: "Pepsi",
      product_name: "Pepsi Kola Kutu",
      quantity_value: 330,
      quantity_unit: "ml",
      quantity_display: "330 ml",
      variant: null,
      category: "Gazlı İçecek",
      ingredients: "Su, şeker",
      nutrition_basis: "100ml",
      energy_kcal_100g: 42,
      energy_kj_100g: 176,
      fat_100g: 0,
      saturated_fat_100g: 0,
      carbohydrates_100g: 10.6,
      sugars_100g: 10.6,
      fiber_100g: 0,
      protein_100g: 0,
      salt_100g: 0.03,
      sodium_100g: 0.012,
      image_front_url: "https://img.test/1.jpg",
      image_source_url: "https://img.test/1.jpg",
      data_updated_at: "2026-07-30",
      match_confidence: 82,
      issue_list: [],
    };

    const candidate = mapSourceCandidateToProductFinderCandidate(sourceCandidate);
    expect(candidate.product_name).toBe("Pepsi Kola Kutu");
    expect(candidate.data_source).toBe("migros");
    expect(candidate.serving_size).toBe("330 ml");
  });

  it("exports data_updated_at as ISO date string", () => {
    const candidate = createHydratedCandidateFromImportRow({
      barcode: "8690574114658",
      product_name: "Pepsi Kola Kutu",
      brand: "Pepsi",
      category: "Gazlı İçecek",
      ingredients: "Su, şeker",
      quantity_value: "330",
      quantity_unit: "ml",
      data_source: "migros",
      source_url: "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
      data_updated_at: "2026-07-30",
    });
    const row = mapCandidateToImportRow(candidate);
    const matrix = buildExportMatrix([{ ...candidate, approved_for_export: true }]);

    expect(row.data_updated_at).toBe("2026-07-30");
    expect(matrix[1]?.[importTemplateHeaders.indexOf("data_updated_at")]).toBe("2026-07-30");
  });

  it("exports nutrition table unavailable marker in verification notes", () => {
    let candidate = createHydratedCandidateFromImportRow({
      barcode: "8690574114658",
      product_name: "Bal",
      brand: "Marka",
      category: "Bal",
      ingredients: "Bal",
      data_source: "migros",
      source_url: "https://www.migros.com.tr/bal-p-1",
      data_updated_at: "2026-07-30",
    });
    candidate = updateCandidateField(candidate, "nutrition_table_not_available", "true");
    const row = mapCandidateToImportRow(candidate);
    expect(String(row.verification_notes)).toContain("nutrition_table_not_available:true");
  });

  it("migros candidate without barcode is not exportable", () => {
    const sourceCandidate: SourceCandidate = {
      source_name: "migros",
      source_url: "https://www.migros.com.tr/test",
      source_product_id: "migros-123",
      barcode: "",
      brand: "Pepsi",
      product_name: "Pepsi Kola Kutu",
      quantity_value: 330,
      quantity_unit: "ml",
      quantity_display: "330 ml",
      variant: null,
      category: "Gazlı İçecek",
      ingredients: "Su, şeker",
      nutrition_basis: "100ml",
      energy_kcal_100g: 42,
      energy_kj_100g: 176,
      fat_100g: 0,
      saturated_fat_100g: 0,
      carbohydrates_100g: 10.6,
      sugars_100g: 10.6,
      fiber_100g: 0,
      protein_100g: 0,
      salt_100g: 0.03,
      sodium_100g: 0.012,
      image_front_url: "https://img.test/1.jpg",
      image_source_url: "https://img.test/1.jpg",
      data_updated_at: "2026-07-30",
      match_confidence: 82,
      issue_list: [],
    };

    const candidate = mapSourceCandidateToProductFinderCandidate(sourceCandidate);
    expect(candidate.approved_for_export).toBe(false);
    expect(candidate.issue_list.some((item) => item.code === "invalid_barcode")).toBe(true);
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

  it("parses Migros product detail URLs from textarea and removes duplicates", () => {
    const parsed = parseProductUrlTextarea(`
https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927
https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927
https://www.migros.com.tr/coca-cola-1-l-p-123abc
    `);

    expect(parsed.rawCount).toBe(3);
    expect(parsed.parsedCount).toBe(2);
    expect(parsed.duplicatesRemoved).toBe(1);
    expect(parsed.urls.map((item) => item.url)).toEqual([
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
      "https://www.migros.com.tr/coca-cola-1-l-p-123abc",
    ]);
  });

  it("rejects Migros search/category URLs and invalid rows from textarea parsing", () => {
    const parsed = parseProductUrlTextarea(`
https://www.migros.com.tr/arama?q=pepsi
https://example.com/pepsi
bu-bir-url-degil
    `);

    expect(parsed.parsedCount).toBe(0);
    expect(parsed.unsupportedCount).toBe(2);
    expect(parsed.invalidCount).toBe(1);
  });

  it("maps URL parsed candidates with empty barcode into review flow", () => {
    const candidate = mapSourceCandidateToProductFinderCandidate(
      {
        barcode: "",
        product_name: "Pepsi Kola Kutu",
        brand: "Pepsi",
        category: "Gazlı İçecek",
        ingredients: "Su, şeker",
        quantity_value: 330,
        quantity_unit: "ml",
        quantity_display: "330 ml",
        energy_kcal_100g: 42,
        energy_kj_100g: 176,
        fat_100g: 0,
        saturated_fat_100g: 0,
        carbohydrates_100g: 10.6,
        sugars_100g: 10.6,
        fiber_100g: 0,
        protein_100g: 0,
        salt_100g: 0.02,
        sodium_100g: null,
        nutrition_basis: "100ml",
        image_front_url: "https://img.test/pepsi.jpg",
        source_name: "migros",
        source_url: "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
        source_product_id: "7a3927",
        match_confidence: null,
        issue_list: [],
        raw_payload: null,
        data_updated_at: "2026-07-30",
      },
      { candidateId: "finder-url-test" },
    );

    expect(candidate.id).toBe("finder-url-test");
    expect(candidate.barcode).toBe("");
    expect(candidate.status).toBe("rejected");
    expect(candidate.issue_list.some((item) => item.code === "invalid_barcode")).toBe(true);
  });

  it("preserves category and nutrition basis suggestions in source candidate mapping", () => {
    const candidate = mapSourceCandidateToProductFinderCandidate(
      {
        barcode: "",
        product_name: "Pepsi Kola Kutu",
        brand: "Pepsi",
        category: null,
        ingredients: "Su, şeker",
        quantity_value: 330,
        quantity_unit: "ml",
        quantity_display: "330 ml",
        energy_kcal_100g: 42,
        energy_kj_100g: 176,
        fat_100g: 0,
        saturated_fat_100g: 0,
        carbohydrates_100g: 10.6,
        sugars_100g: 10.6,
        fiber_100g: 0,
        protein_100g: 0,
        salt_100g: 0.02,
        sodium_100g: null,
        nutrition_basis: null,
        image_front_url: null,
        image_source_url: null,
        source_name: "migros",
        source_url: "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
        source_product_id: "7a3927",
        data_updated_at: "2026-07-30",
        match_confidence: 92,
        issue_list: [],
        raw_payload: {
          category_suggestion: "Gazlı İçecek",
          category_suggestion_reason: "ürün adındaki kola sinyaliyle önerildi",
          category_suggestion_confidence: "high",
          nutrition_basis_suggestion: "100ml",
          nutrition_basis_suggestion_reason: "miktar birimi ml olduğu için önerildi",
        },
      },
      { candidateId: "finder-url-suggestions" },
    );

    expect(candidate.category_suggestion).toBe("Gazlı İçecek");
    expect(candidate.category_suggestion_reason).toContain("kola");
    expect(candidate.nutrition_basis_suggestion).toBe("100ml");
    expect(candidate.nutrition_basis_suggestion_reason).toContain("ml");
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

  it("applying a discovered barcode keeps the row in manual review flow", () => {
    let candidate = revalidateCandidate(createMockCandidate(""));
    candidate = updateCandidateField(candidate, "product_name", "Pepsi Kola Kutu");
    candidate = updateCandidateField(candidate, "brand", "Pepsi");
    candidate = updateCandidateField(candidate, "barcode", "8690574114658");

    expect(candidate.barcode).toBe("8690574114658");
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

  it("uses nutrition_missing without nutrition table unavailable flag", () => {
    const candidate = revalidateCandidate(createMockCandidate("8690504030012"));
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(true);
    expect(candidate.issue_list.some((item) => item.code === "nutrition_table_not_available")).toBe(false);
  });

  it("uses nutrition_table_not_available flag instead of nutrition_missing", () => {
    let candidate = createMockCandidate("8690504030012");
    candidate = updateCandidateField(candidate, "nutrition_table_not_available", "true");
    expect(candidate.issue_list.some((item) => item.code === "nutrition_table_not_available")).toBe(true);
    expect(candidate.issue_list.some((item) => item.code === "nutrition_missing")).toBe(false);
    expect(candidate.verification_notes).toContain("nutrition_table_not_available:true");
  });
});

describe("product finder candidate suggestions", () => {
  it("detects applicable row-level suggestions", () => {
    const candidate = {
      ...createMockCandidate(""),
      product_name: "Pepsi Kola Kutu",
      category_suggestion: "Gazlı İçecek",
      category_suggestion_reason: "ürün adındaki kola sinyaliyle önerildi",
      nutrition_basis_suggestion: "100ml" as const,
      nutrition_basis_suggestion_reason: "miktar birimi ml olduğu için önerildi",
    };

    const state = getCandidateSuggestionState(candidate);
    expect(state.canApplyCategory).toBe(true);
    expect(state.canApplyNutritionBasis).toBe(true);
    expect(state.hasAnySuggestion).toBe(true);
  });

  it("applies row-level category and nutrition basis suggestions when fields are empty", () => {
    const candidate = {
      ...createMockCandidate(""),
      category_suggestion: "Gazlı İçecek",
      category_suggestion_reason: "ürün adındaki kola sinyaliyle önerildi",
      nutrition_basis_suggestion: "100ml" as const,
      nutrition_basis_suggestion_reason: "miktar birimi ml olduğu için önerildi",
    };

    const applied = applyCandidateSuggestions(candidate);
    expect(applied.candidate.category).toBe("Gazlı İçecek");
    expect(applied.candidate.nutrition_basis).toBe("100ml");
    expect(applied.candidate.issue_list.some((item) => item.code === "category_missing")).toBe(false);
    expect(applied.candidate.issue_list.some((item) => item.code === "nutrition_basis_missing")).toBe(false);
    expect(applied.counts.categoryApplied).toBe(1);
    expect(applied.counts.nutritionBasisApplied).toBe(1);
  });

  it("does not overwrite existing category or nutrition basis", () => {
    const candidate = {
      ...createMockCandidate(""),
      category: "Hazır İçecek",
      nutrition_basis: "100g" as const,
      category_suggestion: "Gazlı İçecek",
      nutrition_basis_suggestion: "100ml" as const,
    };

    const applied = applyCandidateSuggestions(candidate);
    expect(applied.candidate.category).toBe("Hazır İçecek");
    expect(applied.candidate.nutrition_basis).toBe("100g");
    expect(applied.counts.categoryApplied).toBe(0);
    expect(applied.counts.nutritionBasisApplied).toBe(0);
  });

  it("bulk applies suggestions across multiple candidates and returns counts", () => {
    const first = {
      ...createMockCandidate(""),
      category_suggestion: "Gazlı İçecek",
      nutrition_basis_suggestion: "100ml" as const,
    };
    const second = {
      ...createMockCandidate(""),
      category: "Bisküvi",
      category_suggestion: "Kraker",
      nutrition_basis_suggestion: "100g" as const,
    };

    const applied = applySuggestionsToCandidates([first, second]);
    expect(applied.candidates[0]?.category).toBe("Gazlı İçecek");
    expect(applied.candidates[0]?.nutrition_basis).toBe("100ml");
    expect(applied.candidates[1]?.category).toBe("Bisküvi");
    expect(applied.candidates[1]?.nutrition_basis).toBe("100g");
    expect(applied.counts.categoryApplied).toBe(1);
    expect(applied.counts.nutritionBasisApplied).toBe(2);
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
