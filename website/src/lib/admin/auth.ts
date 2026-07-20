import { redirect } from "next/navigation";
import { createSupabaseAdminClient, createSupabaseServerClient } from "@/lib/supabase/server";
import type { AdminSession } from "@/lib/admin/types";

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
  const session = await getCurrentSession();

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
  const session = await getCurrentSession();

  if (!session) {
    return { session: null, isAdmin: false };
  }

  const admin = await isAdminUser(session.userId);
  return { session, isAdmin: admin };
}
