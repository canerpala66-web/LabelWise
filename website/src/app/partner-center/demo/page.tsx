import type { Metadata } from "next";
import Link from "next/link";
import { requireActivePartner } from "@/lib/partners/auth";

export const metadata: Metadata = {
  title: "Partner Demo",
  description: "LabelWise partnerleri için korumalı demo alanı.",
  robots: {
    index: false,
    follow: false,
  },
};

export const dynamic = "force-dynamic";

export default async function PartnerDemoPage() {
  await requireActivePartner();

  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[24rem] opacity-75" />

      <section className="mx-auto w-full max-w-5xl px-6 pb-16 pt-10 sm:px-8 lg:px-10 lg:pt-14">
        <div className="glass-panel p-8 sm:p-10 lg:p-12">
          <span className="hero-pill">Partner Demo</span>
          <h1 className="mt-5 font-display text-4xl leading-tight text-white sm:text-5xl">
            Partner Demo
          </h1>
          <p className="mt-5 max-w-3xl text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
            LabelWise web önizlemesini yeni sekmede açarak deneyebilirsin.
          </p>

          <div className="mt-8 card p-6 sm:p-7">
            <span className="section-label">Bilgilendirme</span>
            <p className="mt-4 text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
              Bu demo, influencer ve iş birliği değerlendirmeleri için hazırlanmıştır.
              Nihai mobil deneyim Android uygulamasında sunulur.
            </p>
          </div>

          <div className="mt-8 card p-6 sm:p-7">
            <span className="section-label">Sınırlamalar</span>
            <ul className="mt-4 grid gap-3 text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
              <li>• Google Play satın alma akışları web önizlemede devre dışı olabilir.</li>
              <li>• Kamera tarama cihaz ve tarayıcıya göre değişebilir.</li>
              <li>• En iyi deneyim için manuel barkod girişi veya örnek ürün akışlarını kullanabilirsin.</li>
            </ul>
          </div>

          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="/partner-demo/index.html"
              target="_blank"
              rel="noreferrer"
              className="button-primary"
            >
              Demoyu aç
            </a>
            <Link href="/partner-center/dashboard" className="button-secondary">
              Panele dön
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
