import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import {
  buildBarcodeDiscoveryQueries,
  extractBarcodeCandidatesFromResults,
  type BarcodeDiscoveryInput,
} from "@/lib/admin/product-finder/barcode-discovery";
import {
  isSerperConfigured,
  searchWithSerper,
  type SearchProviderResult,
} from "@/lib/admin/product-finder/search-provider";

type RequestCandidate = {
  id?: unknown;
  barcode?: unknown;
  brand?: unknown;
  product_name?: unknown;
  quantity_value?: unknown;
  quantity_unit?: unknown;
  source_url?: unknown;
};

type RequestBody = {
  candidates?: unknown;
};

type CandidateStatus =
  | "high_confidence"
  | "medium_confidence"
  | "low_confidence"
  | "not_found"
  | "search_not_configured"
  | "source_error"
  | "skipped_existing_barcode";

function asText(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function asNumber(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

export async function POST(request: NextRequest) {
  try {
    await requireAdminUserForApi();
  } catch (error) {
    if (error instanceof Error && error.message === "ADMIN_SESSION_MISSING") {
      return NextResponse.json({ error: "Admin oturumu bulunamadı." }, { status: 401 });
    }
    if (error instanceof Error && error.message === "ADMIN_FORBIDDEN") {
      return NextResponse.json({ error: "Bu işlem için admin yetkisi gerekiyor." }, { status: 403 });
    }
    return NextResponse.json(
      { error: "Barkod aday çözümleme yetkisi doğrulanamadı." },
      { status: 500 },
    );
  }

  let body: RequestBody;
  try {
    body = (await request.json()) as RequestBody;
  } catch {
    return NextResponse.json({ error: "Geçerli bir JSON body gerekli." }, { status: 400 });
  }

  const candidates = Array.isArray(body.candidates) ? body.candidates : [];

  if (candidates.length === 0) {
    return NextResponse.json({ error: "En az bir candidate gönderilmeli." }, { status: 400 });
  }

  if (candidates.length > 100) {
    return NextResponse.json({ error: "En fazla 100 candidate gönderilebilir." }, { status: 400 });
  }

  const serperConfigured = isSerperConfigured();

  const results = await Promise.all(
    candidates.map(async (rawCandidate) => {
      const candidate = rawCandidate as RequestCandidate;
      const id = asText(candidate.id);
      const barcode = asText(candidate.barcode);
      const input: BarcodeDiscoveryInput = {
        brand: asText(candidate.brand),
        product_name: asText(candidate.product_name),
        quantity_value: asNumber(candidate.quantity_value),
        quantity_unit: asText(candidate.quantity_unit),
        source_url: asText(candidate.source_url),
      };

      if (barcode) {
        return {
          id,
          status: "skipped_existing_barcode" as const,
          barcode_candidates: [],
          queries: [] as string[],
        };
      }

      if (!input.product_name) {
        return {
          id,
          status: "not_found" as const,
          barcode_candidates: [],
          queries: [] as string[],
        };
      }

      const queries = buildBarcodeDiscoveryQueries(input);

      if (queries.length === 0) {
        return {
          id,
          status: "not_found" as const,
          barcode_candidates: [],
          queries,
        };
      }

      if (!serperConfigured) {
        return {
          id,
          status: "search_not_configured" as const,
          barcode_candidates: [],
          queries,
        };
      }

      const mergedResults: SearchProviderResult[] = [];
      let sawSourceError = false;

      for (const query of queries) {
        const response = await searchWithSerper(query);

        if (response.status === "ok") {
          mergedResults.push(...response.results);
          continue;
        }

        if (response.status === "source_unavailable") {
          return {
            id,
            status: "search_not_configured" as const,
            barcode_candidates: [],
            queries,
          };
        }

        sawSourceError = true;
      }

      const barcodeCandidates = extractBarcodeCandidatesFromResults(input, mergedResults);

      if (barcodeCandidates.length === 0) {
        return {
          id,
          status: sawSourceError ? ("source_error" as const) : ("not_found" as const),
          barcode_candidates: [],
          queries,
        };
      }

      const topConfidence = barcodeCandidates[0]?.confidence ?? "low";
      const status: CandidateStatus =
        topConfidence === "high"
          ? "high_confidence"
          : topConfidence === "medium"
            ? "medium_confidence"
            : "low_confidence";

      return {
        id,
        status,
        barcode_candidates: barcodeCandidates,
        queries,
      };
    }),
  );

  return NextResponse.json(
    {
      results,
      summary: {
        total: results.length,
        with_candidates: results.filter((item) =>
          ["high_confidence", "medium_confidence", "low_confidence"].includes(item.status),
        ).length,
        not_found: results.filter((item) => item.status === "not_found").length,
        search_not_configured: results.filter((item) => item.status === "search_not_configured")
          .length,
        source_error: results.filter((item) => item.status === "source_error").length,
        skipped_existing_barcode: results.filter(
          (item) => item.status === "skipped_existing_barcode",
        ).length,
      },
    },
    { status: 200, headers: { "Cache-Control": "no-store" } },
  );
}
