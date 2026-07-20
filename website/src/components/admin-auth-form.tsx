"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import {
  createSupabaseBrowserClient,
  hasSupabaseBrowserEnv,
} from "@/lib/supabase/browser";

type SafeAuthError = {
  name?: string;
  code?: string;
  status?: number;
  message?: string;
};

function sanitizeAuthMessage(message: string | undefined) {
  if (!message) {
    return "";
  }

  return message
    .replace(/bearer\s+[a-z0-9\-._~+/]+=*/gi, "[redacted]")
    .replace(/\beyj[a-z0-9\-._~+/=]+\b/gi, "[redacted]")
    .trim();
}

function mapAdminLoginError(error: SafeAuthError) {
  const message = sanitizeAuthMessage(error.message).toLowerCase();
  const code = `${error.code ?? ""}`.toLowerCase();
  const status = error.status;

  if (
    message.includes("invalid login credentials") ||
    code.includes("invalid_credentials")
  ) {
    return "E-posta veya şifre hatalı.";
  }

  if (
    message.includes("email not confirmed") ||
    code.includes("email_not_confirmed")
  ) {
    return "Bu e-posta henüz doğrulanmamış.";
  }

  if (
    message.includes("user not found") ||
    message.includes("no user found") ||
    code.includes("user_not_found")
  ) {
    return "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
  }

  if (
    status === 429 ||
    code.includes("over_request_rate_limit") ||
    message.includes("too many requests")
  ) {
    return "Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.";
  }

  if (
    status === 0 ||
    message.includes("failed to fetch") ||
    message.includes("network") ||
    message.includes("fetch") ||
    message.includes("supabase public env eksik") ||
    code.includes("auth_retryable_fetch_error")
  ) {
    return "Giriş servisine bağlanılamadı. Yapılandırma kontrol edilmeli.";
  }

  return sanitizeAuthMessage(error.message) || "Giriş yapılamadı. Lütfen tekrar dene.";
}

function getSafeAuthErrorDetails(error: unknown): SafeAuthError {
  if (typeof error !== "object" || error === null) {
    return {
      message: typeof error === "string" ? error : "Bilinmeyen hata",
    };
  }

  const candidate = error as {
    name?: string;
    code?: string;
    status?: number;
    statusCode?: number;
    message?: string;
  };

  return {
    name: candidate.name,
    code: candidate.code,
    status: candidate.status ?? candidate.statusCode,
    message: candidate.message,
  };
}

export function AdminAuthForm() {
  const router = useRouter();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  async function handleSubmit(formData: FormData) {
    setErrorMessage(null);
    const email = `${formData.get("email") ?? ""}`.trim();
    const password = `${formData.get("password") ?? ""}`;

    if (process.env.NODE_ENV !== "production") {
      console.log("[AdminLogin] signIn started");
      console.log(
        `[AdminLogin] Supabase browser client exists: ${hasSupabaseBrowserEnv()}`,
      );
    }

    try {
      if (!hasSupabaseBrowserEnv()) {
        setErrorMessage("Supabase public env eksik.");
        return;
      }

      const supabase = createSupabaseBrowserClient();
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (process.env.NODE_ENV !== "production") {
        console.log(
          `[AdminLogin] session returned: ${Boolean(data.session)}`,
        );
        console.log(`[AdminLogin] user returned: ${Boolean(data.user)}`);
      }

      if (error) {
        const safeError = getSafeAuthErrorDetails(error);
        if (process.env.NODE_ENV !== "production") {
          console.log(
            `[AdminLogin] error name/code/status/message sanitized: ${JSON.stringify({
              name: safeError.name ?? null,
              code: safeError.code ?? null,
              status: safeError.status ?? null,
              message: sanitizeAuthMessage(safeError.message),
            })}`,
          );
        }
        setErrorMessage(mapAdminLoginError(safeError));
        return;
      }

      startTransition(() => {
        router.replace("/admin/status");
        router.refresh();
      });
    } catch (error) {
      const safeError = getSafeAuthErrorDetails(error);
      if (process.env.NODE_ENV !== "production") {
        console.log(
          `[AdminLogin] error name/code/status/message sanitized: ${JSON.stringify({
            name: safeError.name ?? null,
            code: safeError.code ?? null,
            status: safeError.status ?? null,
            message: sanitizeAuthMessage(safeError.message),
          })}`,
        );
        console.log("[AdminLogin] session returned: false");
        console.log("[AdminLogin] user returned: false");
      }
      setErrorMessage(
        safeError.message?.includes("Missing required environment variable")
          ? "Supabase public env eksik."
          : mapAdminLoginError(safeError),
      );
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
