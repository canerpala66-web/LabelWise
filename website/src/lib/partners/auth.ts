import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type PartnerProfile = {
  id: string;
  user_id: string;
  display_name: string;
  handle: string | null;
  email: string | null;
  status: string;
  public_bio: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
};

export async function getCurrentPartnerProfile() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { session },
    error: sessionError,
  } = await supabase.auth.getSession();

  if (sessionError) {
    throw new Error("Partner oturumu doğrulanamadı.");
  }

  if (!session?.user) {
    return {
      session: null,
      partner: null as PartnerProfile | null,
    };
  }

  const { data: partner, error: partnerError } = await supabase
    .from("partners")
    .select("*")
    .eq("user_id", session.user.id)
    .maybeSingle<PartnerProfile>();

  if (partnerError) {
    throw new Error("Partner bilgisi alınamadı.");
  }

  return {
    session,
    partner,
  };
}

export async function requireActivePartner() {
  const { session, partner } = await getCurrentPartnerProfile();

  if (!session?.user) {
    redirect("/partner-center/login");
  }

  if (!partner || partner.status !== "active") {
    redirect("/partner-center/login?access=denied");
  }

  return {
    session,
    partner,
  };
}
