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

      <section className="mx-auto w-full max-w-6xl px-6 pb-16 pt-10 sm:px-8 lg:px-10 lg:pt-14">
        <div className="glass-panel p-8 sm:p-10 lg:p-12">
          <span className="hero-pill">Partner Demo / Web Önizleme</span>
          <h1 className="mt-5 font-display text-4xl leading-tight text-white sm:text-5xl">
            LabelWise web demosu partner erişimine açıldı
          </h1>
          <p className="mt-5 max-w-3xl text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
            Bu demo, influencer ve iş birliği değerlendirmeleri için hazırlanmıştır.
            Nihai mobil deneyim Android uygulamasında sunulur. Satın alma, kamera
            tarama ve Google Play akışları web önizlemede sınırlı olabilir.
          </p>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <div className="card p-5">
              <span className="section-label">Kullanım notu</span>
              <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                En iyi deneyim için manuel barkod girişi veya örnek ürün akışlarını
                kullanabilirsiniz.
              </p>
            </div>
            <div className="card p-5">
              <span className="section-label">Web kısıtları</span>
              <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                Satın alma, kamera tarama ve Google Play akışları web önizlemede
                sınırlı ya da devre dışı olabilir.
              </p>
            </div>
            <div className="card p-5">
              <span className="section-label">Partner modu</span>
              <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                Bu alan genel kullanıcı yayını değil, yalnızca partner önizleme
                deneyimi içindir.
              </p>
            </div>
          </div>

          <div className="mt-8 flex flex-wrap gap-3">
            <Link href="/partner-center/dashboard" className="button-secondary">
              Panele dön
            </Link>
            <a
              href="/partner-demo/index.html"
              target="_blank"
              rel="noreferrer"
              className="button-primary"
            >
              Demo yeni sekmede açılsın
            </a>
          </div>

          <div className="mt-8 overflow-hidden rounded-[2rem] border border-white/10 bg-[#07110d] shadow-[0_30px_80px_rgba(0,0,0,0.32)]">
            <div className="flex items-center justify-between border-b border-white/8 bg-white/[0.03] px-4 py-3">
              <div className="flex items-center gap-2">
                <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
                <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
                <span className="h-3 w-3 rounded-full bg-[#28c840]" />
              </div>
              <p className="text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
                labelwise.net / partner demo
              </p>
            </div>

            <div className="bg-[radial-gradient(circle_at_top,rgba(61,128,93,0.18),transparent_42%)] p-2 sm:p-3">
              <div className="overflow-hidden rounded-[1.6rem] border border-white/8 bg-black">
                <iframe
                  src="/partner-demo/index.html"
                  title="LabelWise Partner Demo"
                  className="block h-[78vh] min-h-[720px] w-full bg-white md:h-[82vh]"
                  loading="eager"
                  referrerPolicy="strict-origin-when-cross-origin"
                  allow="camera; microphone; clipboard-read; clipboard-write"
                />
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
