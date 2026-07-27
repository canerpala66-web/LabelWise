import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { PartnerAuthForm } from "@/components/partner-auth-form";
import { PartnerLogoutButton } from "@/components/partner-logout-button";
import { getCurrentPartnerProfile } from "@/lib/partners/auth";

export const metadata: Metadata = {
  title: "Partner Girişi",
  description: "LabelWise Partner Center için güvenli giriş ekranı.",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function PartnerLoginPage() {
  const { session, partner } = await getCurrentPartnerProfile();

  if (session?.user && partner?.status === "active") {
    redirect("/partner-center/dashboard");
  }

  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[28rem] opacity-80" />
      <section className="mx-auto flex min-h-[72vh] w-full max-w-6xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        {session?.user && (!partner || partner.status !== "active") ? (
          <div className="card w-full max-w-xl p-8 sm:p-10">
            <p className="text-xs font-semibold uppercase tracking-[0.32em] text-[color:var(--gold-soft)]">
              Erişim kısıtlı
            </p>
            <h1 className="mt-4 font-display text-4xl text-white">
              Bu hesap henüz partner olarak tanımlanmadı
            </h1>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Partner paneli yalnızca onaylı iş birliği hesapları için açılır.
              Farklı bir hesapla giriş yapabilir veya erişim talebi için bizimle
              iletişime geçebilirsiniz.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a
                href="mailto:canerpala66@gmail.com?subject=LabelWise%20Partner%20Eri%C5%9Fim%20Talebi"
                className="button-primary"
              >
                Erişim talep et
              </a>
              <PartnerLogoutButton />
            </div>
          </div>
        ) : (
          <PartnerAuthForm />
        )}
      </section>
    </main>
  );
}
