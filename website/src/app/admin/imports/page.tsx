import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AdminImportHistoryTable } from "@/components/admin-import-history-table";
import { AdminImportsClient } from "@/components/admin-imports-client";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { getAdminDiagnostics, getAdminGateState } from "@/lib/admin/auth";
import { getImportJobs } from "@/lib/admin/imports/products";

export const metadata: Metadata = {
  title: "Admin Ürün İçe Aktarma",
  description: "LabelWise admin panelinde toplu ürün import ekranı.",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminImportsPage() {
  const { session, isAdmin, error } = await getAdminGateState();

  if (!session) {
    redirect("/admin/login");
  }

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  if (error) {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Ürün içe aktarma"
        description="Toplu ürün dosyalarını yükleyin, doğrulayın ve güvenli biçimde products tablosuna aktarın."
      >
        <AdminStatusCard
          title="Import ekranı açılamadı"
          message="Admin paneli açılamadı. Supabase ortam değişkenleri, migration ve admin_users kaydı kontrol edilmeli."
          actionLabel="Admin girişine dön"
          actionHref="/admin/login"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  let jobs = [];

  try {
    jobs = await getImportJobs();
  } catch {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Ürün içe aktarma"
        description="Toplu ürün dosyalarını yükleyin, doğrulayın ve güvenli biçimde products tablosuna aktarın."
      >
        <AdminStatusCard
          title="Import geçmişi yüklenemedi"
          message="Import geçmişi okunamadı."
          actionLabel="Listeyi yenile"
          actionHref="/admin/imports"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title="Ürün içe aktarma"
      description="CSV, XLSX veya JSON ürün dosyalarını önce doğrulayın, ardından açık onayla veritabanına aktarın."
    >
      <AdminImportsClient />
      <AdminImportHistoryTable jobs={jobs} />
    </AdminShell>
  );
}
