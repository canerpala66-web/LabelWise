import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AdminProductFinderClient } from "@/components/admin-product-finder-client";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { getAdminDiagnostics, getAdminGateState } from "@/lib/admin/auth";

export const metadata: Metadata = {
  title: "Ürün Bulucu",
  description: "LabelWise admin panelinde barkodlardan ürün adayı oluşturma ve XLSX export ekranı.",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminProductFinderPage() {
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
        title="Ürün Bulucu"
        description="Barkodlardan ürün adayı oluşturun, düzenleyin ve mevcut 31 kolonluk import formatına uygun XLSX çıktısı alın."
      >
        <AdminStatusCard
          title="Ürün Bulucu açılamadı"
          message="Admin paneli açılamadı."
          actionLabel="Admin girişine dön"
          actionHref="/admin/login"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title="Ürün Bulucu"
      description="Barkodlardan ürün adayları oluşturun, eksik alanları düzenleyin ve mevcut ürün içe aktarma formatıyla uyumlu XLSX çıktısı alın."
    >
      <AdminProductFinderClient />
    </AdminShell>
  );
}
