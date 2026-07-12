import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
} as const;

const analysisVersion = "v3";
const openAiEndpoint = "https://api.openai.com/v1/responses";
const openAiModel = "gpt-4.1-mini";
const productSelectFields =
  "barcode, name, brand, category, ingredients_text, nutriscore_grade, energy_kcal, fat, saturated_fat, carbohydrates, sugars, fiber, protein, salt, ai_summary, ai_risk_level, ai_generated_at, ai_analysis_version";

type ProductRecord = {
  barcode?: string | null;
  name?: string | null;
  brand?: string | null;
  category?: string | null;
  ingredients_text?: string | null;
  nutriscore_grade?: string | null;
  energy_kcal?: number | string | null;
  fat?: number | string | null;
  saturated_fat?: number | string | null;
  carbohydrates?: number | string | null;
  sugars?: number | string | null;
  fiber?: number | string | null;
  protein?: number | string | null;
  salt?: number | string | null;
  ai_summary?: string | null;
  ai_risk_level?: string | null;
  ai_generated_at?: string | null;
  ai_analysis_version?: string | null;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function errorResponse(
  error: string,
  step: string,
  status: number,
): Response {
  console.log(`AI Edge Function: returning error step=${step} error=${error}`);
  return jsonResponse({ error, step }, status);
}

function isValidBarcode(barcode: unknown): barcode is string {
  if (typeof barcode !== "string") return false;
  const trimmed = barcode.trim();
  if (!/^\d+$/.test(trimmed)) return false;
  return trimmed.length === 8 || trimmed.length === 12 || trimmed.length === 13;
}

function toNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function textValue(value: unknown): string {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : "Bilinmiyor";
}

function optionalText(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function normalizeRiskLevel(value: unknown): "düşük" | "orta" | "yüksek" {
  const normalized = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (normalized === "düşük" || normalized === "low") return "düşük";
  if (normalized === "yüksek" || normalized === "high") return "yüksek";
  if (normalized === "orta" || normalized === "medium") return "orta";
  return "orta";
}

function limitWords(text: string, maximumWords: number): string {
  const words = text.trim().split(/\s+/);
  if (words.length <= maximumWords) return text.trim();
  return `${words.slice(0, maximumWords).join(" ")}…`;
}

function containsForbiddenLanguage(summary: string): boolean {
  const normalized = summary.toLowerCase();
  return [
    "asla tüketmeyin",
    "kesinlikle tüketmeyin",
    "kanser",
    "toksik",
    "zehir",
    "zehirlidir",
    "güvenlidir",
    "zararlıdır",
    "sağlıklıdır",
    "tüketmeyin",
  ].some((item) => normalized.includes(item));
}

function buildPrompt(barcode: string, product: ProductRecord | null): string {
  if (product == null) {
    return `
You are LabelWise.
Write a short, calm, neutral Turkish food product note.

Only barcode is available right now, so do not invent nutrition facts.
Clearly say that product details are limited.
Do not make medical claims.
Do not use fear language.
Never use "zararlı", "sağlıklıdır", "tüketmeyin", "kanser", "toksik", or "zehir".

Barcode: ${barcode}

Return JSON only:
{
  "summary": "Kısa Türkçe açıklama",
  "risk_level": "düşük | orta | yüksek"
}
`.trim();
  }

  const ingredients = optionalText(product.ingredients_text) ?? "Bilinmiyor";
  const category = optionalText(product.category) ?? "Bilinmiyor";
  const nutriScore = optionalText(product.nutriscore_grade) ?? "Bilinmiyor";

  return `
You are LabelWise.
You help Turkish consumers understand packaged foods in a simple, calm, neutral way.

Write a short Turkish interpretation based only on the available product data below.
Do not invent missing facts.
Do not make medical claims.
Do not attack or promote brands.
Do not use fear language.
Never use "zararlı", "sağlıklıdır", "tüketmeyin", "kanser", "toksik", or "zehir".
Keep the answer understandable and practical.
Keep the summary under 55 words if possible.

Product barcode: ${barcode}
Product name: ${textValue(product.name)}
Brand: ${textValue(product.brand)}
Category: ${category}
Ingredients: ${ingredients}
Nutri-Score: ${nutriScore}
Energy: ${toNumber(product.energy_kcal) ?? "Bilinmiyor"} kcal
Fat: ${toNumber(product.fat) ?? "Bilinmiyor"} g
Saturated fat: ${toNumber(product.saturated_fat) ?? "Bilinmiyor"} g
Carbohydrates: ${toNumber(product.carbohydrates) ?? "Bilinmiyor"} g
Sugars: ${toNumber(product.sugars) ?? "Bilinmiyor"} g
Fiber: ${toNumber(product.fiber) ?? "Bilinmiyor"} g
Protein: ${toNumber(product.protein) ?? "Bilinmiyor"} g
Salt: ${toNumber(product.salt) ?? "Bilinmiyor"} g

Return JSON only:
{
  "summary": "Kısa Türkçe açıklama",
  "risk_level": "düşük | orta | yüksek"
}
`.trim();
}

async function fetchProductByBarcode(
  barcode: string,
): Promise<{
  client: ReturnType<typeof createClient>;
  product: ProductRecord | null;
} | {
  client: null;
  product: null;
  serviceRoleMissing: true;
}> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();

  if (!supabaseUrl || !serviceRoleKey) {
    return {
      client: null,
      product: null,
      serviceRoleMissing: true,
    };
  }

  try {
    const client = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await client
      .from("products")
      .select(productSelectFields)
      .eq("barcode", barcode)
      .maybeSingle();

    if (error) {
      console.log(`AI Edge Function: product fetch failed error=${error.message}`);
      return { client, product: null };
    }

    return { client, product: data as ProductRecord | null };
  } catch (error) {
    console.log(`AI Edge Function: product fetch exception=${String(error)}`);
    return { client: null, product: null };
  }
}

function hasValidCachedAnalysis(product: ProductRecord | null): boolean {
  if (product == null) return false;
  const summary = optionalText(product.ai_summary);
  const risk = optionalText(product.ai_risk_level);
  const version = optionalText(product.ai_analysis_version);
  return summary !== null && risk !== null && version === analysisVersion;
}

async function saveAnalysisResult(
  client: ReturnType<typeof createClient> | null,
  barcode: string,
  summary: string,
  riskLevel: string,
  generatedAt: string,
): Promise<boolean> {
  if (client == null) return false;

  try {
    const { error } = await client
      .from("products")
      .update({
        ai_summary: summary,
        ai_risk_level: riskLevel,
        ai_generated_at: generatedAt,
        ai_analysis_version: analysisVersion,
      })
      .eq("barcode", barcode);

    if (error) {
      console.log(`AI Edge Function: save ai failed error=${error.message}`);
      return false;
    }

    return true;
  } catch (error) {
    console.log(`AI Edge Function: save ai exception=${String(error)}`);
    return false;
  }
}

async function callOpenAi(prompt: string, apiKey: string): Promise<string> {
  console.log("AI Edge Function: calling OpenAI");
  const response = await fetch(openAiEndpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: openAiModel,
      input: prompt,
      temperature: 0.2,
      max_output_tokens: 250,
      store: false,
      text: {
        format: {
          type: "json_schema",
          name: "labelwise_analysis",
          strict: true,
          schema: {
            type: "object",
            properties: {
              summary: { type: "string" },
              risk_level: {
                type: "string",
                enum: ["düşük", "orta", "yüksek", "bilinmiyor"],
              },
            },
            required: ["summary", "risk_level"],
            additionalProperties: false,
          },
        },
      },
    }),
  });

  console.log(
    `AI Edge Function: OpenAI status=${response.status}`,
  );

  if (!response.ok) {
    const body = await response.text();
    console.log(
      `AI Edge Function: OpenAI error body=${body.slice(0, 300)}`,
    );
    throw new Error(`OpenAI request failed (${response.status})`);
  }

  const responseJson = await response.json();
  const output = responseJson?.output;
  if (!Array.isArray(output)) {
    throw new Error("Responses API output is missing");
  }

  for (const item of output) {
    if (item?.type !== "message" || !Array.isArray(item.content)) continue;
    for (const part of item.content) {
      if (part?.type === "output_text" && typeof part.text === "string" && part.text) {
        return part.text;
      }
    }
  }

  throw new Error("Responses API output text is missing");
}

function parseAnalysis(outputText: string) {
  const parsed = JSON.parse(outputText);
  if (!parsed || typeof parsed !== "object") {
    throw new Error("Analysis output is not a JSON object");
  }

  const summary = typeof parsed.summary === "string" ? parsed.summary.trim() : "";
  if (!summary) {
    throw new Error("Analysis summary is invalid");
  }

  const safeSummary = limitWords(summary, 55);
  if (containsForbiddenLanguage(safeSummary)) {
    throw new Error("Analysis summary contains unsafe wording");
  }

  const riskLevel = normalizeRiskLevel((parsed as { risk_level?: unknown }).risk_level);
  return { summary: safeSummary, riskLevel };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (request.method !== "POST") {
    return errorResponse("Method not allowed", "method_check", 405);
  }

  console.log("AI Edge Function: request received");
  const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim() ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ?? "";
  console.log(`AI Edge Function: OPENAI_API_KEY exists=${apiKey.length > 0}`);
  console.log(`AI Edge Function: SUPABASE_URL exists=${supabaseUrl.length > 0}`);
  console.log(
    `AI Edge Function: SUPABASE_SERVICE_ROLE_KEY exists=${serviceRoleKey.length > 0}`,
  );

  if (!apiKey) {
    return errorResponse("Missing OPENAI_API_KEY", "env_check", 500);
  }

  try {
    const body = await request.json();
    const barcode = body?.barcode;

    if (!isValidBarcode(barcode)) {
      return errorResponse("Invalid barcode", "barcode_validation", 400);
    }

    const trimmedBarcode = barcode.trim();
    console.log(`AI Edge Function: barcode=${trimmedBarcode}`);

    console.log("AI Edge Function: product fetch started");
    const fetchResult = await fetchProductByBarcode(trimmedBarcode);
    if ("serviceRoleMissing" in fetchResult && fetchResult.serviceRoleMissing) {
      console.log(
        "AI Edge Function: product fetch error=Missing Supabase service role key",
      );
      return errorResponse(
        "Missing Supabase service role key",
        "env_check",
        500,
      );
    }

    const { client, product } = fetchResult;
    console.log(`AI Edge Function: product found=${product !== null}`);

    if (product == null) {
      return errorResponse("Product not found", "product_fetch", 404);
    }

    const cachedValid = hasValidCachedAnalysis(product);
    console.log(`AI Edge Function: cache valid=${cachedValid}`);
    if (cachedValid) {
      console.log("AI Edge Function: returning cached analysis");
      return jsonResponse({
        summary: optionalText(product.ai_summary),
        risk_level: normalizeRiskLevel(product.ai_risk_level),
        analysis_version: analysisVersion,
        generated_at: optionalText(product.ai_generated_at) ??
          new Date().toISOString(),
        cached: true,
      });
    }

    console.log("AI Edge Function: calling OpenAI=true");
    const prompt = buildPrompt(trimmedBarcode, product);
    let outputText = "";
    try {
      outputText = await callOpenAi(prompt, apiKey);
    } catch (error) {
      console.log(`AI Edge Function: OpenAI error body=${String(error)}`);
      return errorResponse("OpenAI request failed", "openai_call", 500);
    }

    let analysis: { summary: string; riskLevel: "düşük" | "orta" | "yüksek" };
    try {
      analysis = parseAnalysis(outputText);
      console.log("AI Edge Function: parse success=true");
    } catch (error) {
      console.log(`AI Edge Function: parse success=false error=${String(error)}`);
      return errorResponse("AI response parse failed", "response_parse", 500);
    }

    const generatedAt = new Date().toISOString();
    console.log("AI Edge Function: update products started");
    const saved = await saveAnalysisResult(
      client,
      trimmedBarcode,
      analysis.summary,
      analysis.riskLevel,
      generatedAt,
    );
    if (!saved) {
      console.log("AI Edge Function: update products error=save returned false");
    }

    console.log(
      `AI Edge Function: parsed risk_level=${analysis.riskLevel}`,
    );
    console.log(`AI Edge Function: saved ai result=${saved}`);
    console.log("AI Edge Function: returning response");

    return jsonResponse({
      summary: analysis.summary,
      risk_level: analysis.riskLevel,
      analysis_version: analysisVersion,
      generated_at: generatedAt,
      cached: false,
    });
  } catch (error) {
    console.log(`AI Edge Function: error=${String(error)}`);
    return errorResponse(
      "AI analysis could not be generated",
      "unexpected",
      500,
    );
  }
});
