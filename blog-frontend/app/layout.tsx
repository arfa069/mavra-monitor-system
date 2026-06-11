import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";
import { canonicalUrl, publicBaseUrl } from "../src/lib/blog";

export const metadata: Metadata = {
  metadataBase: new URL(publicBaseUrl()),
  title: {
    default: "Mavra Blog",
    template: "%s | Mavra Blog",
  },
  description: "Notes from Mavra Monitor System.",
  alternates: {
    canonical: canonicalUrl("/blog"),
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <div className="site-shell">
          <header className="site-header">
            <Link href="/blog" className="brand">
              <span className="brand-mark">M</span>
              <span>Mavra Blog</span>
            </Link>
            <nav className="nav-links" aria-label="Blog navigation">
              <Link href="/blog">Latest</Link>
              <Link href="/blog#categories">Categories</Link>
              <a href="/">Console</a>
            </nav>
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
