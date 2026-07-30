import { describe, expect, it } from "vitest";
import { buildMigrosSearchQuery, filterMigrosSearchResults, parseMigrosSearchHtml, scoreMigrosSearchCandidates } from "@/lib/admin/product-finder/adapters/migros-search";
import type { ProductIdentityResult } from "@/lib/admin/product-finder/providers";

const pepsiIdentity: ProductIdentityResult = {
  providerId: "test",
  barcode: "8690574114658",
  raw_name: "Pepsi Kola Kutu 330 ml",
  brand: "Pepsi",
  product_name: "Pepsi Kola Kutu",
  quantity_value: 330,
  quantity_unit: "ml",
  quantity_display: "330 ml",
  variant: null,
  source_name: "supabase",
  source_url: null,
  confidence: 96,
  issues: [],
};

describe("migros search adapter", () => {
  it("builds search query from resolved identity", () => {
    expect(buildMigrosSearchQuery(pepsiIdentity)).toBe("Pepsi Kola Kutu 330 ml");
  });

  it("scores exact size above wrong size", () => {
    const candidates = scoreMigrosSearchCandidates(pepsiIdentity, [
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
      "https://www.migros.com.tr/pepsi-kola-kutu-1-l-p-123456",
    ]);

    expect(candidates[0]?.source_url).toContain("330-ml");
    expect((candidates[0]?.match_confidence ?? 0)).toBeGreaterThan(
      candidates[1]?.match_confidence ?? 0,
    );
  });

  it("penalizes conflicting variants", () => {
    const candidates = scoreMigrosSearchCandidates(pepsiIdentity, [
      "https://www.migros.com.tr/pepsi-max-kutu-330-ml-p-111111",
      "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
    ]);

    expect(candidates[0]?.source_url).toContain("pepsi-kola-kutu-330-ml");
  });

  it("parses product urls from safe html", () => {
    const html = `
      <a href="/pepsi-kola-kutu-330-ml-p-7a3927">Pepsi</a>
      <a href="/pepsi-kola-kutu-1-l-p-123456">Pepsi 1L</a>
    `;

    const result = parseMigrosSearchHtml(html, pepsiIdentity);
    expect(result.status).toBe("ok");
    if (result.status === "ok") {
      expect(result.candidates[0]?.source_url).toContain("330-ml");
    }
  });

  it("returns source_error when cloudflare block html is detected", () => {
    const result = parseMigrosSearchHtml(
      "<html><title>Just a moment...</title>Enable JavaScript and cookies to continue cf_chl_opt</html>",
      pepsiIdentity,
    );

    expect(result.status).toBe("source_error");
    if (result.status !== "ok") {
      expect(result.blocked).toBe(true);
    }
  });

  it("filters only official Migros product detail urls", () => {
    const filtered = filterMigrosSearchResults([
      {
        title: "Pepsi Kola Kutu 330 ml",
        snippet: "",
        url: "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
        domain: "migros.com.tr",
        position: 1,
      },
      {
        title: "Migros arama",
        snippet: "",
        url: "https://www.migros.com.tr/arama?q=pepsi",
        domain: "migros.com.tr",
        position: 2,
      },
      {
        title: "Kategori",
        snippet: "",
        url: "https://www.migros.com.tr/kategori/icecek-c-1",
        domain: "migros.com.tr",
        position: 3,
      },
    ]);

    expect(filtered).toHaveLength(1);
    expect(filtered[0]?.url).toContain("-p-7a3927");
  });
});
