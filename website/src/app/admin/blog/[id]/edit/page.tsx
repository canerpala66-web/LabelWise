import Link from "next/link";
import { notFound } from "next/navigation";
import { AdminBlogPostForm } from "@/components/admin-blog-post-form";
import { AdminShell } from "@/components/admin-shell";
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
  const post = await getBlogPostByIdForAdmin(id);

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
