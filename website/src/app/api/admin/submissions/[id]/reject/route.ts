import { NextResponse } from "next/server";
import { requireAdminUserForApi } from "@/lib/admin/auth";
import { extractDraftPayload, rejectSubmission, saveSubmissionDraft } from "@/lib/admin/submissions";

type Props = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, { params }: Props) {
  try {
    const admin = await requireAdminUserForApi();
    const { id } = await params;
    const formData = await request.formData();

    await saveSubmissionDraft(id, formData);
    const payload = extractDraftPayload(formData);
    await rejectSubmission(id, admin.userId, payload.review_note);

    return NextResponse.json({ message: "Urun reddedildi." });
  } catch (error) {
    const message =
      error instanceof Error && error.message === "ADMIN_SESSION_MISSING"
        ? "Oturum bulunamadi."
        : error instanceof Error && error.message === "ADMIN_FORBIDDEN"
          ? "Admin yetkisi bulunamadi."
          : error instanceof Error && error.message === "ADMIN_UNAVAILABLE"
            ? "Veri okunurken hata olustu."
            : "Urun reddedilemedi.";

    return NextResponse.json(
      { message },
      { status: 500 },
    );
  }
}
