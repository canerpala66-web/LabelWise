import { NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { buildRowIssuesCsv } from "@/lib/admin/imports/export";
import { getImportRowsByJobId } from "@/lib/admin/imports/products";
import type { ValidationMessage } from "@/lib/admin/imports/types";

type Props = {
  params: Promise<{ id: string }>;
};

export async function GET(_: Request, { params }: Props) {
  try {
    await requireAdminUserForApi();
  } catch (error) {
    if (error instanceof Error && error.message === "ADMIN_SESSION_MISSING") {
      return NextResponse.json({ error: "Admin oturumu bulunamadı." }, { status: 401 });
    }

    if (error instanceof Error && error.message === "ADMIN_FORBIDDEN") {
      return NextResponse.json({ error: "Bu işlem için admin yetkisi gerekiyor." }, { status: 403 });
    }

    return NextResponse.json({ error: "CSV hazırlanamadı." }, { status: 500 });
  }

  const { id } = await params;

  try {
    const rows = await getImportRowsByJobId(id);
    const filteredRows = rows
      .map((row) => {
        const normalized = row.normalized_data as { productName?: string | null; brand?: string | null };
        return {
          rowNumber: row.row_number,
          barcode: row.barcode,
          productName: normalized.productName ?? null,
          brand: normalized.brand ?? null,
          errors: (row.validation_errors ?? []) as ValidationMessage[],
          warnings: (row.validation_warnings ?? []) as ValidationMessage[],
        };
      })
      .filter((row) => row.errors.length > 0 || row.warnings.length > 0);

    const csv = buildRowIssuesCsv(filteredRows);

    return new NextResponse(csv, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="labelwise-import-${id.slice(0, 8)}-issues.csv"`,
        "Cache-Control": "no-store",
      },
    });
  } catch {
    return NextResponse.json({ error: "CSV hazırlanamadı." }, { status: 400 });
  }
}
