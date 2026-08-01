import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { getPublishedBlogPosts } from "@/lib/blog/queries";

function formatDate(value: string | null) {
  if (!value) return "Yakında";
  return new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Europe/Istanbul",
  }).format(new Date(value));
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
  const posts = await getPublishedBlogPosts();

  return (
    <main className="relative overflow-hidden">
      <section className="mx-auto flex w-full max-w-7xl flex-col gap-10 px-6 py-16 sm:px-8 lg:px-10">
        <div className="glass-panel p-8 sm:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.34em] text-[color:var(--gold-soft)]">
            LabelWise Blog
          </p>
          <h1 className="mt-4 font-display text-4xl text-white sm:text-5xl">
            Etiketleri sadeleştiren yazılar
          </h1>
          <p className="mt-4 max-w-3xl text-base leading-8 text-[color:var(--text-muted)]">
            Gıda etiketleri, katkı maddeleri ve günlük seçimleri kolaylaştıran içerikleri tek
            yerde topluyoruz.
          </p>
        </div>

        {posts.length === 0 ? (
          <div className="card p-8 sm:p-10">
            <h2 className="text-2xl font-semibold text-white">Henüz yayımlanmış yazı yok</h2>
            <p className="mt-3 max-w-2xl text-sm leading-7 text-[color:var(--text-muted)]">
              İlk yazılar çok yakında burada olacak. Bu sayfa sadece yayındaki içerikleri gösterir.
            </p>
          </div>
        ) : (
          <div className="grid gap-6 lg:grid-cols-2">
            {posts.map((post) => (
              <article key={post.id} className="card overflow-hidden">
                {post.cover_image_url ? (
                  <div className="relative h-56 w-full overflow-hidden border-b border-white/8">
                    <Image
                      src={post.cover_image_url}
                      alt={post.title}
                      fill
                      unoptimized
                      className="object-cover"
                      sizes="(max-width: 1024px) 100vw, 50vw"
                    />
                  </div>
                ) : null}
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
