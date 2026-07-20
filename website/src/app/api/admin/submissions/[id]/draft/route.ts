import { NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { saveSubmissionDraft } from "@/lib/admin/submissions";

type Props = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, { params }: Props) {
  try {
    await requireAdminUserForApi();
    const { id } = await params;
    const formData = await request.formData();
    await saveSubmissionDraft(id, formData);

    return NextResponse.json({ message: "Degisiklikler kaydedildi." });
  } catch (error) {
    const message =
      error instanceof Error && error.message === "ADMIN_SESSION_MISSING"
        ? "Oturum bulunamadi."
        : error instanceof Error && error.message === "ADMIN_FORBIDDEN"
          ? "Admin yetkisi bulunamadi."
          : "Degisiklikler kaydedilemedi.";

    return NextResponse.json(
      { message },
      { status: 500 },
    );
  }
}
