import type { Metadata } from "next";
import { AdminShell } from "@/components/admin-shell";
import { AdminSubmissionsTable } from "@/components/admin-submissions-table";
import { requireAdminUser } from "@/lib/admin/auth";
import { listSubmittedProducts, normalizeSubmissionStatus } from "@/lib/admin/submissions";

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
  await requireAdminUser();

  const params = await searchParams;
  const rawStatus = params.status?.trim().toLowerCase();
  const status = rawStatus === "all" ? "all" : normalizeSubmissionStatus(rawStatus);
  const items = await listSubmittedProducts(status);

  return (
    <AdminShell
      title="Submitted product inceleme alani"
      description="Eksik urun olarak gonderilen kayitlari incele, duzenle ve products tablosuna guvenli sekilde aktar."
    >
      <AdminSubmissionsTable items={items} activeFilter={status} />
    </AdminShell>
  );
}
