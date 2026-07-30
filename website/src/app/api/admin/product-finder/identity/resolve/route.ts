import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { openFoodFactsIdentityProvider } from "@/lib/admin/product-finder/adapters/openfoodfacts-identity";
import { supabaseIdentityProvider } from "@/lib/admin/product-finder/adapters/supabase-identity";
import { webSearchIdentityProvider } from "@/lib/admin/product-finder/adapters/web-search-identity";
import { resolveBarcodeIdentityBatch } from "@/lib/admin/product-finder/barcode-identity-resolver";

type RequestBody = {
  barcodes?: unknown;
};

function sanitizeBarcodes(input: unknown) {
  if (!Array.isArray(input)) return [];

  return input
    .map((item) => (typeof item === "string" ? item.trim() : ""))
    .filter(Boolean)
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
      { error: "Barkod kimliği çözümleme yetkisi doğrulanamadı." },
      { status: 500 },
    );
  }

  let body: RequestBody;
  try {
    body = (await request.json()) as RequestBody;
  } catch {
    return NextResponse.json({ error: "Geçerli bir JSON body gerekli." }, { status: 400 });
  }

  const barcodes = sanitizeBarcodes(body.barcodes);
  if (barcodes.length === 0) {
    return NextResponse.json(
      { error: "En az bir barkod gönderilmeli." },
      { status: 400 },
    );
  }

  if (barcodes.length > 100) {
    return NextResponse.json(
      { error: "En fazla 100 barkod gönderilebilir." },
      { status: 400 },
    );
  }

  const payload = await resolveBarcodeIdentityBatch(barcodes, [
    supabaseIdentityProvider,
    openFoodFactsIdentityProvider,
    webSearchIdentityProvider,
  ]);

  return NextResponse.json(payload, {
    status: 200,
    headers: { "Cache-Control": "no-store" },
  });
}
