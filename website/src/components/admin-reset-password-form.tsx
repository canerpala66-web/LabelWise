"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  createSupabaseBrowserClient,
  getBrowserSupabaseEnvStatus,
  hasSupabaseBrowserEnv,
} from "@/lib/supabase/browser";

type ResetState = "checking" | "ready" | "invalid" | "success";

function sanitizeAuthMessage(message: string | undefined) {
  if (!message) {
    return "";
  }

  return message
    .replace(/bearer\s+[a-z0-9\-._~+/]+=*/gi, "[redacted]")
    .replace(/\beyj[a-z0-9\-._~+/=]+\b/gi, "[redacted]")
    .trim();
}

function mapResetError(error: unknown) {
  const message =
    typeof error === "object" && error !== null && "message" in error
      ? sanitizeAuthMessage(String((error as { message?: string }).message))
      : "";
  const lower = message.toLowerCase();

  if (
    lower.includes("expired") ||
    lower.includes("otp_expired") ||
    lower.includes("invalid_grant") ||
    lower.includes("session_not_found")
  ) {
    return "Şifre sıfırlama bağlantısı geçersiz veya süresi dolmuş olabilir.";
  }

  if (lower.includes("same password")) {
    return "Yeni şifre mevcut şifreyle aynı olamaz.";
  }

  if (lower.includes("weak password")) {
    return "Daha güçlü bir şifre belirlemen gerekiyor.";
  }

  return message || "Şifre güncellenemedi. Lütfen tekrar dene.";
}

function validatePasswordStrength(password: string) {
  if (password.length < 8) {
    return "Şifre en az 8 karakter olmalıdır.";
  }

  if (!/[A-ZÇĞİÖŞÜ]/.test(password)) {
    return "Şifre en az bir büyük harf içermelidir.";
  }

  if (!/[a-zçğıöşü]/.test(password)) {
    return "Şifre en az bir küçük harf içermelidir.";
  }

  if (!/\d/.test(password)) {
    return "Şifre en az bir rakam içermelidir.";
  }

  return null;
}

function parseHashParams(hash: string) {
  const normalized = hash.startsWith("#") ? hash.slice(1) : hash;
  return new URLSearchParams(normalized);
}

export function AdminResetPasswordForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [state, setState] = useState<ResetState>("checking");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isPending, startTransition] = useTransition();
  const envStatus = useMemo(() => getBrowserSupabaseEnvStatus(), []);

  useEffect(() => {
    let active = true;

    async function prepareRecoverySession() {
      if (!hasSupabaseBrowserEnv()) {
        if (!active) return;
        setErrorMessage(
          "Supabase public env eksik. NEXT_PUBLIC_SUPABASE_URL ve NEXT_PUBLIC_SUPABASE_ANON_KEY kontrol edilmeli.",
        );
        setState("invalid");
        return;
      }

      const supabase = createSupabaseBrowserClient();
      const code = searchParams.get("code");
      const type = searchParams.get("type");
      const tokenHash = searchParams.get("token_hash");
      const hashParams =
        typeof window !== "undefined" ? parseHashParams(window.location.hash) : new URLSearchParams();
      const accessToken = hashParams.get("access_token");
      const refreshToken = hashParams.get("refresh_token");
      const hashType = hashParams.get("type");

      try {
        if (code) {
          const { error } = await supabase.auth.exchangeCodeForSession(code);
          if (error) {
            throw error;
          }
        } else if (tokenHash && type === "recovery") {
          const { error } = await supabase.auth.verifyOtp({
            token_hash: tokenHash,
            type: "recovery",
          });
          if (error) {
            throw error;
          }
        } else if (accessToken && refreshToken && hashType === "recovery") {
          const { error } = await supabase.auth.setSession({
            access_token: accessToken,
            refresh_token: refreshToken,
          });
          if (error) {
            throw error;
          }
        }

        const {
          data: { session },
        } = await supabase.auth.getSession();

        if (!session) {
          throw new Error("session_not_found");
        }

        if (!active) return;

        if (typeof window !== "undefined" && window.location.hash) {
          window.history.replaceState({}, document.title, window.location.pathname + window.location.search);
        }

        setState("ready");
      } catch (error) {
        if (!active) return;
        setErrorMessage(mapResetError(error));
        setState("invalid");
      }
    }

    prepareRecoverySession();

    return () => {
      active = false;
    };
  }, [searchParams]);

  async function handleSubmit(formData: FormData) {
    setErrorMessage(null);
    setSuccessMessage(null);

    const password = String(formData.get("password") ?? "");
    const passwordRepeat = String(formData.get("password_repeat") ?? "");

    if (password !== passwordRepeat) {
      setErrorMessage("Yeni şifre alanları birbiriyle eşleşmiyor.");
      return;
    }

    const passwordStrengthError = validatePasswordStrength(password);
    if (passwordStrengthError) {
      setErrorMessage(passwordStrengthError);
      return;
    }

    try {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.updateUser({ password });

      if (error) {
        throw error;
      }

      await supabase.auth.signOut();
      setState("success");
      setSuccessMessage("Şifre başarıyla güncellendi. Giriş ekranına yönlendiriliyorsun.");

      startTransition(() => {
        window.setTimeout(() => {
          router.replace("/admin/login");
          router.refresh();
        }, 900);
      });
    } catch (error) {
      setErrorMessage(mapResetError(error));
    }
  }

  return (
    <div className="card w-full max-w-lg p-8 sm:p-10">
      <p className="text-xs font-semibold uppercase tracking-[0.32em] text-[color:var(--gold-soft)]">
        Admin Şifre Sıfırlama
      </p>
      <h1 className="mt-4 font-display text-4xl text-white">Yeni şifre belirle</h1>
      <p className="mt-4 text-sm leading-7 text-[color:var(--text-muted)]">
        Recovery bağlantın geçerliyse burada yeni şifreni belirleyebilirsin.
      </p>

      {state === "checking" ? (
        <div className="mt-8 rounded-2xl border border-white/10 bg-white/6 px-4 py-4 text-sm text-white/82">
          Recovery oturumu kontrol ediliyor...
        </div>
      ) : null}

      {state === "invalid" ? (
        <div className="mt-8 rounded-2xl border border-red-400/18 bg-red-400/8 px-4 py-4 text-sm text-red-200">
          <p>{errorMessage ?? "Şifre sıfırlama bağlantısı kullanılamıyor."}</p>
          <div className="mt-3 text-xs text-red-100/90">
            <p>NEXT_PUBLIC_SUPABASE_URL present: {envStatus.urlPresent ? "true" : "false"}</p>
            <p>NEXT_PUBLIC_SUPABASE_ANON_KEY present: {envStatus.anonKeyPresent ? "true" : "false"}</p>
          </div>
        </div>
      ) : null}

      {state === "success" && successMessage ? (
        <div className="mt-8 rounded-2xl border border-emerald-400/18 bg-emerald-400/8 px-4 py-4 text-sm text-emerald-100">
          {successMessage}
        </div>
      ) : null}

      {state === "ready" ? (
        <form action={handleSubmit} className="mt-8">
          <div className="grid gap-4">
            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Yeni şifre</span>
              <input
                name="password"
                type="password"
                autoComplete="new-password"
                required
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                className="rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]"
                placeholder="Yeni şifren"
              />
            </label>
            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Yeni şifre tekrar</span>
              <input
                name="password_repeat"
                type="password"
                autoComplete="new-password"
                required
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                className="rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]"
                placeholder="Yeni şifreni tekrar yaz"
              />
            </label>
          </div>

          <div className="mt-4 rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-4 text-sm leading-7 text-[color:var(--text-muted)]">
            Şifre en az 8 karakter, en az bir büyük harf, bir küçük harf ve bir rakam içermelidir.
          </div>

          {errorMessage ? (
            <div className="mt-4 rounded-2xl border border-red-400/18 bg-red-400/8 px-4 py-3 text-sm text-red-200">
              {errorMessage}
            </div>
          ) : null}

          <button
            type="submit"
            disabled={isPending}
            className="button-primary mt-8 w-full justify-center disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isPending ? "Şifre güncelleniyor..." : "Şifreyi güncelle"}
          </button>
        </form>
      ) : null}
    </div>
  );
}
