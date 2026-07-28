import { NextResponse } from "next/server";

function readPublicEnv(name: string) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required public environment variable: ${name}`);
  }
  return value;
}

export async function GET() {
  try {
    const payload = {
      supabaseUrl: readPublicEnv("NEXT_PUBLIC_SUPABASE_URL"),
      supabaseAnonKey: readPublicEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
      googleWebClientId:
        process.env.NEXT_PUBLIC_GOOGLE_WEB_CLIENT_ID?.trim() ?? "",
    };

    return NextResponse.json(payload, {
      headers: {
        "Cache-Control": "no-store, max-age=0",
      },
    });
  } catch {
    return NextResponse.json(
      {
        error: "Partner demo config kullanılamıyor.",
      },
      {
        status: 500,
        headers: {
          "Cache-Control": "no-store, max-age=0",
        },
      },
    );
  }
}
