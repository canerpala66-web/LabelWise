"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireAdminUser } from "@/lib/admin/auth";
import { parseTagInput, slugifyTurkish } from "@/lib/blog/slug";
import type { BlogPostFormValues, BlogPostStatus } from "@/lib/blog/types";
import { createSupabaseAdminClient } from "@/lib/supabase/server";

export type BlogPostActionState = {
  success: boolean;
  message: string | null;
  fieldErrors?: Partial<Record<keyof BlogPostFormValues, string>>;
  values?: Partial<BlogPostFormValues>;
};

function mapValues(formData: FormData): BlogPostFormValues {
  return {
    title: `${formData.get("title") ?? ""}`.trim(),
    slug: `${formData.get("slug") ?? ""}`.trim(),
    excerpt: `${formData.get("excerpt") ?? ""}`.trim(),
    content_markdown: `${formData.get("content_markdown") ?? ""}`.trim(),
    cover_image_url: `${formData.get("cover_image_url") ?? ""}`.trim(),
    category: `${formData.get("category") ?? ""}`.trim(),
    tags: `${formData.get("tags") ?? ""}`.trim(),
    seo_title: `${formData.get("seo_title") ?? ""}`.trim(),
    seo_description: `${formData.get("seo_description") ?? ""}`.trim(),
    status: `${formData.get("status") ?? "draft"}`.trim() === "published" ? "published" : "draft",
    published_at: `${formData.get("published_at") ?? ""}`.trim(),
  };
}

function normalizeStatus(values: BlogPostFormValues, formData: FormData): BlogPostStatus {
  const intent = `${formData.get("intent") ?? ""}`.trim();
  if (intent === "publish") return "published";
  if (intent === "draft") return "draft";
  return values.status;
}

function validateValues(values: BlogPostFormValues) {
  const errors: BlogPostActionState["fieldErrors"] = {};

  if (!values.title) {
    errors.title = "Başlık gerekli.";
  }

  if (!values.slug) {
    errors.slug = "Slug gerekli.";
  }

  if (!values.content_markdown) {
    errors.content_markdown = "İçerik gerekli.";
  }

  if (!["draft", "published"].includes(values.status)) {
    errors.status = "Durum geçersiz.";
  }

  if (values.seo_description.length > 180) {
    errors.seo_description = "SEO açıklaması 180 karakteri geçmemeli.";
  }

  return Object.keys(errors).length > 0 ? errors : undefined;
}

function sanitizeValues(values: BlogPostFormValues, nextStatus: BlogPostStatus, existingPublishedAt?: string | null) {
  const nowIso = new Date().toISOString();
  const normalizedSlug = slugifyTurkish(values.slug || values.title);

  return {
    title: values.title,
    slug: normalizedSlug,
    excerpt: values.excerpt || null,
    content_markdown: values.content_markdown,
    cover_image_url: values.cover_image_url || null,
    category: values.category || null,
    tags: parseTagInput(values.tags),
    seo_title: values.seo_title || null,
    seo_description: values.seo_description || null,
    status: nextStatus,
    published_at:
      nextStatus === "published"
        ? values.published_at || existingPublishedAt || nowIso
        : existingPublishedAt ?? null,
    updated_at: nowIso,
  };
}

function safeMessageFromError(error: unknown) {
  const message =
    typeof error === "object" && error && "message" in error
      ? String((error as { message?: string }).message ?? "")
      : "";

  const lower = message.toLowerCase();
  if (lower.includes("blog_posts_slug_key") || lower.includes("duplicate key")) {
    return "Bu slug zaten kullanılıyor. Farklı bir slug seç.";
  }

  return "Blog yazısı kaydedilemedi. Lütfen tekrar dene.";
}

function revalidateBlogPaths(slug?: string) {
  revalidatePath("/blog");
  revalidatePath("/admin/blog");
  if (slug) {
    revalidatePath(`/blog/${slug}`);
  }
}

export async function createBlogPostAction(
  _previousState: BlogPostActionState,
  formData: FormData,
): Promise<BlogPostActionState> {
  const session = await requireAdminUser();
  const rawValues = mapValues(formData);
  const values: BlogPostFormValues = {
    ...rawValues,
    slug: slugifyTurkish(rawValues.slug || rawValues.title),
    status: normalizeStatus(rawValues, formData),
  };

  const fieldErrors = validateValues(values);
  if (fieldErrors) {
    return { success: false, message: "Formu kontrol et.", fieldErrors, values };
  }

  try {
    const supabase = createSupabaseAdminClient();
    const payload = sanitizeValues(values, values.status);
    const { data, error } = await supabase
      .from("blog_posts")
      .insert({
        ...payload,
        created_by: session.userId,
        updated_by: session.userId,
      })
      .select("id")
      .single();

    if (error) {
      throw error;
    }

    revalidateBlogPaths(payload.slug);
    redirect(`/admin/blog/${data.id}/edit?saved=1`);
  } catch (error) {
    return { success: false, message: safeMessageFromError(error), values };
  }
}

export async function updateBlogPostAction(
  _previousState: BlogPostActionState,
  formData: FormData,
): Promise<BlogPostActionState> {
  const session = await requireAdminUser();
  const postId = `${formData.get("post_id") ?? ""}`.trim();

  if (!postId) {
    return { success: false, message: "Blog yazısı bulunamadı." };
  }

  const rawValues = mapValues(formData);
  const values: BlogPostFormValues = {
    ...rawValues,
    slug: slugifyTurkish(rawValues.slug || rawValues.title),
    status: normalizeStatus(rawValues, formData),
  };

  const fieldErrors = validateValues(values);
  if (fieldErrors) {
    return { success: false, message: "Formu kontrol et.", fieldErrors, values };
  }

  try {
    const supabase = createSupabaseAdminClient();
    const { data: existing, error: existingError } = await supabase
      .from("blog_posts")
      .select("published_at")
      .eq("id", postId)
      .single();

    if (existingError) {
      throw existingError;
    }

    const payload = sanitizeValues(values, values.status, existing.published_at);
    const { error } = await supabase
      .from("blog_posts")
      .update({
        ...payload,
        updated_by: session.userId,
      })
      .eq("id", postId);

    if (error) {
      throw error;
    }

    revalidateBlogPaths(payload.slug);
    return { success: true, message: "Blog yazısı kaydedildi.", values };
  } catch (error) {
    return { success: false, message: safeMessageFromError(error), values };
  }
}

export async function deleteBlogPostAction(formData: FormData) {
  await requireAdminUser();
  const postId = `${formData.get("post_id") ?? ""}`.trim();

  if (!postId) {
    redirect("/admin/blog");
  }

  const supabase = createSupabaseAdminClient();
  await supabase.from("blog_posts").delete().eq("id", postId);
  revalidateBlogPaths();
  redirect("/admin/blog");
}

export async function toggleBlogPostStatusAction(formData: FormData) {
  const session = await requireAdminUser();
  const postId = `${formData.get("post_id") ?? ""}`.trim();
  const currentStatus = `${formData.get("current_status") ?? "draft"}`.trim() === "published"
    ? "published"
    : "draft";

  if (!postId) {
    redirect("/admin/blog");
  }

  const nextStatus: BlogPostStatus = currentStatus === "published" ? "draft" : "published";
  const supabase = createSupabaseAdminClient();
  const nowIso = new Date().toISOString();
  const { data: existing } = await supabase
    .from("blog_posts")
    .select("slug, published_at")
    .eq("id", postId)
    .maybeSingle();

  await supabase
    .from("blog_posts")
    .update({
      status: nextStatus,
      published_at:
        nextStatus === "published" ? existing?.published_at ?? nowIso : existing?.published_at ?? null,
      updated_by: session.userId,
      updated_at: nowIso,
    })
    .eq("id", postId);

  revalidateBlogPaths(existing?.slug ?? undefined);
  redirect("/admin/blog");
}
