import Link from "next/link";
import { notFound } from "next/navigation";
import { AdminBlogPostForm } from "@/components/admin-blog-post-form";
import { AdminShell } from "@/components/admin-shell";
import { AdminStatusCard } from "@/components/admin-status-card";
import { updateBlogPostAction } from "@/lib/admin/blog-actions";
import { requireAdminUser } from "@/lib/admin/auth";
import { getBlogPostByIdForAdmin } from "@/lib/blog/queries";

type Props = {
  params: Promise<{
    id: string;
  }>;
};

export default async function AdminEditBlogPostPage({ params }: Props) {
  await requireAdminUser();
  const { id } = await params;
  let post = null;
  let postLoadError: string | null = null;

  try {
    post = await getBlogPostByIdForAdmin(id);
  } catch (error) {
    console.error("[admin/blog/edit] blog_posts query failed", { id, error });
    postLoadError = "Bu blog kaydı okunamadı. Tablo veya kayıt durumunu kontrol edin.";
  }

  if (postLoadError) {
    return (
      <main className="relative overflow-hidden">
        <section className="mx-auto flex min-h-[60vh] w-full max-w-5xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
          <AdminStatusCard
            title="Blog yazısı açılamadı"
            message={postLoadError}
            actionLabel="Blog listesine dön"
            actionHref="/admin/blog"
          />
        </section>
      </main>
    );
  }

  if (!post) {
    notFound();
  }

  return (
    <AdminShell
      title="Blog Yazısını Düzenle"
      description="Taslak ve yayın akışı aynı form üzerinden yönetilir. Public tarafta sadece yayındaki içerikler görünür."
    >
      <div className="flex justify-end">
        <Link
          href={post.status === "published" ? `/blog/${post.slug}` : "/blog"}
          className="button-secondary min-h-10 px-4"
        >
          {post.status === "published" ? "Public sayfayı aç" : "Blog listesini aç"}
        </Link>
      </div>
      <AdminBlogPostForm
        action={updateBlogPostAction}
        initialPost={post}
        submitLabel="Güncelle ve yayınla"
      />
    </AdminShell>
  );
}
