import type { ReactNode } from "react";

type LegalSection = {
  title: string;
  body: ReactNode;
};

type LegalPageProps = {
  eyebrow: string;
  title: string;
  intro: string;
  sections: LegalSection[];
};

export function LegalPage({
  eyebrow,
  title,
  intro,
  sections,
}: LegalPageProps) {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-96 opacity-70" />
      <section className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-20 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold)]">
            {eyebrow}
          </p>
          <h1 className="mt-4 font-display text-4xl leading-tight text-[color:var(--green-deep)] sm:text-5xl">
            {title}
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-8 text-[color:var(--text-muted)]">
            {intro}
          </p>
        </div>

        <div className="grid gap-5">
          {sections.map((section) => (
            <article key={section.title} className="card p-7 sm:p-8">
              <h2 className="font-display text-2xl text-[color:var(--green-deep)]">
                {section.title}
              </h2>
              <div className="mt-3 text-sm leading-8 text-[color:var(--text-muted)] sm:text-base">
                {section.body}
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
