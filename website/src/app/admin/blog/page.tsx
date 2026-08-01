import Link from "next/link";
import { AdminBlogRowActions } from "@/components/admin-blog-row-actions";
import { AdminShell } from "@/components/admin-shell";
import { requireAdminUser } from "@/lib/admin/auth";
import { getAllBlogPostsForAdmin } from "@/lib/blog/queries";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "Europe/Istanbul",
  }).format(new Date(value));
}

export default async function AdminBlogPage() {
  await requireAdminUser();
  const posts = await getAllBlogPostsForAdmin();

  return (
    <AdminShell
      title="Blog Yazıları"
      description="Taslak ve yayındaki LabelWise blog yazılarını buradan yönetebilirsin."
    >
      <section className="card p-6 sm:p-8">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-2xl font-semibold text-white">Yazı listesi</h2>
            <p className="mt-2 text-sm leading-7 text-[color:var(--text-muted)]">
              Taslaklar herkese görünmez. Yayındaki yazılar otomatik olarak /blog altında listelenir.
            </p>
          </div>
          <Link href="/admin/blog/new" className="button-primary min-h-11 px-5">
            Yeni blog yazısı
          </Link>
        </div>

        {posts.length === 0 ? (
          <div className="mt-6 rounded-[1.5rem] border border-dashed border-white/12 bg-white/[0.03] p-6">
            <p className="text-sm leading-7 text-[color:var(--text-muted)]">
              Henüz yazı yok. İlk yazıyı oluşturup taslak olarak kaydedebilirsin.
            </p>
          </div>
        ) : (
          <div className="mt-6 overflow-hidden rounded-[1.5rem] border border-white/8">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-white/8 text-sm">
                <thead className="bg-white/[0.03] text-left text-[color:var(--text-soft)]">
                  <tr>
                    <th className="px-4 py-4 font-medium">Başlık</th>
                    <th className="px-4 py-4 font-medium">Durum</th>
                    <th className="px-4 py-4 font-medium">Kategori</th>
                    <th className="px-4 py-4 font-medium">Yayın</th>
                    <th className="px-4 py-4 font-medium">Güncelleme</th>
                    <th className="px-4 py-4 text-right font-medium">Aksiyonlar</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/8">
                  {posts.map((post) => (
                    <tr key={post.id} className="align-top">
                      <td className="px-4 py-4">
                        <div className="font-medium text-white">{post.title}</div>
                        <div className="mt-1 text-xs text-[color:var(--text-soft)]">/{post.slug}</div>
                      </td>
                      <td className="px-4 py-4">
                        <span
                          className={`rounded-full px-3 py-1 text-xs font-semibold ${
                            post.status === "published"
                              ? "bg-emerald-400/12 text-emerald-100"
                              : "bg-white/8 text-white/72"
                          }`}
                        >
                          {post.status === "published" ? "Yayında" : "Taslak"}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-[color:var(--text-muted)]">{post.category ?? "—"}</td>
                      <td className="px-4 py-4 text-[color:var(--text-muted)]">{formatDate(post.published_at)}</td>
                      <td className="px-4 py-4 text-[color:var(--text-muted)]">{formatDate(post.updated_at)}</td>
                      <td className="px-4 py-4">
                        <AdminBlogRowActions post={post} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </section>
    </AdminShell>
  );
}
