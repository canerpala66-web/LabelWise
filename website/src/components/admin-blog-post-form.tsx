"use client";

import { useActionState, useMemo, useState } from "react";
import ReactMarkdown from "react-markdown";
import type { BlogPostActionState } from "@/lib/admin/blog-actions";
import { slugifyTurkish } from "@/lib/blog/slug";
import type { BlogPostRecord } from "@/lib/blog/types";

type Props = {
  action: (
    previousState: BlogPostActionState,
    formData: FormData,
  ) => Promise<BlogPostActionState>;
  initialPost?: BlogPostRecord | null;
  submitLabel?: string;
};

function inputClassName() {
  return "rounded-2xl border border-white/10 bg-white/6 px-4 py-3 text-white outline-none placeholder:text-white/35 focus:border-[color:var(--gold)]";
}

function tagsToText(tags: string[] | null | undefined) {
  return (tags ?? []).join(", ");
}

export function AdminBlogPostForm({ action, initialPost, submitLabel = "Yayınla" }: Props) {
  const [state, formAction, isPending] = useActionState(action, {
    success: false,
    message: null,
  });
  const [title, setTitle] = useState(initialPost?.title ?? "");
  const [slug, setSlug] = useState(initialPost?.slug ?? "");
  const [slugTouched, setSlugTouched] = useState(Boolean(initialPost?.slug));
  const [content, setContent] = useState(initialPost?.content_markdown ?? "");

  const previewContent = useMemo(() => content.trim(), [content]);

  return (
    <form action={formAction} className="grid gap-6">
      {initialPost ? <input type="hidden" name="post_id" value={initialPost.id} /> : null}

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(320px,0.8fr)]">
        <section className="card p-6 sm:p-8">
          <div className="grid gap-5">
            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Başlık</span>
              <input
                name="title"
                value={title}
                onChange={(event) => {
                  const nextTitle = event.target.value;
                  setTitle(nextTitle);
                  if (!slugTouched) {
                    setSlug(slugifyTurkish(nextTitle));
                  }
                }}
                className={inputClassName()}
                placeholder="Glukoz-fruktoz şurubu nedir?"
                required
              />
              {state.fieldErrors?.title ? (
                <span className="text-sm text-red-200">{state.fieldErrors.title}</span>
              ) : null}
            </label>

            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Slug</span>
              <input
                name="slug"
                value={slug}
                onChange={(event) => {
                  setSlugTouched(true);
                  setSlug(event.target.value);
                }}
                className={inputClassName()}
                placeholder="glukoz-fruktoz-surubu-nedir"
                required
              />
              <span className="text-xs text-[color:var(--text-soft)]">
                Türkçe karakterler otomatik olarak sadeleşir. İstersen manuel de düzenleyebilirsin.
              </span>
              {state.fieldErrors?.slug ? (
                <span className="text-sm text-red-200">{state.fieldErrors.slug}</span>
              ) : null}
            </label>

            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Özet</span>
              <textarea
                name="excerpt"
                defaultValue={state.values?.excerpt ?? initialPost?.excerpt ?? ""}
                rows={3}
                className={inputClassName()}
                placeholder="Paketli gıdalarda sık karşımıza çıkan glukoz-fruktoz şurubunu sade bir dille anlatıyoruz."
              />
            </label>

            <div className="grid gap-5 md:grid-cols-2">
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">Kapak görseli URL</span>
                <input
                  name="cover_image_url"
                  defaultValue={state.values?.cover_image_url ?? initialPost?.cover_image_url ?? ""}
                  className={inputClassName()}
                  placeholder="https://..."
                />
              </label>
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">Kategori</span>
                <input
                  name="category"
                  defaultValue={state.values?.category ?? initialPost?.category ?? ""}
                  className={inputClassName()}
                  placeholder="İçerik Rehberi"
                />
              </label>
            </div>

            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Etiketler</span>
              <input
                name="tags"
                defaultValue={state.values?.tags ?? tagsToText(initialPost?.tags)}
                className={inputClassName()}
                placeholder="katkı maddeleri, şeker, etiket okuma"
              />
            </label>

            <div className="grid gap-5 md:grid-cols-2">
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">SEO başlığı</span>
                <input
                  name="seo_title"
                  defaultValue={state.values?.seo_title ?? initialPost?.seo_title ?? ""}
                  className={inputClassName()}
                  placeholder="Glukoz-fruktoz şurubu nedir? | LabelWise Blog"
                />
              </label>
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">SEO açıklaması</span>
                <textarea
                  name="seo_description"
                  defaultValue={state.values?.seo_description ?? initialPost?.seo_description ?? ""}
                  rows={3}
                  className={inputClassName()}
                  placeholder="Arama sonucu için kısa açıklama"
                />
                {state.fieldErrors?.seo_description ? (
                  <span className="text-sm text-amber-200">{state.fieldErrors.seo_description}</span>
                ) : null}
              </label>
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">Durum</span>
                <select
                  name="status"
                  defaultValue={state.values?.status ?? initialPost?.status ?? "draft"}
                  className={inputClassName()}
                >
                  <option value="draft">Taslak</option>
                  <option value="published">Yayında</option>
                </select>
                {state.fieldErrors?.status ? (
                  <span className="text-sm text-red-200">{state.fieldErrors.status}</span>
                ) : null}
              </label>
              <label className="grid gap-2">
                <span className="text-sm font-medium text-white">Yayın tarihi</span>
                <input
                  name="published_at"
                  defaultValue={state.values?.published_at ?? initialPost?.published_at ?? ""}
                  className={inputClassName()}
                  placeholder="Boşsa yayınlarken otomatik atanır"
                />
              </label>
            </div>

            <label className="grid gap-2">
              <span className="text-sm font-medium text-white">Markdown içerik</span>
              <textarea
                name="content_markdown"
                value={content}
                onChange={(event) => setContent(event.target.value)}
                rows={18}
                className={`${inputClassName()} min-h-[26rem] font-mono text-sm leading-7`}
                placeholder="# Başlık&#10;&#10;Paragraf metni..."
                required
              />
              {state.fieldErrors?.content_markdown ? (
                <span className="text-sm text-red-200">{state.fieldErrors.content_markdown}</span>
              ) : null}
            </label>
          </div>
        </section>

        <aside className="grid gap-6">
          <section className="card p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.28em] text-[color:var(--gold-soft)]">
              Önizleme
            </p>
            <h2 className="mt-4 text-2xl font-semibold text-white">
              {title || "Yazı başlığı burada görünecek"}
            </h2>
            <div className="mt-6 rounded-[1.5rem] border border-white/8 bg-white/[0.04] p-5">
              {previewContent ? (
                <div className="markdown-content">
                  <ReactMarkdown>{previewContent}</ReactMarkdown>
                </div>
              ) : (
                <p className="text-sm leading-7 text-[color:var(--text-muted)]">
                  Markdown önizlemesi, içerik girdikçe burada görünür.
                </p>
              )}
            </div>
          </section>

          <section className="card p-6">
            <p className="text-sm leading-7 text-[color:var(--text-muted)]">
              Taslak kaydı public blogda görünmez. Yayınla düğmesi, yayın tarihi boşsa bugünün anını kullanır.
            </p>

            {state.message ? (
              <p
                className={`mt-5 rounded-2xl border px-4 py-3 text-sm ${
                  state.success
                    ? "border-emerald-400/20 bg-emerald-400/10 text-emerald-100"
                    : "border-red-400/20 bg-red-400/10 text-red-100"
                }`}
              >
                {state.message}
              </p>
            ) : null}

            <div className="mt-6 flex flex-col gap-3">
              <button
                type="submit"
                name="intent"
                value="draft"
                disabled={isPending}
                className="button-secondary min-h-12 justify-center disabled:cursor-not-allowed disabled:opacity-60"
              >
                Taslak kaydet
              </button>
              <button
                type="submit"
                name="intent"
                value="publish"
                disabled={isPending}
                className="button-primary min-h-12 justify-center disabled:cursor-not-allowed disabled:opacity-60"
              >
                {submitLabel}
              </button>
            </div>
          </section>
        </aside>
      </div>
    </form>
  );
}
