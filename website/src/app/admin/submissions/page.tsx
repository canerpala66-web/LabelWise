import type { Metadata } from "next";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { AdminSubmissionsTable } from "@/components/admin-submissions-table";
import { getAdminDiagnostics, getAdminGateState } from "@/lib/admin/auth";
import { listSubmittedProducts, normalizeSubmissionStatus } from "@/lib/admin/submissions";
import { redirect } from "next/navigation";

export const metadata: Metadata = {
  title: "Admin Gonderimleri",
  description: "LabelWise admin panelinde gonderilen urunleri inceleyin.",
  robots: {
    index: false,
    follow: false,
  },
};

type Props = {
  searchParams: Promise<{
    status?: string;
  }>;
};

export default async function AdminSubmissionsPage({ searchParams }: Props) {
  const { session, isAdmin, error } = await getAdminGateState();

  if (!session) {
    redirect("/admin/login");
  }

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  const params = await searchParams;
  const rawStatus = params.status?.trim().toLowerCase();
  const status = rawStatus === "all" ? "all" : normalizeSubmissionStatus(rawStatus);

  if (error) {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Submitted product inceleme alani"
        description="Eksik urun olarak gonderilen kayitlari incele, duzenle ve products tablosuna guvenli sekilde aktar."
      >
        <AdminStatusCard
          title="Gonderimler yuklenemedi"
          message="Admin paneli açılamadı. Supabase ortam değişkenleri, migration ve admin_users kaydı kontrol edilmeli."
          actionLabel="Admin girisine don"
          actionHref="/admin/login"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  let items;

  try {
    items = await listSubmittedProducts(status);
  } catch {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Submitted product inceleme alani"
        description="Eksik urun olarak gonderilen kayitlari incele, duzenle ve products tablosuna guvenli sekilde aktar."
      >
        <AdminStatusCard
          title="Gonderimler yuklenemedi"
          message="Gonderimler yuklenemedi."
          actionLabel="Listeyi yenile"
          actionHref="/admin/submissions"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title="Submitted product inceleme alani"
      description="Eksik urun olarak gonderilen kayitlari incele, duzenle ve products tablosuna guvenli sekilde aktar."
    >
      <AdminSubmissionsTable items={items} activeFilter={status} />
    </AdminShell>
  );
}
