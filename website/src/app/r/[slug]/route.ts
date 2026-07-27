import { createHash } from "node:crypto";
import { NextResponse } from "next/server";
import { createSupabaseAdminClient } from "@/lib/supabase/server";

function hashIp(ip: string | null) {
  if (!ip) {
    return null;
  }

  return createHash("sha256").update(ip).digest("hex");
}

export async function GET(
  request: Request,
  context: { params: Promise<{ slug: string }> },
) {
  const { slug } = await context.params;
  const fallbackUrl = new URL("/partner-center", request.url);

  if (!slug?.trim()) {
    return NextResponse.redirect(fallbackUrl);
  }

  const supabase = createSupabaseAdminClient();
  const { data: link } = await supabase
    .from("partner_links")
    .select("id, partner_id, slug, destination_url, is_active")
    .eq("slug", slug)
    .eq("is_active", true)
    .maybeSingle();

  if (!link?.destination_url) {
    return NextResponse.redirect(fallbackUrl);
  }

  const headers = request.headers;
  const rawIp =
    headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    headers.get("x-real-ip")?.trim() ??
    null;

  const clickPayload = {
    partner_link_id: link.id,
    partner_id: link.partner_id,
    slug: link.slug,
    referrer: headers.get("referer"),
    user_agent: headers.get("user-agent"),
    ip_hash: hashIp(rawIp),
  };

  try {
    const { error } = await supabase.from("partner_clicks").insert(clickPayload);

    if (error) {
      console.error("[partner-click] analytics insert failed", {
        slug: link.slug,
        partnerLinkId: link.id,
      });
    }
  } catch {
    console.error("[partner-click] analytics insert failed", {
      slug: link.slug,
      partnerLinkId: link.id,
    });
  }

  return NextResponse.redirect(link.destination_url);
}
