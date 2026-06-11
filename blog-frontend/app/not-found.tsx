import Link from "next/link";

export default function NotFound() {
  return (
    <main className="page">
      <section className="article-shell">
        <p className="eyebrow">Not found</p>
        <h1>This note is not public.</h1>
        <p className="hero-copy">
          It may still be a draft, scheduled for later, or moved elsewhere.
        </p>
        <Link className="button" href="/blog">
          Back to blog
        </Link>
      </section>
    </main>
  );
}
