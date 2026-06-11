import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  outputFileTracingRoot: rootDir,
  devIndicators: false,
  images: {
    unoptimized: true,
  },
  async rewrites() {
    const backendOrigin = process.env.BLOG_BACKEND_ORIGIN || "http://127.0.0.1:8000";
    return [
      {
        source: "/blog-media/:path*",
        destination: `${backendOrigin}/blog-media/:path*`,
      },
    ];
  },
};

export default nextConfig;
