import type { Metadata } from "next";
import Link from "next/link";
import { ContributionFlowScene } from "@/components/contribution-flow-scene";
import { DatabaseVisionScene } from "@/components/database-vision-scene";
import { HeroInteractiveStage } from "@/components/hero-interactive-stage";
import { LabelChaosScene } from "@/components/label-chaos-scene";
import { ProductAnalysisScene } from "@/components/product-analysis-scene";
import { Reveal } from "@/components/reveal";

export const metadata: Metadata = {
  title: "Etiketlerin arkasındaki gerçeği görün",
  description:
    "LabelWise, paketli gıdaların etiketlerini, içeriklerini ve besin değerlerini daha anlaşılır hale getiren premium barkod deneyimidir.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "LabelWise | Etiketlerin arkasındaki gerçeği görün.",
    description:
      "Barkodu tara, içeriği anla, daha bilinçli seç. Türkiye odaklı gıda şeffaflığı deneyimi.",
    url: "https://labelwise.net",
    images: [
      {
        url: "/labelwise-logo.png",
        width: 1200,
        height: 1200,
        alt: "LabelWise",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "LabelWise | Etiketlerin arkasındaki gerçeği görün.",
    description:
      "Paketli gıdaların etiketlerini daha anlaşılır hale getiren AI destekli barkod deneyimi.",
    images: ["/labelwise-logo.png"],
  },
};

const flowSteps = [
  {
    title: "Taranıyor",
    description:
      "Barkod ışını ürün kimliğini yakalar ve veriyi tek akışta toplamaya başlar.",
  },
  {
    title: "Analiz ediliyor",
    description:
      "İçindekiler, besin tablosu ve ürün bağlamı daha okunur katmanlara ayrılır.",
  },
  {
    title: "Açıklandı",
    description:
      "Skor, AI notu ve daha iyi alternatifler alışveriş anında karar vermeni kolaylaştırır.",
  },
];

const ingredientRows = [
  {
    raw: "Glukoz-fruktoz şurubu",
    result: "Şeker yükünü artırabilir; sık tüketimde dikkatli olunabilir.",
  },
  {
    raw: "Palm yağı",
    result: "Doymuş yağ içeriği nedeniyle genel tüketimde dikkat gerektirebilir.",
  },
  {
    raw: "Sodyum benzoat",
    result: "Koruyucu katkı maddesidir; hassas kullanıcılar etiketi incelemelidir.",
  },
];

const premiumBenefits = [
  "Reklamsız kullanım",
  "Detaylı AI ürün analizleri",
  "Daha sağlıklı alternatif önerileri",
  "Premium deneyim",
];

const trustItems = [
  "Genel bilgilendirme amaçlıdır.",
  "Tıbbi tavsiye değildir.",
  "Hesap silme uygulama içinden yapılabilir.",
  "Gizlilik ve abonelik koşulları her zaman erişilebilirdir.",
];

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[78rem] opacity-100" />
      <div className="hero-noise absolute inset-0 opacity-40" aria-hidden="true" />

      <section className="relative mx-auto flex min-h-[calc(100vh-5rem)] w-full max-w-7xl flex-col justify-center px-6 pb-18 pt-8 sm:px-8 lg:px-10 lg:pb-24 lg:pt-12">
        <div className="home-hero grid items-center gap-12 lg:grid-cols-[1.02fr_0.98fr]">
          <Reveal>
            <div className="hero-copy">
              <span className="hero-pill">Etiketlerin arkasındaki gerçeği görün</span>
              <h1 className="mt-7 max-w-5xl font-display text-5xl leading-[0.88] text-white sm:text-6xl lg:text-[6.7rem]">
                Gıda etiketlerini okumak zorunda değilsin.
              </h1>
              <p className="mt-4 text-2xl font-semibold tracking-[-0.04em] text-[color:var(--mint-bright)] sm:text-3xl">
                LabelWise senin için açıklar.
              </p>
              <p className="mt-6 max-w-2xl text-base leading-8 text-[color:var(--text-muted)] sm:text-lg">
                Barkodu tara, içerikleri ve besin değerlerini anlaşılır şekilde gör.
                AI destekli analizlerle daha bilinçli seçimler yap.
              </p>

              <div className="mt-8 flex flex-col gap-4 sm:flex-row">
                <span className="button-primary">Google Play’de yakında</span>
                <Link href="#how-it-works" className="button-secondary">
                  Nasıl çalışır?
                </Link>
              </div>

              <p className="mt-5 text-sm leading-7 text-[color:var(--text-soft)]">
                Tıbbi tavsiye değildir. Genel bilgilendirme amaçlıdır.
              </p>
            </div>
          </Reveal>

          <Reveal delay={140}>
            <HeroInteractiveStage />
          </Reveal>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10">
        <div className="grid gap-8 lg:grid-cols-[0.95fr_1.05fr] lg:items-center">
          <Reveal>
            <div className="manifesto-copy">
              <span className="section-label">Sorun</span>
              <h2 className="section-title mt-4">
                Küçük puntolar, teknik içerikler, karmaşık besin tabloları…
              </h2>
              <p className="section-description mt-5">
                LabelWise bu dağınık bilgiyi tek bakışta anlaşılır bir yapıya dönüştürür.
                Barkoddan besin tablosuna, katkı isimlerinden AI özetine kadar her
                katman aynı hikâyeyi anlatır: daha net, daha sakin, daha güvenilir karar.
              </p>
            </div>
          </Reveal>

          <Reveal delay={120}>
            <LabelChaosScene />
          </Reveal>
        </div>
      </section>

      <section
        id="how-it-works"
        className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10"
      >
        <Reveal>
          <div className="section-heading">
            <span className="section-label">Akış</span>
            <h2 className="section-title">
              Barkod → ürün kimliği → içerikler → AI açıklama → skor → alternatif
            </h2>
            <p className="section-description">
              Deneyim sadece bilgi sunmaz; alışveriş anındaki kafa karışıklığını azaltan
              görsel ve anlamlı bir akış kurar.
            </p>
          </div>
        </Reveal>

        <div className="flow-journey mt-12">
          {flowSteps.map((step, index) => (
            <Reveal key={step.title} delay={index * 120}>
              <article className="flow-journey__step">
                <div className="flow-journey__visual">
                  <span className="flow-journey__index">
                    {String(index + 1).padStart(2, "0")}
                  </span>
                  <div className={`flow-journey__state flow-journey__state--${index + 1}`}>
                    <span />
                    <span />
                    <span />
                  </div>
                </div>
                <div className="flow-journey__copy">
                  <h3>{step.title}</h3>
                  <p>{step.description}</p>
                </div>
              </article>
            </Reveal>
          ))}
        </div>
      </section>

      <section
        id="analysis"
        className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10"
      >
        <div className="grid gap-8 lg:grid-cols-[0.92fr_1.08fr] lg:items-center">
          <Reveal>
            <div className="manifesto-copy">
              <span className="section-label">Analiz vitrini</span>
              <h2 className="section-title mt-4">
                Premium uygulama hissi veren ürün sonucu.
              </h2>
              <p className="section-description mt-5">
                LabelWise skor, içerik özeti, besin tablosu ve AI açıklamasını tek
                sahnede bir araya getirir. Amaç korkutmak değil; daha hızlı anlamayı
                mümkün kılmaktır.
              </p>
            </div>
          </Reveal>

          <Reveal delay={120}>
            <ProductAnalysisScene />
          </Reveal>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10">
        <div className="grid gap-8 lg:grid-cols-[0.92fr_1.08fr]">
          <Reveal>
            <div className="manifesto-copy">
              <span className="section-label">AI içerik açıklaması</span>
              <h2 className="section-title mt-4">
                Karmaşık terimler, daha sade Türkçe açıklamalar.
              </h2>
              <p className="section-description mt-5">
                Kullanıcının amacı kimyasal isim ezberlemek değil; ürünün ne anlama
                geldiğini daha rahat anlamak. Bu yüzden açıklamalar dikkatli, kısa ve
                günlük dile yakındır.
              </p>
            </div>
          </Reveal>

          <div className="ingredient-transform">
            {ingredientRows.map((row, index) => (
              <Reveal key={row.raw} delay={index * 110}>
                <div className="ingredient-transform__row">
                  <div className="ingredient-transform__raw">{row.raw}</div>
                  <div className="ingredient-transform__divider" aria-hidden="true">
                    →
                  </div>
                  <div className="ingredient-transform__result">{row.result}</div>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section
        id="premium"
        className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10"
      >
        <Reveal>
          <div className="section-heading">
            <span className="section-label">Premium deneyim</span>
            <h2 className="section-title">
              Premium, etiketi anlamanın ötesine geçer.
            </h2>
            <p className="section-description">
              Daha iyi seçenekleri keşfetmene, daha rafine açıklamalar görmene ve
              daha sakin bir deneyim yaşamana yardımcı olur.
            </p>
          </div>
        </Reveal>

        <div className="premium-scene mt-12 grid gap-8 lg:grid-cols-[1.04fr_0.96fr]">
          <Reveal>
            <div className="premium-scene__comparison">
              <div className="premium-scene__comparison-head">
                <span>Alternatif karşılaştırması</span>
                <strong>Daha dengeli seçenekler</strong>
              </div>
              <div className="premium-scene__cards">
                {["Mevcut ürün", "Daha sade seçenek", "En dengeli seçenek"].map(
                  (title, index) => (
                    <article
                      key={title}
                      className={`premium-scene__product premium-scene__product--${index + 1}`}
                    >
                      <span>{title}</span>
                      <strong>{index === 0 ? "64" : index === 1 ? "78" : "86"}</strong>
                      <p>{index === 0 ? "Şeker daha yüksek" : index === 1 ? "Daha sade içerik" : "Daha dengeli profil"}</p>
                    </article>
                  ),
                )}
              </div>
            </div>
          </Reveal>

          <div className="premium-scene__benefits">
            {premiumBenefits.map((item, index) => (
              <Reveal key={item} delay={index * 90}>
                <div className="premium-scene__benefit">
                  <span>0{index + 1}</span>
                  <p>{item}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10">
        <div className="grid gap-8 lg:grid-cols-[1.02fr_0.98fr] lg:items-center">
          <Reveal>
            <div className="manifesto-copy">
              <span className="section-label">Türkiye veri tabanı vizyonu</span>
              <h2 className="section-title mt-4">
                Türkiye’deki paketli gıdaları daha anlaşılır hale getiren büyüyen bir
                veri tabanı.
              </h2>
              <p className="section-description mt-5">
                Bu sadece bir ürün sayfası koleksiyonu değil; kullanıcı katkısı,
                doğrulama ve açıklama katmanıyla büyüyen yerel bir bilgi ağıdır.
              </p>
              <p className="section-description mt-4">
                Eksik ürünler kullanıcılar tarafından gönderilebilir, doğrulama
                sürecinden sonra sisteme eklenir.
              </p>
            </div>
          </Reveal>

          <Reveal delay={120}>
            <DatabaseVisionScene />
          </Reveal>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10">
        <div className="grid gap-8 lg:grid-cols-[0.96fr_1.04fr] lg:items-center">
          <Reveal>
            <div className="manifesto-copy">
              <span className="section-label">Topluluk katkısı</span>
              <h2 className="section-title mt-4">
                Bulamadığın ürünü gönder, veri tabanını birlikte büyütelim.
              </h2>
              <p className="section-description mt-5">
                Ön yüz, arka etiket, besin tablosu ve içerik verisi birlikte
                değerlendirilir. Her gönderim doğrudan yayına alınmak yerine kalite
                kontrolünden geçer.
              </p>
            </div>
          </Reveal>

          <Reveal delay={120}>
            <ContributionFlowScene />
          </Reveal>
        </div>
      </section>

      <section
        id="trust"
        className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10"
      >
        <Reveal>
          <div className="trust-manifesto">
            <div>
              <span className="section-label">Güven, gizlilik ve güvenlik</span>
              <h2 className="section-title mt-4">
                Şeffaflık sadece ürünlerde değil, ürünün kendisinde de görünür olmalı.
              </h2>
              <p className="section-description mt-5">
                LabelWise ürün yorumlarını daha anlaşılır hale getirmeyi amaçlar.
                Tıbbi tavsiye vermez. Gizlilik, hesap silme ve abonelik koşulları açık
                şekilde erişilebilir kalır.
              </p>
            </div>

            <div className="trust-manifesto__items">
              {trustItems.map((item) => (
                <div key={item} className="trust-manifesto__item">
                  <span />
                  <p>{item}</p>
                </div>
              ))}
            </div>

            <div className="trust-manifesto__links">
              <Link href="/privacy">Gizlilik Politikası</Link>
              <Link href="/terms">Kullanım Koşulları</Link>
              <Link href="/subscription-terms">Abonelik Koşulları</Link>
              <Link href="/account-deletion">Hesap Silme</Link>
            </div>
          </div>
        </Reveal>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 pb-20 pt-10 sm:px-8 lg:px-10 lg:pb-28">
        <Reveal>
          <div className="campaign-ending">
            <span className="section-label">Final</span>
            <h2 className="section-title mt-4">
              Daha bilinçli seçimler için etiketi anlaşılır hale getir.
            </h2>
            <p className="section-description mt-5">
              LabelWise, Google Play açık erişim sürecine yaklaşırken güçlü bir marka,
              ürün vitrini ve güvenli bilgi katmanı olarak hazır bekliyor.
            </p>
            <div className="mt-8 flex flex-col gap-4 sm:flex-row">
              <span className="button-primary">Google Play’de yakında</span>
              <Link href="/privacy" className="button-secondary">
                Gizlilik politikasını incele
              </Link>
            </div>
          </div>
        </Reveal>
      </section>
    </main>
  );
}
