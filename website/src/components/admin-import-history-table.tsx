import Link from "next/link";
import { formatDateTime } from "@/lib/admin/imports/helpers";
import type { ImportJobRecord } from "@/lib/admin/imports/types";

function statusLabel(status: string) {
  switch (status) {
    case "completed":
      return "Tamamlandı";
    case "partially_completed":
      return "Kısmen tamamlandı";
    case "failed":
      return "Başarısız";
    case "importing":
      return "İçe aktarılıyor";
    default:
      return "Hazırlanıyor";
  }
}

export function AdminImportHistoryTable({ jobs }: { jobs: ImportJobRecord[] }) {
  return (
    <div className="card overflow-hidden">
      <div className="flex flex-col gap-3 border-b border-white/8 px-6 py-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">Import geçmişi</h2>
          <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
            Tamamlanan ve bekleyen toplu içe aktarma işlerini buradan takip edebilirsiniz.
          </p>
        </div>
      </div>
      {jobs.length === 0 ? (
        <div className="px-6 py-10 text-sm text-[color:var(--text-muted)]">
          Henüz kaydedilmiş bir import işi bulunmuyor.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left">
            <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
              <tr>
                <th className="px-6 py-4">Dosya</th>
                <th className="px-6 py-4">Oluşturan</th>
                <th className="px-6 py-4">Tarih</th>
                <th className="px-6 py-4">Durum</th>
                <th className="px-6 py-4">Toplam</th>
                <th className="px-6 py-4">Eklendi</th>
                <th className="px-6 py-4">Güncellendi</th>
                <th className="px-6 py-4">Atlandı</th>
                <th className="px-6 py-4">Hatalı</th>
                <th className="px-6 py-4" />
              </tr>
            </thead>
            <tbody>
              {jobs.map((job) => (
                <tr key={job.id} className="border-t border-white/8">
                  <td className="px-6 py-4 text-sm text-white/92">
                    <div className="font-semibold">{job.file_name}</div>
                    <div className="mt-1 text-xs text-[color:var(--text-soft)]">
                      {job.file_type.toUpperCase()} · {(job.file_size / 1024).toFixed(1)} KB
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                    {job.created_by ? `Admin · ${job.created_by.slice(0, 8)}` : "Admin"}
                  </td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                    {formatDateTime(job.created_at)}
                  </td>
                  <td className="px-6 py-4">
                    <span className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-white/82">
                      {statusLabel(job.status)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{job.total_rows}</td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{job.inserted_rows}</td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{job.updated_rows}</td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{job.skipped_rows}</td>
                  <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">{job.failed_rows}</td>
                  <td className="px-6 py-4 text-right">
                    <Link
                      href={`/admin/imports/${job.id}`}
                      className="inline-flex rounded-full border border-white/10 bg-white/6 px-4 py-2 text-sm font-medium text-white hover:border-[color:var(--gold)]"
                    >
                      Detay
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
