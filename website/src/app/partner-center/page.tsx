import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "LabelWise Partner Center",
  description:
    "Influencer ve iş birlikleri için hazırlanan LabelWise partner önizleme alanı.",
  alternates: {
    canonical: "/partner-center",
  },
  openGraph: {
    title: "LabelWise Partner Center",
    description:
      "Android kapalı test sürecindeki LabelWise deneyimini partner önizleme akışıyla keşfedin.",
    url: "https://labelwise.net/partner-center",
  },
};

const previewAreas = [
  "Ürün analiz deneyimi",
  "İçerik açıklamaları",
  "AI destekli analiz kartları",
  "Premium deneyim akışı",
  "Eksik ürün gönderme mantığı",
];

export default function PartnerCenterPage() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[34rem] opacity-90" />

      <section className="mx-auto w-full max-w-7xl px-6 pb-12 pt-10 sm:px-8 lg:px-10 lg:pb-16 lg:pt-14">
        <div className="glass-panel p-8 sm:p-10 lg:p-12">
          <span className="hero-pill">LabelWise Partner Center</span>

          <div className="mt-8 grid gap-10 lg:grid-cols-[1.05fr_0.95fr] lg:items-start">
            <div>
              <h1 className="font-display text-4xl leading-[0.95] text-white sm:text-5xl lg:text-6xl">
                Influencer ve iş birlikleri için özel demo alanı
              </h1>

              <p className="mt-6 max-w-3xl text-base leading-8 text-[color:var(--text-muted)] sm:text-lg">
                LabelWise şu anda Android kapalı test sürecinde. iPhone kullanan
                partnerlerin ürün deneyimini görebilmesi için güvenli bir web demo
                akışı planlıyoruz. Bu alan, o önizleme deneyiminin merkezi olarak
                hazırlanmıştır.
              </p>

              <div
                id="demo-access"
                className="mt-8 flex flex-col gap-4 sm:flex-row sm:items-center"
              >
                <Link href="/partner-center/login" className="button-primary">
                  Partner demosuna giriş
                </Link>
                <a
                  href="mailto:canerpala66@gmail.com?subject=LabelWise%20Partner%20Demo%20Eri%C5%9Fimi"
                  className="button-secondary"
                >
                  Erişim talep et
                </a>
              </div>

              <p className="mt-4 text-sm leading-7 text-[color:var(--text-soft)]">
                Korumalı demo girişi ayrı bir sprintte güvenli erişim katmanıyla
                açılacaktır.
              </p>
            </div>

            <div className="card p-6 sm:p-7">
              <span className="section-label">Partnerların test edebileceği alanlar</span>
              <div className="mt-5 grid gap-3">
                {previewAreas.map((item, index) => (
                  <div
                    key={item}
                    className="flex items-start gap-4 rounded-[1.35rem] border border-white/8 bg-white/[0.03] px-4 py-4"
                  >
                    <span className="gradient-number inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-semibold text-white">
                      {String(index + 1).padStart(2, "0")}
                    </span>
                    <p className="text-sm leading-7 text-white/88 sm:text-base">
                      {item}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-6 sm:px-8 lg:px-10 lg:py-10">
        <div className="grid gap-6 lg:grid-cols-3">
          <article className="card p-6">
            <span className="section-label">Kapalı test bilgisi</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              Android uygulaması şu anda kapalı testte
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Google Play kapalı test yapısı Android kullanıcıları için aynen
              korunuyor. Bu partner alanı, o akışı bozmadan iPhone kullanıcıları
              için tarayıcı tabanlı bir önizleme hazırlamak amacıyla açıldı.
            </p>
          </article>

          <article className="card p-6">
            <span className="section-label">Web demo yaklaşımı</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              Güvenli demo, mevcut website route’ları altında çalışacak
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Bu sprintte tüm partner akışı doğrudan <strong>labelwise.net</strong>{" "}
              altında ilerliyor: giriş, dashboard, demo ve yönlendirme linkleri
              aynı ana website yapısında korunuyor. Admin paneli yetkileri partner
              erişimi için kullanılmayacaktır.
            </p>
          </article>

          <article className="card p-6">
            <span className="section-label">İletişim</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              İş birliği ve erişim
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Demo erişimi ve iş birliği talepleri için:
            </p>
            <a
              href="mailto:canerpala66@gmail.com"
              className="mt-4 inline-flex text-base font-semibold text-[color:var(--gold-soft)] underline underline-offset-4"
            >
              canerpala66@gmail.com
            </a>
          </article>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-2 sm:px-8 lg:px-10 lg:py-6">
        <div className="grid gap-6 lg:grid-cols-3">
          <article className="card p-6">
            <span className="section-label">Referans partnerler</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              İlk partnerlerimizle yakında burada
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Bu bölüm, gerçek iş birlikleri netleştikçe doğrulanmış partner
              profilleriyle güncellenecek.
            </p>
          </article>

          <article className="card p-6">
            <span className="section-label">Partner başarıları</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              Kampanya verileri hazırlanıyor
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              Tıklama, kayıt ve premium dönüşüm metrikleri güvenli partner paneli
              içinde sunulacak. Bu sayfada henüz gerçek rakam paylaşılmıyor.
            </p>
          </article>

          <article className="card p-6">
            <span className="section-label">Toplulukla büyüyen ürün</span>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              İş birlikleriyle daha güçlü bir anlatı
            </h2>
            <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
              LabelWise, ürün şeffaflığını daha geniş kitlelere ulaştırmak için
              topluluk ve içerik üretici iş birlikleriyle büyümeyi hedefliyor.
            </p>
          </article>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-8 sm:px-8 lg:px-10 lg:pb-16">
        <div className="card p-6 sm:p-8">
          <span className="section-label">Önemli not</span>
          <p className="mt-4 max-w-4xl text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
            Bu alan yalnızca partner önizlemesi içindir. Nihai mobil deneyim
            Android uygulamasında sunulur. Web önizleme katmanı, ürün hissini ve
            temel akışları göstermek için hazırlanacaktır; admin erişimi veya özel
            sistem yetkileri sağlamaz.
          </p>

          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/" className="button-secondary">
              Ana sayfaya dön
            </Link>
            <Link href="/contact" className="button-secondary">
              İletişim sayfası
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
