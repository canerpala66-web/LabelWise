import Link from "next/link";
import { Reveal } from "@/components/reveal";

const features = [
  {
    title: "Barkod tarama",
    description:
      "Ürünü saniyeler içinde tanıyıp etiket bilgisini daha okunur bir deneyime dönüştürür.",
  },
  {
    title: "Besin puanı",
    description:
      "Besin değerlerini tek bakışta yorumlamaya yardımcı olacak sade bir değerlendirme sunar.",
  },
  {
    title: "İçerik açıklamaları",
    description:
      "Katkı maddeleri ve içerikler için daha anlaşılır, günlük dile yakın açıklamalar sağlar.",
  },
  {
    title: "AI ürün yorumu",
    description:
      "Etiket ve ürün verilerini bir araya getirerek anlaşılır özetler üretir.",
  },
  {
    title: "Daha dengeli alternatifler",
    description:
      "Benzer ürünler arasında daha bilinçli kıyas yapmayı kolaylaştırmayı hedefler.",
  },
  {
    title: "Eksik ürün gönderimi",
    description:
      "Sistemde bulunmayan ürünlerin uygulama üzerinden bildirilmesine destek verir.",
  },
];

const steps = [
  "Barkodu okut",
  "Ürün bilgilerini gör",
  "Daha bilinçli karar ver",
];

const premiumItems = [
  "Reklamsız deneyim",
  "Detaylı AI açıklamaları",
  "Daha dengeli alternatifler",
  "Gelişmiş geçmiş / offline features later",
];

const signals = [
  "Türkiye odaklı ürün dili",
  "Etiketleri sadeleştiren yorum katmanı",
  "Karar anında hızlı ve güven veren görünüm",
];

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[58rem] opacity-100" />
      <div className="absolute right-[-10rem] top-28 h-80 w-80 rounded-full bg-[radial-gradient(circle,_rgba(200,169,107,0.34)_0%,_transparent_72%)] blur-3xl" />
      <div className="absolute left-[-8rem] top-[32rem] h-80 w-80 rounded-full bg-[radial-gradient(circle,_rgba(63,183,140,0.18)_0%,_transparent_72%)] blur-3xl" />
      <div className="absolute inset-x-0 top-[34rem] h-px bg-[linear-gradient(90deg,transparent,rgba(200,169,107,0.25),transparent)]" />

      <section className="mx-auto flex w-full max-w-7xl flex-col px-6 pb-20 pt-10 sm:px-8 lg:px-10 lg:pb-28">
        <Reveal>
          <div className="glass-panel relative overflow-hidden px-6 py-8 sm:px-8 lg:px-10 lg:py-10">
          <div className="absolute inset-y-0 right-0 hidden w-1/2 bg-[linear-gradient(135deg,rgba(27,94,74,0.14),transparent_55%)] lg:block" />
          <div className="absolute left-0 top-0 h-px w-full bg-[linear-gradient(90deg,transparent,rgba(255,255,255,0.2),transparent)]" />
          <div className="grid gap-12 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
            <div className="animate-fade-up">
              <span className="inline-flex items-center rounded-full border border-white/10 bg-white/8 px-4 py-2 text-xs font-semibold uppercase tracking-[0.32em] text-[color:var(--gold-soft)] shadow-[0_12px_30px_rgba(0,0,0,0.12)] backdrop-blur">
                Türkiye için gıda etiketi rehberi
              </span>
              <h1 className="mt-7 max-w-4xl font-display text-5xl leading-[0.92] text-white sm:text-6xl lg:text-8xl">
                Barkodu okut, daha bilinçli seç.
              </h1>
              <p className="mt-6 max-w-2xl text-base leading-8 text-[color:var(--text-muted)] sm:text-lg">
                LabelWise, gıda ürünlerinin içeriklerini, besin değerlerini ve
                etiket bilgilerini daha anlaşılır hale getiren mobil barkod
                tarama uygulamasıdır.
              </p>
              <div className="mt-8 flex flex-col gap-4 sm:flex-row">
                <span className="button-primary">
                  Yakında Google Play&apos;de
                </span>
                <Link href="/privacy" className="button-secondary">
                  Gizlilik Politikası
                </Link>
              </div>
              <div className="mt-10 grid gap-3 sm:max-w-xl sm:grid-cols-3">
                {signals.map((item) => (
                  <div
                    key={item}
                    className="rounded-[1.35rem] border border-white/8 bg-white/[0.04] px-4 py-4 text-sm leading-6 text-white/76 backdrop-blur"
                  >
                    {item}
                  </div>
                ))}
              </div>
            </div>

            <div className="animate-tilt">
              <div className="card relative mx-auto max-w-md overflow-hidden p-6 sm:p-7">
                <div className="absolute inset-x-0 top-0 h-1 bg-[linear-gradient(90deg,var(--green-deep),var(--gold))]" />
                <div className="grid gap-4">
                  <div className="rounded-[1.75rem] bg-[linear-gradient(180deg,rgba(27,94,74,0.95),rgba(18,58,46,0.96))] p-5 text-white shadow-[0_20px_60px_rgba(16,40,32,0.25)]">
                    <div className="flex items-center justify-between text-sm">
                      <span className="rounded-full bg-white/14 px-3 py-1 text-xs uppercase tracking-[0.28em] text-white/78">
                        Scan Insight
                      </span>
                      <span className="text-xs text-white/65">LabelWise</span>
                    </div>
                    <div className="mt-6 space-y-4">
                      <div>
                        <p className="text-xs uppercase tracking-[0.26em] text-white/58">
                          Besin görünümü
                        </p>
                        <p className="mt-2 text-3xl font-semibold">
                          Dengeli seçim için hızlı özet
                        </p>
                      </div>
                      <div className="grid grid-cols-3 gap-3">
                        {[
                          ["Puan", "82/100"],
                          ["Şeker", "Orta"],
                          ["Lif", "İyi"],
                        ].map(([label, value]) => (
                          <div
                            key={label}
                            className="rounded-2xl border border-white/12 bg-white/8 p-3"
                          >
                            <p className="text-[11px] uppercase tracking-[0.22em] text-white/56">
                              {label}
                            </p>
                            <p className="mt-2 text-sm font-semibold">{value}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                  <div className="grid gap-3 sm:grid-cols-2">
                    <div className="rounded-[1.5rem] border border-white/8 bg-white/6 p-4">
                      <p className="text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
                        AI Özet
                      </p>
                      <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                        İçerik listesi ve besin değerleri daha anlaşılır bir
                        dille yorumlanır.
                      </p>
                    </div>
                    <div className="rounded-[1.5rem] border border-white/8 bg-[rgba(200,169,107,0.08)] p-4">
                      <p className="text-xs uppercase tracking-[0.24em] text-[color:var(--text-soft)]">
                        Alternatifler
                      </p>
                      <p className="mt-3 text-sm leading-7 text-[color:var(--text-muted)]">
                        Benzer ürünleri karşılaştırıp daha dengeli tercihleri
                        keşfetmeye yardımcı olur.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          </div>
        </Reveal>
      </section>

      <section
        id="about"
        className="mx-auto w-full max-w-7xl px-6 py-12 sm:px-8 lg:px-10"
      >
        <div className="grid gap-5 lg:grid-cols-[1.05fr_0.95fr]">
          <Reveal>
            <div className="glass-panel p-8 sm:p-10">
            <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
              Hakkında
            </p>
            <h2 className="mt-4 font-display text-4xl text-white sm:text-5xl">
              Sıradan bilgi sayfası değil, karar anına eşlik eden akıllı bir katman.
            </h2>
            <p className="mt-5 max-w-2xl text-base leading-8 text-[color:var(--text-muted)]">
              LabelWise, market rafında saniyeler içinde daha net bir karar vermeyi
              hedefler. Ürünün etiketini daha okunur hale getirir, karmaşık içerik
              dilini sadeleştirir ve güven duygusunu merkezde tutar.
            </p>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <div className="card relative overflow-hidden p-8 sm:p-10">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,_rgba(200,169,107,0.18),transparent_46%)]" />
            <div className="relative grid gap-4">
              {[
                "Etiketi okumayı kolaylaştıran arayüz dili",
                "Veri, AI ve ürün bağlamını birleştiren yorum yaklaşımı",
                "Premium, güven ve sadelik dengesini koruyan görsel kimlik",
              ].map((point) => (
                <div
                  key={point}
                  className="rounded-[1.35rem] border border-white/8 bg-white/[0.04] px-5 py-5 text-sm leading-7 text-white/80"
                >
                  {point}
                </div>
                ))}
            </div>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-12 sm:px-8 lg:px-10">
        <div className="mb-8 flex flex-col gap-4">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            Ne yapar?
          </p>
          <h2 className="font-display text-4xl text-white sm:text-5xl">
            Etiketi veri olmaktan çıkarır, karara dönüştürür.
          </h2>
        </div>
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {features.map((feature, index) => (
            <Reveal key={feature.title} delay={index * 90}>
              <article className="card feature-card group p-6 sm:p-7">
                <div className="gradient-number mb-5 flex h-12 w-12 items-center justify-center rounded-2xl text-sm font-semibold text-[color:var(--gold-soft)]">
                  0{index + 1}
                </div>
                <h3 className="text-2xl font-semibold text-white">
                  {feature.title}
                </h3>
                <p className="mt-3 text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
                  {feature.description}
                </p>
              </article>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-12 sm:px-8 lg:px-10">
        <Reveal>
          <div className="card grid gap-8 p-8 sm:p-10 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
              Nasıl çalışır?
            </p>
            <h2 className="mt-4 font-display text-4xl text-white sm:text-5xl">
              Üç adımda daha net bir alışveriş deneyimi.
            </h2>
          </div>
          <div className="grid gap-4">
            {steps.map((step, index) => (
              <div
                key={step}
                className="flex items-center gap-4 rounded-[1.5rem] border border-white/8 bg-white/[0.04] px-5 py-5 shadow-[0_14px_40px_rgba(0,0,0,0.16)] backdrop-blur"
              >
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[linear-gradient(135deg,var(--green-rich),var(--green-deep))] text-sm font-semibold text-white shadow-[0_14px_35px_rgba(27,94,74,0.26)]">
                  {index + 1}
                </span>
                <p className="text-base font-medium text-white sm:text-lg">
                  {step}
                </p>
              </div>
            ))}
          </div>
          </div>
        </Reveal>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-12 sm:px-8 lg:px-10">
        <Reveal>
          <div className="relative overflow-hidden rounded-[2rem] border border-[color:var(--border-soft)] bg-[linear-gradient(135deg,#184D3D_0%,#123B2F_55%,#1B5E4A_100%)] px-8 py-10 text-white shadow-[0_35px_90px_rgba(16,40,32,0.28)] sm:px-10 sm:py-12">
          <div className="absolute right-0 top-0 h-full w-1/2 bg-[radial-gradient(circle_at_top_right,_rgba(200,169,107,0.22),transparent_55%)]" />
          <div className="relative grid gap-8 lg:grid-cols-[0.95fr_1.05fr] lg:items-center">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
                Premium
              </p>
              <h2 className="mt-4 font-display text-4xl sm:text-5xl">
                Daha derin içgörü isteyenler için planlanan ek deneyimler.
              </h2>
              <p className="mt-5 max-w-2xl text-base leading-8 text-white/76">
                Premium özellikler kademeli olarak kullanıma sunulacaktır.
              </p>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {premiumItems.map((item) => (
                <div
                  key={item}
                  className="rounded-[1.5rem] border border-white/12 bg-white/8 px-5 py-5 backdrop-blur"
                >
                  <p className="text-sm leading-7 text-white/84">{item}</p>
                </div>
              ))}
            </div>
          </div>
          </div>
        </Reveal>
      </section>

      <section
        id="developer"
        className="mx-auto w-full max-w-7xl px-6 py-12 sm:px-8 lg:px-10"
      >
        <div className="grid gap-5 lg:grid-cols-[0.88fr_1.12fr]">
          <Reveal>
            <div className="glass-panel p-8 sm:p-10">
            <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
              Geliştirici
            </p>
            <h2 className="mt-4 font-display text-4xl text-white sm:text-5xl">
              Ürünün arkasında sade ama iddialı bir vizyon var.
            </h2>
            <p className="mt-5 text-base leading-8 text-[color:var(--text-muted)]">
              LabelWise, karmaşık gıda etiketlerini günlük kararlar için daha
              kullanışlı hale getirme fikri etrafında şekilleniyor. Amaç, soğuk bir
              veri paneli değil; insanın güven duymak isteyeceği bir rehber deneyimi.
            </p>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <div className="card p-8 sm:p-10">
            <div className="grid gap-4 sm:grid-cols-2">
              {[
                ["Kimlik", "Bağımsız ürün geliştirme odağı"],
                ["Yaklaşım", "AI, açıklık ve güven dengesini koruyan ürün tasarımı"],
                ["Odak", "Türkiye'de gıda ürünlerini daha anlaşılır hale getirmek"],
                ["İletişim", "Geri bildirim ve yayın öncesi hazırlık için açık kanal"],
              ].map(([label, value]) => (
                <div
                  key={label}
                  className="rounded-[1.4rem] border border-white/8 bg-white/[0.04] p-5"
                >
                  <p className="text-xs uppercase tracking-[0.28em] text-[color:var(--gold-soft)]">
                    {label}
                  </p>
                  <p className="mt-3 text-sm leading-7 text-white/82">{value}</p>
                </div>
              ))}
            </div>
            <div className="mt-5">
              <Link href="/contact" className="button-secondary">
                Geliştirici ile iletişime geç
              </Link>
            </div>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="mx-auto w-full max-w-7xl px-6 py-12 pb-24 sm:px-8 lg:px-10">
        <Reveal>
          <div className="card p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            Önemli not
          </p>
          <p className="mt-4 max-w-4xl text-lg leading-9 text-[color:var(--text-muted)]">
            LabelWise bilgilendirme amaçlıdır; tıbbi tavsiye, teşhis veya tedavi
            önerisi sunmaz. Ürün etiketleri, veri kaynakları ve yapay zekâ
            çıktıları eksik ya da hatalı olabilir.
          </p>
          </div>
        </Reveal>
      </section>
    </main>
  );
}
