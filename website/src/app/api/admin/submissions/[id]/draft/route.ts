import { NextResponse } from "next/server";
import { requireAdminUser } from "@/lib/admin/auth";
import { saveSubmissionDraft } from "@/lib/admin/submissions";

type Props = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, { params }: Props) {
  try {
    await requireAdminUser();
    const { id } = await params;
    const formData = await request.formData();
    await saveSubmissionDraft(id, formData);

    return NextResponse.json({ message: "Degisiklikler kaydedildi." });
  } catch {
    return NextResponse.json(
      { message: "Degisiklikler kaydedilemedi." },
      { status: 500 },
    );
  }
}
