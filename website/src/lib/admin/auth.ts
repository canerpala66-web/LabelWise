import { redirect } from "next/navigation";
import { createSupabaseAdminClient, createSupabaseServerClient } from "@/lib/supabase/server";
import type { AdminSession } from "@/lib/admin/types";
import {
  getSupabaseAnonKey,
  getSupabaseServiceRoleKey,
  getSupabaseUrl,
} from "@/lib/supabase/env";

export type AdminDiagnostics = {
  supabaseUrlPresent: boolean;
  supabaseAnonKeyPresent: boolean;
  supabaseServiceRolePresent: boolean;
  userLoggedIn: boolean;
  adminMembershipFound: boolean;
  adminUsersTableReachable: boolean;
  submissionsQueryOk: boolean;
  message: string | null;
};

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
  const session = await requireLoggedInUser();
  const isAdmin = await isAdminUser(session.userId);

  if (!isAdmin) {
    redirect("/admin/unauthorized");
  }

  return session;
}

export async function getAdminGateState() {
  try {
    const session = await getCurrentSession();

    if (!session) {
      return { session: null, isAdmin: false, error: null };
    }

    const admin = await isAdminUser(session.userId);
    return { session, isAdmin: admin, error: null };
  } catch {
    return {
      session: null,
      isAdmin: false,
      error:
        "Yonetim paneli su anda yuklenemedi. Lutfen environment ayarlarini ve admin yetkilerini kontrol edin.",
    };
  }
}

export async function getAdminDiagnostics(): Promise<AdminDiagnostics> {
  const diagnostics: AdminDiagnostics = {
    supabaseUrlPresent: false,
    supabaseAnonKeyPresent: false,
    supabaseServiceRolePresent: false,
    userLoggedIn: false,
    adminMembershipFound: false,
    adminUsersTableReachable: false,
    submissionsQueryOk: false,
    message: null,
  };

  try {
    diagnostics.supabaseUrlPresent = Boolean(getSupabaseUrl());
    diagnostics.supabaseAnonKeyPresent = Boolean(getSupabaseAnonKey());
    diagnostics.supabaseServiceRolePresent = Boolean(getSupabaseServiceRoleKey());
  } catch {
    diagnostics.message =
        "Admin paneli acilamadi. Supabase ortam degiskenleri, migration ve admin_users kaydi kontrol edilmeli.";
    return diagnostics;
  }

  try {
    const session = await getCurrentSession();
    diagnostics.userLoggedIn = Boolean(session);

    const adminClient = createSupabaseAdminClient();
    const { error: adminUsersError } = await adminClient
      .from("admin_users")
      .select("user_id", { head: true, count: "exact" })
      .limit(1);

    diagnostics.adminUsersTableReachable = !adminUsersError;

    if (session) {
      const { data, error } = await adminClient
        .from("admin_users")
        .select("user_id")
        .eq("user_id", session.userId)
        .maybeSingle();

      diagnostics.adminMembershipFound = !error && Boolean(data);
    }

    const { error: submissionsError } = await adminClient
      .from("submitted_products")
      .select("id", { head: true, count: "exact" })
      .limit(1);
    diagnostics.submissionsQueryOk = !submissionsError;
  } catch {
    diagnostics.message =
        "Admin paneli acilamadi. Supabase ortam degiskenleri, migration ve admin_users kaydi kontrol edilmeli.";
    return diagnostics;
  }

  if (
    !diagnostics.adminUsersTableReachable ||
    !diagnostics.submissionsQueryOk ||
    !diagnostics.supabaseServiceRolePresent
  ) {
    diagnostics.message =
        "Admin paneli acilamadi. Supabase ortam degiskenleri, migration ve admin_users kaydi kontrol edilmeli.";
  }

  return diagnostics;
}
