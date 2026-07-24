import { createClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
} as const;

const androidPublisherScope =
  "https://www.googleapis.com/auth/androidpublisher";

const supportedProductIds = new Set([
  "labelwise_premium_monthly",
  "labelwise_premium_yearly",
]);

type VerificationRequest = {
  productId: string;
  purchaseToken: string;
  platform: "android";
};

type VerificationSuccessBody = {
  success: boolean;
  active: boolean;
  isPremium: boolean;
  productId: string;
  planCode: "monthly" | "yearly";
  expiresAt: string | null;
  validUntil: string | null;
  subscriptionState: string;
  status: string;
  message: string;
};

type GoogleServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
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
      active: false,
      isPremium: false,
      productId: null,
      planCode: null,
      expiresAt: null,
      validUntil: null,
      subscriptionState: "unknown",
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

function maskToken(token: string): string {
  if (token.length <= 10) {
    return "***";
  }

  return `${token.slice(0, 6)}...${token.slice(-4)}`;
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

function mapSubscriptionStateToStatus(subscriptionState: string): string {
  switch (subscriptionState) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return "active";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "grace_period";
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return "account_hold";
    case "SUBSCRIPTION_STATE_PENDING":
      return "pending";
    case "SUBSCRIPTION_STATE_CANCELED":
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED":
      return "canceled";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expired";
    default:
      return "unknown";
  }
}

function buildUserMessage(active: boolean, subscriptionState: string): string {
  if (active) {
    return "Premium üyelik doğrulandı.";
  }

  switch (subscriptionState) {
    case "SUBSCRIPTION_STATE_PENDING":
      return "Abonelik ödemesi henüz onay bekliyor.";
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return "Abonelik şu anda askıda görünüyor.";
    case "SUBSCRIPTION_STATE_PAUSED":
      return "Abonelik şu anda duraklatılmış görünüyor.";
    case "SUBSCRIPTION_STATE_CANCELED":
      return "Abonelik iptal edilmiş görünüyor.";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "Abonelik süresi sona ermiş görünüyor.";
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED":
      return "Abonelik işlemi tamamlanmamış görünüyor.";
    default:
      return "Abonelik şu anda aktif görünmüyor.";
  }
}

function validateInput(body: unknown):
  | { ok: true; value: VerificationRequest }
  | { ok: false; response: Response } {
  if (typeof body !== "object" || body === null) {
    return {
      ok: false,
      response: errorResponse("Geçersiz abonelik bilgisi.", "validate_input", 400),
    };
  }

  const productId = normalizeText((body as Record<string, unknown>).productId);
  const purchaseToken = normalizeText(
    (body as Record<string, unknown>).purchaseToken,
  );
  const platform = normalizeText((body as Record<string, unknown>).platform);

  if (!supportedProductIds.has(productId)) {
    return {
      ok: false,
      response: errorResponse("Geçersiz abonelik ürünü.", "validate_input", 400),
    };
  }

  if (platform !== "android") {
    return {
      ok: false,
      response: errorResponse("Geçersiz platform bilgisi.", "validate_input", 400),
    };
  }

  if (purchaseToken.length === 0) {
    return {
      ok: false,
      response: errorResponse(
        "Abonelik doğrulaması için satın alma bilgisi eksik.",
        "validate_input",
        400,
      ),
    };
  }

  return {
    ok: true,
    value: {
      productId,
      purchaseToken,
      platform: "android",
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

function base64UrlEncode(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");

  const binary = atob(normalized);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return bytes.buffer;
}

async function importServiceAccountKey(privateKeyPem: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

async function createGoogleAccessToken(
  serviceAccount: GoogleServiceAccount,
): Promise<string> {
  const tokenUri =
    normalizeText(serviceAccount.token_uri) || "https://oauth2.googleapis.com/token";

  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + 3600;

  const header = base64UrlEncode(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const payload = base64UrlEncode(
    new TextEncoder().encode(
      JSON.stringify({
        iss: serviceAccount.client_email,
        scope: androidPublisherScope,
        aud: tokenUri,
        exp: expiresAt,
        iat: issuedAt,
      }),
    ),
  );

  const signingInput = `${header}.${payload}`;
  const privateKey = await importServiceAccountKey(serviceAccount.private_key);
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  const signature = base64UrlEncode(new Uint8Array(signatureBuffer));

  const assertion = `${signingInput}.${signature}`;

  const response = await fetch(tokenUri, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.log(
      `Google Play Verify Function: token exchange failed status=${response.status} body=${errorText.slice(0, 300)}`,
    );
    throw new Error("google_token_exchange_failed");
  }

  const data = (await response.json()) as { access_token?: string };
  if (!data.access_token) {
    throw new Error("google_access_token_missing");
  }

  return data.access_token;
}

function getGoogleServiceAccount(): GoogleServiceAccount {
  const rawJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")?.trim();
  if (!rawJson) {
    throw new Error("missing_service_account_json");
  }

  const parsed = JSON.parse(rawJson) as Partial<GoogleServiceAccount>;
  if (
    normalizeText(parsed.client_email).length === 0 ||
    normalizeText(parsed.private_key).length === 0
  ) {
    throw new Error("invalid_service_account_json");
  }

  return {
    client_email: parsed.client_email!.trim(),
    private_key: parsed.private_key!,
    token_uri: normalizeText(parsed.token_uri) || undefined,
  };
}

async function fetchSubscriptionPurchase(
  packageName: string,
  purchaseToken: string,
  accessToken: string,
): Promise<Record<string, unknown>> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.log(
      `Google Play Verify Function: subscriptionsv2.get failed status=${response.status} body=${errorText.slice(0, 300)}`,
    );
    throw new Error(`google_subscription_get_failed:${response.status}`);
  }

  return (await response.json()) as Record<string, unknown>;
}

function extractMatchingLineItem(
  purchase: Record<string, unknown>,
  requestedProductId: string,
): Record<string, unknown> | null {
  const lineItems = Array.isArray(purchase.lineItems)
    ? purchase.lineItems.filter(
        (item): item is Record<string, unknown> =>
          typeof item === "object" && item !== null,
      )
    : [];

  if (lineItems.length === 0) {
    return null;
  }

  return (
    lineItems.find(
      (item) => normalizeText(item.productId) === requestedProductId,
    ) ?? lineItems[0]
  );
}

function parseExpiryTime(
  lineItem: Record<string, unknown> | null,
): Date | null {
  const rawExpiry = normalizeText(lineItem?.expiryTime);
  if (!rawExpiry) {
    return null;
  }

  const parsed = new Date(rawExpiry);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return parsed;
}

async function acknowledgeSubscriptionIfNeeded(
  packageName: string,
  productId: string,
  purchaseToken: string,
  accessToken: string,
  userId: string,
): Promise<void> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      developerPayload: `labelwise:${userId}`,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.log(
      `Google Play Verify Function: acknowledge failed userId=${userId} productId=${productId} status=${response.status} body=${errorText.slice(0, 300)}`,
    );
    throw new Error("google_acknowledge_failed");
  }

  console.log(
    `Google Play Verify Function: acknowledge success userId=${userId} productId=${productId}`,
  );
}

function buildVerificationResult(
  productId: string,
  planCode: "monthly" | "yearly",
  purchase: Record<string, unknown>,
): VerificationSuccessBody {
  const subscriptionState = normalizeText(purchase.subscriptionState) || "unknown";
  const lineItem = extractMatchingLineItem(purchase, productId);
  const expiryDate = parseExpiryTime(lineItem);
  const expiresAt = expiryDate?.toISOString() ?? null;
  const status = mapSubscriptionStateToStatus(subscriptionState);
  const expiryInFuture =
    expiryDate != null && expiryDate.getTime() > Date.now();
  const active =
    expiryInFuture &&
    (subscriptionState === "SUBSCRIPTION_STATE_ACTIVE" ||
      subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD");

  return {
    success: true,
    active,
    isPremium: active,
    productId,
    planCode,
    expiresAt,
    validUntil: expiresAt,
    subscriptionState,
    status,
    message: buildUserMessage(active, subscriptionState),
  };
}

async function upsertSubscriptionRecord(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
  productId: string,
  purchaseTokenHash: string,
  verification: VerificationSuccessBody,
  purchase: Record<string, unknown>,
): Promise<void> {
  const lineItem = extractMatchingLineItem(purchase, productId);
  const offerDetails =
    lineItem && typeof lineItem.offerDetails === "object" &&
        lineItem.offerDetails !== null
      ? (lineItem.offerDetails as Record<string, unknown>)
      : null;
  const autoRenewingPlan =
    lineItem && typeof lineItem.autoRenewingPlan === "object" &&
        lineItem.autoRenewingPlan !== null
      ? (lineItem.autoRenewingPlan as Record<string, unknown>)
      : null;

  const row = {
    user_id: userId,
    provider: "google_play",
    product_id: productId,
    purchase_token_hash: purchaseTokenHash,
    status: verification.status,
    starts_at: normalizeText(purchase.startTime) || null,
    expires_at: verification.expiresAt,
    auto_renewing:
      typeof autoRenewingPlan?.autoRenewEnabled === "boolean"
        ? autoRenewingPlan.autoRenewEnabled
        : null,
    last_verified_at: new Date().toISOString(),
    order_id:
      normalizeText(lineItem?.latestSuccessfulOrderId) ||
      normalizeText(purchase.latestOrderId) ||
      null,
    base_plan_id: normalizeText(offerDetails?.basePlanId) || null,
    environment: purchase.testPurchase ? "sandbox" : "production",
  };

  const { error } = await adminClient.from("user_subscriptions").upsert(row, {
    onConflict: "purchase_token_hash",
  });

  if (error) {
    console.log(
      `Google Play Verify Function: user_subscriptions upsert failed userId=${userId} productId=${productId} code=${error.code ?? "unknown"}`,
    );
    throw new Error("user_subscriptions_upsert_failed");
  }
}

async function refreshUserEntitlement(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<void> {
  const nowIso = new Date().toISOString();
  const { data, error } = await adminClient
    .from("user_subscriptions")
    .select("product_id, expires_at, status")
    .eq("user_id", userId)
    .in("status", ["active", "grace_period"])
    .gt("expires_at", nowIso)
    .order("expires_at", { ascending: false })
    .limit(1);

  if (error) {
    console.log(
      `Google Play Verify Function: user_subscriptions entitlement lookup failed userId=${userId} code=${error.code ?? "unknown"}`,
    );
    throw new Error("user_entitlement_lookup_failed");
  }

  const top = Array.isArray(data) && data.length > 0 ? data[0] : null;
  const active = top != null;
  const planCode = top
    ? mapProductIdToPlanCode(normalizeText(top.product_id))
    : null;
  const validUntil = top ? normalizeText(top.expires_at) || null : null;

  const { error: upsertError } = await adminClient
    .from("user_entitlements")
    .upsert(
      {
        user_id: userId,
        is_premium: active,
        plan_code: active ? planCode : null,
        entitlement_source: "google_play",
        valid_until: active ? validUntil : null,
      },
      { onConflict: "user_id" },
    );

  if (upsertError) {
    console.log(
      `Google Play Verify Function: user_entitlements upsert failed userId=${userId} code=${upsertError.code ?? "unknown"}`,
    );
    throw new Error("user_entitlements_upsert_failed");
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Geçersiz istek.", "method", 405);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch (_error) {
    return errorResponse("Geçersiz abonelik bilgisi.", "parse_body", 400);
  }

  const validation = validateInput(body);
  if (!validation.ok) {
    return validation.response;
  }

  const { productId, purchaseToken } = validation.value;
  const planCode = mapProductIdToPlanCode(productId);
  if (planCode == null) {
    return errorResponse("Geçersiz abonelik ürünü.", "map_product", 400);
  }

  const authResult = await getAuthenticatedUser(request);
  if (!authResult.ok) {
    return authResult.response;
  }

  const user = authResult.user;
  const purchaseTokenHash = await sha256Hex(purchaseToken);
  const maskedToken = maskToken(purchaseToken);
  const packageName = normalizeText(Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME"));
  if (!packageName) {
    return errorResponse(
      "Google Play paket bilgisi eksik.",
      "google_play_package_name",
      500,
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Sunucu yapılandırması eksik.", "env", 500);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  console.log(
    `Google Play Verify Function: request received userId=${user.id} productId=${productId} token=${maskedToken}`,
  );

  let verification: VerificationSuccessBody;

  try {
    const serviceAccount = getGoogleServiceAccount();
    const accessToken = await createGoogleAccessToken(serviceAccount);
    const googlePurchase = await fetchSubscriptionPurchase(
      packageName,
      purchaseToken,
      accessToken,
    );

    verification = buildVerificationResult(productId, planCode, googlePurchase);

    console.log(
      `Google Play Verify Function: verified userId=${user.id} productId=${productId} subscriptionState=${verification.subscriptionState} expiresAt=${verification.expiresAt ?? "null"} active=${verification.active}`,
    );

    if (
      verification.active &&
      normalizeText(googlePurchase.acknowledgementState) ===
        "ACKNOWLEDGEMENT_STATE_PENDING"
    ) {
      try {
        await acknowledgeSubscriptionIfNeeded(
          packageName,
          productId,
          purchaseToken,
          accessToken,
          user.id,
        );
      } catch (_error) {
        return errorResponse(
          "Abonelik doğrulandı ancak satın alma onayı tamamlanamadı.",
          "acknowledge_subscription",
          502,
        );
      }
    }

    await upsertSubscriptionRecord(
      adminClient,
      user.id,
      productId,
      purchaseTokenHash,
      verification,
      googlePurchase,
    );
    await refreshUserEntitlement(adminClient, user.id);

    return jsonResponse(verification);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";

    if (
      message === "missing_service_account_json" ||
      message === "invalid_service_account_json"
    ) {
      return errorResponse(
        "Google Play doğrulama yapılandırması eksik.",
        "google_service_account",
        500,
      );
    }

    if (message.startsWith("google_subscription_get_failed:")) {
      return errorResponse(
        "Abonelik bilgisi şu anda Google Play üzerinden doğrulanamadı.",
        "google_subscription_get",
        502,
      );
    }

    if (message === "google_token_exchange_failed") {
      return errorResponse(
        "Google Play doğrulama erişimi alınamadı.",
        "google_access_token",
        502,
      );
    }

    if (
      message === "user_subscriptions_upsert_failed" ||
      message === "user_entitlement_lookup_failed" ||
      message === "user_entitlements_upsert_failed"
    ) {
      return errorResponse(
        "Abonelik doğrulandı ancak üyelik durumu kaydedilemedi.",
        "supabase_upsert",
        500,
      );
    }

    console.log(
      `Google Play Verify Function: unexpected error userId=${user.id} productId=${productId} error=${message}`,
    );
    return errorResponse(
      "Abonelik bilgisi şu anda getirilemedi. Lütfen birkaç saniye sonra tekrar deneyin.",
      "unexpected",
      500,
    );
  }
});
