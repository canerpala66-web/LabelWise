import { NextResponse } from "next/server";
import { requireAdminUser } from "@/lib/admin/auth";
import { approveSubmission, saveSubmissionDraft } from "@/lib/admin/submissions";

type Props = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, { params }: Props) {
  try {
    const admin = await requireAdminUser();
    const { id } = await params;
    const formData = await request.formData();

    await saveSubmissionDraft(id, formData);
    await approveSubmission(id, admin.userId);

    return NextResponse.json({ message: "Urun onaylandi." });
  } catch (error) {
    const message =
      error instanceof Error && error.message === "SUBMISSION_INVALID"
        ? "Urun onaylanamadi. Barkod ve urun adi gerekli."
        : "Urun onaylanamadi.";

    return NextResponse.json({ message }, { status: 500 });
  }
}
