import { createClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
} as const;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function errorResponse(message: string, step: string, status: number): Response {
  console.log(`Delete Account Function: error step=${step} message=${message}`);
  return jsonResponse(
    {
      success: false,
      message,
      step,
    },
    status,
  );
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
      response: errorResponse("Oturum doğrulanamadı.", "auth_headers", 401),
    };
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });

  const { data, error } = await authClient.auth.getUser();
  if (error || !data.user) {
    return {
      ok: false,
      response: errorResponse("Oturum doğrulanamadı.", "auth_user", 401),
    };
  }

  return {
    ok: true,
    user: data.user,
  };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Geçersiz istek yöntemi.", "request_method", 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();

  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse(
      "Hesap silme servisi şu anda kullanılamıyor.",
      "env_check",
      500,
    );
  }

  const authResult = await getAuthenticatedUser(request);
  if (!authResult.ok) {
    return authResult.response;
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const userId = authResult.user.id;
  console.log(`Delete Account Function: request received userId=${userId}`);

  const { error } = await adminClient.auth.admin.deleteUser(userId, true);
  if (error) {
    console.log(
      `Delete Account Function: delete failed userId=${userId} message=${error.message}`,
    );
    return errorResponse(
      "Hesap şu anda silinemedi. Lütfen tekrar deneyin.",
      "delete_user",
      500,
    );
  }

  console.log(`Delete Account Function: delete success userId=${userId}`);
  return jsonResponse({
    success: true,
    message: "Hesabın kalıcı olarak silindi.",
  });
});
