import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { SubmissionDetailForm } from "@/components/submission-detail-form";
import { getAdminDiagnostics, getAdminGateState } from "@/lib/admin/auth";
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
  const { session, isAdmin, error } = await getAdminGateState();

  if (!session) {
    redirect("/admin/login");
  }

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  const { id } = await params;

  if (error) {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Gonderim detayi"
        description="Secilen gonderim detaylari guvenli sekilde yuklenemedi."
      >
        <AdminStatusCard
          title="Sayfa yuklenemedi"
          message="Admin paneli açılamadı. Supabase ortam değişkenleri, migration ve admin_users kaydı kontrol edilmeli."
          actionLabel="Listeye don"
          actionHref="/admin/submissions"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  let submission;
  let signedImages;

  try {
    submission = await getSubmittedProductById(id);
    if (!submission) {
      notFound();
    }
    signedImages = await buildSignedSubmissionImages(submission);
  } catch {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Gonderim detayi"
        description="Secilen gonderim detaylari guvenli sekilde yuklenemedi."
      >
        <AdminStatusCard
          title="Gonderim yuklenemedi"
          message="Gonderimler yuklenemedi."
          actionLabel="Listeye don"
          actionHref="/admin/submissions"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }
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
