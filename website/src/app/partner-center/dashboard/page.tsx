import type { Metadata } from "next";
import Link from "next/link";
import { PartnerLogoutButton } from "@/components/partner-logout-button";
import { requireActivePartner } from "@/lib/partners/auth";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "Partner Dashboard",
  description: "LabelWise partner önizleme paneli.",
  robots: {
    index: false,
    follow: false,
  },
};

export const dynamic = "force-dynamic";

const statCards = [
  { title: "Link tıklamaları", value: "Yakında" },
  { title: "Kayıtlar", value: "Hazırlanıyor" },
  { title: "Premium dönüşümler", value: "Hazırlanıyor" },
  { title: "Aylık paket", value: "Yakında" },
  { title: "Yıllık paket", value: "Yakında" },
];

export default async function PartnerDashboardPage() {
  const { partner } = await requireActivePartner();
  const supabase = await createSupabaseServerClient();

  const { data: links } = await supabase
    .from("partner_links")
    .select("slug,destination_url,is_active,created_at")
    .eq("partner_id", partner.id)
    .order("created_at", { ascending: true })
    .limit(1);

  const primaryLink = links?.[0] ?? null;
  const referralUrl = primaryLink
    ? `https://labelwise.net/r/${primaryLink.slug}`
    : "Henüz özel bir yönlendirme linki oluşturulmadı.";

  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[24rem] opacity-75" />

      <section className="mx-auto w-full max-w-7xl px-6 pb-14 pt-10 sm:px-8 lg:px-10 lg:pb-18 lg:pt-14">
        <div className="glass-panel p-8 sm:p-10 lg:p-12">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <span className="hero-pill">Partner Dashboard</span>
              <h1 className="mt-5 font-display text-4xl leading-tight text-white sm:text-5xl">
                Hoş geldin, {partner.display_name}
              </h1>
              <p className="mt-4 max-w-3xl text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
                Bu panel şu anda partner önizleme sürecindedir. Nihai istatistik ve
                hak ediş ekranları daha sonra aktif edilecektir.
              </p>
            </div>

            <PartnerLogoutButton />
          </div>

          <div className="mt-10 grid gap-6 lg:grid-cols-2">
            <article className="card p-6 sm:p-7">
              <span className="section-label">Demo erişimi</span>
              <h2 className="mt-4 text-2xl font-semibold text-white">
                Tarayıcıdan ürün deneyimini önizle
              </h2>
              <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
                Web demo akışı partner değerlendirmeleri için ayrı bir güvenli alanda
                ilerleyecek. Bu adım, ürün hissini ve temel kullanıcı yolculuğunu
                göstermek için hazırlanıyor.
              </p>
              <div className="mt-6">
                <Link href="/partner-center/demo" className="button-primary">
                  Demo alanını aç
                </Link>
              </div>
            </article>

            <article className="card p-6 sm:p-7">
              <span className="section-label">Yönlendirme linki</span>
              <h2 className="mt-4 text-2xl font-semibold text-white">
                Partner bağlantın
              </h2>
              <p className="mt-4 break-all rounded-[1.35rem] border border-white/8 bg-white/[0.03] px-4 py-4 text-sm leading-7 text-white/88">
                {referralUrl}
              </p>
              <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
                Link tıklama takibi ve kampanya istatistikleri bu panelde aşamalı
                olarak aktif edilecek.
              </p>
            </article>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 pb-8 sm:px-8 lg:px-10">
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
          {statCards.map((card) => (
            <article key={card.title} className="card p-5">
              <span className="section-label">{card.title}</span>
              <p className="mt-4 text-2xl font-semibold text-white">{card.value}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
