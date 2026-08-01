import type { Metadata } from "next";
import Image from "next/image";
import Script from "next/script";
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { getPublishedBlogPostBySlug, getPublishedBlogPostBySlugSafe } from "@/lib/blog/queries";

type Props = {
  params: Promise<{
    slug: string;
  }>;
};

function getSafeExternalImageUrl(value: string | null) {
  if (!value) return null;

  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:" ? value : null;
  } catch {
    return null;
  }
}

function formatDate(value: string | null) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Europe/Istanbul",
  }).format(date);
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const { data: post } = await getPublishedBlogPostBySlugSafe(slug);

  if (!post) {
    return {
      title: "Yazı bulunamadı",
    };
  }

  const title = post.seo_title || post.title;
  const description = post.seo_description || post.excerpt || "LabelWise blog yazısı";
  const safeCoverImageUrl = getSafeExternalImageUrl(post.cover_image_url);

  return {
    title,
    description,
    alternates: {
      canonical: `/blog/${post.slug}`,
    },
    openGraph: {
      title,
      description,
      url: `https://labelwise.net/blog/${post.slug}`,
      type: "article",
      images: safeCoverImageUrl
        ? [
            {
              url: safeCoverImageUrl,
              alt: post.title,
            },
          ]
        : undefined,
    },
  };
}

export default async function BlogDetailPage({ params }: Props) {
  const { slug } = await params;
  const post = await getPublishedBlogPostBySlug(slug);

  if (!post) {
    notFound();
  }

  const safeCoverImageUrl = getSafeExternalImageUrl(post.cover_image_url);
  const formattedDate = formatDate(post.published_at);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.seo_description || post.excerpt || post.title,
    ...(post.published_at ? { datePublished: post.published_at } : {}),
    ...(post.updated_at ? { dateModified: post.updated_at } : {}),
    ...(safeCoverImageUrl ? { image: [safeCoverImageUrl] } : {}),
    author: {
      "@type": "Organization",
      name: "LabelWise",
    },
    publisher: {
      "@type": "Organization",
      name: "LabelWise",
      logo: {
        "@type": "ImageObject",
        url: "https://labelwise.net/labelwise-logo.png",
      },
    },
    mainEntityOfPage: `https://labelwise.net/blog/${post.slug}`,
  };

  return (
    <main className="relative overflow-hidden">
      <Script
        id={`blog-posting-${post.id}`}
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-16 sm:px-8 lg:px-10">
        <header className="glass-panel p-8 sm:p-10">
          <div className="flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.26em] text-[color:var(--gold-soft)]">
            {post.category ? <span>{post.category}</span> : null}
            {formattedDate ? (
              <>
                <span className="text-white/35">•</span>
                <time dateTime={post.published_at ?? undefined}>{formattedDate}</time>
              </>
            ) : null}
          </div>
          <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">{post.title}</h1>
          {post.excerpt ? (
            <p className="mt-5 max-w-3xl text-base leading-8 text-[color:var(--text-muted)]">
              {post.excerpt}
            </p>
          ) : null}
          {post.tags.length ? (
            <div className="mt-6 flex flex-wrap gap-2">
              {post.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full border border-white/10 bg-white/[0.05] px-3 py-1 text-xs text-white/78"
                >
                  #{tag}
                </span>
              ))}
            </div>
          ) : null}
        </header>

        {safeCoverImageUrl ? (
          <div className="h-72 overflow-hidden rounded-[2rem] border border-white/8 sm:h-[26rem]">
            <div className="relative h-full w-full">
              <Image
                src={safeCoverImageUrl}
                alt={post.title}
                fill
                unoptimized
                className="object-cover"
                sizes="(max-width: 1024px) 100vw, 896px"
              />
            </div>
          </div>
        ) : null}

        <section className="card p-8 sm:p-10">
          <div className="markdown-content">
            <ReactMarkdown>{post.content_markdown || "Bu yazının içeriği henüz eklenmemiş."}</ReactMarkdown>
          </div>
        </section>
      </article>
    </main>
  );
}
