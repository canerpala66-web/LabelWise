"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export function AdminAuthForm() {
  const router = useRouter();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  async function handleSubmit(formData: FormData) {
    setErrorMessage(null);
    const email = `${formData.get("email") ?? ""}`.trim();
    const password = `${formData.get("password") ?? ""}`;
    try {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        setErrorMessage("Giris yapilamadi.");
        return;
      }

      startTransition(() => {
        router.replace("/admin/submissions");
        router.refresh();
      });
    } catch {
      setErrorMessage("Yonetim paneli su anda acilamadi.");
    }
  }

  return (
    <form
      action={handleSubmit}
      className="card w-full max-w-md p-8 sm:p-10"
    >
      <p className="text-xs font-semibold uppercase tracking-[0.32em] text-[color:var(--gold-soft)]">
        Admin Girisi
      </p>
      <h1 className="mt-4 font-display text-4xl text-white">
        LabelWise yonetim paneli
      </h1>
      <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
        Sadece yetkili kullanicilar girebilir. Urun gonderimlerini incelemek icin
        admin hesabinla oturum ac.
      </p>

      <div className="mt-8 grid gap-4">
        <label className="grid gap-2">
          <span className="text-sm font-medium text-white">E-posta</span>
          <input
            name="email"
            type="email"
            required
            autoComplete="email"
            className="rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]"
            placeholder="ornek@labelwise.net"
          />
        </label>
        <label className="grid gap-2">
          <span className="text-sm font-medium text-white">Sifre</span>
          <input
            name="password"
            type="password"
            required
            autoComplete="current-password"
            className="rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]"
            placeholder="Sifren"
          />
        </label>
      </div>

      {errorMessage ? (
        <p className="mt-4 rounded-2xl border border-red-400/18 bg-red-400/8 px-4 py-3 text-sm text-red-200">
          {errorMessage}
        </p>
      ) : null}

      <button
        type="submit"
        disabled={isPending}
        className="button-primary mt-8 w-full justify-center disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isPending ? "Giris yapiliyor..." : "Giris Yap"}
      </button>
    </form>
  );
}
