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

const credibilityMetrics = [
  {
    value: "22.000+",
    label: "ürün",
    description: "Büyüyen ürün veritabanı",
  },
  {
    value: "6.500+",
    label: "doğrulanmış katkı",
    description: "Admin ve editörler tarafından eklenen kayıtlar",
  },
  {
    value: "12.000+",
    label: "tarama",
    description: "Kapalı beta ve test sürecinde yapılan ürün taramaları",
  },
  {
    value: "17 tester",
    label: "14 günlük test",
    description: "Google Play kapalı test grubuyla yürütülen süreç",
  },
];

const foundationColumns = [
  {
    title: "Güçlü temel",
    items: [
      "Çalışan Android kapalı beta ve 14 günlük Google Play kapalı test süreci",
      "17 kişilik test grubu ve 12.000+ ürün taraması/test taraması",
      "22.000+ ürünlük veritabanı ve 6.500+ admin/editör katkılı kayıt",
      "AI destekli ürün açıklamaları, alternatif akışı ve Premium altyapısı",
      "Eksik ürün gönderme, doğrulama süreci ve Partner Center hazırlığı",
    ],
  },
  {
    title: "Gelişim alanları",
    items: [
      "iOS uygulaması kapalı test tamamlandıktan sonra geliştirilmeye devam edecek",
      "Ürün veritabanı sürekli genişletiliyor; yaklaşık 10.000 ürün verisi üzerinde geliştirme sürüyor",
      "Marka bilinirliği ve partner ağı hâlâ erken aşamada büyüyor",
      "Kapalı beta geri bildirimleriyle ürün deneyimi düzenli olarak iyileştiriliyor",
    ],
  },
  {
    title: "Nasıl kapatıyoruz?",
    items: [
      "iOS kullanan influencer ve iş birliği adayları için Web Demo ve Partner Center altyapısı geliştirildi",
      "Eksik ürünler kullanıcı katkısı + doğrulama akışıyla sisteme alınabiliyor",
      "Admin ve editör destekli kontrol süreci veri kalitesini güçlendiriyor",
      "Partner Center ileride özel bağlantılar, demo erişimi ve performans istatistikleriyle genişletilecek",
      "İletişim dili, tıbbi tavsiye vermeden sade ve güvenli bilgilendirme sunacak şekilde korunuyor",
    ],
  },
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

              <p className="mt-5 max-w-2xl text-sm leading-7 text-[color:var(--text-soft)] sm:text-base">
                LabelWise, Türkiye&apos;de paketli gıda etiketlerini daha anlaşılır
                hale getirmek amacıyla Caner Pala tarafından geliştirilen bağımsız bir
                girişimdir.
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

      <section className="mx-auto w-full max-w-7xl px-6 py-8 sm:px-8 lg:px-10">
        <div className="metrics-grid">
          {credibilityMetrics.map((metric, index) => (
            <Reveal key={metric.label} delay={index * 70}>
              <article className="metric-card">
                <span className="metric-card__value">{metric.value}</span>
                <strong className="metric-card__label">{metric.label}</strong>
                <p className="metric-card__description">{metric.description}</p>
              </article>
            </Reveal>
          ))}
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

      <section
        id="foundation"
        className="mx-auto w-full max-w-7xl px-6 py-14 sm:px-8 lg:px-10"
      >
        <Reveal>
          <div className="section-heading">
            <span className="section-label">Güven veren temel yapı</span>
            <h2 className="section-title">
              LabelWise, yalnızca barkod tarayan bir arayüz değil; Türkiye&apos;de
              paketli gıda etiketlerini daha anlaşılır hale getiren büyüyen bir bilgi
              altyapısı olarak geliştiriliyor.
            </h2>
            <p className="section-description">
              Kamuya açık söylemimiz net: abartısız, sakin ve güven veren. Kapalı
              beta, doğrulama süreçleri ve büyüyen veri katmanı birlikte ilerliyor.
            </p>
          </div>
        </Reveal>

        <div className="foundation-grid mt-12">
          {foundationColumns.map((column, index) => (
            <Reveal key={column.title} delay={index * 90}>
              <article className="foundation-card">
                <h3>{column.title}</h3>
                <ul>
                  {column.items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </article>
            </Reveal>
          ))}
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
              <p className="section-description mt-4">
                Tüm ürünlerin doğrulandığı iddia edilmez; veri tabanı yerel katkı,
                editör kontrolü ve API kaynaklarıyla kademeli olarak güçlendirilir.
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
              <p className="section-description mt-4">
                Google Play kapalı test süreci tamamlandıktan sonra iOS geliştirme
                süreci tamamlanacak. Bu süre boyunca iOS kullanan influencer ve iş
                birliği adaylarının ürünü inceleyebilmesi için Web Demo ve Partner
                Center altyapısı geliştirildi.
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
              <p className="section-description mt-4">
                Partner Center, kapalı test sonrasında güvenilir iş birlikleri için
                hazırlanıyor. İlerleyen süreçte özel bağlantılar, demo erişimi ve iş
                birliği performansını ölçen istatistik alanlarıyla genişletilecektir.
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
              LabelWise, Google Play kapalı test sürecini tamamlayıp Türkiye odaklı
              ürün deneyimini daha da olgunlaştırırken; kullanıcılar, partnerler ve
              potansiyel yatırımcılar için güvenilir bir temel oluşturmaya devam ediyor.
            </p>
            <div className="mt-8 flex flex-col gap-4 sm:flex-row sm:flex-wrap">
              <span className="button-primary">Google Play’de yakında</span>
              <Link href="/privacy" className="button-secondary">
                Gizlilik politikasını incele
              </Link>
              <a href="mailto:labelwisetr@gmail.com" className="button-secondary">
                labelwisetr@gmail.com
              </a>
            </div>
            <div className="contact-strip mt-8">
              <a href="mailto:labelwisetr@gmail.com">labelwisetr@gmail.com</a>
              <a href="tel:+905528010914">0552 801 09 14</a>
            </div>
          </div>
        </Reveal>
      </section>
    </main>
  );
}
