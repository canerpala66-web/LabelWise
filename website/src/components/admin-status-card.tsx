import Link from "next/link";
import type { AdminDiagnostics } from "@/lib/admin/auth";

type Props = {
  title: string;
  message: string;
  actionLabel?: string;
  actionHref?: string;
  diagnostics?: AdminDiagnostics;
};

export function AdminStatusCard({
  title,
  message,
  actionLabel,
  actionHref,
  diagnostics,
}: Props) {
  return (
    <div className="card w-full max-w-3xl p-8 text-center sm:p-10">
      <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
        Admin Panel
      </p>
      <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
        {title}
      </h1>
      <p className="mt-5 text-base leading-8 text-[color:var(--text-muted)]">
        {message}
      </p>
      {diagnostics ? (
        <div className="mt-6 grid gap-3 text-left text-sm text-[color:var(--text-muted)] sm:grid-cols-2">
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            Supabase URL env: {diagnostics.supabaseUrlPresent ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            Anon key env: {diagnostics.supabaseAnonKeyPresent ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            Service role env: {diagnostics.supabaseServiceRolePresent ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            Kullanici oturumu: {diagnostics.userLoggedIn ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            Admin kaydi: {diagnostics.adminMembershipFound ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3">
            admin_users erisimi: {diagnostics.adminUsersTableReachable ? "evet" : "hayir"}
          </div>
          <div className="rounded-2xl border border-white/8 bg-white/[0.04] px-4 py-3 sm:col-span-2">
            submitted_products sorgusu: {diagnostics.submissionsQueryOk ? "evet" : "hayir"}
          </div>
        </div>
      ) : null}
      {actionLabel && actionHref ? (
        <div className="mt-8 flex justify-center">
          <Link href={actionHref} className="button-secondary">
            {actionLabel}
          </Link>
        </div>
      ) : null}
    </div>
  );
}
