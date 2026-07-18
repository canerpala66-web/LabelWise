import { createClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
} as const;

const supportedProductIds = new Set([
  "labelwise_premium_monthly",
  "labelwise_premium_yearly",
]);

const expectedPackageName = "com.labelwise.app";

type VerificationRequest = {
  productId: string;
  purchaseToken: string;
  packageName: string;
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
  console.log(
    `Google Play Verify Function: returning error step=${step} error=${error}`,
  );
  return jsonResponse(
    {
      success: false,
      isPremium: false,
      planCode: null,
      validUntil: null,
      status: "unknown",
      message: error,
      step,
    },
    status,
  );
}

function normalizeText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function mapProductIdToPlanCode(productId: string): "monthly" | "yearly" | null {
  switch (productId) {
    case "labelwise_premium_monthly":
      return "monthly";
    case "labelwise_premium_yearly":
      return "yearly";
    default:
      return null;
  }
}

function validateInput(body: unknown):
  | { ok: true; value: VerificationRequest }
  | { ok: false; response: Response } {
  if (typeof body !== "object" || body === null) {
    return {
      ok: false,
      response: errorResponse("Geçersiz ürün bilgisi.", "validate_input", 400),
    };
  }

  const productId = normalizeText((body as Record<string, unknown>).productId);
  const purchaseToken = normalizeText(
    (body as Record<string, unknown>).purchaseToken,
  );
  const packageName = normalizeText(
    (body as Record<string, unknown>).packageName,
  );

  if (!supportedProductIds.has(productId)) {
    return {
      ok: false,
      response: errorResponse("Geçersiz ürün bilgisi.", "validate_input", 400),
    };
  }

  if (packageName !== expectedPackageName) {
    return {
      ok: false,
      response: errorResponse("Geçersiz ürün bilgisi.", "validate_input", 400),
    };
  }

  if (purchaseToken.length === 0) {
    return {
      ok: false,
      response: errorResponse("Geçersiz ürün bilgisi.", "validate_input", 400),
    };
  }

  return {
    ok: true,
    value: {
      productId,
      purchaseToken,
      packageName,
    },
  };
}

async function sha256Hex(value: string): Promise<string> {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(value);
  const hashBuffer = await crypto.subtle.digest("SHA-256", bytes);
  const hashBytes = Array.from(new Uint8Array(hashBuffer));
  return hashBytes.map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function getAuthenticatedUser(
  request: Request,
): Promise<
  | {
      ok: true;
      user: User;
    }
  | {
      ok: false;
      response: Response;
    }
> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const supabaseAnonKey = request.headers.get("apikey")?.trim();
  const authHeader = request.headers.get("Authorization")?.trim();

  if (!supabaseUrl || !supabaseAnonKey || !authHeader) {
    return {
      ok: false,
      response: errorResponse(
        "Oturum bulunamadı. Lütfen tekrar giriş yap.",
        "auth",
        401,
      ),
    };
  }

  try {
    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (jwt.length === 0) {
      return {
        ok: false,
        response: errorResponse(
          "Oturum bulunamadı. Lütfen tekrar giriş yap.",
          "auth",
          401,
        ),
      };
    }

    const { data, error } = await authClient.auth.getUser(jwt);
    if (error || !data.user) {
      return {
        ok: false,
        response: errorResponse(
          "Oturum bulunamadı. Lütfen tekrar giriş yap.",
          "auth",
          401,
        ),
      };
    }

    return { ok: true, user: data.user };
  } catch (_error) {
    return {
      ok: false,
      response: errorResponse(
        "Oturum bulunamadı. Lütfen tekrar giriş yap.",
        "auth",
        401,
      ),
    };
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Geçersiz istek.", "method", 405);
  }

  console.log("Google Play Verify Function: request received");

  let body: unknown;

  try {
    body = await request.json();
  } catch (_error) {
    return errorResponse("Geçersiz ürün bilgisi.", "parse_body", 400);
  }

  const validation = validateInput(body);
  if (!validation.ok) {
    return validation.response;
  }

  const { productId, purchaseToken } = validation.value;
  console.log(
    `Google Play Verify Function: validate_input success productId=${productId}`,
  );

  const authResult = await getAuthenticatedUser(request);
  if (!authResult.ok) {
    return authResult.response;
  }

  console.log("Google Play Verify Function: auth success");

  const planCode = mapProductIdToPlanCode(productId);
  if (planCode == null) {
    return errorResponse("Geçersiz ürün bilgisi.", "map_product", 400);
  }

  const tokenHash = await sha256Hex(purchaseToken);
  console.log(
    `Google Play Verify Function: purchase token hashed productId=${productId} hashLength=${tokenHash.length}`,
  );

  console.log(
    "Google Play Verify Function: verification not enabled yet returning placeholder response",
  );

  return jsonResponse({
    success: false,
    isPremium: false,
    planCode: null,
    validUntil: null,
    status: "unknown",
    message: "Abonelik doğrulaması henüz aktif değil.",
  });
});
