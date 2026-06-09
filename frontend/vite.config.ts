import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { visualizer } from "rollup-plugin-visualizer";

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
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  build: {
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
        rewrite: (path: string) => path.replace(/^\/api/, ""),
      },
    },
  },
});
