import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  absoluteAssetUrl,
  buildArticleJsonLd,
  canonicalUrl,
  formatDate,
  getPost,
} from "../../../src/lib/blog";

export const dynamic = "force-dynamic";

type BlogPostPageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateMetadata({
  params,
}: BlogPostPageProps): Promise<Metadata> {
  try {
    const { slug } = await params;
    const post = await getPost(slug);
    const title = post.seo_title || post.title;
    const description = post.seo_description || post.excerpt || undefined;
    const image = absoluteAssetUrl(post.og_image_url || post.cover_url) || undefined;
    return {
      title,
      description,
      alternates: {
        canonical: post.canonical_url || canonicalUrl(`/blog/${post.slug}`),
      },
      openGraph: {
        type: "article",
        title,
        description,
        url: post.canonical_url || canonicalUrl(`/blog/${post.slug}`),
        publishedTime: post.published_at || undefined,
        modifiedTime: post.updated_at,
        images: image ? [{ url: image }] : undefined,
      },
    };
  } catch {
    return { title: "Post not found" };
  }
}

export default async function BlogPostPage({ params }: BlogPostPageProps) {
  let post;
  try {
    const { slug } = await params;
    post = await getPost(slug);
  } catch {
    notFound();
  }
  const coverUrl = absoluteAssetUrl(post.cover_url);
  const jsonLd = buildArticleJsonLd(post);

  return (
    <main className="page">
      <article className="article-shell">
        <p className="eyebrow">{post.category?.name || "Mavra Blog"}</p>
        <h1>{post.title}</h1>
        <div className="article-meta">
          <span className="pill">{formatDate(post.published_at)}</span>
          {post.tags.map((tag) => (
            <Link className="pill" href={`/blog/tag/${tag.slug}`} key={tag.id}>
              {tag.name}
            </Link>
          ))}
        </div>
        {post.excerpt ? <p className="hero-copy">{post.excerpt}</p> : null}
        {coverUrl ? <img className="article-cover" src={coverUrl} alt="" /> : null}
        <div
          className="article-content"
          dangerouslySetInnerHTML={{ __html: post.content_html }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </article>
    </main>
  );
}
