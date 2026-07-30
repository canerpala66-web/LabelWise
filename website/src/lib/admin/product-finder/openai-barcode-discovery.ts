import "server-only";

import { hasEnv } from "@/lib/supabase/env";
import {
  buildBarcodeDiscoveryQueries,
  isValidBarcodeCandidate,
  type BarcodeDiscoveryCandidate,
  type BarcodeDiscoveryEvidence,
  type BarcodeDiscoveryInput,
} from "@/lib/admin/product-finder/barcode-discovery";

type OpenAiBarcodeCandidatePayload = {
  barcode?: unknown;
  confidence?: unknown;
  score?: unknown;
  evidence?: unknown;
  reasons?: unknown;
  warnings?: unknown;
};

type OpenAiBarcodeResponsePayload = {
  status?: unknown;
  candidates?: unknown;
  notes?: unknown;
};

export type OpenAiBarcodeDiscoveryResult =
  | {
      status: "found" | "not_found" | "conflict";
      candidates: BarcodeDiscoveryCandidate[];
      notes: string;
    }
  | {
      status: "openai_web_search_not_configured" | "openai_search_error";
      candidates: [];
      notes: string;
    };

function asString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function asStringArray(value: unknown) {
  return Array.isArray(value)
    ? value.map((item) => asString(item)).filter(Boolean)
    : [];
}

function normalizeEvidence(value: unknown): BarcodeDiscoveryEvidence[] {
  if (!Array.isArray(value)) return [];

  return value
    .map((item) => {
      const record =
        item && typeof item === "object" ? (item as Record<string, unknown>) : null;

      if (!record) return null;

      const title = asString(record.title);
      const snippet = asString(record.snippet);
      const url = asString(record.url);
      let domain = "";

      try {
        domain = url ? new URL(url).hostname.replace(/^www\./, "") : "";
      } catch {}

      if (!title || !snippet || !url) return null;

      return {
        title,
        snippet,
        url,
        domain,
      } satisfies BarcodeDiscoveryEvidence;
    })
    .filter((item): item is BarcodeDiscoveryEvidence => Boolean(item));
}

function normalizeCandidate(
  payload: OpenAiBarcodeCandidatePayload,
): BarcodeDiscoveryCandidate | null {
  const barcode = asString(payload.barcode);
  const confidenceRaw = asString(payload.confidence).toLowerCase();
  const evidence = normalizeEvidence(payload.evidence);

  if (!isValidBarcodeCandidate(barcode) || evidence.length === 0) {
    return null;
  }

  const scoreValue =
    typeof payload.score === "number" && Number.isFinite(payload.score)
      ? payload.score
      : Number(asString(payload.score));

  const boundedScore = Number.isFinite(scoreValue)
    ? Math.max(0, Math.min(scoreValue, 1))
    : 0.4;

  const confidence: BarcodeDiscoveryCandidate["confidence"] =
    confidenceRaw === "high" || confidenceRaw === "medium" || confidenceRaw === "low"
      ? confidenceRaw
      : boundedScore >= 0.85
        ? "high"
        : boundedScore >= 0.65
          ? "medium"
          : "low";

  return {
    barcode,
    confidence,
    score: Number(boundedScore.toFixed(2)),
    evidence: evidence.slice(0, 3),
    reasons: asStringArray(payload.reasons),
    warnings: asStringArray(payload.warnings),
  };
}

function dedupeCandidates(candidates: BarcodeDiscoveryCandidate[]) {
  const byBarcode = new Map<string, BarcodeDiscoveryCandidate>();

  for (const candidate of candidates) {
    const existing = byBarcode.get(candidate.barcode);
    if (!existing || candidate.score > existing.score) {
      byBarcode.set(candidate.barcode, candidate);
    }
  }

  return Array.from(byBarcode.values()).sort((left, right) => right.score - left.score);
}

function extractOutputText(payload: unknown) {
  if (!payload || typeof payload !== "object") return "";

  const directText = asString((payload as { output_text?: unknown }).output_text);
  if (directText) return directText;

  const output = Array.isArray((payload as { output?: unknown[] }).output)
    ? ((payload as { output: unknown[] }).output ?? [])
    : [];

  const parts: string[] = [];

  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as { content?: unknown[] }).content)
      ? ((item as { content: unknown[] }).content ?? [])
      : [];

    for (const block of content) {
      if (!block || typeof block !== "object") continue;
      const blockType = asString((block as { type?: unknown }).type);
      if (blockType === "output_text" || blockType === "text") {
        const text = asString((block as { text?: unknown }).text);
        if (text) parts.push(text);
      }
    }
  }

  return parts.join("\n").trim();
}

function buildPrompt(input: BarcodeDiscoveryInput) {
  const quantity =
    input.quantity_value != null && input.quantity_unit
      ? `${input.quantity_value} ${input.quantity_unit}`
      : "belirsiz";

  const queryHints = buildBarcodeDiscoveryQueries(input);

  return [
    "Türkiye odaklı bir market ürünü için yalnızca arama sonucu seviyesinde barkod adayları çıkar.",
    "Sadece search result title, snippet ve url bilgisini kullan.",
    "Ürün sayfası içeriğini scrape etmeye veya fetch etmeye çalışma.",
    "İçindekiler, besin değerleri, görsel, kategori, fiyat veya açıklama üretme.",
    "Asla barkod uydurma.",
    "Search sonucunda barkod açıkça görünmüyorsa status=not_found döndür.",
    "Her barkod adayı için evidence.title, evidence.snippet ve evidence.url zorunlu.",
    "Maksimum 3 barkod adayı döndür.",
    "Zero / Max / Light / Şekersiz varyant farkında veya gramaj-litre uyumsuzluğunda confidence düşür ve warning ekle.",
    "Max ve Zero aynı ürün kabul edilmemeli; güçlü eşleşme yoksa low confidence veya conflict kullan.",
    "1.5 L ile 1 L veya 2.5 L aynı ürün kabul edilmemeli; quantity conflict warning ekle.",
    "Aynı marka + aynı varyant + aynı 1.5 L / 1500 ml eşleşmesi confidence artırır.",
    "Geçersiz, eksik veya kanıtsız barkod döndürme.",
    "Çıktıyı yalnızca JSON olarak ver.",
    "",
    `Marka: ${input.brand || "bilinmiyor"}`,
    `Ürün adı: ${input.product_name || "bilinmiyor"}`,
    `Miktar: ${quantity}`,
    `Kaynak URL: ${input.source_url || "yok"}`,
    queryHints.length > 0 ? "Yalnızca bu arama niyetleriyle düşün:" : "",
    ...queryHints.map((query) => `- ${query}`),
    "",
    "Beklenen JSON şeması:",
    '{"status":"found|not_found|conflict|source_error","candidates":[{"barcode":"869...","confidence":"high|medium|low","score":0.0,"evidence":[{"title":"...","url":"...","snippet":"..."}],"reasons":["..."],"warnings":["..."]}],"notes":"..."}',
  ]
    .filter(Boolean)
    .join("\n");
}

export function isOpenAiBarcodeDiscoveryConfigured() {
  return hasEnv("OPENAI_API_KEY");
}

export async function discoverBarcodeCandidatesWithOpenAi(
  input: BarcodeDiscoveryInput,
): Promise<OpenAiBarcodeDiscoveryResult> {
  const apiKey = process.env.OPENAI_API_KEY?.trim();

  if (!apiKey) {
    return {
      status: "openai_web_search_not_configured",
      candidates: [],
      notes: "OpenAI web search yapılandırılmamış. OPENAI_API_KEY gerekli.",
    };
  }

  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        tools: [{ type: "web_search_preview" }],
        input: buildPrompt(input),
      }),
    });

    if (!response.ok) {
      return {
        status: "openai_search_error",
        candidates: [],
        notes: `OpenAI web search aracı kullanılamıyor. Barkod adayları üretilemedi. (${response.status})`,
      };
    }

    const payload = (await response.json()) as unknown;
    const rawText = extractOutputText(payload);

    if (!rawText) {
      return {
        status: "openai_search_error",
        candidates: [],
        notes: "OpenAI web search boş yanıt döndürdü.",
      };
    }

    const cleanedText = rawText
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/\s*```$/i, "")
      .trim();

    let parsed: OpenAiBarcodeResponsePayload | null = null;
    try {
      parsed = JSON.parse(cleanedText) as OpenAiBarcodeResponsePayload;
    } catch {
      const jsonMatch = cleanedText.match(/\{[\s\S]*\}$/);
      if (jsonMatch) {
        try {
          parsed = JSON.parse(jsonMatch[0]) as OpenAiBarcodeResponsePayload;
        } catch {}
      }
    }

    if (!parsed) {
      return {
        status: "openai_search_error",
        candidates: [],
        notes: "OpenAI yanıtı beklenen JSON formatında değil.",
      };
    }

    const rawCandidates = Array.isArray(parsed.candidates) ? parsed.candidates : [];
    const candidates = dedupeCandidates(
      rawCandidates
        .map((item) => normalizeCandidate(item as OpenAiBarcodeCandidatePayload))
        .filter((item): item is BarcodeDiscoveryCandidate => Boolean(item)),
    );

    const normalizedStatus = asString(parsed.status).toLowerCase();
    const notes = asString(parsed.notes);

    if (candidates.length === 0) {
      return {
        status:
          normalizedStatus === "conflict"
            ? "conflict"
            : normalizedStatus === "source_error"
              ? "not_found"
              : "not_found",
        candidates: [],
        notes: notes || "Kanıtlı barkod adayı bulunamadı.",
      };
    }

    return {
      status: normalizedStatus === "conflict" ? "conflict" : "found",
      candidates: candidates.slice(0, 3),
      notes,
    };
  } catch {
    return {
      status: "openai_search_error",
      candidates: [],
      notes: "OpenAI web search araması tamamlanamadı.",
    };
  }
}

export const __testables__ = {
  normalizeCandidate,
  dedupeCandidates,
  extractOutputText,
};
