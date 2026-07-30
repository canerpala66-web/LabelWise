import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { fetchMigrosProductByUrl, validateMigrosProductUrl } from "@/lib/admin/product-finder/adapters/migros";

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

    return NextResponse.json({ error: "Migros parser yetkisi doğrulanamadı." }, { status: 500 });
  }

  let body: { url?: string };
  try {
    body = (await request.json()) as { url?: string };
  } catch {
    return NextResponse.json({ error: "Geçerli bir JSON body gerekli." }, { status: 400 });
  }

  const url = body.url?.trim() ?? "";
  if (!validateMigrosProductUrl(url)) {
    return NextResponse.json(
      { error: "Geçerli bir Migros ürün URL’si girin." },
      { status: 400 },
    );
  }

  try {
    const candidate = await fetchMigrosProductByUrl(url);
    return NextResponse.json(
      { candidate },
      {
        status: 200,
        headers: { "Cache-Control": "no-store" },
      },
    );
  } catch {
    return NextResponse.json(
      { error: "Migros ürün URL’si çözümlenemedi." },
      { status: 500 },
    );
  }
}
