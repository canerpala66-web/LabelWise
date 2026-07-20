import Link from "next/link";

export function AdminUnauthorized() {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[28rem] opacity-80" />
      <section className="mx-auto flex min-h-[60vh] w-full max-w-4xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        <div className="card w-full max-w-2xl p-8 text-center sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            Yetki Kontrolu
          </p>
          <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
            Yetkisiz erisim
          </h1>
          <p className="mt-5 text-base leading-8 text-[color:var(--text-muted)]">
            Bu alana erisim yetkiniz yok.
          </p>
          <div className="mt-8 flex justify-center">
            <Link href="/admin/login" className="button-secondary">
              Admin girisine don
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
