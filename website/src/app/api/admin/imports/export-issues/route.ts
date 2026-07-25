import { NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { buildRowIssuesCsv } from "@/lib/admin/imports/export";
import type { ValidationMessage } from "@/lib/admin/imports/types";

type ExportBody = {
  rows?: Array<{
    rowNumber: number;
    barcode: string | null;
    productName: string | null;
    brand: string | null;
    errors: Array<{ message: string; code: string; severity: "error" | "warning"; field?: string }>;
    warnings: Array<{ message: string; code: string; severity: "error" | "warning"; field?: string }>;
  }>;
};

export async function POST(request: Request) {
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

  try {
    const body = (await request.json()) as ExportBody;
    const rows = Array.isArray(body.rows) ? body.rows : [];

    const csv = buildRowIssuesCsv(rows.map((row) => ({
      rowNumber: row.rowNumber,
      barcode: row.barcode,
      productName: row.productName,
      brand: row.brand,
      errors: (row.errors ?? []) as ValidationMessage[],
      warnings: (row.warnings ?? []) as ValidationMessage[],
    })));

    return new NextResponse(csv, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": 'attachment; filename="labelwise-import-issues.csv"',
        "Cache-Control": "no-store",
      },
    });
  } catch {
    return NextResponse.json({ error: "CSV hazırlanamadı." }, { status: 400 });
  }
}
