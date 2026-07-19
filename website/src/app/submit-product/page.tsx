import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Eksik Ürün Gönderimi",
  description: "LabelWise eksik ürün gönderimi bilgilendirme sayfası.",
  alternates: {
    canonical: "/submit-product",
  },
};

export default function SubmitProductPage() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-96 opacity-70" />
      <section className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-20 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold)]">
            Ürün Gönderimi
          </p>
          <h1 className="mt-4 font-display text-4xl text-[color:var(--green-deep)] sm:text-5xl">
            Eksik ürün bildirimleri
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-8 text-[color:var(--text-muted)]">
            Kullanıcı katkısını destekleyen daha net bir süreç için bu alan ileride
            genişletilecektir.
          </p>
        </div>

        <div className="grid gap-5">
          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Mevcut durum
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              Eksik ürün gönderimi şu anda LabelWise mobil uygulaması üzerinden
              yapılacaktır.
            </p>
          </article>

          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Gelecek planı
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              İleride web üzerinden ürün gönderimi de desteklenebilir.
            </p>
          </article>
        </div>
      </section>
    </main>
  );
}
