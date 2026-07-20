import Link from "next/link";
import type { ReactNode } from "react";

type AdminShellProps = {
  title: string;
  description: string;
  children: ReactNode;
};

export function AdminShell({ title, description, children }: AdminShellProps) {
  return (
    <main className="relative overflow-hidden">
      <div className="hero-glow absolute inset-x-0 top-0 h-[32rem] opacity-90" />
      <section className="mx-auto flex w-full max-w-7xl flex-col gap-8 px-6 py-16 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
                Admin Panel
              </p>
              <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
                {title}
              </h1>
              <p className="mt-4 max-w-3xl text-base leading-8 text-[color:var(--text-muted)]">
                {description}
              </p>
            </div>
            <nav className="flex flex-wrap gap-3 text-sm">
              <Link href="/admin/submissions" className="button-secondary min-h-11 px-5">
                Gonderimler
              </Link>
            </nav>
          </div>
        </div>
        {children}
      </section>
    </main>
  );
}
