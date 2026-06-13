import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { visualizer } from "rollup-plugin-visualizer";
import { compression } from "vite-plugin-compression2";

const VENDOR_CHUNKS: Record<string, string[]> = {
  "vendor-react": ["react", "react-dom", "react-router-dom"],
  "vendor-antd": ["antd", "@ant-design/icons"],
  "vendor-recharts": ["recharts"],
  "vendor-framer": ["framer-motion"],
  "vendor-query": ["@tanstack/react-query", "axios"],
};

function manualChunks(id: string): string | undefined {
  for (const [chunk, pkgs] of Object.entries(VENDOR_CHUNKS)) {
    if (pkgs.some((pkg) => id.includes(`/node_modules/${pkg}/`))) {
      return chunk;
    }
  }
  return undefined;
}

export default defineConfig({
  plugins: [
    react(),
    // Generates dist/stats.html after every build — open it to see bundle composition.
    visualizer({ filename: "dist/stats.html", open: false, gzipSize: true }),
    // Pre-compress assets for nginx/caddy static serving (gzip + brotli).
    // Nginx: add `gzip_static on; brotli_static on;` to your server block.
    compression({ algorithms: ["gzip", "brotliCompress"], exclude: [/\.map$/, /\.html$/] }),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  build: {
    chunkSizeWarningLimit: 1500,
    rollupOptions: {
      output: {
        manualChunks,
      },
    },
  },
  server: {
    port: 3000,
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
    },
  },
});
