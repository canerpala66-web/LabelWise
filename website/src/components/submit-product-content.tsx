export function SubmitProductContent() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-96 opacity-70" />
      <section className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-20 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold)]">
            Urun Gonderimi
          </p>
          <h1 className="mt-4 font-display text-4xl text-[color:var(--green-deep)] sm:text-5xl">
            Eksik urun bildirimleri
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-8 text-[color:var(--text-muted)]">
            Kullanici katkisini destekleyen daha net bir surec icin bu alan
            ileride genisletilecektir.
          </p>
        </div>

        <div className="grid gap-5">
          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Mevcut durum
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              Eksik urun gonderimi su anda LabelWise mobil uygulamasi uzerinden
              yapilacaktir.
            </p>
          </article>

          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Uygulama ici gonderim
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              Kullanicilar barkodu okutunca urun bulunmazsa uygulama icinden urun
              bilgisi gonderebilir.
            </p>
          </article>

          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Inceleme ve gelisim
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              Gonderilen bilgiler inceleme sonrasi urun veritabanini gelistirmek
              icin kullanilabilir.
            </p>
          </article>

          <article className="card p-8 sm:p-10">
            <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
              Fotograf guvenligi
            </h2>
            <p className="mt-3 text-base leading-8 text-[color:var(--text-muted)]">
              Fotograf gonderirken kisisel veri iceren gorseller yuklenmemelidir.
            </p>
          </article>
        </div>
      </section>
    </main>
  );
}
