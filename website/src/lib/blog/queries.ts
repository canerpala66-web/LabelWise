import { cache } from "react";
import { createSupabaseAdminClient, createSupabaseServerClient } from "@/lib/supabase/server";
import type { BlogPostQueryResult, BlogPostRecord } from "@/lib/blog/types";

const selectFields = [
  "id",
  "title",
  "slug",
  "excerpt",
  "content_markdown",
  "cover_image_url",
  "category",
  "tags",
  "seo_title",
  "seo_description",
  "status",
  "published_at",
  "created_at",
  "updated_at",
  "created_by",
  "updated_by",
].join(", ");

function normalizeBlogPostRecord(input: unknown): BlogPostRecord | null {
  if (!input || typeof input !== "object") {
    return null;
  }

  const row = input as Record<string, unknown>;
  const id = typeof row.id === "string" ? row.id : "";
  const title = typeof row.title === "string" ? row.title : "";
  const slug = typeof row.slug === "string" ? row.slug : "";
  const contentMarkdown =
    typeof row.content_markdown === "string" ? row.content_markdown : "";

  if (!id || !title || !slug) {
    return null;
  }

  return {
    id,
    title,
    slug,
    excerpt: typeof row.excerpt === "string" ? row.excerpt : null,
    content_markdown: contentMarkdown,
    cover_image_url: typeof row.cover_image_url === "string" ? row.cover_image_url : null,
    category: typeof row.category === "string" ? row.category : null,
    tags: Array.isArray(row.tags) ? row.tags.filter((tag): tag is string => typeof tag === "string") : [],
    seo_title: typeof row.seo_title === "string" ? row.seo_title : null,
    seo_description: typeof row.seo_description === "string" ? row.seo_description : null,
    status: row.status === "published" ? "published" : "draft",
    published_at: typeof row.published_at === "string" ? row.published_at : null,
    created_at: typeof row.created_at === "string" ? row.created_at : "",
    updated_at: typeof row.updated_at === "string" ? row.updated_at : "",
    created_by: typeof row.created_by === "string" ? row.created_by : null,
    updated_by: typeof row.updated_by === "string" ? row.updated_by : null,
  };
}

function normalizeBlogPostList(rows: unknown): BlogPostRecord[] {
  if (!Array.isArray(rows)) {
    return [];
  }

  return rows
    .map(normalizeBlogPostRecord)
    .filter((row): row is BlogPostRecord => row !== null);
}

export const getPublishedBlogPosts = cache(async (): Promise<BlogPostRecord[]> => {
  const result = await getPublishedBlogPostsSafe();
  return result.data;
});

export const getPublishedBlogPostsSafe = cache(async (): Promise<BlogPostQueryResult<BlogPostRecord[]>> => {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("blog_posts")
    .select(selectFields)
    .eq("status", "published")
    .order("published_at", { ascending: false, nullsFirst: false });

  if (error) {
    console.error("[blog] published posts query failed", {
      message: error.message,
      code: error.code,
      details: error.details,
    });
    return {
      data: [],
      error: "Blog yazıları şu anda yüklenemedi.",
    };
  }

  return {
    data: normalizeBlogPostList(data),
    error: null,
  };
});

export const getPublishedBlogPostBySlug = cache(async (slug: string): Promise<BlogPostRecord | null> => {
  const result = await getPublishedBlogPostBySlugSafe(slug);
  return result.data;
});

export const getPublishedBlogPostBySlugSafe = cache(
  async (slug: string): Promise<BlogPostQueryResult<BlogPostRecord | null>> => {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("blog_posts")
    .select(selectFields)
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) {
      console.error("[blog] blog detail query failed", {
        slug,
        message: error.message,
        code: error.code,
        details: error.details,
      });
      return {
        data: null,
        error: "Blog yazısı şu anda yüklenemedi.",
      };
  }

    return {
      data: normalizeBlogPostRecord(data),
      error: null,
    };
  },
);

export async function getAllBlogPostsForAdmin(): Promise<BlogPostRecord[]> {
  const supabase = createSupabaseAdminClient();
  const { data, error } = await supabase.from("blog_posts").select(selectFields).order("updated_at", {
    ascending: false,
  });

  if (error) {
    throw error;
  }

  return normalizeBlogPostList(data);
}

export async function getBlogPostByIdForAdmin(id: string): Promise<BlogPostRecord | null> {
  const supabase = createSupabaseAdminClient();
  const { data, error } = await supabase
    .from("blog_posts")
    .select(selectFields)
    .eq("id", id)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return normalizeBlogPostRecord(data);
}
