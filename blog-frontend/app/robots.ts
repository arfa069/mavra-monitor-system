import type { MetadataRoute } from "next";
import { canonicalUrl } from "../src/lib/blog";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/blog",
    },
    sitemap: canonicalUrl("/sitemap.xml"),
  };
}
