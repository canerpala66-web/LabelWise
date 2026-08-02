import { AdminBlogPostForm } from "@/components/admin-blog-post-form";
import { AdminShell } from "@/components/admin-shell";
import { createBlogPostAction } from "@/lib/admin/blog-actions";
import { requireAdminUser } from "@/lib/admin/auth";

export default async function AdminNewBlogPostPage() {
  await requireAdminUser();

  return (
    <AdminShell
      title="Yeni Blog Yazısı"
      description="Markdown ile yaz, taslak olarak kaydet veya yayınla."
    >
      <AdminBlogPostForm action={createBlogPostAction} submitLabel="Yayınla" />
    </AdminShell>
  );
}
