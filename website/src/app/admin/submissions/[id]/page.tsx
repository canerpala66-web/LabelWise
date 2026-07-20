import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { AdminShell } from "@/components/admin-shell";
import { SubmissionDetailForm } from "@/components/submission-detail-form";
import { requireAdminUser } from "@/lib/admin/auth";
import {
  buildSignedSubmissionImages,
  getSubmittedProductById,
  normalizeSubmissionStatus,
} from "@/lib/admin/submissions";

export const metadata: Metadata = {
  title: "Gonderim Detayi",
  description: "LabelWise admin paneli gonderim detay ekrani.",
  robots: {
    index: false,
    follow: false,
  },
};

type Props = {
  params: Promise<{ id: string }>;
};

export default async function SubmissionDetailPage({ params }: Props) {
  await requireAdminUser();

  const { id } = await params;
  const submission = await getSubmittedProductById(id);

  if (!submission) {
    notFound();
  }

  const signedImages = await buildSignedSubmissionImages(submission);
  const normalizedStatus = normalizeSubmissionStatus(submission.status);

  return (
    <AdminShell
      title={submission.name || "Urun gonderimi"}
      description="Alanlari duzenleyebilir, admin notu ekleyebilir ve guvenli sekilde onay veya ret islemi yapabilirsin."
    >
      <div className="flex flex-wrap items-center gap-3">
        <Link href="/admin/submissions" className="button-secondary min-h-11 px-5">
          Listeye don
        </Link>
        <span className="rounded-full border border-white/10 bg-white/6 px-4 py-2 text-sm font-medium text-white/82">
          Durum: {normalizedStatus === "approved" ? "Onaylandi" : normalizedStatus === "rejected" ? "Reddedildi" : "Beklemede"}
        </span>
      </div>
      <SubmissionDetailForm submission={submission} images={signedImages} />
    </AdminShell>
  );
}
