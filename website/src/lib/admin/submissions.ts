import { createSupabaseAdminClient } from "@/lib/supabase/server";
import type {
  SubmissionImagePreview,
  SubmissionStatus,
  SubmittedProduct,
} from "@/lib/admin/types";

const submissionFields =
  "id, barcode, name, brand, ingredients_text, energy_kcal, fat, " +
  "saturated_fat, sugars, fiber, protein, salt, front_image_path, " +
  "nutrition_image_path, ingredients_image_path, status, source, created_at, " +
  "reviewed_at, review_note, reviewed_by, category";

const fallbackSubmissionFields =
  "id, barcode, name, brand, ingredients_text, energy_kcal, fat, " +
  "saturated_fat, sugars, fiber, protein, salt, front_image_path, " +
  "nutrition_image_path, ingredients_image_path, status, source, created_at, " +
  "reviewed_at, review_note, category";

export function normalizeSubmissionStatus(value: string | null | undefined) {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "approved" || normalized === "rejected") {
    return normalized satisfies SubmissionStatus;
  }
  return "pending" satisfies SubmissionStatus;
}

function isMissingColumnError(error: { message?: string; details?: string; hint?: string }) {
  const text = `${error.message ?? ""} ${error.details ?? ""} ${error.hint ?? ""}`.toLowerCase();
  return text.includes("reviewed_by");
}

async function runSubmissionQuery<T>(
  queryFactory: (fields: string) => Promise<T>,
) {
  try {
    return await queryFactory(submissionFields);
  } catch (error) {
    if (
      typeof error === "object" &&
      error !== null &&
      "message" in error &&
      isMissingColumnError(error as { message?: string; details?: string; hint?: string })
    ) {
      return queryFactory(fallbackSubmissionFields);
    }
    throw error;
  }
}

export async function listSubmittedProducts(status: SubmissionStatus | "all") {
  const client = createSupabaseAdminClient();

  return runSubmissionQuery(async (fields) => {
    let query = client.from("submitted_products").select(fields);

    if (status === "pending") {
      query = query.or("status.eq.pending,status.is.null");
    } else if (status !== "all") {
      query = query.eq("status", status);
    }

    const { data, error } = await query.order("created_at", { ascending: false });

    if (error) {
      throw error;
    }

    return (data ?? []) as unknown as SubmittedProduct[];
  });
}

export async function getSubmittedProductById(id: string) {
  const client = createSupabaseAdminClient();

  return runSubmissionQuery(async (fields) => {
    const { data, error } = await client
      .from("submitted_products")
      .select(fields)
      .eq("id", id)
      .maybeSingle();

    if (error) {
      throw error;
    }

    return (data ?? null) as unknown as SubmittedProduct | null;
  });
}

export async function buildSignedSubmissionImages(
  submission: SubmittedProduct,
) {
  const client = createSupabaseAdminClient();
  const items = [
    { label: "On Yuz", path: submission.front_image_path },
    { label: "Besin Degerleri", path: submission.nutrition_image_path },
    { label: "Icerikler", path: submission.ingredients_image_path },
  ].filter((item) => item.path);

  const signedImages: SubmissionImagePreview[] = [];

  for (const item of items) {
    const { data, error } = await client.storage
      .from("submitted-product-photos")
      .createSignedUrl(item.path!, 3600);

    if (!error && data?.signedUrl) {
      signedImages.push({
        label: item.label,
        path: item.path!,
        signedUrl: data.signedUrl,
      });
    }
  }

  return signedImages;
}

function addIfPresent(
  target: Record<string, string | number | null>,
  key: string,
  value: string | number | null | undefined,
) {
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed) {
      target[key] = trimmed;
    }
    return;
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    target[key] = value;
  }
}

function maybeNumber(value: FormDataEntryValue | null) {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim().replace(",", ".");
  if (!normalized) {
    return null;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function maybeText(value: FormDataEntryValue | null) {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed || null;
}

export function extractDraftPayload(formData: FormData) {
  return {
    barcode: maybeText(formData.get("barcode")),
    name: maybeText(formData.get("name")),
    brand: maybeText(formData.get("brand")),
    category: maybeText(formData.get("category")),
    ingredients_text: maybeText(formData.get("ingredients_text")),
    energy_kcal: maybeNumber(formData.get("energy_kcal")),
    fat: maybeNumber(formData.get("fat")),
    saturated_fat: maybeNumber(formData.get("saturated_fat")),
    sugars: maybeNumber(formData.get("sugars")),
    fiber: maybeNumber(formData.get("fiber")),
    protein: maybeNumber(formData.get("protein")),
    salt: maybeNumber(formData.get("salt")),
    review_note: maybeText(formData.get("review_note")),
  };
}

export async function saveSubmissionDraft(id: string, formData: FormData) {
  const client = createSupabaseAdminClient();
  const payload = extractDraftPayload(formData);

  const { error } = await client
    .from("submitted_products")
    .update(payload)
    .eq("id", id);

  if (error) {
    throw error;
  }
}

async function upsertApprovedProduct(submission: SubmittedProduct) {
  const client = createSupabaseAdminClient();
  const productData: Record<string, string | number | null> = {
    barcode: submission.barcode,
    name: submission.name,
    source: "user_submission",
  };

  addIfPresent(productData, "brand", submission.brand);
  addIfPresent(productData, "category", submission.category);
  addIfPresent(productData, "ingredients_text", submission.ingredients_text);
  addIfPresent(productData, "energy_kcal", submission.energy_kcal);
  addIfPresent(productData, "fat", submission.fat);
  addIfPresent(productData, "saturated_fat", submission.saturated_fat);
  addIfPresent(productData, "sugars", submission.sugars);
  addIfPresent(productData, "fiber", submission.fiber);
  addIfPresent(productData, "protein", submission.protein);
  addIfPresent(productData, "salt", submission.salt);
  addIfPresent(productData, "front_image_path", submission.front_image_path);

  try {
    const { error } = await client
      .from("products")
      .upsert(productData, { onConflict: "barcode" });

    if (error) {
      throw error;
    }
  } catch (error) {
    if (
      typeof error === "object" &&
      error !== null &&
      "message" in error &&
      `${(error as { message?: string }).message ?? ""}`.toLowerCase().includes("category")
    ) {
      const fallbackData = { ...productData };
      delete fallbackData.category;
      const { error: fallbackError } = await client
        .from("products")
        .upsert(fallbackData, { onConflict: "barcode" });

      if (fallbackError) {
        throw fallbackError;
      }
      return;
    }

    throw error;
  }
}

export async function approveSubmission(id: string, reviewerId: string) {
  const client = createSupabaseAdminClient();
  const submission = await getSubmittedProductById(id);

  if (!submission) {
    throw new Error("SUBMISSION_NOT_FOUND");
  }

  if (!submission.barcode?.trim() || !submission.name?.trim()) {
    throw new Error("SUBMISSION_INVALID");
  }

  await upsertApprovedProduct(submission);

  const { error } = await client
    .from("submitted_products")
    .update({
      status: "approved",
      reviewed_at: new Date().toISOString(),
      reviewed_by: reviewerId,
    })
    .eq("id", id);

  if (error) {
    throw error;
  }
}

export async function rejectSubmission(
  id: string,
  reviewerId: string,
  reviewNote: string | null,
) {
  const client = createSupabaseAdminClient();
  const { error } = await client
    .from("submitted_products")
    .update({
      status: "rejected",
      reviewed_at: new Date().toISOString(),
      reviewed_by: reviewerId,
      review_note: reviewNote,
    })
    .eq("id", id);

  if (error) {
    throw error;
  }
}
