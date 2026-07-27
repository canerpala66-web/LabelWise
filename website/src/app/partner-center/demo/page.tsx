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
          <span className="hero-pill">Protected Partner Demo</span>
          <h1 className="mt-5 font-display text-4xl leading-tight text-white sm:text-5xl">
            Web demo erişim kabuğu hazır
          </h1>
          <p className="mt-5 max-w-3xl text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
            Bu demo, influencer ve iş birliği değerlendirmeleri için hazırlanmıştır.
            Nihai mobil deneyim Android uygulamasında sunulur. Satın alma, kamera
            tarama ve Google Play akışları web demo’da devre dışı olabilir.
          </p>

          <div className="mt-10 grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
            <article className="card p-6 sm:p-7">
              <span className="section-label">Bu sprintte hazır olan temel</span>
              <h2 className="mt-4 text-2xl font-semibold text-white">
                Korumalı demo alanı
              </h2>
              <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
                Bu sayfa, partner girişinden sonra açılan güvenli demo giriş noktasıdır.
                Flutter web deneyimi bu alana daha sonra bağlanabilir ya da gömülü
                olmayan ayrı bir önizleme akışıyla sunulabilir.
              </p>

              <div className="mt-6 rounded-[1.6rem] border border-dashed border-white/12 bg-white/[0.03] p-6">
                <p className="text-sm leading-7 text-white/85">
                  Demo yerleşimi hazırlanıyor. Sonraki sprintte burada:
                </p>
                <ul className="mt-4 grid gap-3 text-sm leading-7 text-[color:var(--text-muted)]">
                  <li>• örnek ürün arama akışı</li>
                  <li>• AI analiz kartı önizlemesi</li>
                  <li>• premium deneyim demosu</li>
                  <li>• eksik ürün gönderme mantığı</li>
                </ul>
              </div>
            </article>

            <article className="card p-6 sm:p-7">
              <span className="section-label">Sonraki adım</span>
              <h2 className="mt-4 text-2xl font-semibold text-white">
                Flutter web demo dağıtımı
              </h2>
              <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
                Demo uygulaması bu route altında ayrı bir korumalı deneyim olarak
                sunulabilir. Bu sprintte güvenli kabuk hazırlandı; gerçek Flutter
                web entegrasyonu daha sonra bu alanın içine kontrollü şekilde
                bağlanabilir.
              </p>
              <div className="mt-6 flex flex-wrap gap-3">
                <Link href="/partner-center/dashboard" className="button-secondary">
                  Panele dön
                </Link>
                <a
                  href="mailto:canerpala66@gmail.com?subject=LabelWise%20Partner%20Demo"
                  className="button-primary"
                >
                  Demo talebi gönder
                </a>
              </div>
            </article>
          </div>
        </div>
      </section>
    </main>
  );
}
