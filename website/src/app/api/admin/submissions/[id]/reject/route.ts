import { NextResponse } from "next/server";
import { requireAdminUser } from "@/lib/admin/auth";
import { extractDraftPayload, rejectSubmission, saveSubmissionDraft } from "@/lib/admin/submissions";

type Props = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, { params }: Props) {
  try {
    const admin = await requireAdminUser();
    const { id } = await params;
    const formData = await request.formData();

    await saveSubmissionDraft(id, formData);
    const payload = extractDraftPayload(formData);
    await rejectSubmission(id, admin.userId, payload.review_note);

    return NextResponse.json({ message: "Urun reddedildi." });
  } catch {
    return NextResponse.json(
      { message: "Urun reddedilemedi." },
      { status: 500 },
    );
  }
}
