import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import {
  type BarcodeDiscoveryInput,
} from "@/lib/admin/product-finder/barcode-discovery";
import {
  discoverBarcodeCandidatesWithOpenAi,
  isOpenAiBarcodeDiscoveryConfigured,
} from "@/lib/admin/product-finder/openai-barcode-discovery";

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
  | "openai_web_search_not_configured"
  | "openai_search_error"
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

  const openAiConfigured = isOpenAiBarcodeDiscoveryConfigured();

  const results: Array<{
    id: string;
    status: CandidateStatus;
    barcode_candidates: Awaited<
      ReturnType<typeof discoverBarcodeCandidatesWithOpenAi>
    >["candidates"];
    queries: string[];
    notes?: string;
  }> = [];

  for (const rawCandidate of candidates) {
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
      results.push({
        id,
        status: "skipped_existing_barcode",
        barcode_candidates: [],
        queries: [],
      });
      continue;
    }

    if (!input.product_name) {
      results.push({
        id,
        status: "not_found",
        barcode_candidates: [],
        queries: [],
      });
      continue;
    }

    if (!openAiConfigured) {
      results.push({
        id,
        status: "openai_web_search_not_configured",
        barcode_candidates: [],
        queries: [],
      });
      continue;
    }

    const discoveryResult = await discoverBarcodeCandidatesWithOpenAi(input);
    const barcodeCandidates = discoveryResult.candidates;

    if (barcodeCandidates.length === 0) {
      results.push({
        id,
        status:
          discoveryResult.status === "openai_web_search_not_configured"
            ? "openai_web_search_not_configured"
            : discoveryResult.status === "openai_search_error"
              ? "openai_search_error"
              : "not_found",
        barcode_candidates: [],
        queries: [],
        notes: discoveryResult.notes,
      });
      continue;
    }

    const topConfidence = barcodeCandidates[0]?.confidence ?? "low";
    const status: CandidateStatus =
      topConfidence === "high"
        ? "high_confidence"
        : topConfidence === "medium"
          ? "medium_confidence"
          : "low_confidence";

    results.push({
      id,
      status,
      barcode_candidates: barcodeCandidates,
      queries: [],
      notes: discoveryResult.notes,
    });
  }

  return NextResponse.json(
    {
      results,
      summary: {
        total: results.length,
        with_candidates: results.filter((item) =>
          ["high_confidence", "medium_confidence", "low_confidence"].includes(item.status),
        ).length,
        not_found: results.filter((item) => item.status === "not_found").length,
        openai_web_search_not_configured: results.filter(
          (item) => item.status === "openai_web_search_not_configured",
        ).length,
        openai_search_error: results.filter((item) => item.status === "openai_search_error")
          .length,
        skipped_existing_barcode: results.filter(
          (item) => item.status === "skipped_existing_barcode",
        ).length,
      },
    },
    { status: 200, headers: { "Cache-Control": "no-store" } },
  );
}
