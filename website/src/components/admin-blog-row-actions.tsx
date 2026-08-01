"use client";

import { useState } from "react";
import Link from "next/link";
import { deleteBlogPostAction, toggleBlogPostStatusAction } from "@/lib/admin/blog-actions";
import type { BlogPostRecord } from "@/lib/blog/types";

type Props = {
  post: BlogPostRecord;
};

export function AdminBlogRowActions({ post }: Props) {
  const [isDeleting, setIsDeleting] = useState(false);

  return (
    <div className="flex flex-wrap justify-end gap-2">
      <Link href={`/admin/blog/${post.id}/edit`} className="button-secondary min-h-9 px-4 text-xs">
        Düzenle
      </Link>

      <form action={toggleBlogPostStatusAction}>
        <input type="hidden" name="post_id" value={post.id} />
        <input type="hidden" name="current_status" value={post.status} />
        <button type="submit" className="button-secondary min-h-9 px-4 text-xs">
          {post.status === "published" ? "Taslağa al" : "Yayınla"}
        </button>
      </form>

      <form
        action={deleteBlogPostAction}
        onSubmit={(event) => {
          if (isDeleting) return;
          const confirmed = window.confirm(`"${post.title}" silinsin mi?`);
          if (!confirmed) {
            event.preventDefault();
            return;
          }
          setIsDeleting(true);
        }}
      >
        <input type="hidden" name="post_id" value={post.id} />
        <button
          type="submit"
          className="inline-flex min-h-9 items-center justify-center rounded-full border border-red-300/25 bg-red-300/10 px-4 text-xs font-semibold text-red-100"
        >
          Sil
        </button>
      </form>
    </div>
  );
}
