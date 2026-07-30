import "server-only";

import { hasEnv } from "@/lib/supabase/env";

export type SearchProviderResult = {
  title: string;
  snippet: string;
  url: string;
  domain: string;
  position: number;
};

export type SearchProviderResponse =
  | {
      status: "ok";
      provider: "serper";
      results: SearchProviderResult[];
    }
  | {
      status: "source_unavailable" | "source_error";
      provider: "serper";
      reason: string;
      results: SearchProviderResult[];
    };

type SerperResponse = {
  organic?: Array<{
    title?: string;
    link?: string;
    snippet?: string;
    position?: number;
  }>;
};

export function isSerperConfigured() {
  return hasEnv("SERPER_API_KEY");
}

export async function searchWithSerper(query: string): Promise<SearchProviderResponse> {
  const apiKey = process.env.SERPER_API_KEY?.trim();

  if (!apiKey) {
    return {
      status: "source_unavailable",
      provider: "serper",
      reason: "SERPER_API_KEY tanımlı değil.",
      results: [],
    };
  }

  const response = await fetch("https://google.serper.dev/search", {
    method: "POST",
    cache: "no-store",
    headers: {
      "X-API-KEY": apiKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      q: query,
      gl: "tr",
      hl: "tr",
      num: 10,
    }),
  });

  if (!response.ok) {
    return {
      status: "source_error",
      provider: "serper",
      reason: `Serper isteği başarısız: ${response.status}`,
      results: [],
    };
  }

  const payload = (await response.json()) as SerperResponse;
  const results = (payload.organic ?? []).slice(0, 10).map((item, index) => {
    const url = item.link ?? "";
    let domain = "";
    try {
      domain = url ? new URL(url).hostname.replace(/^www\./, "") : "";
    } catch {}

    return {
      title: item.title ?? "",
      snippet: item.snippet ?? "",
      url,
      domain,
      position: item.position ?? index + 1,
    };
  });

  return {
    status: "ok",
    provider: "serper",
    results,
  };
}
