import type { Metadata } from "next";
import Image from "next/image";
import Script from "next/script";
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { getPublishedBlogPostBySlug } from "@/lib/blog/queries";

type Props = {
  params: Promise<{
    slug: string;
  }>;
};

function formatDate(value: string | null) {
  if (!value) return null;
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Europe/Istanbul",
  }).format(new Date(value));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPublishedBlogPostBySlug(slug);

  if (!post) {
    return {
      title: "Yazı bulunamadı",
    };
  }

  const title = post.seo_title || post.title;
  const description = post.seo_description || post.excerpt || "LabelWise blog yazısı";

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
      images: post.cover_image_url
        ? [
            {
              url: post.cover_image_url,
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

  const formattedDate = formatDate(post.published_at);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.seo_description || post.excerpt || post.title,
    datePublished: post.published_at,
    dateModified: post.updated_at,
    image: post.cover_image_url ? [post.cover_image_url] : undefined,
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

        {post.cover_image_url ? (
          <div className="relative h-72 overflow-hidden rounded-[2rem] border border-white/8 sm:h-[26rem]">
            <Image
              src={post.cover_image_url}
              alt={post.title}
              fill
              unoptimized
              className="object-cover"
              sizes="(max-width: 1024px) 100vw, 896px"
            />
          </div>
        ) : null}

        <section className="card p-8 sm:p-10">
          <div className="markdown-content">
            <ReactMarkdown>{post.content_markdown}</ReactMarkdown>
          </div>
        </section>
      </article>
    </main>
  );
}
