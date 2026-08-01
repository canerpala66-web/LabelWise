import { cache } from "react";
import { createSupabaseAdminClient, createSupabaseServerClient } from "@/lib/supabase/server";
import type { BlogPostRecord } from "@/lib/blog/types";

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

export const getPublishedBlogPosts = cache(async (): Promise<BlogPostRecord[]> => {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("blog_posts")
    .select(selectFields)
    .eq("status", "published")
    .order("published_at", { ascending: false, nullsFirst: false });

  if (error) {
    throw error;
  }

  return (data ?? []) as unknown as BlogPostRecord[];
});

export const getPublishedBlogPostBySlug = cache(async (slug: string): Promise<BlogPostRecord | null> => {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("blog_posts")
    .select(selectFields)
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (data as unknown as BlogPostRecord | null) ?? null;
});

export async function getAllBlogPostsForAdmin(): Promise<BlogPostRecord[]> {
  const supabase = createSupabaseAdminClient();
  const { data, error } = await supabase.from("blog_posts").select(selectFields).order("updated_at", {
    ascending: false,
  });

  if (error) {
    throw error;
  }

  return (data ?? []) as unknown as BlogPostRecord[];
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

  return (data as unknown as BlogPostRecord | null) ?? null;
}
