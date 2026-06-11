import Link from "next/link";
import {
  absoluteAssetUrl,
  formatDate,
  getCategories,
  getPosts,
  getTags,
} from "../../src/lib/blog";

export const dynamic = "force-dynamic";

type BlogPageProps = {
  searchParams?: Promise<{ q?: string; page?: string }>;
};

export default async function BlogPage({ searchParams }: BlogPageProps) {
  const resolvedSearchParams = await searchParams;
  const keyword = resolvedSearchParams?.q?.trim() || undefined;
  const page = Number(resolvedSearchParams?.page || 1);
  const [posts, categories, tags] = await Promise.all([
    getPosts({ keyword, page: Number.isFinite(page) ? page : 1 }),
    getCategories(),
    getTags(),
  ]);

  return (
    <main className="page">
      <section className="hero">
        <div>
          <p className="eyebrow">PUBLIC NOTES</p>
          <h1>Mavra watches quietly, then writes clearly.</h1>
          <p className="hero-copy">
            Product notes, system changes, and practical automation write-ups
            from the Mavra Monitor System.
          </p>
        </div>
        <div className="search-card">
          <form action="/blog">
            <input
              name="q"
              defaultValue={keyword}
              placeholder="Search notes, tags, and categories"
            />
            <button type="submit">Search</button>
          </form>
        </div>
      </section>

      <section className="post-grid" aria-label="Published posts">
        {posts.items.map((post) => {
          const coverUrl = absoluteAssetUrl(post.cover_url);
          return (
            <Link key={post.slug} href={`/blog/${post.slug}`} className="post-card">
              <div className="post-cover">
                {coverUrl ? <img src={coverUrl} alt="" /> : null}
              </div>
              <div className="post-body">
                <div className="tag-row">
                  {post.category ? (
                    <span className="pill">{post.category.name}</span>
                  ) : null}
                  <span className="pill">{formatDate(post.published_at)}</span>
                </div>
                <h2>{post.title}</h2>
                <p className="muted">{post.excerpt || post.seo_description}</p>
                <div className="tag-row">
                  {post.tags.map((tag) => (
                    <span className="pill" key={tag.id}>
                      {tag.name}
                    </span>
                  ))}
                </div>
              </div>
            </Link>
          );
        })}
      </section>

      <section id="categories" className="taxonomy-grid">
        <div className="taxonomy-card">
          <h2>Categories</h2>
          <div className="tag-row">
            {categories.map((category) => (
              <Link className="pill" href={`/blog/category/${category.slug}`} key={category.id}>
                {category.name}
              </Link>
            ))}
          </div>
        </div>
        <div className="taxonomy-card">
          <h2>Tags</h2>
          <div className="tag-row">
            {tags.map((tag) => (
              <Link className="pill" href={`/blog/tag/${tag.slug}`} key={tag.id}>
                {tag.name}
              </Link>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
