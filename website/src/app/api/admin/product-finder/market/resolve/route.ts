import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import {
  resolveMarketCandidates,
  type MarketResolveInput,
} from "@/lib/admin/product-finder/market-search-resolver";

type RequestBody = {
  candidates?: unknown;
};

function sanitizeCandidates(input: unknown): MarketResolveInput[] {
  if (!Array.isArray(input)) return [];

  const results: MarketResolveInput[] = [];

  for (const item of input) {
    if (!item || typeof item !== "object") continue;
    const value = item as Record<string, unknown>;
    const candidate: MarketResolveInput = {
      id: typeof value.id === "string" ? value.id : "",
      barcode: typeof value.barcode === "string" ? value.barcode.trim() : "",
      brand: typeof value.brand === "string" ? value.brand : null,
      product_name: typeof value.product_name === "string" ? value.product_name : null,
      quantity_value:
        typeof value.quantity_value === "number" ? value.quantity_value : null,
      quantity_unit:
        typeof value.quantity_unit === "string" ? value.quantity_unit : null,
      variant: typeof value.variant === "string" ? value.variant : null,
    };

    if (candidate.id && candidate.barcode) {
      results.push(candidate);
    }
  }

  return results;
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
    return NextResponse.json({ error: "Migros arama yetkisi doğrulanamadı." }, { status: 500 });
  }

  let body: RequestBody;
  try {
    body = (await request.json()) as RequestBody;
  } catch {
    return NextResponse.json({ error: "Geçerli bir JSON body gerekli." }, { status: 400 });
  }

  const candidates = sanitizeCandidates(body.candidates);
  if (!candidates.length) {
    return NextResponse.json({ error: "En az bir aday gerekli." }, { status: 400 });
  }

  if (candidates.length > 100) {
    return NextResponse.json({ error: "En fazla 100 aday gönderilebilir." }, { status: 400 });
  }

  const payload = await resolveMarketCandidates(candidates);
  return NextResponse.json(payload, {
    status: 200,
    headers: { "Cache-Control": "no-store" },
  });
}
