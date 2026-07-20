import type { Metadata } from "next";
import { AdminStatusCard } from "@/components/admin-status-card";
import { getAdminDiagnostics } from "@/lib/admin/auth";

export const metadata: Metadata = {
  title: "Admin Durumu",
  description: "LabelWise admin paneli baglanti ve yetki durumu.",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminStatusPage() {
  const diagnostics = await getAdminDiagnostics();

  return (
    <main className="relative overflow-hidden">
      <section className="mx-auto flex min-h-[70vh] w-full max-w-5xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        <AdminStatusCard
          title="Admin durum ozeti"
          message={diagnostics.message ?? "Admin paneli baglanti kontrolleri tamamlandi."}
          actionLabel="Admin girisine don"
          actionHref="/admin/login"
          diagnostics={diagnostics}
        />
      </section>
    </main>
  );
}
