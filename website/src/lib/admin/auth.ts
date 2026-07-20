import { redirect } from "next/navigation";
import { createSupabaseAdminClient, createSupabaseServerClient } from "@/lib/supabase/server";
import type { AdminSession } from "@/lib/admin/types";
import { hasEnv } from "@/lib/supabase/env";

export type AdminDiagnostics = {
  supabaseUrlPresent: boolean;
  supabaseAnonKeyPresent: boolean;
  supabaseServiceRolePresent: boolean;
  currentSessionExists: boolean;
  currentUserIdExists: boolean;
  adminMembershipFound: boolean;
  adminUsersTableReachable: boolean;
  submissionsQueryOk: boolean;
  reviewColumnsUsable: boolean;
  message: string | null;
};

type AdminGateState = {
  session: AdminSession | null;
  isAdmin: boolean;
  error: string | null;
  diagnostics: AdminDiagnostics;
};

function getEmptyDiagnostics(): AdminDiagnostics {
  return {
    supabaseUrlPresent: hasEnv("NEXT_PUBLIC_SUPABASE_URL"),
    supabaseAnonKeyPresent: hasEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
    supabaseServiceRolePresent: hasEnv("SUPABASE_SERVICE_ROLE_KEY"),
    currentSessionExists: false,
    currentUserIdExists: false,
    adminMembershipFound: false,
    adminUsersTableReachable: false,
    submissionsQueryOk: false,
    reviewColumnsUsable: false,
    message: null,
  };
}

function summarizeAdminIssue(diagnostics: AdminDiagnostics) {
  if (!diagnostics.supabaseUrlPresent || !diagnostics.supabaseAnonKeyPresent) {
    return "Supabase baglantisi eksik.";
  }

  if (!diagnostics.supabaseServiceRolePresent) {
    return "Service role yapilandirmasi eksik.";
  }

  if (!diagnostics.currentSessionExists || !diagnostics.currentUserIdExists) {
    return "Oturum bulunamadi.";
  }

  if (!diagnostics.adminUsersTableReachable) {
    return "admin_users tablosu eksik olabilir veya okunamiyor.";
  }

  if (!diagnostics.adminMembershipFound) {
    return "Admin yetkisi bulunamadi.";
  }

  if (!diagnostics.submissionsQueryOk) {
    return "submitted_products tablosu okunamiyor.";
  }

  if (!diagnostics.reviewColumnsUsable) {
    return "submitted_products tablosu/kolonlari eksik olabilir.";
  }

  return "Veri okunurken hata olustu.";
}

async function getCurrentSession() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return null;
  }

  return {
    userId: user.id,
    email: user.email ?? null,
  } satisfies AdminSession;
}

export async function requireLoggedInUser(redirectTo = "/admin/login") {
  const { session } = await getAdminGateState();

  if (!session) {
    redirect(redirectTo);
  }

  return session;
}

export async function isAdminUser(userId: string) {
  const adminClient = createSupabaseAdminClient();
  const { data, error } = await adminClient
    .from("admin_users")
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return Boolean(data);
}

export async function requireAdminUser() {
  const { session, isAdmin, error } = await getAdminGateState();

  if (error === "Oturum bulunamadi.") {
    redirect("/admin/login");
  }

  if (error || !session || !isAdmin) {
    redirect("/admin/unauthorized");
  }

  return session;
}

export async function requireAdminUserForApi() {
  const { session, isAdmin, error } = await getAdminGateState();

  if (!session) {
    throw new Error("ADMIN_SESSION_MISSING");
  }

  if (error === "Admin yetkisi bulunamadi." || !isAdmin) {
    throw new Error("ADMIN_FORBIDDEN");
  }

  if (error) {
    throw new Error("ADMIN_UNAVAILABLE");
  }

  return session;
}

export async function getAdminGateState(): Promise<AdminGateState> {
  const diagnostics = await getAdminDiagnostics();

  if (diagnostics.message === "Oturum bulunamadi.") {
    return { session: null, isAdmin: false, error: null, diagnostics };
  }

  if (diagnostics.message) {
    return {
      session: null,
      isAdmin: false,
      error: diagnostics.message,
      diagnostics,
    };
  }

  try {
    const session = await getCurrentSession();

    if (!session) {
      return { session: null, isAdmin: false, error: null, diagnostics };
    }

    const admin = await isAdminUser(session.userId);
    return { session, isAdmin: admin, error: null, diagnostics };
  } catch {
    return {
      session: null,
      isAdmin: false,
      error: "Veri okunurken hata olustu.",
      diagnostics,
    };
  }
}

export async function getAdminDiagnostics(): Promise<AdminDiagnostics> {
  const diagnostics = getEmptyDiagnostics();

  if (!diagnostics.supabaseUrlPresent || !diagnostics.supabaseAnonKeyPresent) {
    diagnostics.message = summarizeAdminIssue(diagnostics);
    return diagnostics;
  }

  try {
    const session = await getCurrentSession();
    diagnostics.currentSessionExists = Boolean(session);
    diagnostics.currentUserIdExists = Boolean(session?.userId);
  } catch {
    diagnostics.message = summarizeAdminIssue(diagnostics);
    return diagnostics;
  }

  if (!diagnostics.supabaseServiceRolePresent) {
    diagnostics.message = summarizeAdminIssue(diagnostics);
    return diagnostics;
  }

  try {
    const adminClient = createSupabaseAdminClient();
    const { error: adminUsersError } = await adminClient
      .from("admin_users")
      .select("user_id", { head: true, count: "exact" })
      .limit(1);

    diagnostics.adminUsersTableReachable = !adminUsersError;

    if (diagnostics.currentUserIdExists) {
      const session = await getCurrentSession();
      const { data, error } = await adminClient
        .from("admin_users")
        .select("user_id")
        .eq("user_id", session!.userId)
        .maybeSingle();

      diagnostics.adminMembershipFound = !error && Boolean(data);
    }

    const { error: submissionsError } = await adminClient
      .from("submitted_products")
      .select("id", { head: true, count: "exact" })
      .limit(1);
    diagnostics.submissionsQueryOk = !submissionsError;

    const { error: reviewColumnsError } = await adminClient
      .from("submitted_products")
      .select("reviewed_at, review_note, reviewed_by", { head: true, count: "exact" })
      .limit(1);
    diagnostics.reviewColumnsUsable = !reviewColumnsError;
  } catch {
    diagnostics.message = summarizeAdminIssue(diagnostics);
    return diagnostics;
  }

  if (!diagnostics.adminMembershipFound && diagnostics.currentSessionExists) {
    diagnostics.message = summarizeAdminIssue(diagnostics);
    return diagnostics;
  }

  if (!diagnostics.currentSessionExists) {
    diagnostics.message = "Oturum bulunamadi.";
    return diagnostics;
  }

  if (
    !diagnostics.adminUsersTableReachable ||
    !diagnostics.submissionsQueryOk ||
    !diagnostics.reviewColumnsUsable
  ) {
    diagnostics.message = summarizeAdminIssue(diagnostics);
  }

  return diagnostics;
}
