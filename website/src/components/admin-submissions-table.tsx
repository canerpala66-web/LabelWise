import Link from "next/link";
import type { SubmissionStatus, SubmittedProduct } from "@/lib/admin/types";

const filters: Array<{ label: string; value: SubmissionStatus | "all" }> = [
  { label: "Bekleyen", value: "pending" },
  { label: "Onaylanan", value: "approved" },
  { label: "Reddedilen", value: "rejected" },
  { label: "Tum", value: "all" },
];

function statusLabel(status: string | null) {
  if (status === "approved") return "Onaylandi";
  if (status === "rejected") return "Reddedildi";
  return "Beklemede";
}

function formatDate(value: string | null) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

type Props = {
  items: SubmittedProduct[];
  activeFilter: SubmissionStatus | "all";
};

export function AdminSubmissionsTable({ items, activeFilter }: Props) {
  return (
    <div className="card overflow-hidden">
      <div className="flex flex-col gap-4 border-b border-white/8 px-6 py-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-semibold text-white">Urun gonderimleri</h2>
          <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
            Bekleyen gonderimleri incele, duzenle ve guvenli sekilde onayla.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          {filters.map((filter) => (
            <Link
              key={filter.value}
              href={`/admin/submissions?status=${filter.value}`}
              className={`rounded-full border px-4 py-2 text-sm font-medium ${
                activeFilter === filter.value
                  ? "border-[color:var(--gold)] bg-[rgba(200,169,107,0.16)] text-white"
                  : "border-white/10 bg-white/5 text-white/72 hover:text-white"
              }`}
            >
              {filter.label}
            </Link>
          ))}
        </div>
      </div>

      {items.length === 0 ? (
        <div className="px-6 py-12 text-center text-sm leading-7 text-[color:var(--text-muted)]">
          Bu filtre icin gonderim bulunamadi.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left">
            <thead className="bg-white/[0.03] text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
              <tr>
                <th className="px-6 py-4">Barkod</th>
                <th className="px-6 py-4">Urun</th>
                <th className="px-6 py-4">Marka</th>
                <th className="px-6 py-4">Kategori</th>
                <th className="px-6 py-4">Durum</th>
                <th className="px-6 py-4">Fotograf</th>
                <th className="px-6 py-4">Olusturma</th>
                <th className="px-6 py-4" />
              </tr>
            </thead>
            <tbody>
              {items.map((item) => {
                const hasPhotos = Boolean(
                  item.front_image_path ||
                    item.nutrition_image_path ||
                    item.ingredients_image_path,
                );

                return (
                  <tr key={item.id} className="border-t border-white/8">
                    <td className="px-6 py-4 text-sm text-white/92">{item.barcode}</td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-semibold text-white">{item.name || "Adsiz urun"}</div>
                      <div className="mt-1 text-xs text-[color:var(--text-soft)]">
                        #{item.id.slice(0, 8)}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                      {item.brand || "—"}
                    </td>
                    <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                      {item.category || "—"}
                    </td>
                    <td className="px-6 py-4">
                      <span className="rounded-full border border-white/10 bg-white/6 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-white/82">
                        {statusLabel(item.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                      {hasPhotos ? "Var" : "Yok"}
                    </td>
                    <td className="px-6 py-4 text-sm text-[color:var(--text-muted)]">
                      {formatDate(item.created_at)}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <Link
                        href={`/admin/submissions/${item.id}`}
                        className="inline-flex rounded-full border border-white/10 bg-white/6 px-4 py-2 text-sm font-medium text-white hover:border-[color:var(--gold)]"
                      >
                        Incele
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
