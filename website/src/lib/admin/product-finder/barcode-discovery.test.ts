import { describe, expect, it } from "vitest";
import {
  buildBarcodeDiscoveryQueries,
  extractBarcodeCandidatesFromResults,
} from "@/lib/admin/product-finder/barcode-discovery";
import type { SearchProviderResult } from "@/lib/admin/product-finder/search-provider";

const pepsiInput = {
  brand: "Pepsi",
  product_name: "Pepsi Kola Kutu",
  quantity_value: 330,
  quantity_unit: "ml",
};

function createResult(
  overrides: Partial<SearchProviderResult>,
): SearchProviderResult {
  return {
    title: "Pepsi Kola Kutu 330 ml barkod 8690574114658",
    snippet: "Pepsi barkod bilgisi 8690574114658 olarak listeleniyor.",
    url: "https://example.com/pepsi",
    domain: "example.com",
    position: 1,
    ...overrides,
  };
}

describe("barcode discovery", () => {
  it("builds deterministic queries", () => {
    expect(buildBarcodeDiscoveryQueries(pepsiInput)).toEqual([
      "Pepsi Pepsi Kola Kutu 330 ml barkod",
      "Pepsi Pepsi Kola Kutu 330 ml barcode",
      "Pepsi Pepsi Kola Kutu 330 ml 869",
    ]);
  });

  it("extracts EAN-like barcode from title", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [createResult({})]);
    expect(results[0]?.barcode).toBe("8690574114658");
  });

  it("extracts barcode from snippet", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [
      createResult({
        title: "Pepsi ürün bilgisi",
        snippet: "Bu ürünün barkodu 8690574114658 olarak geçiyor.",
      }),
    ]);

    expect(results[0]?.barcode).toBe("8690574114658");
  });

  it("ignores unrelated phone and date-like numbers", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [
      createResult({
        title: "Pepsi çağrı hattı 905551112233",
        snippet: "Son güncelleme 20260730 fiyat 3300",
      }),
    ]);

    expect(results).toHaveLength(0);
  });

  it("deduplicates same barcode across multiple results", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [
      createResult({ domain: "example-one.com" }),
      createResult({ domain: "example-two.com", position: 2 }),
    ]);

    expect(results).toHaveLength(1);
    expect(results[0]?.evidence).toHaveLength(2);
  });

  it("scores stronger when brand, name and quantity all match", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [createResult({})]);
    expect(results[0]?.score).toBeGreaterThanOrEqual(0.8);
  });

  it("lowers score when quantity conflicts", () => {
    const matching = extractBarcodeCandidatesFromResults(pepsiInput, [createResult({})])[0];
    const mismatched = extractBarcodeCandidatesFromResults(pepsiInput, [
      createResult({
        title: "Pepsi Kola 1 L barkod 8690574114658",
        snippet: "Pepsi 1 L ürün barkodu 8690574114658",
      }),
    ])[0];

    expect(matching?.score ?? 0).toBeGreaterThan(mismatched?.score ?? 0);
    expect(mismatched?.warnings).toContain("quantity mismatch");
  });

  it("lowers score when variant conflicts", () => {
    const zeroInput = {
      ...pepsiInput,
      product_name: "Pepsi Max",
    };

    const results = extractBarcodeCandidatesFromResults(zeroInput, [
      createResult({
        title: "Pepsi Kola 330 ml barkod 8690574114658",
        snippet: "Klasik Pepsi için barkod sonucu",
      }),
    ]);

    expect(results[0]?.warnings).toContain("variant conflict");
  });

  it("raises confidence when same barcode repeats with good evidence", () => {
    const results = extractBarcodeCandidatesFromResults(pepsiInput, [
      createResult({ domain: "migros.com.tr" }),
      createResult({ domain: "openfoodfacts.org", position: 2 }),
      createResult({ domain: "market.example", position: 3 }),
    ]);

    expect(results[0]?.confidence).toBe("high");
  });
});
