import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { getPublishedBlogPostsSafe } from "@/lib/blog/queries";

function getSafeExternalImageUrl(value: string | null) {
  if (!value) return false;

  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:" ? value : null;
  } catch {
    return null;
  }
}

function formatDate(value: string | null) {
  if (!value) return "Yakında";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Yakında";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Europe/Istanbul",
  }).format(date);
}

export const metadata: Metadata = {
  title: "LabelWise Blog",
  description: "Gıda etiketleri, katkı maddeleri ve bilinçli tüketim hakkında yazılar.",
  alternates: {
    canonical: "/blog",
  },
  openGraph: {
    title: "LabelWise Blog",
    description: "Gıda etiketleri, katkı maddeleri ve bilinçli tüketim hakkında yazılar.",
    url: "https://labelwise.net/blog",
    type: "website",
  },
};

export default async function BlogPage() {
  const { data: posts, error } = await getPublishedBlogPostsSafe();

  return (
    <main className="relative overflow-hidden">
      <section className="mx-auto flex w-full max-w-7xl flex-col gap-10 px-6 py-16 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            LabelWise Blog
          </p>
          <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
            LabelWise Blog
          </h1>
          <p className="mt-4 max-w-3xl text-base leading-8 text-[color:var(--text-muted)]">
            Gıda etiketleri, katkı maddeleri ve bilinçli tüketim üzerine yazılar.
          </p>
        </div>

        {error ? (
          <div className="card p-6 sm:p-8">
            <p className="text-sm leading-7 text-[color:var(--text-muted)]">
              Blog içerikleri şu anda alınamadı. Biraz sonra tekrar deneyebilirsin.
            </p>
          </div>
        ) : null}

        {posts.length === 0 ? (
          <div className="card p-8 sm:p-10">
            <h2 className="text-2xl font-semibold text-white">Henüz yayınlanmış blog yazısı yok.</h2>
            <p className="mt-3 max-w-2xl text-sm leading-7 text-[color:var(--text-muted)]">
              İlk yazılar çok yakında burada olacak. Bu sayfa sadece yayındaki içerikleri gösterir.
            </p>
          </div>
        ) : (
          <div className="grid gap-6 lg:grid-cols-2">
            {posts.map((post) => (
              <article key={post.id} className="card overflow-hidden">
                {(() => {
                  const safeCoverImageUrl = getSafeExternalImageUrl(post.cover_image_url);
                  if (!safeCoverImageUrl) return null;

                  return (
                  <div className="h-56 w-full overflow-hidden border-b border-white/8">
                    <div className="relative h-full w-full">
                      <Image
                        src={safeCoverImageUrl}
                        alt={post.title}
                        fill
                        unoptimized
                        className="object-cover"
                        sizes="(max-width: 1024px) 100vw, 50vw"
                      />
                    </div>
                  </div>
                  );
                })()}
                <div className="p-8">
                  <div className="flex flex-wrap items-center gap-3 text-xs uppercase tracking-[0.24em] text-[color:var(--gold-soft)]">
                    {post.category ? <span>{post.category}</span> : null}
                    <span className="text-white/35">•</span>
                    <time dateTime={post.published_at ?? undefined}>{formatDate(post.published_at)}</time>
                  </div>
                  <h2 className="mt-4 text-3xl font-semibold text-white">{post.title}</h2>
                  {post.excerpt ? (
                    <p className="mt-4 text-sm leading-8 text-[color:var(--text-muted)]">
                      {post.excerpt}
                    </p>
                  ) : null}
                  <Link href={`/blog/${post.slug}`} className="button-primary mt-8 min-h-11 px-5">
                    Yazıyı oku
                  </Link>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
