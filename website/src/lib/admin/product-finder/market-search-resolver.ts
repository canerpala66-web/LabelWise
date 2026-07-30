import { fetchMigrosProductByUrl } from "@/lib/admin/product-finder/adapters/migros";
import {
  buildMigrosSearchQuery,
  searchMigrosProducts,
  type MigrosSearchCandidate,
} from "@/lib/admin/product-finder/adapters/migros-search";
import type { ProductIdentityResult, SourceCandidate } from "@/lib/admin/product-finder/providers";

export type MarketResolveInput = {
  id: string;
  barcode: string;
  brand?: string | null;
  product_name?: string | null;
  quantity_value?: number | null;
  quantity_unit?: string | null;
  variant?: string | null;
};

export type MarketResolveResult = {
  candidate_id: string;
  barcode: string;
  status: "enriched" | "needs_market_review" | "not_found" | "source_error";
  selected_source_url: string | null;
  match_confidence: number | null;
  match_reasons: string[];
  parsed_candidate: SourceCandidate | null;
  market_candidates: MigrosSearchCandidate[];
  note?: string;
};

function toIdentity(input: MarketResolveInput): ProductIdentityResult | null {
  if (!input.product_name?.trim()) {
    return null;
  }

  return {
    providerId: "market-input",
    barcode: input.barcode,
    raw_name: input.product_name,
    brand: input.brand?.trim() || null,
    product_name: input.product_name.trim(),
    quantity_value: input.quantity_value ?? null,
    quantity_unit: input.quantity_unit?.trim() || null,
    quantity_display:
      input.quantity_value != null && input.quantity_unit
        ? `${input.quantity_value} ${input.quantity_unit}`
        : null,
    variant: input.variant?.trim() || null,
    source_name: "market-input",
    source_url: null,
    confidence: 80,
    issues: [],
  };
}

function shouldAutoAccept(candidates: MigrosSearchCandidate[]) {
  const best = candidates[0];
  const second = candidates[1];

  if (!best) return false;
  if (best.match_confidence < 85) return false;
  if (second && best.match_confidence - second.match_confidence < 10) return false;
  return true;
}

export async function resolveMarketCandidate(
  input: MarketResolveInput,
): Promise<MarketResolveResult> {
  const identity = toIdentity(input);

  if (!identity) {
    return {
      candidate_id: input.id,
      barcode: input.barcode,
      status: "not_found",
      selected_source_url: null,
      match_confidence: null,
      match_reasons: [],
      parsed_candidate: null,
      market_candidates: [],
      note: "Ürün adı olmadan market araması yapılamadı.",
    };
  }

  const search = await searchMigrosProducts(identity);

  if (search.status !== "ok") {
    return {
      candidate_id: input.id,
      barcode: input.barcode,
      status: search.status,
      selected_source_url: null,
      match_confidence: null,
      match_reasons: [],
      parsed_candidate: null,
      market_candidates: search.candidates,
      note: search.reason,
    };
  }

  if (!search.candidates.length) {
    return {
      candidate_id: input.id,
      barcode: input.barcode,
      status: "not_found",
      selected_source_url: null,
      match_confidence: null,
      match_reasons: [],
      parsed_candidate: null,
      market_candidates: [],
      note: `Migros araması sonuç vermedi: ${buildMigrosSearchQuery(identity)}`,
    };
  }

  const selected = search.candidates[0] ?? null;

  if (!selected || !shouldAutoAccept(search.candidates)) {
    return {
      candidate_id: input.id,
      barcode: input.barcode,
      status: "needs_market_review",
      selected_source_url: selected?.source_url ?? null,
      match_confidence: selected?.match_confidence ?? null,
      match_reasons: selected?.match_reasons ?? [],
      parsed_candidate: null,
      market_candidates: search.candidates.slice(0, 5),
      note: "Migros sonucu bulundu ancak otomatik seçim için güven yeterli değil.",
    };
  }

  const parsedCandidate = await fetchMigrosProductByUrl(selected.source_url);
  parsedCandidate.barcode = input.barcode;

  return {
    candidate_id: input.id,
    barcode: input.barcode,
    status: "enriched",
    selected_source_url: selected.source_url,
    match_confidence: selected.match_confidence,
    match_reasons: selected.match_reasons,
    parsed_candidate: parsedCandidate,
    market_candidates: search.candidates.slice(0, 5),
  };
}

export async function resolveMarketCandidates(inputs: MarketResolveInput[]) {
  const results = await Promise.all(inputs.map((input) => resolveMarketCandidate(input)));

  const summary = results.reduce(
    (acc, item) => {
      acc.total += 1;
      acc[item.status] += 1;
      return acc;
    },
    {
      total: 0,
      enriched: 0,
      needs_market_review: 0,
      not_found: 0,
      source_error: 0,
    } as Record<string, number>,
  );

  return { results, summary };
}
