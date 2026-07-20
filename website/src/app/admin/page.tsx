import { redirect } from "next/navigation";
import { AdminStatusCard } from "@/components/admin-status-card";
import { getAdminGateState } from "@/lib/admin/auth";

export default async function AdminIndexPage() {
  const { session, isAdmin, error } = await getAdminGateState();

  if (error) {
    return (
      <main className="relative overflow-hidden">
        <section className="mx-auto flex min-h-[60vh] w-full max-w-5xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
          <AdminStatusCard
            title="Panel yuklenemedi"
            message={error}
            actionLabel="Admin girisine don"
            actionHref="/admin/login"
          />
        </section>
      </main>
    );
  }

  if (!session) {
    redirect("/admin/login");
  }

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  redirect("/admin/submissions");
}
