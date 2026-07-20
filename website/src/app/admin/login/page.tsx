import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { AdminAuthForm } from "@/components/admin-auth-form";
import { AdminStatusCard } from "@/components/admin-status-card";
import { getAdminGateState } from "@/lib/admin/auth";

export const metadata: Metadata = {
  title: "Admin Girisi",
  description: "LabelWise admin paneli icin guvenli giris ekrani.",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminLoginPage() {
  const { session, isAdmin, error } = await getAdminGateState();

  if (session && isAdmin) {
    redirect("/admin/submissions");
  }

  if (session && !isAdmin) {
    redirect("/admin/unauthorized");
  }

  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[28rem] opacity-80" />
      <section className="mx-auto flex min-h-[70vh] w-full max-w-6xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        {error ? (
          <AdminStatusCard
            title="Panel hazir degil"
            message={error}
            actionLabel="Ana sayfaya don"
            actionHref="/"
          />
        ) : (
          <AdminAuthForm />
        )}
      </section>
    </main>
  );
}
