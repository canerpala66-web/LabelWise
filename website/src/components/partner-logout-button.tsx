"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export function PartnerLogoutButton({
  variant = "secondary",
}: {
  variant?: "secondary" | "inline";
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  async function handleLogout() {
    startTransition(async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        await supabase.auth.signOut();
      } finally {
        router.replace("/partner-center/login");
        router.refresh();
      }
    });
  }

  const className =
    variant === "inline"
      ? "text-sm font-medium text-[color:var(--gold-soft)] underline underline-offset-4 disabled:cursor-not-allowed disabled:opacity-60"
      : "button-secondary disabled:cursor-not-allowed disabled:opacity-60";

  return (
    <button type="button" onClick={handleLogout} disabled={isPending} className={className}>
      {isPending ? "Çıkış yapılıyor..." : "Çıkış Yap"}
    </button>
  );
}
