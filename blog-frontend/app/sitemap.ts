import type { MetadataRoute } from "next";
import { canonicalUrl, getPosts } from "../src/lib/blog";

export const dynamic = "force-dynamic";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  let posts = { items: [] as Awaited<ReturnType<typeof getPosts>>["items"] };
  try {
    posts = await getPosts({ size: 50 });
  } catch {
    posts = { items: [] };
  }
  return [
    {
      url: canonicalUrl("/blog"),
      lastModified: new Date(),
      changeFrequency: "daily",
      priority: 0.9,
    },
    ...posts.items.map((post) => ({
      url: canonicalUrl(`/blog/${post.slug}`),
      lastModified: new Date(post.updated_at),
      changeFrequency: "weekly" as const,
      priority: 0.7,
    })),
  ];
}
