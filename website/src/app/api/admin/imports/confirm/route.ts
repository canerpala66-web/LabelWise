import { NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { confirmImport } from "@/lib/admin/imports/confirm";
import { importModes, type ImportMode } from "@/lib/admin/imports/types";

type ConfirmBody = {
  preview: unknown;
  importMode: unknown;
  allowStaleOverride: unknown;
};

export async function POST(request: Request) {
  let session;

  try {
    session = await requireAdminUserForApi();
  } catch (error) {
    if (error instanceof Error && error.message === "ADMIN_SESSION_MISSING") {
      return NextResponse.json({ error: "Admin oturumu bulunamadı." }, { status: 401 });
    }

    if (error instanceof Error && error.message === "ADMIN_FORBIDDEN") {
      return NextResponse.json({ error: "Bu işlem için admin yetkisi gerekiyor." }, { status: 403 });
    }

    return NextResponse.json({ error: "İçe aktarma onayı verilemedi." }, { status: 500 });
  }

  try {
    const body = (await request.json()) as ConfirmBody;
    if (!body || typeof body !== "object") {
      return NextResponse.json({ error: "İstek gövdesi okunamadı." }, { status: 400 });
    }

    const importMode: ImportMode | null =
      typeof body.importMode === "string" && importModes.includes(body.importMode as never)
        ? (body.importMode as ImportMode)
        : null;

    if (!importMode) {
      return NextResponse.json({ error: "Geçerli bir import modu seçilmelidir." }, { status: 400 });
    }

    if (!body.preview || typeof body.preview !== "object" || !Array.isArray((body.preview as { rows?: unknown[] }).rows)) {
      return NextResponse.json({ error: "Ön izleme verisi eksik veya bozuk." }, { status: 400 });
    }

    const result = await confirmImport({
      preview: body.preview as Parameters<typeof confirmImport>[0]["preview"],
      importMode,
      allowStaleOverride: Boolean(body.allowStaleOverride),
      createdBy: session.userId,
    });

    return NextResponse.json(result, {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error && error.message
            ? error.message
            : "İçe aktarma onayı sırasında beklenmeyen bir hata oluştu.",
      },
      { status: 400 },
    );
  }
}
