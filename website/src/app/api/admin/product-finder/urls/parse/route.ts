import { NextRequest, NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { fetchMigrosProductByUrl } from "@/lib/admin/product-finder/adapters/migros";
import { parseProductUrlTextarea } from "@/lib/admin/product-finder/url-input";

type RequestBody = {
  urls?: unknown;
};

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

    return NextResponse.json({ error: "URL çözümleme yetkisi doğrulanamadı." }, { status: 500 });
  }

  let body: RequestBody;
  try {
    body = (await request.json()) as RequestBody;
  } catch {
    return NextResponse.json({ error: "Geçerli bir JSON body gerekli." }, { status: 400 });
  }

  const rawUrls = Array.isArray(body.urls)
    ? body.urls.filter((item): item is string => typeof item === "string").join("\n")
    : "";

  const parsed = parseProductUrlTextarea(rawUrls);
  if (parsed.urls.length === 0) {
    return NextResponse.json({ error: "En az bir desteklenen ürün URL’si gerekli." }, { status: 400 });
  }

  if (parsed.urls.length > 100) {
    return NextResponse.json({ error: "En fazla 100 ürün URL’si gönderilebilir." }, { status: 400 });
  }

  const results = await Promise.all(
    parsed.urls.map(async (item) => {
      try {
        const candidate = await fetchMigrosProductByUrl(item.url);
        candidate.barcode = "";
        return {
          url: item.url,
          status: "parsed" as const,
          candidate,
          issues: candidate.issue_list,
        };
      } catch {
        return {
          url: item.url,
          status: "source_error" as const,
          candidate: null,
          issues: [
            {
              code: "source_error" as const,
              message: "Ürün URL’si çözümlenemedi.",
              severity: "warning" as const,
            },
          ],
        };
      }
    }),
  );

  return NextResponse.json(
    {
      results,
      summary: {
        total: results.length,
        parsed: results.filter((item) => item.status === "parsed").length,
        source_error: results.filter((item) => item.status === "source_error").length,
        invalid: parsed.invalidCount,
        unsupported_domain: parsed.unsupportedCount,
        duplicates_removed: parsed.duplicatesRemoved,
      },
    },
    {
      status: 200,
      headers: { "Cache-Control": "no-store" },
    },
  );
}
