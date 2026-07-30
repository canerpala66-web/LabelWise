import { afterEach, describe, expect, it, vi } from "vitest";
import {
  __testables__,
  discoverBarcodeCandidatesWithOpenAi,
} from "@/lib/admin/product-finder/openai-barcode-discovery";

const input = {
  brand: "Pepsi",
  product_name: "Pepsi Kola Kutu",
  quantity_value: 330,
  quantity_unit: "ml",
  source_url: "https://www.migros.com.tr/pepsi-kola-kutu-330-ml-p-7a3927",
};

describe("openai barcode discovery", () => {
  const originalKey = process.env.OPENAI_API_KEY;

  afterEach(() => {
    process.env.OPENAI_API_KEY = originalKey;
    vi.restoreAllMocks();
  });

  it("returns openai_web_search_not_configured when key is missing", async () => {
    delete process.env.OPENAI_API_KEY;

    const result = await discoverBarcodeCandidatesWithOpenAi(input);

    expect(result.status).toBe("openai_web_search_not_configured");
    expect(result.candidates).toEqual([]);
  });

  it("accepts valid mocked OpenAI JSON with evidence", async () => {
    process.env.OPENAI_API_KEY = "test-key";
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          output_text: JSON.stringify({
            status: "found",
            candidates: [
              {
                barcode: "8690574114658",
                confidence: "high",
                score: 0.93,
                evidence: [
                  {
                    title: "Pepsi Kola Kutu 330 ml barkod",
                    url: "https://example.com/pepsi",
                    snippet: "8690574114658 barkod numarası",
                  },
                ],
                reasons: ["brand matched"],
                warnings: [],
              },
            ],
          }),
        }),
      }),
    );

    const result = await discoverBarcodeCandidatesWithOpenAi(input);

    expect(result.status).toBe("found");
    expect(result.candidates[0]?.barcode).toBe("8690574114658");
  });

  it("rejects invalid barcode returned by AI", () => {
    const candidate = __testables__.normalizeCandidate({
      barcode: "153",
      confidence: "high",
      score: 0.99,
      evidence: [
        {
          title: "Test",
          url: "https://example.com",
          snippet: "Test",
        },
      ],
    });

    expect(candidate).toBeNull();
  });

  it("rejects candidate without evidence", () => {
    const candidate = __testables__.normalizeCandidate({
      barcode: "8690574114658",
      confidence: "high",
      score: 0.99,
      evidence: [],
    });

    expect(candidate).toBeNull();
  });

  it("dedupes duplicate barcode candidates", () => {
    const deduped = __testables__.dedupeCandidates([
      {
        barcode: "8690574114658",
        confidence: "medium",
        score: 0.7,
        evidence: [
          {
            title: "A",
            url: "https://a.example",
            snippet: "A",
            domain: "a.example",
          },
        ],
        reasons: [],
        warnings: [],
      },
      {
        barcode: "8690574114658",
        confidence: "high",
        score: 0.91,
        evidence: [
          {
            title: "B",
            url: "https://b.example",
            snippet: "B",
            domain: "b.example",
          },
        ],
        reasons: [],
        warnings: [],
      },
    ]);

    expect(deduped).toHaveLength(1);
    expect(deduped[0]?.score).toBe(0.91);
  });
});
