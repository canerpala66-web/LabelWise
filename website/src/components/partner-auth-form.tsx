"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  createSupabaseBrowserClient,
  getBrowserSupabaseEnvStatus,
  hasSupabaseBrowserEnv,
} from "@/lib/supabase/browser";

type SafeAuthError = {
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

function getSafeAuthErrorDetails(error: unknown): SafeAuthError {
  if (typeof error !== "object" || error === null) {
    return {
      message: typeof error === "string" ? error : "Bilinmeyen hata",
    };
  }

  const candidate = error as {
    code?: string;
    status?: number;
    statusCode?: number;
    message?: string;
  };

  return {
    code: candidate.code,
    status: candidate.status ?? candidate.statusCode,
    message: candidate.message,
  };
}

function mapPartnerLoginError(error: SafeAuthError) {
  const message = sanitizeAuthMessage(error.message).toLowerCase();
  const code = `${error.code ?? ""}`.toLowerCase();
  const status = error.status;

  if (
    message.includes("invalid login credentials") ||
    code.includes("invalid_credentials")
  ) {
    return "E-posta veya şifre hatalı görünüyor.";
  }

  if (
    message.includes("email not confirmed") ||
    code.includes("email_not_confirmed")
  ) {
    return "Bu hesap henüz doğrulanmamış.";
  }

  if (
    status === 429 ||
    code.includes("over_request_rate_limit") ||
    message.includes("too many requests")
  ) {
    return "Çok fazla deneme yapıldı. Biraz bekleyip tekrar deneyin.";
  }

  if (
    status === 0 ||
    message.includes("failed to fetch") ||
    message.includes("network") ||
    message.includes("fetch") ||
    message.includes("supabase public env eksik")
  ) {
    return "Giriş servisine bağlanılamadı. Yapılandırma kontrol edilmeli.";
  }

  return sanitizeAuthMessage(error.message) || "Partner girişi şu anda tamamlanamadı.";
}

export function PartnerAuthForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [envStatus, setEnvStatus] = useState<{
    urlPresent: boolean;
    anonKeyPresent: boolean;
  } | null>(null);

  const initialMessage = useMemo(() => {
    if (searchParams.get("access") === "denied") {
      return "Bu hesap partner paneline erişemiyor. Doğru partner hesabıyla giriş yapın.";
    }

    return null;
  }, [searchParams]);

  async function handleSubmit(formData: FormData) {
    setErrorMessage(null);
    setEnvStatus(null);

    const email = `${formData.get("email") ?? ""}`.trim();
    const password = `${formData.get("password") ?? ""}`;

    try {
      if (!hasSupabaseBrowserEnv()) {
        const browserEnvStatus = getBrowserSupabaseEnvStatus();
        setEnvStatus(browserEnvStatus);
        setErrorMessage(
          "Supabase public env eksik. NEXT_PUBLIC_SUPABASE_URL ve NEXT_PUBLIC_SUPABASE_ANON_KEY kontrol edilmeli.",
        );
        return;
      }

      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        setErrorMessage(mapPartnerLoginError(getSafeAuthErrorDetails(error)));
        return;
      }

      startTransition(() => {
        router.replace("/partner-center/dashboard");
        router.refresh();
      });
    } catch (error) {
      const safeError = getSafeAuthErrorDetails(error);
      setErrorMessage(mapPartnerLoginError(safeError));

      if (safeError.message?.includes("Missing required environment variable")) {
        setEnvStatus(getBrowserSupabaseEnvStatus());
      }
    }
  }

  return (
    <form action={handleSubmit} className="card w-full max-w-md p-8 sm:p-10">
      <p className="text-xs font-semibold uppercase tracking-[0.32em] text-[color:var(--gold-soft)]">
        Partner Girişi
      </p>
      <h1 className="mt-4 font-display text-4xl text-white">
        LabelWise Partner Center
      </h1>
      <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
        Influencer ve iş birliği önizlemeleri için hazırlanan partner paneline
        güvenli şekilde giriş yapın.
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
            placeholder="partner@labelwise.net"
          />
        </label>
        <label className="grid gap-2">
          <span className="text-sm font-medium text-white">Şifre</span>
          <input
            name="password"
            type="password"
            required
            autoComplete="current-password"
            className="rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]"
            placeholder="Şifreniz"
          />
        </label>
      </div>

      {initialMessage && !errorMessage ? (
        <div className="mt-4 rounded-2xl border border-amber-300/20 bg-amber-300/8 px-4 py-3 text-sm text-amber-100">
          {initialMessage}
        </div>
      ) : null}

      {errorMessage ? (
        <div className="mt-4 rounded-2xl border border-red-400/18 bg-red-400/8 px-4 py-3 text-sm text-red-200">
          <p>{errorMessage}</p>
          {envStatus ? (
            <div className="mt-3 grid gap-2 text-xs text-red-100/90 sm:grid-cols-2">
              <p>NEXT_PUBLIC_SUPABASE_URL present: {envStatus.urlPresent ? "true" : "false"}</p>
              <p>NEXT_PUBLIC_SUPABASE_ANON_KEY present: {envStatus.anonKeyPresent ? "true" : "false"}</p>
            </div>
          ) : null}
        </div>
      ) : null}

      <button
        type="submit"
        disabled={isPending}
        className="button-primary mt-8 w-full justify-center disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isPending ? "Giriş yapılıyor..." : "Partner olarak giriş yap"}
      </button>
    </form>
  );
}
