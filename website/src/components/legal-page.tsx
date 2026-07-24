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
  effectiveDate: string;
  contactEmail: string;
  transparencyNote?: string;
};

export function LegalPage({
  eyebrow,
  title,
  intro,
  sections,
  effectiveDate,
  contactEmail,
  transparencyNote,
}: LegalPageProps) {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[32rem] opacity-80" />
      <section className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-6 py-20 sm:px-8 lg:px-10">
        <div className="legal-hero">
          <p className="section-label">{eyebrow}</p>
          <h1 className="legal-hero__title">{title}</h1>
          <p className="legal-hero__intro">{intro}</p>

          <div className="legal-hero__meta">
            <p>
              <span>Yürürlük tarihi</span>
              <strong>{effectiveDate}</strong>
            </p>
            <p>
              <span>İletişim</span>
              <strong>{contactEmail}</strong>
            </p>
          </div>

          {transparencyNote ? (
            <div className="legal-hero__notice">{transparencyNote}</div>
          ) : null}
        </div>

        <div className="legal-sections">
          {sections.map((section, index) => (
            <article key={section.title} className="legal-section-card">
              <div className="legal-section-card__index">
                {String(index + 1).padStart(2, "0")}
              </div>
              <div className="legal-section-card__content">
                <h2>{section.title}</h2>
                <div className="legal-rich-text">{section.body}</div>
              </div>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
