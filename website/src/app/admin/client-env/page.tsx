"use client";

import { getBrowserSupabaseEnvStatus } from "@/lib/supabase/browser";

export default function AdminClientEnvPage() {
  const status = getBrowserSupabaseEnvStatus();

  return (
    <main className="relative overflow-hidden">
      <section className="mx-auto flex min-h-[70vh] w-full max-w-4xl items-center justify-center px-6 py-16 sm:px-8 lg:px-10">
        <div className="card w-full max-w-2xl p-8 text-center sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            Admin Client Env
          </p>
          <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
            Client env kontrolu
          </h1>
          <div className="mt-8 grid gap-3 text-left text-sm text-[color:var(--text-muted)]">
            <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
              NEXT_PUBLIC_SUPABASE_URL present: {status.urlPresent ? "true" : "false"}
            </div>
            <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
              NEXT_PUBLIC_SUPABASE_ANON_KEY present: {status.anonKeyPresent ? "true" : "false"}
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
