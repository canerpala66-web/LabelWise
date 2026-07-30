import { describe, expect, it } from "vitest";
import { extractIdentityFromSearchResults } from "@/lib/admin/product-finder/search-result-identity-extractor";

describe("search result identity extractor", () => {
  it("extracts product identity from clear title", () => {
    const identity = extractIdentityFromSearchResults("8690574114658", [
      {
        title: "8690574114658 Pepsi Kola Kutu 330 ml",
        snippet: "Pepsi kola kutu ürün detayı",
        url: "https://example.com/pepsi",
        domain: "example.com",
      },
    ]);

    expect(identity?.brand).toBe("Pepsi");
    expect(identity?.product_name).toBe("Pepsi Kola Kutu");
    expect(identity?.quantity_value).toBe(330);
    expect(identity?.quantity_unit).toBe("ml");
  });

  it("extracts quantity 1 L and variant tokens", () => {
    const identity = extractIdentityFromSearchResults("1234567890123", [
      {
        title: "1234567890123 Coca-Cola Zero 1 L",
        snippet: "Şekersiz kola",
        url: "https://example.com/coke-zero",
        domain: "example.com",
      },
    ]);

    expect(identity?.quantity_value).toBe(1);
    expect(identity?.quantity_unit).toBe("l");
    expect(identity?.variant).toBe("zero");
  });

  it("increases confidence when same identity repeats across results", () => {
    const identity = extractIdentityFromSearchResults("8690574114658", [
      {
        title: "8690574114658 Pepsi Kola Kutu 330 ml",
        snippet: "Ürün",
        url: "https://example.com/1",
        domain: "example.com",
      },
      {
        title: "Pepsi Kola Kutu 330 ml barkod 8690574114658",
        snippet: "Market sonucu",
        url: "https://market.test/2",
        domain: "market.test",
      },
    ]);

    expect((identity?.confidence ?? 0)).toBeGreaterThanOrEqual(80);
    expect(identity?.evidence_results?.length).toBeGreaterThan(0);
  });

  it("adds conflict issue when contradictory names appear", () => {
    const identity = extractIdentityFromSearchResults("8690574114658", [
      {
        title: "8690574114658 Pepsi Kola Kutu 330 ml",
        snippet: "Pepsi ürün",
        url: "https://example.com/1",
        domain: "example.com",
      },
      {
        title: "8690574114658 Fanta Portakal 330 ml",
        snippet: "Başka ürün",
        url: "https://example.com/2",
        domain: "example.com",
      },
    ]);

    expect(identity?.issues.some((issue) => issue.code === "web_search_conflict")).toBe(true);
  });

  it("ignores irrelevant coupon-like results", () => {
    const identity = extractIdentityFromSearchResults("8690574114658", [
      {
        title: "8690574114658 indirim kuponu",
        snippet: "Kupon kampanya",
        url: "https://coupon.test/1",
        domain: "coupon.test",
      },
    ]);

    expect(identity).toBeNull();
  });
});
