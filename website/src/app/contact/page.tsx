import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "İletişim",
  description: "LabelWise iletişim bilgileri.",
  alternates: {
    canonical: "/contact",
  },
};

export default function ContactPage() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-96 opacity-70" />
      <section className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-20 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold)]">
            İletişim
          </p>
          <h1 className="mt-4 font-display text-4xl text-[color:var(--green-deep)] sm:text-5xl">
            LabelWise ile iletişime geçin
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-8 text-[color:var(--text-muted)]">
            Soru, geri bildirim veya yayın öncesi iletişim ihtiyaçları için aşağıdaki
            bilgiler kullanılabilir.
          </p>
        </div>

        <div className="card p-8 sm:p-10">
          <p className="text-sm uppercase tracking-[0.28em] text-[color:var(--text-soft)]">
            İrtibat kişisi
          </p>
          <p className="mt-4 font-display text-3xl text-[color:var(--green-deep)]">
            Caner Pala
          </p>
          <a
            href="mailto:canerpala66@gmail.com"
            className="mt-4 inline-flex text-base font-semibold text-[color:var(--green-deep)] hover:text-[color:var(--gold-deep)]"
          >
            canerpala66@gmail.com
          </a>
        </div>
      </section>
    </main>
  );
}
