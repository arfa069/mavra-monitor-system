import Link from "next/link";
import {
  absoluteAssetUrl,
  formatDate,
  getPosts,
} from "../../../../src/lib/blog";

export const dynamic = "force-dynamic";

type CategoryPageProps = {
  params: Promise<{ slug: string }>;
};

export default async function CategoryPage({ params }: CategoryPageProps) {
  const { slug } = await params;
  const posts = await getPosts({ category: slug });

  return (
    <main className="page">
      <section className="hero">
        <div>
          <p className="eyebrow">CATEGORY</p>
          <h1>{slug}</h1>
        </div>
      </section>
      <section className="post-grid">
        {posts.items.map((post) => {
          const coverUrl = absoluteAssetUrl(post.cover_url);
          return (
            <Link
              key={post.slug}
              href={`/blog/${post.slug}`}
              className="post-card"
            >
              <div className="post-cover">
                {coverUrl ? <img src={coverUrl} alt="" /> : null}
              </div>
              <div className="post-body">
                <span className="pill">{formatDate(post.published_at)}</span>
                <h2>{post.title}</h2>
                <p className="muted">{post.excerpt}</p>
              </div>
            </Link>
          );
        })}
      </section>
    </main>
  );
}
