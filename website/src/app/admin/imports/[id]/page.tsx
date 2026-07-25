import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { formatDateTime } from "@/lib/admin/imports/helpers";
import { getImportJobById, getImportRowsByJobId } from "@/lib/admin/imports/products";
import { getAdminDiagnostics, getAdminGateState } from "@/lib/admin/auth";

export const metadata: Metadata = {
  title: "Import Detayı",
  description: "LabelWise admin paneli import detay sayfası.",
  robots: {
    index: false,
    follow: false,
  },
};

type Props = {
  params: Promise<{ id: string }>;
};

export default async function AdminImportDetailPage({ params }: Props) {
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
        title="Import detayı"
        description="Seçilen import işinin sonucu güvenli biçimde gösterilemedi."
      >
        <AdminStatusCard
          title="Import detayı açılamadı"
          message="Admin paneli açılamadı. Supabase ortam değişkenleri, migration ve admin_users kaydı kontrol edilmeli."
          actionLabel="Import listesine dön"
          actionHref="/admin/imports"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  let job;
  let rows;

  try {
    job = await getImportJobById(id);
    if (!job) {
      notFound();
    }
    rows = await getImportRowsByJobId(id);
  } catch {
    const diagnostics = await getAdminDiagnostics();
    return (
      <AdminShell
        title="Import detayı"
        description="Seçilen import işinin sonucu güvenli biçimde gösterilemedi."
      >
        <AdminStatusCard
          title="Import detayı yüklenemedi"
          message="Import detayları okunamadı."
          actionLabel="Import listesine dön"
          actionHref="/admin/imports"
          diagnostics={diagnostics}
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title={job.file_name}
      description="Bu ekranda import işinin özetini, satır sonuçlarını ve indirilebilir hata CSV bağlantısını görebilirsiniz."
    >
      <div className="flex flex-wrap items-center gap-3">
        <Link href="/admin/imports" className="button-secondary min-h-11 px-5">
          Import listesine dön
        </Link>
        <a href={`/api/admin/imports/${job.id}/issues`} className="button-secondary min-h-11 px-5">
          Hatalı satır CSV indir
        </a>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ["Durum", job.status],
          ["Toplam satır", String(job.total_rows)],
          ["Eklenen", String(job.inserted_rows)],
          ["Güncellenen", String(job.updated_rows)],
          ["Atlanan", String(job.skipped_rows)],
          ["Hatalı", String(job.failed_rows)],
          ["Oluşturma", formatDateTime(job.created_at)],
          ["Tamamlanma", formatDateTime(job.completed_at)],
        ].map(([label, value]) => (
          <div key={label} className="card p-5">
            <div className="text-xs uppercase tracking-[0.2em] text-[color:var(--text-soft)]">{label}</div>
            <div className="mt-3 text-lg font-semibold text-white">{value}</div>
          </div>
        ))}
      </div>

      <div className="card overflow-hidden">
        <div className="border-b border-white/8 px-6 py-5">
          <h2 className="text-xl font-semibold text-white">Satır sonuçları</h2>
          <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
            Ön izleme ve içe aktarma sırasında kaydedilen tüm satırlar burada görünür.
          </p>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full text-left">
            <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
              <tr>
                <th className="px-6 py-4">Satır</th>
                <th className="px-6 py-4">Barkod</th>
                <th className="px-6 py-4">Ürün</th>
                <th className="px-6 py-4">Durum</th>
                <th className="px-6 py-4">Hatalar</th>
                <th className="px-6 py-4">Uyarılar</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => {
                const normalized = row.normalized_data as {
                  productName?: string | null;
                };
                const errors = Array.isArray(row.validation_errors) ? row.validation_errors : [];
                const warnings = Array.isArray(row.validation_warnings) ? row.validation_warnings : [];
                return (
                  <tr key={row.id} className="border-t border-white/8 align-top">
                    <td className="px-6 py-4 text-sm text-white/82">{row.row_number}</td>
                    <td className="px-6 py-4 text-sm text-white/92">{row.barcode || "—"}</td>
                    <td className="px-6 py-4 text-sm text-white">{normalized.productName || "—"}</td>
                    <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{row.status}</td>
                    <td className="px-6 py-4 text-xs leading-6 text-rose-200">
                      {errors.length > 0
                        ? errors.map((item) => (typeof item === "object" && item && "message" in item ? String(item.message) : "")).join(" • ")
                        : "—"}
                    </td>
                    <td className="px-6 py-4 text-xs leading-6 text-amber-100">
                      {warnings.length > 0
                        ? warnings.map((item) => (typeof item === "object" && item && "message" in item ? String(item.message) : "")).join(" • ")
                        : "—"}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  );
}
