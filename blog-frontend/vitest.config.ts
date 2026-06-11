import { transformWithOxc } from "vite";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [
    {
      name: "tsx-test-transform",
      enforce: "pre",
      async transform(code, id) {
        if (!id.endsWith(".tsx")) {
          return null;
        }
        return transformWithOxc(code, id, {
          loader: "tsx",
          jsx: { runtime: "automatic" },
        } as any);
      },
    },
  ],
  test: {
    environment: "node",
  },
});
